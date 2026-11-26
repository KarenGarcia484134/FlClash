import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/macos_update.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:prism_ui/common_button.dart';

import '../helpers/app_paths.dart';
import '../helpers/host_scaffold.dart';
import '../helpers/test_app.dart';

class MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

class _FakeMacosAppUpdate extends MacosAppUpdate {
  _FakeMacosAppUpdate(this.onInstall) : super('/Applications/FlClash.app');

  final Future<bool> Function({
    required String staged,
    required String tag,
    required String marker,
  })
  onInstall;
  int installCalls = 0;

  @override
  Future<bool> install({
    required String staged,
    required String tag,
    required String marker,
  }) {
    installCalls++;
    return onInstall(staged: staged, tag: tag, marker: marker);
  }
}

class _MacosCommonAction extends CommonAction {
  _MacosCommonAction(this._macos);

  final MacosAppUpdate _macos;

  @override
  MacosAppUpdate? get macosUpdate => _macos;
}

class _RecordingSystemAction extends SystemAction {
  _RecordingSystemAction({this.onExit});

  final Future<void> Function()? onExit;
  int exitCalls = 0;

  @override
  Future<void> handleExit([bool needSave = true]) {
    exitCalls++;
    return onExit?.call() ?? Future<void>.value();
  }
}

const runningVersion = '0.8.96';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCoreHandlerInterface core;

  setUpAll(() {
    core = MockCoreHandlerInterface();
    globalState.packageInfo = PackageInfo(
      appName: 'FlClash',
      packageName: 'com.follow.clash',
      version: runningVersion,
      buildNumber: '1',
    );
  });

  setUp(() => reset(core));

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('CommonAction.updateMode', () {
    test('advances through every mode and wraps back to the first', () {
      final container = buildContainer();
      final action = container.read(commonActionProvider.notifier);
      container
          .read(patchClashConfigProvider.notifier)
          .update((state) => state.copyWith(mode: Mode.values.first));

      final seen = <Mode>[container.read(patchClashConfigProvider).mode];
      for (var i = 0; i < Mode.values.length; i++) {
        action.updateMode();
        seen.add(container.read(patchClashConfigProvider).mode);
      }

      expect(seen.sublist(0, Mode.values.length), Mode.values);
      expect(seen.last, Mode.values.first, reason: 'wraps after the last mode');
    });
  });

  group('CommonAction.updateSpeedStatistics', () {
    test('toggles the tray title flag both ways', () {
      final container = buildContainer();
      final action = container.read(commonActionProvider.notifier);
      final initial = container.read(appSettingProvider).showTrayTitle;

      action.updateSpeedStatistics();
      expect(container.read(appSettingProvider).showTrayTitle, !initial);

      action.updateSpeedStatistics();
      expect(container.read(appSettingProvider).showTrayTitle, initial);
    });
  });

  group('CommonAction.updateTraffic', () {
    test('records the sampled traffic and the running total', () async {
      final container = buildContainer();
      container
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(onlyStatisticsProxy: true));
      when(
        () => core.getTraffic(true),
      ).thenAnswer((_) async => const Traffic(up: 10, down: 20));
      when(
        () => core.getTotalTraffic(true),
      ).thenAnswer((_) async => const Traffic(up: 100, down: 200));

      await container.read(commonActionProvider.notifier).updateTraffic();

      expect(container.read(trafficsProvider).list.last.up, 10);
      expect(container.read(trafficsProvider).list.last.down, 20);
      expect(
        container.read(totalTrafficProvider),
        const Traffic(up: 100, down: 200),
      );
      verify(() => core.getTraffic(true)).called(1);
      verify(() => core.getTotalTraffic(true)).called(1);
    });

    test('swallows a core failure and leaves the total untouched', () async {
      final container = buildContainer();
      final before = container.read(totalTrafficProvider);
      when(() => core.getTraffic(any())).thenThrow(StateError('core down'));

      await expectLater(
        container.read(commonActionProvider.notifier).updateTraffic(),
        completes,
      );
      expect(container.read(totalTrafficProvider), before);
    });

    test('does not record a total when only the total call fails', () async {
      final container = buildContainer();
      final before = container.read(totalTrafficProvider);
      when(
        () => core.getTraffic(any()),
      ).thenAnswer((_) async => const Traffic(up: 1, down: 2));
      when(() => core.getTotalTraffic(any())).thenThrow(StateError('boom'));

      await container.read(commonActionProvider.notifier).updateTraffic();

      expect(container.read(trafficsProvider).list.last.up, 1);
      expect(container.read(totalTrafficProvider), before);
    });

    test(
      'drops concurrent in-flight updates while one is in progress',
      () async {
        final container = buildContainer();
        final completer = Completer<Traffic>();
        when(() => core.getTraffic(any())).thenAnswer((_) => completer.future);
        when(
          () => core.getTotalTraffic(any()),
        ).thenAnswer((_) => completer.future);

        final first = container
            .read(commonActionProvider.notifier)
            .updateTraffic();
        final second = container
            .read(commonActionProvider.notifier)
            .updateTraffic();

        await expectLater(second, completes);
        completer.complete(const Traffic(up: 5, down: 10));
        await first;

        verify(() => core.getTraffic(any())).called(1);
        verify(() => core.getTotalTraffic(any())).called(1);
      },
    );
  });

  group('CommonAction.autoCheckUpdate', () {
    test('returns without a network call when the setting is off', () async {
      final container = buildContainer();
      container
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(autoCheckUpdate: false));

      await expectLater(
        container.read(commonActionProvider.notifier).autoCheckUpdate(),
        completion(isFalse),
      );
    });
  });

  group('CommonAction.installUpdate on macOS', () {
    late Directory home;

    setUp(() async {
      home = await Directory.systemTemp.createTemp('flclash-macos-install-');
      await useAppPaths(home);
    });

    tearDown(() async {
      if (home.existsSync()) {
        await home.delete(recursive: true);
      }
    });

    File stageUpdateFile() {
      return File(join(home.path, 'update', 'FlClash.app'))
        ..createSync(recursive: true)
        ..writeAsStringSync('staged');
    }

    test(
      'ignores discardUpdate while macOS install and exit are in flight',
      () async {
        final staged = stageUpdateFile();
        final installStarted = Completer<bool>();
        final exitCompleter = Completer<void>();
        final macos = _FakeMacosAppUpdate(
          ({required staged, required tag, required marker}) =>
              installStarted.future,
        );
        final systemAction = _RecordingSystemAction(
          onExit: () => exitCompleter.future,
        );
        final container = ProviderContainer(
          overrides: [
            commonActionProvider.overrideWith(() => _MacosCommonAction(macos)),
            systemActionProvider.overrideWith(() => systemAction),
          ],
        );
        addTearDown(container.dispose);

        final ready = UpdateReady('v0.9.35', staged.path);
        container.read(updateDownloadStateProvider.notifier).value = ready;

        final action = container.read(commonActionProvider.notifier);
        final installFuture = action.installUpdate();

        expect(container.read(updateDownloadStateProvider), isNull);
        await action.discardUpdate();
        expect(staged.existsSync(), isTrue);

        installStarted.complete(true);
        await pumpEventQueue();
        expect(systemAction.exitCalls, 1);

        await action.discardUpdate();
        expect(staged.existsSync(), isTrue);
        expect(container.read(updateDownloadStateProvider), isNull);

        exitCompleter.complete();
        await installFuture;
      },
    );

    test(
      'restores UpdateReady when macOS install returns without starting',
      () async {
        final staged = stageUpdateFile();
        var shouldStart = false;
        final macos = _FakeMacosAppUpdate(
          ({required staged, required tag, required marker}) async =>
              shouldStart,
        );
        final systemAction = _RecordingSystemAction();
        final container = ProviderContainer(
          overrides: [
            commonActionProvider.overrideWith(() => _MacosCommonAction(macos)),
            systemActionProvider.overrideWith(() => systemAction),
          ],
        );
        addTearDown(container.dispose);

        final ready = UpdateReady('v0.9.35', staged.path);
        container.read(updateDownloadStateProvider.notifier).value = ready;

        final action = container.read(commonActionProvider.notifier);
        await action.installUpdate();

        expect(container.read(updateDownloadStateProvider), ready);
        expect(systemAction.exitCalls, 0);

        shouldStart = true;
        await action.installUpdate();
        expect(macos.installCalls, 2);
        expect(systemAction.exitCalls, 1);
      },
    );

    testWidgets('restores UpdateReady for retry when macOS install throws', (
      tester,
    ) async {
      await useAppPaths(home);
      final staged = stageUpdateFile();
      var attempt = 0;
      final macos = _FakeMacosAppUpdate(({
        required staged,
        required tag,
        required marker,
      }) async {
        attempt++;
        if (attempt == 1) {
          throw const MacosUpdateException('permission denied');
        }
        return true;
      });
      final systemAction = _RecordingSystemAction();
      final container = ProviderContainer(
        overrides: [
          commonActionProvider.overrideWith(() => _MacosCommonAction(macos)),
          systemActionProvider.overrideWith(() => systemAction),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container
          .read(viewSizeProvider.notifier)
          .update((_) => const Size(1200, 800));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: HostScaffold(body: SizedBox.shrink())),
        ),
      );
      await tester.pump();

      final ready = UpdateReady('v0.9.35', staged.path);
      container.read(updateDownloadStateProvider.notifier).value = ready;

      final action = container.read(commonActionProvider.notifier);
      final firstInstall = action.installUpdate();
      await tester.pumpAndSettle();

      expect(container.read(updateDownloadStateProvider), ready);
      expect(find.text('Update failed'), findsOneWidget);
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      await firstInstall;

      expect(staged.existsSync(), isTrue);
      expect(systemAction.exitCalls, 0);

      await action.installUpdate();
      expect(macos.installCalls, 2);
      expect(systemAction.exitCalls, 1);
      expect(container.read(updateDownloadStateProvider), isNull);
    });
  });
}
