import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/migration.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';

import '../helpers/app_paths.dart';
import '../helpers/preferences.dart';

Profile _profile(int id, String label) =>
    Profile(id: id, label: label, autoUpdateDuration: Duration.zero);

class _RecordingSetupAction extends SetupAction {
  int fullSetupCalls = 0;

  @override
  Future<bool> fullSetup() async {
    fullSetupCalls++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database testDatabase;
  late Directory home;

  setUpAll(() async {
    await mockPreferences({'version': 1});
    loadAppLocalizations(const Locale('en'));
    home = Directory.systemTemp.createTempSync('flclash-backup-action-');
    await useAppPaths(home);
  });

  tearDownAll(() {
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  setUp(() {
    testDatabase = Database(NativeDatabase.memory());
    database = testDatabase;
  });

  tearDown(() async {
    await testDatabase.close();
  });

  // AppStateManager's listen keeps the settings alive while a restore awaits.
  ProviderContainer buildContainer({List<Override> overrides = const []}) {
    final container = ProviderContainer(overrides: overrides)
      ..listen(configProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  BackupAction actionOf(ProviderContainer container) =>
      container.read(backupActionProvider.notifier);

  Map<String, Object?> configMapOf(ProviderContainer container) =>
      jsonDecode(jsonEncode(container.read(configProvider).toJson()))
          as Map<String, Object?>;

  group('backup and restore round trip', () {
    late Directory kept;

    setUp(() {
      kept = Directory.systemTemp.createTempSync('flclash-backup-kept-');
      addTearDown(() => kept.deleteSync(recursive: true));
    });

    Set<String> workDirs() => home
        .listSync()
        .map((entity) => basename(entity.path))
        .where((name) => name.startsWith('backup'))
        .toSet();

    Future<String> backupToKept(BackupAction action) async {
      final keptPath = join(kept.path, 'kept.zip');
      final delivered = await action.backup((archivePath) async {
        File(archivePath).copySync(keptPath);
        return true;
      });
      expect(delivered, isTrue);
      return keptPath;
    }

    test('restores the rows, files and settings a backup carries', () async {
      await testDatabase.profilesDao.putAll([
        _profile(1, 'Backed up').toCompanion(0),
      ]);
      final profileFile = File(await appPath.getProfilePath('1'))
        ..createSync(recursive: true)
        ..writeAsStringSync('proxies: []');
      final source = buildContainer();
      source.read(excludeSSIDsProvider.notifier).value = ['home-wifi'];
      final archivePath = await backupToKept(actionOf(source));

      await testDatabase.delete(testDatabase.profiles).go();
      profileFile.deleteSync();
      final target = buildContainer();
      final restored = await actionOf(
        target,
      ).restore(RestoreOption.all, (_) async => archivePath);

      expect(restored, isTrue);
      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label), ['Backed up']);
      expect(profileFile.readAsStringSync(), 'proxies: []');
      expect(target.read(excludeSSIDsProvider), ['home-wifi']);
      expect(workDirs(), isEmpty);
    });

    test('brings back the attachments of local modules and cleans the '
        'rest', () async {
      final module = MitmModule(
        id: 9,
        name: 'Mine',
        resources: const {'own.json': 'own.json'},
        lastUpdateTime: DateTime(2026),
      );
      await testDatabase.mitmModulesDao.putAll([module.toCompanion()]);
      File(join(home.path, 'mitm', 'modules', module.fileName))
        ..createSync(recursive: true)
        ..writeAsStringSync('[Map Local]\n^https://a data="own.json"\n');
      final resources = join(home.path, 'mitm', 'resources');
      final own = File(join(resources, 'own.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      final archivePath = await backupToKept(actionOf(buildContainer()));

      own.deleteSync();
      final stale = File(join(resources, 'stale.json'))..writeAsStringSync('');
      final target = buildContainer();
      final restored = await actionOf(
        target,
      ).restore(RestoreOption.all, (_) async => archivePath);

      expect(restored, isTrue);
      expect(own.readAsStringSync(), '{}');
      expect(stale.existsSync(), isFalse);
    });

    test('preserves custom routings and links across round trip in compatible '
        'and override strategies', () async {
      await testDatabase.profilesDao.putAll([
        _profile(1, 'Backed up').toCompanion(0),
      ]);
      const enabledRouting = CustomRouting(
        id: 10,
        label: 'Corp',
        enabled: true,
        target: 'DIRECT',
        order: 'a0',
        conditions: [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            values: ['corp.example'],
          ),
        ],
      );
      const disabledRouting = CustomRouting(
        id: 11,
        label: 'Optional',
        enabled: false,
        target: 'REJECT',
        order: 'a1',
        conditions: [
          CustomRoutingCondition(
            ruleAction: RuleAction.IP_CIDR,
            values: ['192.0.2.0/24'],
            noResolve: true,
          ),
        ],
      );
      await testDatabase.customRoutingsDao.put(enabledRouting);
      await testDatabase.customRoutingsDao.put(disabledRouting);
      await testDatabase.customRoutingsDao.putSelected(1, enabledRouting.id);

      final source = buildContainer();
      final archivePath = await backupToKept(actionOf(source));

      for (final strategy in [
        RestoreStrategy.compatible,
        RestoreStrategy.override,
      ]) {
        await testDatabase.delete(testDatabase.profileCustomRoutings).go();
        await testDatabase.delete(testDatabase.customRoutings).go();
        await testDatabase.delete(testDatabase.profiles).go();

        final target = buildContainer();
        target
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(restoreStrategy: strategy));

        final first = await actionOf(
          target,
        ).restore(RestoreOption.all, (_) async => archivePath);
        expect(first, isTrue);
        expect(await testDatabase.customRoutingsDao.query().get(), [
          enabledRouting,
          disabledRouting,
        ]);
        expect(await testDatabase.customRoutingsDao.querySelectedIds(1).get(), [
          enabledRouting.id,
        ]);

        if (strategy == RestoreStrategy.compatible) {
          final second = await actionOf(
            target,
          ).restore(RestoreOption.all, (_) async => archivePath);
          expect(second, isTrue);
          expect(await testDatabase.customRoutingsDao.query().get(), [
            enabledRouting,
            disabledRouting,
          ]);
          expect(
            await testDatabase.customRoutingsDao.querySelectedIds(1).get(),
            [enabledRouting.id],
          );
        }
      }
    });

    test('removes the work directory when delivery fails', () async {
      final container = buildContainer();

      await expectLater(
        actionOf(
          container,
        ).backup((_) async => throw const SocketException('offline')),
        throwsA(isA<SocketException>()),
      );

      expect(workDirs(), isEmpty);
    });

    test('a cancelled fetch changes nothing', () async {
      final container = buildContainer();

      final restored = await actionOf(
        container,
      ).restore(RestoreOption.all, (_) async => null);

      expect(restored, isFalse);
    });

    test('an unreadable archive is reported and changes nothing', () async {
      await testDatabase.profilesDao.putAll([
        _profile(9, 'Pre-existing').toCompanion(0),
      ]);
      final bogus = File(join(kept.path, 'bogus.zip'))
        ..writeAsStringSync('not a zip');
      final container = buildContainer();

      await expectLater(
        actionOf(container).restore(RestoreOption.all, (_) async => bogus.path),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            currentAppLocalizations.invalidBackupFile,
          ),
        ),
      );

      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label), ['Pre-existing']);
      expect(workDirs(), isEmpty);
    });

    test('removes the staging an earlier version left behind', () async {
      final legacyArchive = File(join(home.path, 'backup.zip'))
        ..writeAsStringSync('stale');
      final legacyStaging = Directory(join(home.path, 'restore'))..createSync();
      final container = buildContainer();

      await actionOf(container).restore(RestoreOption.all, (_) async => null);

      expect(legacyArchive.existsSync(), isFalse);
      expect(legacyStaging.existsSync(), isFalse);
    });
  });

  group('applyRestore writes the database', () {
    test('inserts the profiles the backup carries', () async {
      final container = buildContainer();

      await actionOf(container).applyRestore(
        MigrationData(profiles: [_profile(1, 'From backup')]),
        RestoreOption.onlyProfiles,
      );

      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label), ['From backup']);
    });

    test('an override restore drops profiles the backup omits', () async {
      final container = buildContainer();
      await testDatabase.profilesDao.putAll([
        _profile(9, 'Pre-existing').toCompanion(0),
      ]);
      container
          .read(appSettingProvider.notifier)
          .update(
            (state) =>
                state.copyWith(restoreStrategy: RestoreStrategy.override),
          );

      await actionOf(container).applyRestore(
        MigrationData(profiles: [_profile(1, 'From backup')]),
        RestoreOption.onlyProfiles,
      );

      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label), ['From backup']);
    });

    test('a compatible restore keeps profiles the backup omits', () async {
      final container = buildContainer();
      await testDatabase.profilesDao.putAll([
        _profile(9, 'Pre-existing').toCompanion(0),
      ]);
      container
          .read(appSettingProvider.notifier)
          .update(
            (state) =>
                state.copyWith(restoreStrategy: RestoreStrategy.compatible),
          );

      await actionOf(container).applyRestore(
        MigrationData(profiles: [_profile(1, 'From backup')]),
        RestoreOption.onlyProfiles,
      );

      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label).toSet(), {
        'Pre-existing',
        'From backup',
      });
    });

    test('a restore drops the cache of a provider it replaced', () async {
      const dropped = ClashProvider(
        id: 5,
        label: 'Dropped',
        url: 'https://example.com/dropped.yaml',
      );
      const kept = ClashProvider(id: 6, label: 'Kept');
      await testDatabase.clashProvidersDao.putAll(
        [dropped, kept].map((item) => item.toCompanion()),
      );
      for (final path in [
        await dropped.path,
        await dropped.compiledPath,
        await kept.path,
        await kept.compiledPath,
      ]) {
        File(path).createSync(recursive: true);
      }
      final container = buildContainer();
      container
          .read(appSettingProvider.notifier)
          .update(
            (state) =>
                state.copyWith(restoreStrategy: RestoreStrategy.override),
          );

      await actionOf(container).applyRestore(
        const MigrationData(clashProviders: [kept]),
        RestoreOption.onlyProfiles,
      );

      expect(File(await dropped.path).existsSync(), isFalse);
      expect(File(await dropped.compiledPath).existsSync(), isFalse);
      expect(File(await kept.path).existsSync(), isTrue);
      expect(
        File(await kept.compiledPath).existsSync(),
        isFalse,
        reason: 'the restored source is compiled again on first use',
      );
    });

    test('rows that fail to restore take their files back out', () async {
      final replaced = File(await appPath.getProfilePath('41'))
        ..createSync(recursive: true)
        ..writeAsStringSync('current');
      final added = File(await appPath.getProfilePath('42'));
      final staging = Directory.systemTemp.createTempSync('flclash-staging-');
      addTearDown(() => staging.deleteSync(recursive: true));
      for (final id in [41, 42]) {
        File(BackupEntries.resolve(staging.path, BackupEntries.profile(id)))
          ..createSync(recursive: true)
          ..writeAsStringSync('from backup');
      }
      await testDatabase.customStatement(
        'CREATE TRIGGER refuse_profiles BEFORE INSERT ON profiles '
        "BEGIN SELECT RAISE(ABORT, 'refused'); END",
      );

      await expectLater(
        actionOf(buildContainer()).applyRestore(
          MigrationData(profiles: [_profile(41, 'One'), _profile(42, 'Two')]),
          RestoreOption.onlyProfiles,
          stagingDirPath: staging.path,
        ),
        throwsA(anything),
      );

      expect(replaced.readAsStringSync(), 'current');
      expect(added.existsSync(), isFalse);
    });

    test('a backup carrying only proxy groups still writes them', () async {
      await testDatabase.profiles.put(
        const Profile(id: 7, autoUpdateDuration: Duration.zero).toCompanion(),
      );
      final container = buildContainer();

      await actionOf(container).applyRestore(
        const MigrationData(
          proxyGroups: [
            ProxyGroup(
              id: 1,
              profileId: 7,
              name: 'Selector',
              type: GroupType.Selector,
            ),
          ],
        ),
        RestoreOption.onlyProfiles,
      );

      final stored = await testDatabase.proxyGroupsDao.query(7).get();
      expect(
        stored.map((item) => item.name),
        ['Selector'],
        reason:
            'proxyGroups belongs in the guard that decides whether the batch '
            'runs, not only in the batch body',
      );
    });

    test('a backup restores custom routings and profile links', () async {
      await testDatabase.profiles.put(
        const Profile(id: 7, autoUpdateDuration: Duration.zero).toCompanion(),
      );
      const routing = CustomRouting(
        id: 11,
        label: 'Work',
        target: 'DIRECT',
        order: 'a',
      );
      const link = ProfileCustomRouting(profileId: 7, routingId: 11);
      final container = buildContainer();

      await actionOf(container).applyRestore(
        const MigrationData(
          customRoutings: [routing],
          profileCustomRoutings: [link],
        ),
        RestoreOption.onlyProfiles,
      );

      expect(await testDatabase.customRoutingsDao.query().get(), [routing]);
      expect(await testDatabase.customRoutingsDao.querySelectedIds(7).get(), [
        11,
      ]);
    });

    test(
      'reloads profilesProvider before notifying currentProfileId listeners',
      () async {
        await testDatabase.profiles.put(
          _profile(9, 'Pre-existing').toCompanion(0),
        );
        final source = buildContainer();
        source.read(currentProfileIdProvider.notifier).value = 7;
        final configMap = configMapOf(source);

        final target = buildContainer()
          ..read(currentProfileIdProvider.notifier).value = 9;
        target.read(profilesProvider.notifier);
        await pumpEventQueue();

        final seenProfileIds = <int>[];
        target.listen(currentProfileIdProvider, (_, next) {
          if (next == 7) {
            seenProfileIds.addAll(
              target.read(profilesProvider).map((item) => item.id),
            );
          }
        });

        await actionOf(target).applyRestore(
          MigrationData(configMap: configMap, profiles: [_profile(7, 'New')]),
          RestoreOption.all,
        );

        expect(seenProfileIds, contains(7));
      },
    );

    test(
      'reapplies via fullSetup only when currentProfileId stays unchanged',
      () async {
        final setupSameAll = _RecordingSetupAction();
        final source = buildContainer();
        source.read(currentProfileIdProvider.notifier).value = 7;
        final configMap = configMapOf(source);

        final sameAll = buildContainer(
          overrides: [
            initProvider.overrideWithBuild((_, _) => true),
            setupActionProvider.overrideWith(() => setupSameAll),
          ],
        );
        sameAll.read(currentProfileIdProvider.notifier).value = 7;
        await actionOf(sameAll).applyRestore(
          MigrationData(configMap: configMap, profiles: [_profile(7, 'Same')]),
          RestoreOption.all,
        );
        expect(setupSameAll.fullSetupCalls, 1);

        final setupOnlyProfiles = _RecordingSetupAction();
        final onlyProfiles = buildContainer(
          overrides: [
            initProvider.overrideWithBuild((_, _) => true),
            setupActionProvider.overrideWith(() => setupOnlyProfiles),
          ],
        );
        onlyProfiles.read(currentProfileIdProvider.notifier).value = 9;
        await actionOf(onlyProfiles).applyRestore(
          MigrationData(profiles: [_profile(7, 'Other')]),
          RestoreOption.onlyProfiles,
        );
        expect(setupOnlyProfiles.fullSetupCalls, 1);

        final setupChangedAll = _RecordingSetupAction();
        final changedAll = buildContainer(
          overrides: [
            initProvider.overrideWithBuild((_, _) => true),
            setupActionProvider.overrideWith(() => setupChangedAll),
          ],
        );
        changedAll.read(currentProfileIdProvider.notifier).value = 9;
        await actionOf(changedAll).applyRestore(
          MigrationData(configMap: configMap, profiles: [_profile(7, 'New')]),
          RestoreOption.all,
        );
        expect(setupChangedAll.fullSetupCalls, 0);
      },
    );
  });

  group('applyRestore writes the settings providers', () {
    test('restores every settings provider the config carries', () async {
      final source = buildContainer();
      source
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(autoLaunch: true));
      source.read(currentProfileIdProvider.notifier).value = 42;
      source
          .read(patchClashConfigProvider.notifier)
          .update((state) => state.copyWith(mixedPort: 7899));
      final configMap = configMapOf(source);

      final target = buildContainer();
      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(currentProfileIdProvider), 42);
      expect(target.read(appSettingProvider).autoLaunch, isTrue);
      expect(target.read(patchClashConfigProvider).mixedPort, 7899);
    });

    test('normalizes former default hosts from an old backup even at current '
        'upgradeVersion', () async {
      await mockPreferences({
        'version': Migration.currentVersion,
        'upgradeVersion': Migration.upgradeVersion,
      });
      expect(await preferences.getUpgradeVersion(), Migration.upgradeVersion);

      final configMap = configMapOf(buildContainer())
        ..['networkProps'] = {
          'bypassDomain': ['localhost', '172.19.*', '172.2*', 'custom.lan'],
        }
        ..['patchClashConfig'] = {
          'dns': {
            'fake-ip-filter': [
              'dns.msftnsci.com',
              'www.msftnsci.com',
              'custom.example',
            ],
          },
        };

      final target = buildContainer();
      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(networkSettingProvider).bypassDomain, [
        'localhost',
        '172.19.*',
        for (var i = 0; i < 10; i++) '172.2$i.*',
        'custom.lan',
      ]);
      expect(target.read(patchClashConfigProvider).dns.fakeIpFilter, [
        'dns.msftncsi.com',
        'www.msftncsi.com',
        'custom.example',
      ]);
    });

    test(
      'a backup holding a mixed port of 0 restores the default and says so',
      () async {
        final configMap = configMapOf(buildContainer());
        (configMap['patchClashConfig']! as Map<String, Object?>)['mixed-port'] =
            0;
        final banners = <String>[];
        final print = debugPrint;
        debugPrint = (message, {wrapWidth}) => banners.add(message ?? '');
        addTearDown(() => debugPrint = print);
        final target = buildContainer();
        target
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith(mixedPort: 7899));

        await actionOf(
          target,
        ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

        expect(
          target.read(patchClashConfigProvider).mixedPort,
          defaultMixedPort,
        );
        expect(
          banners,
          contains(
            '[APP] banner: The mixed port cannot be 0, so it was set back to 7890',
          ),
        );
      },
    );

    test('keeps the bound WebDAV account when the backup has none', () async {
      final configMap = configMapOf(buildContainer());
      const dav = DAVProps(uri: 'https://dav.example', user: 'me');
      final target = buildContainer();
      target.read(davSettingProvider.notifier).value = dav;

      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(davSettingProvider), dav);
    });

    test('keeps the picked apps when the backup lists none', () async {
      final configMap = configMapOf(buildContainer());
      const picked = AccessControlProps(
        enable: true,
        mode: AccessControlMode.acceptSelected,
        acceptList: ['com.example.browser'],
      );
      final target = buildContainer();
      target
          .read(vpnSettingProvider.notifier)
          .update((state) => state.copyWith(accessControlProps: picked));

      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(vpnSettingProvider).accessControlProps, picked);
    });

    test('takes the apps a backup lists from another phone', () async {
      const listed = AccessControlProps(
        enable: true,
        rejectList: ['com.example.bank'],
      );
      final source = buildContainer();
      source
          .read(vpnSettingProvider.notifier)
          .update((state) => state.copyWith(accessControlProps: listed));
      final configMap = configMapOf(source);
      final target = buildContainer();
      target
          .read(vpnSettingProvider.notifier)
          .update(
            (state) => state.copyWith(
              accessControlProps: const AccessControlProps(
                acceptList: ['com.example.browser'],
              ),
            ),
          );

      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(vpnSettingProvider).accessControlProps, listed);
    });

    test('leaves the settings untouched for an onlyProfiles restore', () async {
      final source = buildContainer();
      source.read(currentProfileIdProvider.notifier).value = 42;
      final configMap = configMapOf(source);

      final target = buildContainer();
      final before = target.read(currentProfileIdProvider);

      await actionOf(target).applyRestore(
        MigrationData(configMap: configMap, profiles: [_profile(1, 'P')]),
        RestoreOption.onlyProfiles,
      );

      expect(target.read(currentProfileIdProvider), before);
      expect(await testDatabase.profilesDao.query().get(), hasLength(1));
    });

    test('a backup without a config still restores the database', () async {
      final container = buildContainer();
      final before = container.read(currentProfileIdProvider);

      await actionOf(container).applyRestore(
        MigrationData(profiles: [_profile(1, 'P')]),
        RestoreOption.all,
      );

      expect(container.read(currentProfileIdProvider), before);
      expect(await testDatabase.profilesDao.query().get(), hasLength(1));
    });
  });

  group('a config with unreadable values', () {
    test('restores the rest without keeping a dropped profile', () async {
      final container = buildContainer();
      await testDatabase.profilesDao.putAll([
        _profile(9, 'Pre-existing').toCompanion(0),
      ]);
      container.read(currentProfileIdProvider.notifier).value = 9;
      container
          .read(appSettingProvider.notifier)
          .update(
            (state) =>
                state.copyWith(restoreStrategy: RestoreStrategy.override),
          );

      await actionOf(container).applyRestore(
        MigrationData(
          configMap: const {
            'currentProfileId': 'not an int',
            'appSettingProps': {'hideIp': true},
          },
          profiles: [_profile(1, 'From backup')],
        ),
        RestoreOption.all,
      );

      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label), ['From backup']);
      expect(container.read(currentProfileIdProvider), isNull);
      expect(container.read(appSettingProvider).hideIp, true);
    });
  });
}
