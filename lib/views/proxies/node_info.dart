import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/node_info.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Reads the current profile's config, null when the Core cannot give it.
typedef NodeConfigLoader = Future<Map<String, dynamic>?> Function();

Future<void> showNodeInfo(
  BuildContext context,
  Proxy proxy, {
  String? testUrl,
}) {
  return showSheet<void>(
    context: context,
    builder: (sheetContext) => CommonScaffold(
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

class _NodeInfoViewState extends ConsumerState<NodeInfoView> {
  late final Future<Map<String, dynamic>?> _config =
      (widget.loadConfig ?? _loadCurrentConfig)().catchError((_) => null);

  Future<Map<String, dynamic>?> _loadCurrentConfig() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      return null;
    }
    return ref.read(coreHandlerProvider).getConfig(profileId);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      context.showNotifier(context.appLocalizations.copySuccess);
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
      future: _config,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final node = group == null
            ? findNodeConfig(snapshot.data, proxy.name)
            : null;
        return AppBarClearance(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 20 + BottomInsetScope.of(context)),
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
              else if (node == null)
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
                    for (final field in nodeFields(node))
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
                      copyText: nodeConfigYaml(node),
                    ),
                    DetailRow(
                      key: const ValueKey('node-copy-json'),
                      title: appLocalizations.copyAsJson,
                      copyText: nodeConfigJson(node),
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
