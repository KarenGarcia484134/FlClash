import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' show join;

import 'package:fl_clash/views/config/tailscale_network.dart';

/// The name the injected node takes in the current profile, mirroring the
/// clash check the config generator makes.
String? currentTailscaleProxyName(WidgetRef ref) {
  if (!ref.watch(tailscaleSettingProvider.select((state) => state.enable))) {
    return null;
  }
  final profileId = ref.watch(currentProfileIdProvider);
  final config = profileId == null
      ? null
      : ref.watch(clashConfigProvider(profileId)).value;
  return tailscaleProxyName({
    ...?config?.proxies.map((item) => item.name),
    ...?config?.proxyGroups.map((item) => item.name),
  });
}

/// What the node's connection proxy can be picked from, read from the same
/// config the node is built from: a custom profile's own proxies and groups,
/// a script's result, or the profile file.
final tailscaleDialerCandidatesProvider = FutureProvider.autoDispose
    .family<TailscaleDialerCandidates, int>((ref, profileId) async {
      final setup = await ref.watch(setupStateProvider(profileId).future);
      Map<String, dynamic> config;
      if (setup.profileType == ProfileType.custom) {
        config = {
          'proxies': appProxiesPayload(
            setup.appProxies,
            dialers: setup.proxyDialers,
            groups: setup.proxyGroups,
          ),
          'proxy-groups': [
            for (final group in setup.proxyGroups) group.definition,
          ],
        };
      } else {
        final script = setup.extendType == ExtendType.script
            ? await setup.script?.content
            : null;
        if (script?.isNotEmpty == true) {
          final raw = await ref.read(coreHandlerProvider).getConfig(profileId);
          config = await handleEvaluate(script!, raw);
        } else {
          final clash = await ref.watch(clashConfigProvider(profileId).future);
          config = {
            'proxies': [
              for (final item in clash.proxies)
                {'name': item.name, 'type': item.type},
            ],
            'proxy-groups': [
              for (final item in clash.proxyGroups)
                {'name': item.name, 'type': item.type.name},
            ],
          };
        }
      }
      final own = tailscaleProxyNameFor(config);
      return TailscaleDialerCandidates.fromConfig(config, own: own);
    });

/// Picks what the node's own control, DERP and UDP traffic goes through.
/// An empty answer means dialing directly.
Future<String?> showTailscaleDialerSheet(
  BuildContext context, {
  required String selected,
}) {
  return showSheet<String>(
    context: context,
    builder: (context) => Consumer(
      builder: (_, ref, _) {
        final appLocalizations = context.appLocalizations;
        final profileId = ref.watch(currentProfileIdProvider);
        final candidates = profileId == null
            ? const TailscaleDialerCandidates()
            : ref.watch(tailscaleDialerCandidatesProvider(profileId)).value ??
                  const TailscaleDialerCandidates();
        final groups = candidates.groups;
        final suggested = groups.entries
            .where((entry) => isSelectGroupType(entry.value))
            .firstOrNull
            ?.key;
        final proxies = candidates.proxies;
        return SelectionSheet<String>(
          title: appLocalizations.tailscaleDialerProxy,
          sections: [
            SelectionSection(
              label: appLocalizations.basicStrategy,
              items: [''],
            ),
            SelectionSection(
              label: appLocalizations.proxyGroup,
              items: groups.keys.toList(),
              subtitleBuilder: (_, name) => name == suggested
                  ? '${groups[name]} · ${appLocalizations.recommended}'
                  : groups[name] ?? '',
            ),
            SelectionSection(
              label: appLocalizations.proxies,
              items: proxies.keys.toList(),
              subtitleBuilder: (_, name) => proxies[name] ?? '',
            ),
          ],
          labelBuilder: (item) => item.isEmpty ? 'DIRECT' : item,
          selectedOf: (_) => selected,
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    ),
  );
}

const _manualExitNode = '\u0000manual';

/// Picks the exit node from the peers that offer one, with none, automatic
/// and typing one in as the other choices. Returns null when dismissed.
Future<String?> showTailscaleExitNodeSheet(
  BuildContext context, {
  required String selected,
  required List<TailscalePeer> peers,
}) async {
  final appLocalizations = context.appLocalizations;
  final offers = {
    for (final peer in peers)
      if (peer.exitNodeOption) ?tailscaleExitNodeValue(peer): peer,
  };
  final picked = await showSheet<String>(
    context: context,
    builder: (context) => SelectionSheet<String>(
      title: appLocalizations.tailscaleExitNode,
      sections: [
        SelectionSection(
          label: appLocalizations.basicStrategy,
          items: ['', tailscaleAutoExitNode],
        ),
        SelectionSection(
          label: appLocalizations.tailscaleExitNodeOption,
          items: offers.keys.toList(),
          subtitleBuilder: (_, value) => [
            value,
            if (offers[value]?.online == false)
              appLocalizations.tailscaleOffline,
          ].join(' · '),
        ),
        SelectionSection(
          label: appLocalizations.tailscaleExitNodeManual,
          items: [_manualExitNode],
        ),
      ],
      labelBuilder: (item) => switch (item) {
        '' => appLocalizations.tailscaleExitNodeNone,
        tailscaleAutoExitNode => appLocalizations.tailscaleExitNodeAuto,
        _manualExitNode => appLocalizations.tailscaleExitNodeManual,
        _ => offers[item]?.displayName ?? item,
      },
      emptyLabel: appLocalizations.tailscaleExitNodeNoOffers,
      selectedOf: (_) => selected,
      onSelected: (item) => Navigator.of(context).pop(item),
    ),
  );
  if (picked != _manualExitNode) {
    return picked;
  }
  return dialogs.showCommonDialog<String>(
    child: InputDialog(
      title: appLocalizations.tailscaleExitNode,
      value: selected,
      hintText: appLocalizations.tailscaleExitNodeHint,
    ),
  );
}

/// The red lines under the status: why the node cannot reach its control
/// server, and whether that is the connection proxy's doing.
List<String> tailscaleStatusHints(
  AppLocalizations appLocalizations,
  TailscaleStatus status,
  TailscaleProps props, {
  bool? available,
}) {
  final exitNode = status.exitNodeError;
  final exitHint = exitNode == null || exitNode.isEmpty
      ? null
      : appLocalizations.tailscaleExitNodeFailed(exitNode);
  final route = switch (tailscaleRouteHint(
    configured: props.dialerProxy,
    available: available,
    effective: status.dialerProxy,
    health: status.health,
  )) {
    TailscaleRouteHint.dropped => appLocalizations.tailscaleDialerProxyDropped(
      props.dialerProxy.trim(),
    ),
    TailscaleRouteHint.pending => appLocalizations.tailscaleDialerProxyPending,
    TailscaleRouteHint.direct => appLocalizations.tailscaleDirectBlocked,
    TailscaleRouteHint.none => null,
  };
  if (status.phase == TailscalePhase.running) {
    return [?route, ?exitHint];
  }
  final issue = switch (classifyTailscaleHealth(status.health)) {
    TailscaleIssue.network when route == null =>
      appLocalizations.tailscaleNetworkIssue,
    TailscaleIssue.authKey
        when props.authKey.trim().isNotEmpty &&
            status.phase == TailscalePhase.needsLogin =>
      appLocalizations.tailscaleAuthKeyNotAccepted,
    _ => null,
  };
  return [?route, ?issue, ?exitHint];
}

class TailscaleView extends ConsumerStatefulWidget {
  const TailscaleView({super.key});

  @override
  ConsumerState<TailscaleView> createState() => _TailscaleViewState();
}

class _TailscaleViewState extends ConsumerState<TailscaleView> {
  late final SetupAction _setupAction;
  final _networkKey = GlobalKey<TailscaleNetworkSectionState>();

  @override
  void initState() {
    super.initState();
    _setupAction = ref.read(setupActionProvider.notifier);
  }

  @override
  void dispose() {
    _setupAction.autoApplyProfile();
    super.dispose();
  }

  void _update(TailscaleProps Function(TailscaleProps state) builder) {
    ref.read(tailscaleSettingProvider.notifier).update(builder);
  }

  /// Applies what changed on the page first, so a new connection proxy or
  /// exit node takes effect now: the Core rebuilds a node whose options
  /// changed, and the connect then starts the new one.
  Future<void> _handleConnect() async {
    await _setupAction.applyProfile();
    if (!mounted) return;
    await _networkKey.currentState?.connect();
  }

  Future<void> _handleReset() async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.tailscaleResetTip),
    );
    if (res != true) {
      return;
    }
    await globalState.safeRun(() async {
      if (currentTailscaleProxyName(ref) case final name?) {
        await ref.read(coreHandlerProvider).tailscaleStatus(name, reset: true);
      }
      final home = await appPath.homeDirPath;
      await Directory(
        join(home, tailscaleStateDir),
      ).safeDelete(recursive: true);
      ref.read(tailscaleStateProvider.notifier).reset();
      await _setupAction.applyProfile(force: true);
    });
  }

  Future<void> _handleCopy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      context.showNotifier(
        context.appLocalizations.copySuccess,
        level: MessageLevel.success,
      );
    }
  }

  Widget _textRow({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    bool obscure = false,
  }) {
    return FormRow(
      title: title,
      trailing: TextFormField(
        initialValue: value,
        obscureText: obscure,
        textAlign: TextAlign.end,
        onChanged: onChanged,
        decoration: InputDecoration.collapsed(
          border: const NoInputBorder(),
          hintText: hint ?? context.appLocalizations.optional,
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FormRow(
      title: title,
      onPressed: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildStatus(TailscaleProps props) {
    final appLocalizations = context.appLocalizations;
    final status = ref.watch(tailscaleStateProvider);
    final logLevel = ref.watch(
      patchClashConfigProvider.select((state) => state.logLevel),
    );
    final label = switch (status.phase) {
      TailscalePhase.idle => appLocalizations.tailscaleStatusIdle,
      TailscalePhase.connecting => appLocalizations.tailscaleStatusConnecting,
      TailscalePhase.needsLogin => appLocalizations.tailscaleStatusNeedsLogin,
      TailscalePhase.running => appLocalizations.tailscaleStatusRunning,
    };
    final color = switch (status.phase) {
      TailscalePhase.idle ||
      TailscalePhase.connecting => context.colorScheme.onSurfaceVariant,
      TailscalePhase.needsLogin => context.colorScheme.error,
      TailscalePhase.running => context.colorScheme.primary,
    };
    final url = status.loginUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        generateSection(
          title: appLocalizations.status,
          items: [
            FormRow(
              title: appLocalizations.status,
              trailing: Text(label, style: TextStyle(color: color)),
            ),
            if (status.proxyName case final name?)
              FormRow(
                title: appLocalizations.tailscaleNodeName,
                trailing: Text(name),
              ),
            if (url != null)
              DecorationListItem(
                title: SelectableText(
                  url,
                  style: AppTextStyle.subheadline.of(context).toJetBrainsMono,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: appLocalizations.copy,
                      onPressed: () => _handleCopy(url),
                      icon: const GlyphIcon(AppGlyphs.copy),
                    ),
                    IconButton(
                      tooltip: appLocalizations.tailscaleOpenLogin,
                      onPressed: () => dialogs.openUrl(url),
                      icon: const GlyphIcon(AppGlyphs.openExternal),
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (final message in status.health)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              message,
              style: context.listCaptionStyle.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        for (final hint in tailscaleStatusHints(
          appLocalizations,
          status,
          props,
          available: switch (ref.watch(currentProfileIdProvider)) {
            final int id =>
              ref
                  .watch(tailscaleDialerCandidatesProvider(id))
                  .value
                  ?.contains(props.dialerProxy.trim()),
            null => null,
          },
        ))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              hint,
              style: context.listCaptionStyle.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            appLocalizations.tailscaleLoginDesc,
            style: context.listCaptionStyle,
          ),
        ),
        if (logLevel == LogLevel.silent)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              appLocalizations.tailscaleSilentLogTip,
              style: context.listCaptionStyle.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            // The one connect action on the page. It stays usable while the
            // node is connecting or failed, where it retries the login.
            FilledButton.tonal(
              key: const ValueKey('tailscale-connect'),
              onPressed: props.enable ? _handleConnect : null,
              child: Text(
                status.phase == TailscalePhase.idle
                    ? appLocalizations.tailscaleConnect
                    : appLocalizations.tailscaleReconnect,
              ),
            ),
            TextButton(
              onPressed: _handleReset,
              child: Text(appLocalizations.tailscaleReset),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final props = ref.watch(tailscaleSettingProvider);
    return CommonScaffold(
      title: 'Tailscale',
      body: Builder(
        builder: (context) => ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            context.contentTopPadding,
            16,
            16 + BottomInsetScope.of(context),
          ),
          children: [
            generateSection(
              items: [
                _switchRow(
                  title: appLocalizations.tailscaleEnable,
                  value: props.enable,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(enable: value)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                appLocalizations.tailscaleDesc,
                style: context.listCaptionStyle,
              ),
            ),
            generateSection(
              title: appLocalizations.tailscaleNode,
              items: [
                _textRow(
                  title: appLocalizations.tailscaleHostname,
                  value: props.hostname,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(hostname: value)),
                ),
                _textRow(
                  title: appLocalizations.tailscaleAuthKey,
                  value: props.authKey,
                  obscure: true,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(authKey: value)),
                ),
                _textRow(
                  title: appLocalizations.tailscaleControlUrl,
                  value: props.controlUrl,
                  hint: 'https://controlplane.tailscale.com',
                  onChanged: (value) =>
                      _update((state) => state.copyWith(controlUrl: value)),
                ),
                FormRow(
                  title: appLocalizations.tailscaleDialerProxy,
                  onPressed: () async {
                    final res = await showTailscaleDialerSheet(
                      context,
                      selected: props.dialerProxy,
                    );
                    if (res != null) {
                      _update((state) => state.copyWith(dialerProxy: res));
                    }
                  },
                  trailing: Text(
                    props.dialerProxy.isEmpty ? 'DIRECT' : props.dialerProxy,
                  ),
                ),
                FormRow(
                  key: const ValueKey('tailscale-exit-node'),
                  title: appLocalizations.tailscaleExitNode,
                  onPressed: () async {
                    final res = await showTailscaleExitNodeSheet(
                      context,
                      selected: props.exitNode.trim(),
                      peers:
                          _networkKey.currentState?.status?.peers ?? const [],
                    );
                    if (res != null) {
                      _update((state) => state.copyWith(exitNode: res.trim()));
                    }
                  },
                  trailing: Text(switch (props.exitNode.trim()) {
                    '' => appLocalizations.tailscaleExitNodeNone,
                    tailscaleAutoExitNode =>
                      appLocalizations.tailscaleExitNodeAuto,
                    final value => value,
                  }),
                ),
                _textRow(
                  title: appLocalizations.tailscaleDnsSuffixes,
                  value: props.dnsSuffixes.join(' '),
                  hint: 'example.ts.net',
                  onChanged: (value) => _update(
                    (state) => state.copyWith(
                      dnsSuffixes: value
                          .split(RegExp(r'[\s,]+'))
                          .where((item) => item.isNotEmpty)
                          .toList(),
                    ),
                  ),
                ),
                _switchRow(
                  title: appLocalizations.tailscaleAcceptRoutes,
                  value: props.acceptRoutes,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(acceptRoutes: value)),
                ),
                _switchRow(
                  title: appLocalizations.tailscaleEphemeral,
                  value: props.ephemeral,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(ephemeral: value)),
                ),
                _switchRow(
                  title: 'UDP',
                  value: props.udp,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(udp: value)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                appLocalizations.tailscaleDialerProxyDesc,
                style: context.listCaptionStyle,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatus(props),
            const SizedBox(height: 24),
            TailscaleNetworkSection(
              key: _networkKey,
              proxyName: props.enable ? currentTailscaleProxyName(ref) : null,
              onApply: _setupAction.applyProfile,
            ),
          ],
        ),
      ),
    );
  }
}
