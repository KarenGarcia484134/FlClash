import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _refreshInterval = Duration(seconds: 10);

/// How long a connect keeps reading the node after the core's own wait,
/// and how often.
const tailscaleSettleTimeout = Duration(seconds: 20);
const tailscaleSettleInterval = Duration(seconds: 1);

/// The live node and peer list, polled while the page is on screen and the
/// app is in the foreground.
class TailscaleNetworkSection extends ConsumerStatefulWidget {
  const TailscaleNetworkSection({
    super.key,
    required this.proxyName,
    required this.onApply,
  });

  final String? proxyName;

  /// Applies the profile, for a node that is not in the running config yet.
  final Future<void> Function() onApply;

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
  bool _settling = false;
  final Map<String, TailscalePingResult> _pings = {};
  final Set<String> _pinging = {};

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

  Future<void> refresh({
    bool silent = false,
    bool start = false,
    bool wait = false,
    bool rebind = false,
  }) async {
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
          .tailscaleStatus(name, start: start, wait: wait, rebind: rebind);
      if (!mounted) return;
      setState(() {
        _status = status;
        final ids = {for (final peer in status.peers) peer.id};
        _pings.removeWhere((id, _) => !ids.contains(id));
      });
      ref
          .read(tailscaleStateProvider.notifier)
          .onStatus(status, name, settling: _settling);
    } catch (e) {
      if (mounted) {
        setState(() => _status = TailscaleNetStatus(error: e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Starts the node without rebuilding it, applying the profile first only
  /// when the running config does not carry the node yet. A node that logs
  /// in with its saved key passes through NeedsLogin and Starting on its way
  /// up, so the page shows it connecting and keeps reading until it settles.
  Future<void> connect() => _settle(start: true);

  /// After a network change the node rebinds; the page re-reads it, shows it
  /// connecting until it settles, and drops latencies measured on the old
  /// network.
  Future<void> onNetworkChanged() async {
    if (!mounted) return;
    setState(_pings.clear);
    if (_status?.started == true) {
      await _settle(rebind: true);
    }
  }

  Future<void> _settle({bool start = false, bool rebind = false}) async {
    final name = widget.proxyName;
    if (name == null || _settling) {
      return;
    }
    _settling = true;
    ref.read(tailscaleStateProvider.notifier).onConnecting(name);
    try {
      while (_loading && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await refresh(start: start, wait: true, rebind: rebind);
      if (!mounted) return;
      if (start && _status?.started != true && _status?.error == null) {
        await widget.onApply();
        if (!mounted) return;
        await refresh(start: true, wait: true);
      }
      final deadline = DateTime.now().add(tailscaleSettleTimeout);
      while (mounted &&
          _status != null &&
          !isTailscaleSettled(_status!) &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(tailscaleSettleInterval);
        await refresh(silent: true);
      }
    } finally {
      _settling = false;
      final status = _status;
      if (mounted && status != null) {
        ref.read(tailscaleStateProvider.notifier).onStatus(status, name);
      }
    }
  }

  Future<void> _ping(List<TailscalePeer> peers) async {
    final name = widget.proxyName;
    final targets = {
      for (final peer in peers)
        if (peer.online && !_pinging.contains(peer.id))
          peer.id: ?tailscalePingTarget(peer),
    };
    if (name == null || targets.isEmpty) {
      return;
    }
    setState(() => _pinging.addAll(targets.keys));
    try {
      final results = await ref
          .read(coreHandlerProvider)
          .tailscalePing(name, targets.values.toList());
      final byTarget = {for (final item in results) item.target: item};
      if (!mounted) return;
      setState(() {
        for (final MapEntry(key: id, value: ip) in targets.entries) {
          _pings[id] =
              byTarget[ip] ??
              TailscalePingResult(target: ip, error: 'no reply');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        for (final MapEntry(key: id, value: ip) in targets.entries) {
          _pings[id] = TailscalePingResult(target: ip, error: e.toString());
        }
      });
    } finally {
      if (mounted) setState(() => _pinging.removeAll(targets.keys));
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
    final conditions = tailscalePeerConditions(peer);
    if (target == null || conditions.isEmpty) {
      return;
    }
    final routing = CustomRouting(
      id: snowflake.id,
      label: 'Tailscale ${peer.displayName}',
      logic: CustomRoutingLogic.or,
      conditions: conditions,
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
        '${appLocalizations.tailscaleRoutingAdded}: ${peer.displayName}',
        level: MessageLevel.success,
      );
    }
  }

  Widget _ipChip(String ip) {
    return ActionChip(
      label: Text(ip, style: AppTextStyle.footnote.of(context).toJetBrainsMono),
      avatar: const GlyphIcon(AppGlyphs.copy, size: 14),
      onPressed: () => _copy(ip),
    );
  }

  String? _pathLabel(TailscalePingResult? ping) {
    if (ping == null || !ping.ok) {
      return null;
    }
    final appLocalizations = context.appLocalizations;
    return switch (ping.path) {
      TailscalePath.direct => appLocalizations.tailscalePathDirect,
      TailscalePath.peerRelay => appLocalizations.tailscalePathPeerRelay,
      TailscalePath.derp => appLocalizations.tailscalePathRelay(ping.derpLabel),
      TailscalePath.unknown => null,
    };
  }

  Widget _latencyBadge(TailscalePeer peer) {
    final appLocalizations = context.appLocalizations;
    if (_pinging.contains(peer.id)) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: CommonCircleLoading(size: 16),
      );
    }
    final ping = _pings[peer.id];
    if (ping == null) {
      return IconButton(
        tooltip: appLocalizations.tailscalePing,
        onPressed: () => _ping([peer]),
        icon: const GlyphIcon(AppGlyphs.bolt),
      );
    }
    final delay = ping.ok ? ping.latencyMs : -1;
    return Tooltip(
      message: ping.ok ? appLocalizations.tailscalePing : (ping.error ?? ''),
      child: TextButton(
        onPressed: () => _ping([peer]),
        child: Text(
          ping.ok ? '$delay ms' : appLocalizations.tailscalePingFailed,
          style: AppTextStyle.caption2
              .of(context, emphasized: true)
              .copyWith(color: context.colorScheme.delayColor(delay)),
        ),
      ),
    );
  }

  Widget _buildPeer(TailscalePeer peer, {bool self = false}) {
    final appLocalizations = context.appLocalizations;
    final testable = !self && peer.online && tailscalePingTarget(peer) != null;
    final tags = [
      peer.online
          ? appLocalizations.tailscaleOnline
          : appLocalizations.tailscaleOffline,
      if (peer.os.isNotEmpty) peer.os,
      if (peer.exitNode) appLocalizations.tailscaleCurrentExitNode,
      if (!peer.exitNode && peer.exitNodeOption)
        appLocalizations.tailscaleExitNodeOption,
      if (testable) ?_pathLabel(_pings[peer.id]),
    ];
    final item = DecorationListItem(
      onPressed: testable ? () => _ping([peer]) : null,
      leading: SizedBox.square(
        dimension: 10,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color: peer.online
                ? context.colorScheme.primary
                : context.colorScheme.outline,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(peer.displayName, style: AppTextStyle.subheadline.of(context)),
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
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (testable) _latencyBadge(peer),
                IconButton(
                  tooltip: appLocalizations.tailscaleAddRouting,
                  onPressed: () => _addRouting(peer),
                  icon: const GlyphIcon(AppGlyphs.listAdd),
                ),
              ],
            ),
    );
    if (!testable) {
      return item;
    }
    return GestureDetector(onLongPress: () => _ping([peer]), child: item);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(networkChangesProvider, (_, _) => onNetworkChanged());
    final appLocalizations = context.appLocalizations;
    final status = _status;
    final refreshButton = IconButton(
      tooltip: appLocalizations.tailscaleRefresh,
      onPressed: widget.proxyName == null || _loading ? null : refresh,
      icon: _loading
          ? const CommonCircleLoading(size: 18)
          : const GlyphIcon(AppGlyphs.refresh),
    );
    final header = Row(
      children: [
        Expanded(
          child: Text(
            appLocalizations.tailscaleNetwork,
            style: AppTextStyle.headline.of(context),
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
        ],
      );
    }
    final peers = status.peers.where((peer) => peer.matches(_query)).toList();
    final testable = status.peers.any(
      (peer) => peer.online && !_pinging.contains(peer.id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (status.error case final error?)
          Text(
            error,
            style: context.listCaptionStyle.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        if (status.self case final self?)
          generateSection(
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
        generateSection(
          title: '${appLocalizations.tailscalePeers} (${status.peers.length})',
          actions: [
            // Testing latency needs a device to test, so with none the
            // section shows no action that could pass for a connect button.
            if (status.peers.any((peer) => peer.online))
              IconButtonData(
                glyph: AppGlyphs.bolt,
                tooltip: appLocalizations.tailscalePingAll,
                isLoading: _pinging.isNotEmpty,
                onPressed: testable ? () => _ping(status.peers) : null,
              ),
          ],
          items: [
            if (peers.isEmpty)
              FormRow(
                title: appLocalizations.noData,
                trailing: const SizedBox.shrink(),
              ),
            for (final peer in peers) _buildPeer(peer),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            appLocalizations.tailscalePingDesc,
            style: context.listCaptionStyle,
          ),
        ),
      ],
    );
  }
}
