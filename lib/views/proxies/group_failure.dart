import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A group counts as timed out when the last delay test of the node it
/// currently routes through, against the group's test URL, failed.
bool isFailedDelay(int? delay) => delay != null && delay < 0;

int? watchGroupDelay(WidgetRef ref, Group group) {
  return ref.watch(
    delayProvider(proxyName: group.name, testUrl: group.testUrl),
  );
}

List<Group> watchFailedGroups(WidgetRef ref, List<Group> groups) {
  return [
    for (final group in groups)
      if (isFailedDelay(watchGroupDelay(ref, group))) group,
  ];
}

class GroupFailureTag extends ConsumerWidget {
  const GroupFailureTag({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = watchGroupDelay(ref, group);
    if (!isFailedDelay(delay)) {
      return const SizedBox.shrink();
    }
    final colorScheme = context.colorScheme;
    return Container(
      key: ValueKey('group-failure-tag-${group.name}'),
      margin: const EdgeInsetsDirectional.only(start: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: ShapeDecoration(
        color: colorScheme.errorContainer,
        shape: AppShape.full,
      ),
      child: Text(
        delayFailureText(delay!, context.appLocalizations),
        maxLines: 1,
        style: AppTextStyle.caption2
            .of(context, emphasized: true)
            .copyWith(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

/// The current node of a timed-out group and how its test failed.
class GroupFailureBanner extends ConsumerWidget {
  const GroupFailureBanner({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = watchGroupDelay(ref, group);
    if (!isFailedDelay(delay)) {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final node = ref
        .watch(selectedProxyNameProvider(group.name))
        .takeFirstValid([]);
    return Container(
      key: ValueKey('group-failure-banner-${group.name}'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: colorScheme.errorContainer,
        shape: AppShape.all(12),
      ),
      child: DefaultTextStyle.merge(
        style: AppTextStyle.footnote
            .of(context)
            .copyWith(color: colorScheme.onErrorContainer),
        child: Text(
          appLocalizations.groupFailureDetail(
            node.isEmpty ? '-' : node,
            delayFailureText(delay!, appLocalizations),
          ),
        ),
      ),
    );
  }
}

/// Lists the timed-out groups; picking one hands its name to [onSelected].
Future<void> showFailedGroupsSheet(
  BuildContext context, {
  required List<Group> groups,
  required void Function(String groupName) onSelected,
}) {
  return showSheet<void>(
    context: context,
    builder: (sheetContext) => CommonScaffold(
      title: sheetContext.appLocalizations.timedOutGroups,
      body: _FailedGroupsList(
        groups: groups,
        onSelected: (name) {
          Navigator.of(sheetContext).pop();
          onSelected(name);
        },
      ),
    ),
  );
}

class _FailedGroupsList extends ConsumerStatefulWidget {
  const _FailedGroupsList({required this.groups, required this.onSelected});

  final List<Group> groups;
  final void Function(String groupName) onSelected;

  @override
  ConsumerState<_FailedGroupsList> createState() => _FailedGroupsListState();
}

class _FailedGroupsListState extends ConsumerState<_FailedGroupsList> {
  /// The groups listed when the sheet opened, kept so a recovered one stays
  /// in view as recovered instead of vanishing under the finger.
  late final Set<String> _listed = {
    for (final group in widget.groups)
      if (isFailedDelay(
        ref.read(delayProvider(proxyName: group.name, testUrl: group.testUrl)),
      ))
        group.name,
  };

  Future<void> _retry(Iterable<String> names) {
    final action = ref.read(proxiesActionProvider.notifier);
    return Future.wait([
      for (final name in names)
        action.delayTestPageGroup(name, matchSearch: false),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final failed = watchFailedGroups(ref, widget.groups);
    final failedNames = {for (final group in failed) group.name};
    final shown = [
      for (final group in widget.groups)
        if (_listed.contains(group.name) || failedNames.contains(group.name))
          group,
    ];
    final testing = ref.watch(delayTestingGroupsProvider);
    final anyTesting = shown.any((group) => testing.contains(group.name));
    final appLocalizations = context.appLocalizations;
    return AppBarClearance(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              appLocalizations.timedOutGroupsDesc,
              style: AppTextStyle.footnote.of(context).toLight,
            ),
          ),
          if (shown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FilledButton.tonalIcon(
                key: const ValueKey('retry-failed-groups'),
                onPressed: anyTesting || failed.isEmpty
                    ? null
                    : () => _retry(failedNames),
                icon: anyTesting
                    ? const CommonCircleLoading(size: 16)
                    : const GlyphIcon(AppGlyphs.bolt),
                label: Text(
                  anyTesting
                      ? appLocalizations.retryingTimedOutGroups
                      : appLocalizations.retryTimedOutGroups,
                ),
              ),
            ),
          if (failed.isEmpty && !anyTesting)
            Padding(
              key: const ValueKey('failed-groups-recovered'),
              padding: const EdgeInsets.all(16),
              child: Text(
                shown.isEmpty
                    ? appLocalizations.noTimedOutGroups
                    : appLocalizations.allGroupsRecovered,
              ),
            ),
          for (final group in shown)
            KeyedSubtree(
              key: ValueKey('failed-group-${group.name}'),
              child: ListItem(
                title: Row(
                  children: [
                    Flexible(
                      child: EmojiText(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (failedNames.contains(group.name))
                      GroupFailureTag(group: group)
                    else
                      _RecoveredTag(groupName: group.name),
                  ],
                ),
                subtitle: _FailedGroupNode(group: group),
                trailing: IconButton(
                  key: ValueKey('retry-group-${group.name}'),
                  tooltip: appLocalizations.retry,
                  onPressed: testing.contains(group.name)
                      ? null
                      : () => _retry([group.name]),
                  icon: testing.contains(group.name)
                      ? const CommonCircleLoading(size: 16)
                      : const GlyphIcon(AppGlyphs.bolt),
                ),
                onTap: () => widget.onSelected(group.name),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecoveredTag extends StatelessWidget {
  const _RecoveredTag({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      key: ValueKey('group-recovered-tag-$groupName'),
      margin: const EdgeInsetsDirectional.only(start: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: ShapeDecoration(
        color: colorScheme.primaryContainer,
        shape: AppShape.full,
      ),
      child: Text(
        context.appLocalizations.groupRecovered,
        maxLines: 1,
        style: AppTextStyle.caption2
            .of(context, emphasized: true)
            .copyWith(color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}

class _FailedGroupNode extends ConsumerWidget {
  const _FailedGroupNode({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final delay = watchGroupDelay(ref, group) ?? delayTimedOutValue;
    final node = ref
        .watch(selectedProxyNameProvider(group.name))
        .takeFirstValid([]);
    return Text(
      appLocalizations.groupFailureDetail(
        node.isEmpty ? '-' : node,
        delay < 0 ? delayFailureText(delay, appLocalizations) : '$delay ms',
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
