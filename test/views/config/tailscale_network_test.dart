import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/tailscale_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class _MockCore extends Mock implements CoreHandlerInterface {}

const _name = 'Tailscale';

const _running = TailscaleNetStatus(
  started: true,
  backendState: 'Running',
  peers: [
    TailscalePeer(id: 'a', hostName: 'nas', ips: ['100.64.0.2'], online: true),
    TailscalePeer(
      id: 'b',
      hostName: 'pc',
      ips: ['100.64.0.3', 'fd7a:115c:a1e9::3'],
      online: true,
    ),
    TailscalePeer(id: 'c', hostName: 'old', ips: ['100.64.0.4']),
  ],
);

void main() {
  late _MockCore core;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    core = _MockCore();
    container = ProviderContainer(
      overrides: [
        coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
      ],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  void answerStatus(List<TailscaleNetStatus> answers) {
    var index = 0;
    when(
      () => core.tailscaleStatus(
        any(),
        start: any(named: 'start'),
        reset: any(named: 'reset'),
        wait: any(named: 'wait'),
        rebind: any(named: 'rebind'),
      ),
    ).thenAnswer((_) async {
      final answer =
          answers[index < answers.length ? index : answers.length - 1];
      index++;
      return answer;
    });
  }

  Future<GlobalKey<TailscaleNetworkSectionState>> pump(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<TailscaleNetworkSectionState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: TailscaleNetworkSection(
                key: key,
                proxyName: _name,
                onApply: () async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return key;
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  TailscalePhase phase() => container.read(tailscaleStateProvider).phase;

  testWidgets('a connect shows connecting until the node settles', (
    tester,
  ) async {
    answerStatus(const [
      TailscaleNetStatus(),
      TailscaleNetStatus(started: true, backendState: 'NeedsLogin'),
      TailscaleNetStatus(started: true, backendState: 'Starting'),
      _running,
    ]);
    final key = await pump(tester);

    final connecting = key.currentState!.connect();
    await tester.pump();
    expect(phase(), TailscalePhase.connecting);
    verify(
      () => core.tailscaleStatus(_name, start: true, reset: false, wait: true),
    ).called(1);

    await tester.pump(tailscaleSettleInterval);
    expect(phase(), TailscalePhase.connecting);
    await tester.pump(tailscaleSettleInterval);
    await connecting;
    expect(phase(), TailscalePhase.running);

    await teardown(tester);
  });

  testWidgets('a node that really needs a login shows it after a connect', (
    tester,
  ) async {
    answerStatus(const [
      TailscaleNetStatus(),
      TailscaleNetStatus(started: true, backendState: 'NeedsLogin'),
      TailscaleNetStatus(
        started: true,
        backendState: 'NeedsLogin',
        authUrl: 'https://login.tailscale.com/a/x',
      ),
    ]);
    final key = await pump(tester);

    final connecting = key.currentState!.connect();
    await tester.pump();
    expect(phase(), TailscalePhase.connecting);
    await tester.pump(tailscaleSettleInterval);
    await connecting;
    final status = container.read(tailscaleStateProvider);
    expect(status.phase, TailscalePhase.needsLogin);
    expect(status.loginUrl, 'https://login.tailscale.com/a/x');

    await teardown(tester);
  });

  testWidgets('test all pings the online peers and shows the path', (
    tester,
  ) async {
    answerStatus(const [_running]);
    when(() => core.tailscalePing(any(), any())).thenAnswer(
      (invocation) async => [
        for (final target in invocation.positionalArguments[1] as List<String>)
          switch (target) {
            '100.64.0.2' => const TailscalePingResult(
              target: '100.64.0.2',
              latencyMs: 12,
              endpoint: '1.2.3.4:41641',
            ),
            _ => TailscalePingResult(
              target: target,
              latencyMs: 180,
              derpRegionId: 11,
              derpRegionCode: 'tok',
            ),
          },
      ],
    );
    await pump(tester);
    expect(find.text('12 ms'), findsNothing);

    await tester.tap(find.byTooltip('Test all'));
    await tester.pump();

    final targets =
        verify(() => core.tailscalePing(_name, captureAny())).captured.single
            as List<String>;
    expect(targets, unorderedEquals(['100.64.0.2', '100.64.0.3']));
    expect(find.text('12 ms'), findsOneWidget);
    expect(find.text('180 ms'), findsOneWidget);
    expect(find.textContaining('Direct'), findsOneWidget);
    expect(find.textContaining('Relay DERP-tok'), findsOneWidget);

    await tester.longPress(find.text('nas'));
    await tester.pump();
    final single =
        verify(() => core.tailscalePing(_name, captureAny())).captured.single
            as List<String>;
    expect(single, ['100.64.0.2']);

    await teardown(tester);
  });

  testWidgets('a network change rebinds the node and drops old latencies', (
    tester,
  ) async {
    answerStatus(const [
      _running,
      TailscaleNetStatus(started: true, backendState: 'Starting'),
      _running,
    ]);
    when(() => core.tailscalePing(any(), any())).thenAnswer(
      (_) async => const [
        TailscalePingResult(
          target: '100.64.0.2',
          latencyMs: 12,
          endpoint: '1.2.3.4:41641',
        ),
      ],
    );
    await pump(tester);
    await tester.tap(find.byTooltip('Test latency').first);
    await tester.pump();
    expect(find.text('12 ms'), findsOneWidget);

    container.read(networkChangesProvider.notifier).bump();
    await tester.pump();

    expect(find.text('12 ms'), findsNothing);
    expect(phase(), TailscalePhase.connecting);
    verify(
      () => core.tailscaleStatus(
        _name,
        start: false,
        reset: false,
        wait: true,
        rebind: true,
      ),
    ).called(1);
    await tester.pump(tailscaleSettleInterval);
    await tester.pump();
    expect(phase(), TailscalePhase.running);
    expect(find.byTooltip('Test latency'), findsNWidgets(2));

    await teardown(tester);
  });

  testWidgets('the section has no connect of its own', (tester) async {
    answerStatus([
      const TailscaleNetStatus(),
      const TailscaleNetStatus(
        started: true,
        backendState: 'NeedsLogin',
        self: TailscalePeer(id: 's', hostName: 'localhost', os: 'android'),
      ),
    ]);
    final key = await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Connect'), findsNothing);
    await key.currentState!.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Connect'), findsNothing);
    // With no device to test there is no lightning action either.
    expect(find.byTooltip('Test all'), findsNothing);
    await teardown(tester);
  });
}
