import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/node_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

const _uuid = '11111111-2222-3333-4444-555555555555';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    container.listen(groupsProvider, (_, _) {});
    container.read(groupsProvider.notifier).value = [
      const Group(
        type: GroupType.Selector,
        name: 'Auto',
        hidden: false,
        now: 'HK',
        all: [
          Proxy(name: 'HK', type: 'Vless'),
          Proxy(name: 'JP', type: 'Ss'),
        ],
      ),
    ];
  });

  tearDown(() => container.dispose());

  Future<void> pump(
    WidgetTester tester,
    Proxy proxy, [
    Map<String, dynamic>? config,
  ]) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Scaffold(
            body: NodeInfoView(proxy: proxy, loadConfig: () async => config),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a node shows its fields with secrets masked until revealed', (
    tester,
  ) async {
    await pump(tester, const Proxy(name: 'HK', type: 'Vless'), {
      'proxies': [
        {
          'name': 'HK',
          'type': 'vless',
          'server': 'hk.example.com',
          'port': 443,
          'uuid': _uuid,
          'network': 'ws',
        },
      ],
    });

    expect(find.text('hk.example.com'), findsOneWidget);
    expect(find.text('443'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text(_uuid), findsNothing);
    expect(find.byKey(const ValueKey('node-copy-yaml')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-copy-json')), findsOneWidget);

    await tester.tap(find.byTooltip('Show'));
    await tester.pump();
    expect(find.text(_uuid), findsOneWidget);
    await tester.tap(find.byTooltip('Hide'));
    await tester.pump();
    expect(find.text(_uuid), findsNothing);
  });

  testWidgets('a node missing from the profile says so', (tester) async {
    await pump(tester, const Proxy(name: 'JP', type: 'Ss'), {'proxies': []});
    expect(find.byKey(const ValueKey('node-config-missing')), findsOneWidget);
    expect(find.text('JP'), findsOneWidget);
  });

  testWidgets('a group lists its members and selection', (tester) async {
    await pump(tester, const Proxy(name: 'Auto', type: 'Selector'));
    expect(find.text('Selector'), findsOneWidget);
    expect(find.text('Members (2)'), findsOneWidget);
    expect(find.byKey(const ValueKey('node-member-HK')), findsOneWidget);
    expect(find.text('✓ Vless'), findsOneWidget);
    expect(find.byKey(const ValueKey('node-config-missing')), findsNothing);
  });
}
