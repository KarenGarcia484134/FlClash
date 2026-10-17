import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/views/config/tailscale.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

bool isGroupTypeName(String type) =>
    GroupType.values.any((item) => item.name == type);

DialerGraph _currentGraph(WidgetRef ref, int profileId) {
  final graph =
      ref.watch(dialerGraphProvider(profileId)).value ?? const DialerGraph();
  return graph.withProxy(currentTailscaleProxyName(ref));
}

String dialerProxyIssueText(BuildContext context, DialerProxyIssue issue) {
  final appLocalizations = context.appLocalizations;
  return switch (issue) {
    DialerProxyIssue.missingNode => appLocalizations.dialerProxyMissingNode,
    DialerProxyIssue.missingTarget => appLocalizations.dialerProxyMissingTarget,
    DialerProxyIssue.cycle => appLocalizations.dialerProxyCycle,
  };
}

/// "经 X" for a node carrying a dialer-proxy, the user's or the profile's.
String? dialerProxySubtitle(WidgetRef ref, BuildContext context, String node) {
  final profileId = ref.watch(currentProfileIdProvider);
  if (profileId == null) {
    return null;
  }
  final via =
      ref.watch(profileDialerProxiesProvider(profileId))[node] ??
      ref.watch(dialerGraphProvider(profileId)).value?.existing[node];
  return via == null || via == dialerProxyDirect
      ? null
      : context.appLocalizations.dialerProxyVia(via);
}

Future<void> pickDialerProxy(
  BuildContext context,
  WidgetRef ref,
  String node,
) async {
  final profileId = ref.read(currentProfileIdProvider);
  if (profileId == null) {
    return;
  }
  final appLocalizations = context.appLocalizations;
  final graph = await ref.read(dialerGraphProvider(profileId).future);
  if (!context.mounted) {
    return;
  }
  if (!graph.proxies.contains(node)) {
    dialogs.showNotifier(
      appLocalizations.dialerProxyProviderTip,
      level: MessageLevel.warning,
    );
    return;
  }
  final settings = ref.read(profileDialerProxiesProvider(profileId));
  final full = graph.withProxy(currentTailscaleProxyName(ref));
  final others = effectiveDialers(full, settings)
    ..remove(node)
    ..removeWhere((_, via) => via == dialerProxyDirect);
  final current = settings[node] ?? graph.existing[node];
  final res = await showSheet<String>(
    context: context,
    builder: (_) => OutboundPickerSheet(
      title: appLocalizations.setDialerProxy,
      selected: current ?? '',
      basicItems: const [''],
      basicLabel: (_) => appLocalizations.dialerProxyNone,
      allow: (name) =>
          isDialerTargetCandidate(name, node) &&
          !dialerProxyCreatesCycle(full, others, node, name),
    ),
  );
  if (res == null) {
    return;
  }
  final notifier = ref.read(dialerProxySettingProvider.notifier);
  if (res.isEmpty && graph.existing.containsKey(node)) {
    notifier.set(profileId, node, dialerProxyDirect);
  } else {
    notifier.set(profileId, node, res);
  }
}

/// Long-press menu entries of a node on the proxies page. Append new entries
/// here.
List<CommonPopupMenuItem> proxyNodeMenuItems(
  BuildContext context,
  WidgetRef ref,
  Proxy proxy,
) {
  if (isGroupTypeName(proxy.type)) {
    return const [];
  }
  return [
    CommonPopupMenuItem(
      label: context.appLocalizations.setDialerProxy,
      glyph: AppGlyphs.link,
      onPressed: () => pickDialerProxy(context, ref, proxy.name),
    ),
  ];
}

/// How many of the current profile's settings are skipped on apply.
int dialerProxySkippedCount(WidgetRef ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  if (profileId == null) {
    return 0;
  }
  final settings = ref.watch(profileDialerProxiesProvider(profileId));
  if (settings.isEmpty) {
    return 0;
  }
  final graph = _currentGraph(ref, profileId);
  return settings.keys
      .where((node) => dialerProxyIssue(graph, settings, node) != null)
      .length;
}

class DialerProxyView extends ConsumerWidget {
  const DialerProxyView({super.key});

  Future<void> _clearAll(BuildContext context, WidgetRef ref, int id) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.dialerProxyClearAllTip),
    );
    if (res != true) {
      return;
    }
    ref.read(dialerProxySettingProvider.notifier).clear(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final profileId = ref.watch(currentProfileIdProvider);
    final settings = profileId == null
        ? const <String, String>{}
        : ref.watch(profileDialerProxiesProvider(profileId));
    final graph = profileId == null
        ? const DialerGraph()
        : _currentGraph(ref, profileId);
    final fromProfile = {
      for (final entry in graph.existing.entries)
        if (!settings.containsKey(entry.key)) entry.key: entry.value,
    };
    return BaseScaffold(
      title: appLocalizations.dialerProxy,
      actions: [
        if (profileId != null && settings.isNotEmpty)
          AppBarActionButton(
            data: IconButtonData(
              glyph: AppGlyphs.delete,
              tooltip: appLocalizations.dialerProxyClearAll,
              onPressed: () => _clearAll(context, ref, profileId),
            ),
          ),
      ],
      body: settings.isEmpty && fromProfile.isEmpty
          ? NullStatus(label: appLocalizations.dialerProxyEmpty)
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ).copyWith(top: context.contentTopPadding, bottom: 16),
              children: [
                for (final MapEntry(key: node, value: target)
                    in settings.entries)
                  _DialerProxyItem(
                    node: node,
                    target: target,
                    issue: dialerProxyIssue(graph, settings, node),
                    onDelete: () {
                      ref
                          .read(dialerProxySettingProvider.notifier)
                          .set(profileId!, node, null);
                    },
                  ),
                for (final MapEntry(key: node, value: target)
                    in fromProfile.entries)
                  _DialerProxyItem(node: node, target: target, external: true),
              ],
            ),
    );
  }
}

class _DialerProxyItem extends ConsumerWidget {
  const _DialerProxyItem({
    required this.node,
    required this.target,
    this.issue,
    this.onDelete,
    this.external = false,
  });

  final String node;
  final String target;
  final DialerProxyIssue? issue;
  final VoidCallback? onDelete;
  final bool external;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final issue = this.issue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CommonCard(
        onPressed: issue == DialerProxyIssue.missingNode
            ? null
            : () => pickDialerProxy(context, ref, node),
        child: ListItem(
          title: Text(node),
          subtitle: Text(
            [
              appLocalizations.dialerProxyVia(target),
              if (external) appLocalizations.dialerProxyFromProfile,
              if (issue != null) dialerProxyIssueText(context, issue),
            ].join(' · '),
            style: issue == null
                ? null
                : TextStyle(color: context.colorScheme.error),
          ),
          trailing: onDelete == null
              ? null
              : IconButton(
                  icon: const GlyphIcon(AppGlyphs.delete),
                  tooltip: appLocalizations.delete,
                  onPressed: onDelete,
                ),
        ),
      ),
    );
  }
}
