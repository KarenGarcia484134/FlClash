import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/node_info.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

/// Reads the current profile's config, null when the Core cannot give it.
typedef NodeConfigLoader = Future<Map<String, dynamic>?> Function();

Future<void> showNodeInfo(
  BuildContext context,
  Proxy proxy, {
  String? testUrl,
}) {
  return showSheet<void>(
    context: context,
    builder: (sheetContext) => Scaffold(
      title: sheetContext.appLocalizations.nodeInfoTitle,
      body: NodeInfoView(proxy: proxy, testUrl: testUrl),
    ),
  );
}

class NodeInfoView extends ConsumerStatefulWidget {
  const NodeInfoView({
    super.key,
    required this.proxy,
    this.testUrl,
    this.loadConfig,
  });

  final Proxy proxy;
  final String? testUrl;
  final NodeConfigLoader? loadConfig;

  @override
  ConsumerState<NodeInfoView> createState() => _NodeInfoViewState();
}

typedef _ResolvedNode = ({
  Map<String, Object?> node,
  List<NodeField> fields,
  String yaml,
  String json,
});

class _NodeInfoViewState extends ConsumerState<NodeInfoView> {
  late final Future<_ResolvedNode?> _resolved = _loadResolvedNode().catchError(
    (_) => null,
  );

  Future<_ResolvedNode?> _loadResolvedNode() async {
    final Map<String, Object?>? node;
    if (widget.loadConfig case final loadConfig?) {
      final config = await loadConfig();
      node = findNodeConfig(config, widget.proxy.name);
    } else if (ref.read(groupsProvider).getGroup(widget.proxy.name) != null) {
      return null;
    } else {
      final raw = await ref
          .read(coreHandlerProvider)
          .getProxyDefinition(widget.proxy.name);
      node = raw == null ? null : Map<String, Object?>.from(raw);
    }
    if (node == null) {
      return null;
    }
    return (
      node: node,
      fields: nodeFields(node),
      yaml: nodeConfigYaml(node),
      json: nodeConfigJson(node),
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      dialogs.showBanner(context.appLocalizations.copySuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final proxy = widget.proxy;
    final groups = ref.watch(groupsProvider);
    final group = groups.getGroup(proxy.name);
    final memberOf = [
      for (final item in groups)
        if (item.all.any((member) => member.name == proxy.name)) item.name,
    ];
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: widget.testUrl),
    );
    final delayText = switch (delay) {
      null => '-',
      final value when value < 0 => delayFailureText(value, appLocalizations),
      final value => '$value ms',
    };
    return FutureBuilder(
      future: _resolved,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final resolved = group == null ? snapshot.data : null;
        return AppBarClearance(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 20 + context.bottomInset),
            children: [
              generateSection(
                title: appLocalizations.basicInfo,
                items: [
                  DetailRow.text(
                    title: appLocalizations.name,
                    value: proxy.name,
                  ),
                  DetailRow.text(
                    title: appLocalizations.proxyType,
                    value: group?.type.name ?? proxy.type,
                  ),
                  if (group != null)
                    DetailRow.text(
                      title: appLocalizations.currentSelection,
                      value: group.now?.takeFirstValid([]) ?? '-',
                    ),
                  DetailRow.text(
                    title: appLocalizations.delay,
                    value: delayText,
                  ),
                  if (memberOf.isNotEmpty)
                    DetailRow.text(
                      title: appLocalizations.belongsToGroups,
                      value: memberOf.join(', '),
                    ),
                ],
              ),
              if (group != null)
                generateSection(
                  title: appLocalizations.groupMembers(group.all.length),
                  items: [
                    for (final member in group.all)
                      DetailRow(
                        key: ValueKey('node-member-${member.name}'),
                        title: member.name,
                        copyText: member.name,
                        value: Text(
                          member.name == group.now
                              ? '✓ ${member.type}'
                              : member.type,
                        ),
                      ),
                  ],
                )
              else if (loading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(appLocalizations.loading)),
                )
              else if (resolved == null)
                Padding(
                  key: const ValueKey('node-config-missing'),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    appLocalizations.nodeConfigMissing,
                    style: AppTextStyle.footnote.of(context).toLight,
                  ),
                )
              else ...[
                generateSection(
                  title: appLocalizations.nodeConfig,
                  items: [
                    for (final field in resolved.fields)
                      field.secret
                          ? _SecretRow(
                              key: ValueKey('node-field-${field.path}'),
                              field: field,
                              onCopy: _copy,
                            )
                          : DetailRow.text(
                              key: ValueKey('node-field-${field.path}'),
                              title: field.path,
                              value: field.value,
                            ),
                  ],
                ),
                generateSection(
                  items: [
                    DetailRow(
                      key: const ValueKey('node-copy-yaml'),
                      title: appLocalizations.copyAsYaml,
                      copyText: resolved.yaml,
                    ),
                    DetailRow(
                      key: const ValueKey('node-copy-json'),
                      title: appLocalizations.copyAsJson,
                      copyText: resolved.json,
                    ),
                  ],
                  footer: appLocalizations.nodeConfigCopyTip,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SecretRow extends StatefulWidget {
  const _SecretRow({super.key, required this.field, required this.onCopy});

  final NodeField field;
  final Future<void> Function(String text) onCopy;

  @override
  State<_SecretRow> createState() => _SecretRowState();
}

class _SecretRowState extends State<_SecretRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final field = widget.field;
    return DetailRow(
      title: field.path,
      value: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Text(
                _revealed ? field.value : maskSecret(field.value),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            tooltip: _revealed
                ? appLocalizations.hideSecret
                : appLocalizations.revealSecret,
            onPressed: () => setState(() => _revealed = !_revealed),
            icon: GlyphIcon(
              _revealed ? AppGlyphs.eyeOff : AppGlyphs.eye,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: appLocalizations.copy,
            onPressed: () => widget.onCopy(field.value),
            icon: const GlyphIcon(AppGlyphs.copy, size: 18),
          ),
        ],
      ),
    );
  }
}
