import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/ui/color.dart';

import 'preferences.dart';
import 'task.dart';

typedef MigrationTransform =
    Future<MigrationData> Function(Map<String, Object?> configMap);

abstract interface class MigrationStore {
  /// False when the backing store could not be opened at all, as opposed to a
  /// store that opened but holds nothing.
  Future<bool> get isAvailable;

  Future<Map<String, Object?>?> getConfigMap();

  Future<int> getVersion();

  Future<Map<String, Object?>?> getClashConfigMap();

  Future<void> restore(MigrationData data);

  Future<bool> saveConfig(Config config);

  Future<void> clearClashConfig();

  Future<void> setVersion(int version);

  Future<int> getUpgradeVersion();

  Future<void> setUpgradeVersion(int version);
}

class _AppMigrationStore implements MigrationStore {
  const _AppMigrationStore();

  @override
  Future<bool> get isAvailable => preferences.isInit;

  @override
  Future<Map<String, Object?>?> getConfigMap() => preferences.getConfigMap();

  @override
  Future<int> getVersion() => preferences.getVersion();

  @override
  Future<Map<String, Object?>?> getClashConfigMap() =>
      preferences.getClashConfigMap();

  @override
  Future<void> restore(MigrationData data) {
    return database.restore(
      data.profiles,
      data.scripts,
      data.rules,
      data.disabledRules,
      data.proxyGroups,
      clashProviders: data.clashProviders,
    );
  }

  @override
  Future<bool> saveConfig(Config config) => preferences.saveConfig(config);

  @override
  Future<void> clearClashConfig() => preferences.clearClashConfig();

  @override
  Future<void> setVersion(int version) => preferences.setVersion(version);

  @override
  Future<int> getUpgradeVersion() => preferences.getUpgradeVersion();

  @override
  Future<void> setUpgradeVersion(int version) =>
      preferences.setUpgradeVersion(version);
}

class Migration {
  final MigrationStore _store;
  final MigrationTransform _migrateV0;

  Migration({
    required MigrationStore store,
    MigrationTransform? migrateV0,
    bool? windows,
  }) : _store = store,
       _migrateV0 = migrateV0 ?? oldToNowTask,
       _windows = windows ?? Platform.isWindows;

  final bool _windows;

  static const currentVersion = 1;

  /// One-off setting changes for upgrades, apart from [currentVersion], which
  /// backups carry and an older app refuses when it is newer than its own.
  static const upgradeVersion = 3;

  static const Map<int, Config Function(Config config)> _upgrades = {
    1: _resetThemeColors,
    2: _keepGlassLook,
  };

  Future<Config> run() async {
    final configMap = await _store.getConfigMap();
    final config = await _migrate(configMap);
    final upgraded = await _upgrade(config, installed: configMap != null);
    await _recordDashboard(configMap, upgraded);
    return upgraded;
  }

  /// Seeding a card and moving a legacy layout happen while reading. Writing
  /// the result back at once keeps them from depending on a later save.
  Future<void> _recordDashboard(
    Map<String, Object?>? configMap,
    Config config,
  ) async {
    final stored = configMap?['appSettingProps'];
    if (stored is! Map) {
      return;
    }
    final current = jsonDecode(jsonEncode(config.appSettingProps)) as Map;
    for (final key in _dashboardKeys) {
      if (jsonEncode(stored[key]) != jsonEncode(current[key])) {
        await _store.saveConfig(config);
        return;
      }
    }
  }

  Future<Config> _upgrade(Config config, {required bool installed}) async {
    final from = await _store.getUpgradeVersion();
    if (from >= upgradeVersion) {
      return config;
    }
    var upgraded = config;
    if (installed) {
      for (var version = from + 1; version <= upgradeVersion; version++) {
        upgraded = version == 3
            ? findProcessesOnWindows(upgraded, windows: _windows)
            : _upgrades[version]!(upgraded);
      }
    } else {
      upgraded = findProcessesOnWindows(upgraded, windows: _windows);
    }
    if (upgraded != config && !await _store.saveConfig(upgraded)) {
      return config;
    }
    await _store.setUpgradeVersion(upgradeVersion);
    return upgraded;
  }

  Future<Config> _migrate(Map<String, Object?>? configMap) async {
    var oldVersion = await _store.getVersion();
    Config? config;
    if (oldVersion > currentVersion) {
      throw StateError(
        'Local data version $oldVersion is newer than $currentVersion.',
      );
    }
    if (oldVersion == currentVersion) {
      if (configMap != null && _isV0(configMap)) {
        try {
          config = Config.strictFromJson(configMap);
        } catch (_) {
          oldVersion = 0;
        }
      } else {
        config = Config.realFromJson(configMap);
      }
      if (config != null) {
        final storedDavPassword = _getStoredDavPassword(configMap);
        final hasPlainTextDavPassword =
            storedDavPassword != null &&
            storedDavPassword == config.davProps?.password;
        if (hasPlainTextDavPassword && !await _store.saveConfig(config)) {
          throw StateError('Failed to obfuscate the legacy WebDAV password');
        }
        return config;
      }
    }

    MigrationData data = MigrationData(configMap: configMap);
    var shouldClearClashConfig = false;
    if (oldVersion == 0) {
      final clashConfigMap = await _store.getClashConfigMap();
      if (_isV0(configMap) && configMap != null) {
        final legacyConfigMap = Map<String, Object?>.from(configMap);
        if (clashConfigMap != null) {
          legacyConfigMap['patchClashConfig'] = clashConfigMap;
          shouldClearClashConfig = true;
        }
        data = await _migrateV0(legacyConfigMap);
      } else if (clashConfigMap != null) {
        final currentConfigMap = Map<String, Object?>.from(
          configMap ?? const {},
        );
        currentConfigMap.putIfAbsent('patchClashConfig', () => clashConfigMap);
        data = MigrationData(configMap: currentConfigMap);
        shouldClearClashConfig = true;
      }
    }

    config = Config.realFromJson(data.configMap);
    await _store.restore(data);
    if (!await _store.saveConfig(config)) {
      // An unopenable store is reported later by the corrupt-cache dialog,
      // which offers a reset; failing here would hide that path.
      if (await _store.isAvailable) {
        throw StateError('Failed to save migrated preferences');
      }
      return config;
    }
    if (shouldClearClashConfig) {
      await _store.clearClashConfig();
    }
    await _store.setVersion(currentVersion);
    return config;
  }
}

Config _resetThemeColors(Config config) => config.copyWith(
  themeProps: config.themeProps.copyWith(
    primaryColor: defaultPrimaryColor,
    primaryColors: defaultPrimaryColors,
    colorStyle: ColorStyle.vivid,
  ),
);

// The standard glass became the ultra tier when a lighter standard joined it.
Config _keepGlassLook(Config config) =>
    config.themeProps.liquidGlass == LiquidGlassMode.standard
    ? config.copyWith(
        themeProps: config.themeProps.copyWith(
          liquidGlass: LiquidGlassMode.ultra,
        ),
      )
    : config;

const _dashboardKeys = ['dashboardWidgets', 'seededDashboardWidgets'];

bool _isV0(Map<String, Object?>? configMap) =>
    configMap?['proxiesStyle'] != null;

String? _getStoredDavPassword(Map<String, Object?>? configMap) {
  final dav = configMap?['davProps'] ?? configMap?['dav'];
  if (dav is! Map) {
    return null;
  }
  final password = dav['password'];
  return password is String && password.isNotEmpty ? password : null;
}

final migration = Migration(store: const _AppMigrationStore());

/// Windows has no per-app identity besides the process, and with lookup off
/// the connections page lists every one without a name.
Config findProcessesOnWindows(Config config, {required bool windows}) {
  if (!windows ||
      config.patchClashConfig.findProcessMode != FindProcessMode.off) {
    return config;
  }
  return config.copyWith.patchClashConfig(
    findProcessMode: FindProcessMode.always,
  );
}
