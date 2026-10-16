import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _refreshInterval = Duration(seconds: 10);

/// The live node and peer list, polled while the page is on screen and the
/// app is in the foreground.
class TailscaleNetworkSection extends ConsumerStatefulWidget {
  const TailscaleNetworkSection({
    super.key,
    required this.proxyName,
    required this.onConnect,
  });

  final String? proxyName;
  final Future<void> Function() onConnect;

  @override
  ConsumerState<TailscaleNetworkSection> createState() =>
      TailscaleNetworkSectionState();
}

class TailscaleNetworkSectionState
    extends ConsumerState<TailscaleNetworkSection>
    with WidgetsBindingObserver {
  TailscaleNetStatus? _status;
  bool _loading = false;
  String _query = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    unawaited(refresh());
  }

  @override
  void didUpdateWidget(TailscaleNetworkSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proxyName != widget.proxyName) {
      unawaited(refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      unawaited(refresh());
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh(silent: true));
  }

  Future<void> refresh({bool silent = false, bool start = false}) async {
    final name = widget.proxyName;
    if (name == null) {
      if (mounted) setState(() => _status = null);
      return;
    }
    if (_loading) {
      return;
    }
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final status = await ref
          .read(coreHandlerProvider)
          .tailscaleStatus(name, start: start);
      if (mounted) setState(() => _status = status);
    } catch (e) {
      if (mounted) {
        setState(() => _status = TailscaleNetStatus(error: e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      context.showNotifier(
        context.appLocalizations.copySuccess,
        level: MessageLevel.success,
      );
    }
  }

  Future<void> _addRouting(TailscalePeer peer) async {
    final appLocalizations = context.appLocalizations;
    final target = widget.proxyName;
    final condition = tailscalePeerCondition(peer);
    if (target == null || condition == null) {
      return;
    }
    final routing = CustomRouting(
      id: snowflake.id,
      label: 'Tailscale ${peer.displayName}',
      conditions: [condition],
      target: target,
    );
    await ref.read(customRoutingsProvider.notifier).append(routing);
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null) {
      ref
          .read(profileCustomRoutingIdsProvider(profileId).notifier)
          .toggle(routing.id);
    }
    if (mounted) {
      context.showNotifier(
        '${appLocalizations.tailscaleRoutingAdded}: '
        '${condition.values.first}',
        level: MessageLevel.success,
      );
    }
  }

  Widget _ipChip(String ip) {
    return ActionChip(
      label: Text(ip, style: context.textTheme.bodySmall?.toJetBrainsMono),
      avatar: const GlyphIcon(AppGlyphs.copy, size: 14),
      onPressed: () => _copy(ip),
    );
  }

  Widget _buildPeer(TailscalePeer peer, {bool self = false}) {
    final appLocalizations = context.appLocalizations;
    final tags = [
      peer.online
          ? appLocalizations.tailscaleOnline
          : appLocalizations.tailscaleOffline,
      if (peer.os.isNotEmpty) peer.os,
      if (peer.exitNode) appLocalizations.tailscaleCurrentExitNode,
      if (!peer.exitNode && peer.exitNodeOption)
        appLocalizations.tailscaleExitNodeOption,
    ];
    return DecorationListItem(
      leading: Icon(
        Icons.circle,
        size: 10,
        color: peer.online
            ? context.colorScheme.primary
            : context.colorScheme.outline,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(peer.displayName, style: context.textTheme.titleSmall),
          if (peer.shortDnsName.isNotEmpty)
            Text(
              peer.shortDnsName,
              style: context.listCaptionStyle,
              overflow: TextOverflow.ellipsis,
            ),
          Text(tags.join(' · '), style: context.listCaptionStyle),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [for (final ip in peer.ips) _ipChip(ip)],
          ),
        ],
      ),
      trailing: self
          ? null
          : IconButton(
              tooltip: appLocalizations.tailscaleAddRouting,
              onPressed: () => _addRouting(peer),
              icon: const GlyphIcon(AppGlyphs.listAdd),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final status = _status;
    final refreshButton = IconButton(
      tooltip: appLocalizations.tailscaleRefresh,
      onPressed: widget.proxyName == null || _loading ? null : refresh,
      icon: _loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const GlyphIcon(AppGlyphs.refresh),
    );
    final header = Row(
      children: [
        Expanded(
          child: Text(
            appLocalizations.tailscaleNetwork,
            style: context.textTheme.titleMedium,
          ),
        ),
        refreshButton,
      ],
    );
    if (widget.proxyName == null || status == null || !status.started) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              status?.error ?? appLocalizations.tailscaleNotStarted,
              style: context.listCaptionStyle,
            ),
          ),
          if (widget.proxyName != null)
            FilledButton.tonal(
              onPressed: () async {
                await widget.onConnect();
                await refresh(start: true);
              },
              child: Text(appLocalizations.tailscaleConnect),
            ),
        ],
      );
    }
    final peers = status.peers.where((peer) => peer.matches(_query)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (status.error case final error?)
          Text(
            error,
            style: context.listCaptionStyle?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        if (status.self case final self?)
          generateSectionV3(
            title: appLocalizations.tailscaleLocalNode,
            items: [_buildPeer(self, self: true)],
          ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const GlyphIcon(AppGlyphs.search),
            hintText: appLocalizations.search,
          ),
        ),
        const SizedBox(height: 8),
        generateSectionV3(
          title: '${appLocalizations.tailscalePeers} (${status.peers.length})',
          items: [
            if (peers.isEmpty)
              FormRow(
                title: appLocalizations.noData,
                trailing: const SizedBox.shrink(),
              ),
            for (final peer in peers) _buildPeer(peer),
          ],
        ),
      ],
    );
  }
}
