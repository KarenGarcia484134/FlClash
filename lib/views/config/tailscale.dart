import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/icons/icons.dart';
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

  Future<void> _handleConnect() async {
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
      TailscalePhase.needsLogin => appLocalizations.tailscaleStatusNeedsLogin,
      TailscalePhase.running => appLocalizations.tailscaleStatusRunning,
    };
    final color = switch (status.phase) {
      TailscalePhase.idle => context.colorScheme.onSurfaceVariant,
      TailscalePhase.needsLogin => context.colorScheme.error,
      TailscalePhase.running => context.colorScheme.primary,
    };
    final url = status.loginUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        generateSectionV3(
          title: appLocalizations.status,
          items: [
            FormRow(
              title: appLocalizations.status,
              trailing: Text(label, style: TextStyle(color: color)),
            ),
            if (status.proxyName case final name?)
              FormRow(title: appLocalizations.proxies, trailing: Text(name)),
            if (url != null)
              DecorationListItem(
                title: SelectableText(
                  url,
                  style: context.textTheme.bodyMedium?.toJetBrainsMono,
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
              style: context.listCaptionStyle?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        if (status.phase == TailscalePhase.needsLogin &&
            props.authKey.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              appLocalizations.tailscaleAuthKeyNotAccepted,
              style: context.listCaptionStyle?.copyWith(
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
              style: context.listCaptionStyle?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.tonal(
              onPressed: props.enable ? _handleConnect : null,
              child: Text(appLocalizations.tailscaleConnect),
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
            generateSectionV3(
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
            generateSectionV3(
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
                _textRow(
                  title: appLocalizations.tailscaleExitNode,
                  value: props.exitNode,
                  onChanged: (value) =>
                      _update((state) => state.copyWith(exitNode: value)),
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
            const SizedBox(height: 16),
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
