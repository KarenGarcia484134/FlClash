import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/config.g.dart';

@riverpod
class AppSetting extends _$AppSetting with AutoDisposeNotifierMixin {
  @override
  AppSettingProps build() {
    return const AppSettingProps();
  }
}

@Riverpod(keepAlive: true)
class WindowSetting extends _$WindowSetting with AutoDisposeNotifierMixin {
  @override
  WindowProps build() {
    return const WindowProps();
  }
}

@riverpod
class VpnSetting extends _$VpnSetting with AutoDisposeNotifierMixin {
  @override
  VpnProps build() {
    return const VpnProps();
  }
}

@riverpod
class NetworkSetting extends _$NetworkSetting with AutoDisposeNotifierMixin {
  @override
  NetworkProps build() {
    return const NetworkProps();
  }
}

@riverpod
class TailscaleSetting extends _$TailscaleSetting
    with AutoDisposeNotifierMixin {
  @override
  TailscaleProps build() {
    return const TailscaleProps();
  }
}

/// The user's dialer-proxy per node, per profile id.
@riverpod
class DialerProxySetting extends _$DialerProxySetting
    with AutoDisposeNotifierMixin {
  @override
  Map<String, Map<String, String>> build() {
    return const {};
  }

  void set(int profileId, String node, String? target) {
    update((state) {
      final key = profileId.toString();
      final next = {...?state[key]};
      if (target == null || target.isEmpty) {
        next.remove(node);
      } else {
        next[node] = target;
      }
      return {
        for (final entry in state.entries)
          if (entry.key != key) entry.key: entry.value,
        if (next.isNotEmpty) key: next,
      };
    });
  }

  void clear(int profileId) {
    update(
      (state) => {
        for (final entry in state.entries)
          if (entry.key != profileId.toString()) entry.key: entry.value,
      },
    );
  }
}

@riverpod
Map<String, String> profileDialerProxies(Ref ref, int profileId) {
  return ref.watch(dialerProxySettingProvider)[profileId.toString()] ??
      const {};
}

@riverpod
class ThemeSetting extends _$ThemeSetting with AutoDisposeNotifierMixin {
  @override
  ThemeProps build() {
    return const ThemeProps();
  }
}

@riverpod
class CurrentProfileId extends _$CurrentProfileId
    with AutoDisposeNotifierMixin {
  @override
  int? build() {
    return null;
  }
}

@riverpod
class DavSetting extends _$DavSetting with AutoDisposeNotifierMixin {
  @override
  DAVProps? build() {
    return null;
  }
}

@riverpod
class HotKeyActions extends _$HotKeyActions with AutoDisposeNotifierMixin {
  @override
  List<HotKeyAction> build() {
    return [];
  }
}

@riverpod
class ProxiesStyleSetting extends _$ProxiesStyleSetting
    with AutoDisposeNotifierMixin {
  @override
  ProxiesStyleProps build() {
    return const ProxiesStyleProps();
  }
}

@Riverpod(name: 'patchClashConfigProvider')
class _PatchClashConfig extends _$PatchClashConfig
    with AutoDisposeNotifierMixin {
  @override
  PatchClashConfig build() {
    return const PatchClashConfig();
  }
}

@riverpod
class ExcludeSSIDs extends _$ExcludeSSIDs with AutoDisposeNotifierMixin {
  @override
  List<String> build() {
    return [];
  }
}

@Riverpod(name: 'configProvider')
Config _config(Ref ref) {
  final appSettingProps = ref.watch(appSettingProvider);
  final windowProps = ref.watch(windowSettingProvider);
  final vpnProps = ref.watch(vpnSettingProvider);
  final networkProps = ref.watch(networkSettingProvider);
  final themeProps = ref.watch(themeSettingProvider);
  final currentProfileId = ref.watch(currentProfileIdProvider);
  final davProps = ref.watch(davSettingProvider);
  final hotKeyActions = ref.watch(hotKeyActionsProvider);
  final proxiesStyleProps = ref.watch(proxiesStyleSettingProvider);
  final patchClashConfig = ref.watch(patchClashConfigProvider);
  final excludeSSIDs = ref.watch(excludeSSIDsProvider);
  final tailscaleProps = ref.watch(tailscaleSettingProvider);
  final dialerProxies = ref.watch(dialerProxySettingProvider);
  return Config(
    appSettingProps: appSettingProps,
    windowProps: windowProps,
    vpnProps: vpnProps,
    networkProps: networkProps,
    themeProps: themeProps,
    currentProfileId: currentProfileId,
    davProps: davProps,
    hotKeyActions: hotKeyActions,
    proxiesStyleProps: proxiesStyleProps,
    patchClashConfig: patchClashConfig,
    excludeSSIDs: excludeSSIDs,
    tailscaleProps: tailscaleProps,
    dialerProxies: dialerProxies,
  );
}

void writeConfig(Ref ref, Config config) {
  ref.read(appSettingProvider.notifier).value = config.appSettingProps;
  ref.read(windowSettingProvider.notifier).value = config.windowProps;
  ref.read(vpnSettingProvider.notifier).value = config.vpnProps;
  ref.read(networkSettingProvider.notifier).value = config.networkProps;
  ref.read(themeSettingProvider.notifier).value = config.themeProps;
  ref.read(currentProfileIdProvider.notifier).value = config.currentProfileId;
  ref.read(davSettingProvider.notifier).value = config.davProps;
  ref.read(hotKeyActionsProvider.notifier).value = config.hotKeyActions;
  ref.read(proxiesStyleSettingProvider.notifier).value =
      config.proxiesStyleProps;
  ref.read(patchClashConfigProvider.notifier).value = config.patchClashConfig
      .ensureControllerSecret();
  ref.read(excludeSSIDsProvider.notifier).value = config.excludeSSIDs;
  ref.read(tailscaleSettingProvider.notifier).value = config.tailscaleProps;
  ref.read(dialerProxySettingProvider.notifier).value = config.dialerProxies;
}

List<Override> buildConfigOverrides(Config config) {
  return [
    appSettingProvider.overrideWithBuild((_, _) => config.appSettingProps),
    windowSettingProvider.overrideWithBuild((_, _) => config.windowProps),
    vpnSettingProvider.overrideWithBuild((_, _) => config.vpnProps),
    networkSettingProvider.overrideWithBuild((_, _) => config.networkProps),
    themeSettingProvider.overrideWithBuild((_, _) => config.themeProps),
    currentProfileIdProvider.overrideWithBuild(
      (_, _) => config.currentProfileId,
    ),
    davSettingProvider.overrideWithBuild((_, _) => config.davProps),
    hotKeyActionsProvider.overrideWithBuild((_, _) => config.hotKeyActions),
    proxiesStyleSettingProvider.overrideWithBuild(
      (_, _) => config.proxiesStyleProps,
    ),
    patchClashConfigProvider.overrideWithBuild(
      (_, _) => config.patchClashConfig,
    ),
    excludeSSIDsProvider.overrideWithBuild((_, _) => config.excludeSSIDs),
    tailscaleSettingProvider.overrideWithBuild((_, _) => config.tailscaleProps),
    dialerProxySettingProvider.overrideWithBuild(
      (_, _) => config.dialerProxies,
    ),
  ];
}
