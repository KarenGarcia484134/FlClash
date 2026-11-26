import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/config/choice_sheet.dart';
import 'package:fl_clash/views/config/outbound_delay.dart';
import 'package:fl_clash/views/config/tailscale.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The proxies and groups a profile defines before its script runs, so a
/// target only a script adds still reads as missing here.
/// [injected] is a node the app adds to the running config on its own, the
/// Tailscale one, which the profile's own config does not list.
bool isRoutingTargetMissing(
  ClashConfig? config,
  String? target, {
  String? injected,
}) {
  final name = target?.trim() ?? '';
  if (name.isEmpty || config == null || name == injected) {
    return false;
  }
  return !RuleTarget.ruleTargets.contains(name) &&
      !config.proxyGroups.any((item) => item.name == name) &&
      !config.proxies.any((item) => item.name == name);
}

String customRoutingSummary(CustomRouting routing) {
  final operands = [
    for (final condition in routing.conditions)
      for (final value in condition.cleanValues)
        '${condition.ruleAction.value}:$value',
  ];
  final joiner = routing.logic == CustomRoutingLogic.and ? ' & ' : ' | ';
  return operands.join(joiner);
}

Future<String?> showRoutingTargetSheet(
  BuildContext context, {
  required String? selected,
}) {
  return showSheet<String>(
    context: context,
    builder: (context) => OutboundPickerSheet(selected: selected),
  );
}

/// The outbound picker with latency badges. [basicItems] replaces the
/// built-in policies section and [allow] drops outbounds that can't be
/// picked.
class OutboundPickerSheet extends ConsumerStatefulWidget {
  const OutboundPickerSheet({
    super.key,
    required this.selected,
    this.title,
    this.basicItems,
    this.basicLabel,
    this.allow,
  });

  final String? selected;
  final String? title;
  final List<String>? basicItems;
  final String Function(String item)? basicLabel;
  final bool Function(String name)? allow;

  @override
  ConsumerState<OutboundPickerSheet> createState() =>
      _OutboundPickerSheetState();
}

class _OutboundPickerSheetState extends ConsumerState<OutboundPickerSheet> {
  bool _sortByDelay = false;
  bool _hideTimeout = false;

  List<String> _arrange(List<String> names) {
    if (widget.allow case final allow?) {
      names = names.where(allow).toList();
    }
    if (!_sortByDelay && !_hideTimeout) {
      return names;
    }
    final delays = {
      for (final name in names) name: ref.watch(delayProvider(proxyName: name)),
    };
    return sortedOutbounds(
      names,
      delays,
      sortByDelay: _sortByDelay,
      hideTimeout: _hideTimeout,
      keep: widget.selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final profileId = ref.watch(currentProfileIdProvider);
    final clashConfig = profileId == null
        ? null
        : ref.watch(clashConfigProvider(profileId)).value;
    final groups = clashConfig?.proxyGroups ?? const [];
    final proxies = clashConfig?.proxies ?? const [];
    final groupTypes = {for (final item in groups) item.name: item.type.name};
    final proxyTypes = {for (final item in proxies) item.name: item.type};
    final tailscale = currentTailscaleProxyName(ref);
    final testable = [...groupTypes.keys, ...proxyTypes.keys, ?tailscale];
    final groupNow = {
      for (final name in groupTypes.keys)
        name: ref.watch(realSelectedProxyStateProvider(name)).proxyName,
    };
    final testing = testable.any(
      (name) => ref.watch(delayTestPhaseProvider(proxyName: name)) != null,
    );
    return SelectionSheet<String>(
      title: widget.title ?? appLocalizations.routingTarget,
      actions: [
        AppBarActionButton(
          data: IconButtonData(
            glyph: AppGlyphs.bolt,
            tooltip: appLocalizations.testAllDelays,
            isLoading: testing,
            onPressed: () => testOutboundDelays(ref, testable),
          ),
        ),
      ],
      header: Wrap(
        spacing: 8,
        children: [
          Chip(
            label: appLocalizations.sortByDelay,
            selected: _sortByDelay,
            onPressed: () => setState(() => _sortByDelay = !_sortByDelay),
          ),
          Chip(
            label: appLocalizations.hideTimeoutNodes,
            selected: _hideTimeout,
            onPressed: () => setState(() => _hideTimeout = !_hideTimeout),
          ),
        ],
      ),
      sections: [
        SelectionSection(
          label: appLocalizations.basicStrategy,
          items:
              widget.basicItems ??
              [
                for (final name in RuleTarget.ruleTargetNames)
                  if (!groupTypes.containsKey(name)) name,
                ?tailscale,
              ],
        ),
        SelectionSection(
          label: appLocalizations.proxyGroup,
          items: _arrange(groupTypes.keys.toList()),
          subtitleBuilder: (_, name) {
            final now = groupNow[name] ?? '';
            final type = groupTypes[name] ?? '';
            return now.isEmpty || now == name ? type : '$type → $now';
          },
        ),
        SelectionSection(
          label: appLocalizations.proxies,
          items: _arrange(proxyTypes.keys.toList()),
          subtitleBuilder: (_, name) => proxyTypes[name] ?? '',
        ),
      ],
      labelBuilder: (item) =>
          widget.basicItems?.contains(item) == true && widget.basicLabel != null
          ? widget.basicLabel!(item)
          : item,
      trailingBuilder: (item) =>
          hasOutboundDelay(item) ? OutboundDelayBadge(name: item) : null,
      onLongPress: (item) => testOutboundDelay(ref, item),
      selectedOf: (_) => widget.selected,
      onSelected: (item) => Navigator.of(context).pop(item),
    );
  }
}

enum _CustomRoutingFilter { all, enabled, disabled, applied }

class CustomRoutingsView extends ConsumerStatefulWidget {
  const CustomRoutingsView({super.key});

  @override
  ConsumerState<CustomRoutingsView> createState() => _CustomRoutingsViewState();
}

class _CustomRoutingsViewState extends ConsumerState<CustomRoutingsView> {
  late final SetupAction _setupAction;
  var _query = SearchQuery('');
  final _searchTexts = Expando<String>();
  var _filter = _CustomRoutingFilter.all;
  final _keywords = ValueNotifier<List<ScaffoldKeyword>>(const []);

  @override
  void initState() {
    super.initState();
    _setupAction = ref.read(setupActionProvider.notifier);
  }

  @override
  void dispose() {
    _keywords.dispose();
    _setupAction.autoApplyProfile();
    super.dispose();
  }

  void _handleSearch(String query) {
    setState(() {
      _query = SearchQuery(query);
    });
  }

  String _filterLabel(AppLocalizations l, _CustomRoutingFilter filter) =>
      switch (filter) {
        _CustomRoutingFilter.all => l.routingFilterAll,
        _CustomRoutingFilter.enabled => l.enabled,
        _CustomRoutingFilter.disabled => l.disabled,
        _CustomRoutingFilter.applied => l.routingFilterApplied,
      };

  void _setFilter(
    _CustomRoutingFilter filter,
    AppLocalizations l, {
    int? expectedProfileId,
  }) {
    if (!mounted) {
      return;
    }
    if (filter == _CustomRoutingFilter.applied &&
        (expectedProfileId == null ||
            ref.read(currentProfileIdProvider) != expectedProfileId)) {
      return;
    }
    if (_filter == filter) {
      return;
    }
    setState(() {
      _filter = filter;
    });
    _keywords.value = filter == _CustomRoutingFilter.all
        ? const []
        : [
            ScaffoldKeyword(
              key: filter,
              label: _filterLabel(l, filter),
              onDeleted: () => _setFilter(_CustomRoutingFilter.all, l),
            ),
          ];
  }

  List<PopupMenuItem> _buildMenuItems(
    BuildContext context, {
    required int? profileId,
    required _CustomRoutingFilter activeFilter,
  }) {
    final l = context.appLocalizations;
    final options = [
      _CustomRoutingFilter.all,
      _CustomRoutingFilter.enabled,
      _CustomRoutingFilter.disabled,
      if (profileId != null) _CustomRoutingFilter.applied,
    ];
    return [
      for (final (index, option) in options.indexed)
        PopupMenuItem(
          label: _filterLabel(l, option),
          checked: activeFilter == option,
          section: index == 0 ? PopupMenuSection(title: l.status) : null,
          onPressed: () => _setFilter(
            option,
            l,
            expectedProfileId: option == _CustomRoutingFilter.applied
                ? profileId
                : null,
          ),
        ),
    ];
  }

  Future<void> _handleEdit([CustomRouting? routing]) async {
    final res = await BaseNavigator.push<CustomRouting>(
      context,
      CustomRoutingEditView(routing: routing),
    );
    if (res == null || !mounted) {
      return;
    }
    ref.read(customRoutingsProvider.notifier).put(res);
  }

  Future<void> _handleDelete(CustomRouting routing) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.customRouting),
      ),
    );
    if (res != true || !mounted) {
      return;
    }
    ref.read(customRoutingsProvider.notifier).del(routing.id);
  }

  EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
    16,
    context.contentTopPadding,
    16,
    16 + context.bottomInset,
  );

  Widget _buildItem(
    List<CustomRouting> routings,
    int index, {
    required int? profileId,
    required Set<int> selectedIds,
    required bool sortable,
  }) {
    final routing = routings[index];
    final appLocalizations = context.appLocalizations;
    final applied = profileId != null && selectedIds.contains(routing.id);
    final row = ContextMenuRegion(
      key: sortable ? null : ValueKey(routing.id),
      menuItems: [
        PopupMenuItem(
          glyph: AppGlyphs.edit,
          label: appLocalizations.edit,
          onPressed: () {
            _handleEdit(routing);
          },
        ),
        PopupMenuItem(
          glyph: AppGlyphs.copy,
          label: appLocalizations.copy,
          onPressed: () {
            ref.read(customRoutingsProvider.notifier).duplicate(routing);
          },
        ),
        PopupMenuItem(
          danger: true,
          glyph: AppGlyphs.delete,
          label: appLocalizations.delete,
          onPressed: () {
            _handleDelete(routing);
          },
        ),
      ],
      child: ItemPositionProvider(
        position: ItemPosition.get(index, routings.length),
        child: _CustomRoutingItem(
          routing: routing,
          leading: profileId == null
              ? null
              : Tooltip(
                  message: appLocalizations.customRoutingUseInProfile,
                  child: Checkbox(
                    value: applied,
                    onChanged: (_) => ref
                        .read(
                          profileCustomRoutingIdsProvider(profileId).notifier,
                        )
                        .toggle(routing.id),
                  ),
                ),
          trailing: Switch(
            value: routing.enabled,
            onChanged: (value) {
              ref
                  .read(customRoutingsProvider.notifier)
                  .put(routing.copyWith(enabled: value));
            },
          ),
          onPressed: () {
            _handleEdit(routing);
          },
        ),
      ),
    );
    if (!sortable) {
      return row;
    }
    return SortableItem(key: ValueKey(routing.id), index: index, child: row);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    ref.listen(currentProfileIdProvider, (_, next) {
      if (next == null && _filter == _CustomRoutingFilter.applied) {
        _setFilter(_CustomRoutingFilter.all, appLocalizations);
      }
    });
    final routingsState = ref.watch(customRoutingsProvider);
    final allRoutings = routingsState.value ?? [];
    final profileId = ref.watch(currentProfileIdProvider);
    final selectedIds = profileId == null
        ? const <int>{}
        : (ref.watch(profileCustomRoutingIdsProvider(profileId)).value ??
                  const <int>[])
              .toSet();
    final activeFilter =
        profileId == null && _filter == _CustomRoutingFilter.applied
        ? _CustomRoutingFilter.all
        : _filter;
    final isFiltering =
        _query.isNotEmpty || activeFilter != _CustomRoutingFilter.all;
    final routings = allRoutings
        .where(
          (routing) => switch (activeFilter) {
            _CustomRoutingFilter.all => true,
            _CustomRoutingFilter.enabled => routing.enabled,
            _CustomRoutingFilter.disabled => !routing.enabled,
            _CustomRoutingFilter.applied => selectedIds.contains(routing.id),
          },
        )
        .whereMatches(
          _query,
          (routing) => routing.searchFields,
          texts: _searchTexts,
        )
        .toList();
    return Scaffold(
      title: appLocalizations.customRouting,
      canSort: !isFiltering && allRoutings.length > 1,
      searchState: AppBarSearchState(onSearch: _handleSearch),
      menuItems: _buildMenuItems(
        context,
        profileId: profileId,
        activeFilter: activeFilter,
      ),
      keywords: _keywords,
      actions: [
        IconButton(
          tooltip: appLocalizations.addCustomRouting,
          onPressed: _handleEdit,
          icon: const GlyphIcon(AppGlyphs.addCircle),
        ),
      ],
      body: NullStatusSwitcher(
        isLoading: routingsState.isLoading,
        isEmpty: routings.isEmpty,
        isSearching: isFiltering,
        nullStatus: NullStatus(
          label: appLocalizations.nullTip(appLocalizations.customRouting),
          illustration: NullStatusIllustration.rules,
        ),
        child: Builder(
          builder: (context) => isFiltering
              ? PrismListView(
                  padding: _listPadding(context),
                  itemCount: routings.length,
                  itemBuilder: (_, index) => _buildItem(
                    routings,
                    index,
                    profileId: profileId,
                    selectedIds: selectedIds,
                    sortable: false,
                  ),
                )
              : PrismReorderableListView(
                  padding: _listPadding(context),
                  itemCount: routings.length,
                  itemBuilder: (_, index) => _buildItem(
                    routings,
                    index,
                    profileId: profileId,
                    selectedIds: selectedIds,
                    sortable: true,
                  ),
                  proxyDecorator: (_, index, animation) {
                    return commonProxyDecorator(
                      _buildItem(
                        routings,
                        index,
                        profileId: profileId,
                        selectedIds: selectedIds,
                        sortable: true,
                      ),
                      index,
                      animation,
                    );
                  },
                  onReorderItem: ref
                      .read(customRoutingsProvider.notifier)
                      .order,
                ),
        ),
      ),
    );
  }
}

class _CustomRoutingItem extends ConsumerWidget {
  final CustomRouting routing;
  final Widget? leading;
  final Widget? trailing;
  final bool? isSelected;
  final VoidCallback onPressed;

  const _CustomRoutingItem({
    required this.routing,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(currentProfileIdProvider);
    final clashConfig = profileId == null
        ? null
        : ref.watch(clashConfigProvider(profileId)).value;
    final target = routing.target?.trim() ?? '';
    final missing = isRoutingTargetMissing(
      clashConfig,
      target,
      injected: currentTailscaleProxyName(ref),
    );
    final captionStyle = context.listCaptionStyle;
    return DecorationListItem(
      isSelected: isSelected,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: leading,
      title: Text(routing.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: target.isEmpty ? '-' : target,
              style: captionStyle.copyWith(
                color: missing || target.isEmpty
                    ? context.colorScheme.error
                    : context.colorScheme.tertiary,
              ),
            ),
            if (!missing && hasOutboundDelay(target))
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: OutboundDelayBadge(name: target),
              ),
            TextSpan(text: '  ${customRoutingSummary(routing)}'),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: captionStyle,
      ),
      trailing: trailing,
      onPressed: onPressed,
    );
  }
}

class CustomRoutingEditView extends StatefulWidget {
  final CustomRouting? routing;

  const CustomRoutingEditView({super.key, this.routing});

  @override
  State<CustomRoutingEditView> createState() => _CustomRoutingEditViewState();
}

class _ConditionDraft {
  RuleAction ruleAction;
  bool noResolve;
  final TextEditingController controller;

  _ConditionDraft(CustomRoutingCondition condition)
    : ruleAction = condition.ruleAction,
      noResolve = condition.noResolve,
      controller = TextEditingController(text: condition.values.join('\n'));

  CustomRoutingCondition get condition => CustomRoutingCondition(
    ruleAction: ruleAction,
    values: [
      for (final line in controller.text.split('\n'))
        if (line.trim() case final value when value.isNotEmpty) value,
    ],
    noResolve: noResolve && ruleAction.hasParams,
  );
}

class _CustomRoutingEditViewState extends State<CustomRoutingEditView> {
  final _formKey = GlobalKey<FormState>();
  late final CustomRouting _initial;
  late final TextEditingController _labelController;
  late CustomRoutingLogic _logic;
  late String? _target;
  late final List<_ConditionDraft> _conditions;

  @override
  void initState() {
    super.initState();
    _initial = widget.routing ?? CustomRouting.create();
    _labelController = TextEditingController(text: _initial.label);
    _logic = _initial.logic;
    _target = _initial.target;
    _conditions = [
      for (final condition in _initial.conditions) _ConditionDraft(condition),
      if (_initial.conditions.isEmpty)
        _ConditionDraft(const CustomRoutingCondition()),
    ];
  }

  @override
  void dispose() {
    _labelController.dispose();
    for (final draft in _conditions) {
      draft.controller.dispose();
    }
    super.dispose();
  }

  CustomRouting get _routing => _initial.copyWith(
    label: _labelController.text.trim(),
    logic: _logic,
    target: _target,
    conditions: [
      for (final draft in _conditions)
        if (draft.condition case final condition
            when condition.values.isNotEmpty)
          condition,
    ],
  );

  void _handleSave() {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    final routing = _routing;
    final error = routing.conditions.isEmpty
        ? appLocalizations.routingConditionsEmptyTip
        : !routing.hasTarget
        ? appLocalizations.routingTargetEmptyTip
        : null;
    if (error != null) {
      dialogs.showMessage(message: TextSpan(text: error));
      return;
    }
    Navigator.of(context).pop(routing);
  }

  Future<void> _handlePickAction(_ConditionDraft draft) async {
    final res = await showChoiceSheet<RuleAction>(
      context,
      title: context.appLocalizations.rule,
      options: CustomRoutingConditionExt.actions,
      labelOf: (item) => item.value,
      value: draft.ruleAction,
    );
    if (res == null || !mounted) {
      return;
    }
    setState(() {
      draft.ruleAction = res;
    });
  }

  Future<void> _handlePickTarget() async {
    final res = await showRoutingTargetSheet(context, selected: _target);
    if (res == null || !mounted) {
      return;
    }
    setState(() {
      _target = res;
    });
  }

  void _handleAddCondition() {
    setState(() {
      _conditions.add(_ConditionDraft(const CustomRoutingCondition()));
    });
  }

  void _handleRemoveCondition(_ConditionDraft draft) {
    if (!_conditions.remove(draft)) {
      return;
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      draft.controller.dispose();
    });
  }

  String? _validateValues(String? value) {
    if (value?.contains(customRoutingValueSeparator) == true) {
      return context.appLocalizations.routingValueCommaTip;
    }
    return null;
  }

  Widget _buildCondition(_ConditionDraft draft) {
    final appLocalizations = context.appLocalizations;
    return Card(
      key: ObjectKey(draft),
      onPressed: null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              children: [
                ElasticButton(
                  child: FilledButton(
                    onPressed: () {
                      _handlePickAction(draft);
                    },
                    child: Text(draft.ruleAction.value),
                  ),
                ),
                const Spacer(),
                if (draft.ruleAction.hasParams) ...[
                  Text(appLocalizations.noResolve),
                  Checkbox(
                    value: draft.noResolve,
                    onChanged: (value) {
                      setState(() {
                        draft.noResolve = value ?? false;
                      });
                    },
                  ),
                ],
                if (_conditions.length > 1)
                  EntryButton.remove(
                    onPressed: () {
                      _handleRemoveCondition(draft);
                    },
                  ),
              ],
            ),
            Text(
              draft.ruleAction.getDesc(context),
              style: context.listCaptionStyle,
            ),
            TextFormField(
              controller: draft.controller,
              minLines: 2,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              style: AppTextStyle.subheadline.of(context).toJetBrainsMono,
              validator: _validateValues,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                border: AppShape.input,
                helperText: appLocalizations.value,
                hintText: appLocalizations.routingValuesHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Scaffold(
      title: widget.routing == null
          ? appLocalizations.addCustomRouting
          : appLocalizations.editCustomRouting,
      actions: [
        IconButton(
          tooltip: appLocalizations.save,
          onPressed: _handleSave,
          icon: const GlyphIcon(AppGlyphs.check),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Builder(
          builder: (context) => ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              context.contentTopPadding,
              16,
              16 + context.bottomInset,
            ),
            children: [
              TextFormField(
                controller: _labelController,
                inputFormatters: TextInputLimits.limit(TextInputLimits.name),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : appLocalizations.emptyTip(appLocalizations.name),
                decoration: InputDecoration(
                  border: AppShape.input,
                  helperText: appLocalizations.name,
                ),
              ),
              const SizedBox(height: 16),
              _TargetRow(target: _target, onPressed: _handlePickTarget),
              const SizedBox(height: 16),
              InfoHeader(
                padding: EdgeInsets.zero,
                info: Info(label: appLocalizations.routingLogic),
              ),
              const SizedBox(height: 8),
              SegmentedControl<CustomRoutingLogic>(
                segments: [
                  (CustomRoutingLogic.or, appLocalizations.routingLogicOr),
                  (CustomRoutingLogic.and, appLocalizations.routingLogicAnd),
                ],
                value: _logic,
                onChanged: (value) {
                  setState(() {
                    _logic = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListHeader(
                title: appLocalizations.routingCondition,
                padding: EdgeInsets.zero,
                actions: [
                  IconButtonData(
                    glyph: AppGlyphs.addCircle,
                    tooltip: appLocalizations.add,
                    onPressed: _handleAddCondition,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final draft in _conditions) ...[
                _buildCondition(draft),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetRow extends ConsumerWidget {
  final String? target;
  final VoidCallback onPressed;

  const _TargetRow({required this.target, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final profileId = ref.watch(currentProfileIdProvider);
    final clashConfig = profileId == null
        ? null
        : ref.watch(clashConfigProvider(profileId)).value;
    final name = target?.trim() ?? '';
    final missing = isRoutingTargetMissing(
      clashConfig,
      name,
      injected: currentTailscaleProxyName(ref),
    );
    return ItemPositionProvider(
      position: ItemPosition.startAndEnd,
      child: FormRow(
        title: appLocalizations.routingTarget,
        invalid: name.isEmpty || missing,
        onPressed: onPressed,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (missing)
              InfoMessageButton(
                message: appLocalizations.routingTargetMissingTip(name),
              ),
            Flexible(
              child: Text(
                name.isEmpty ? appLocalizations.routingTargetEmptyTip : name,
                style: AppTextStyle.subheadline
                    .of(context)
                    .toJetBrainsMono
                    .copyWith(
                      color: name.isEmpty || missing
                          ? context.colorScheme.error
                          : context.colorScheme.tertiary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRoutingContent extends ConsumerWidget {
  const CustomRoutingContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final profileId = ProfileIdProvider.of(context)!.profileId;
    final routings = (ref.watch(customRoutingsProvider).value ?? [])
        .where((item) => item.enabled)
        .toList();
    final selectedIds = ref
        .watch(profileCustomRoutingIdsProvider(profileId))
        .value;
    final selected = (selectedIds ?? const <int>[]).toSet();
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: InfoHeader(info: Info(label: appLocalizations.customRouting)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: generateSection(
              items: [
                for (final routing in routings)
                  _CustomRoutingItem(
                    routing: routing,
                    isSelected: selected.contains(routing.id),
                    leading: SizedBox.square(
                      dimension: 24,
                      child: ExcludeFocus(
                        child: Checkbox(
                          value: selected.contains(routing.id),
                          onChanged: (_) {
                            ref
                                .read(
                                  profileCustomRoutingIdsProvider(
                                    profileId,
                                  ).notifier,
                                )
                                .toggle(routing.id);
                          },
                        ),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(
                            profileCustomRoutingIdsProvider(profileId).notifier,
                          )
                          .toggle(routing.id);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: MoreActionButton(
            label: appLocalizations.goToConfigureCustomRouting,
            onPressed: () {
              showInSheet<void>(
                context,
                builder: (_) => const CustomRoutingsView(),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
