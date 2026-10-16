import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The proxies and groups a profile defines before its script runs, so a
/// target only a script adds still reads as missing here.
bool isRoutingTargetMissing(ClashConfig? config, String? target) {
  final name = target?.trim() ?? '';
  if (name.isEmpty || config == null) {
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
    builder: (context) => Consumer(
      builder: (_, ref, _) {
        final appLocalizations = context.appLocalizations;
        final profileId = ref.watch(currentProfileIdProvider);
        final clashConfig = profileId == null
            ? null
            : ref.watch(clashConfigProvider(profileId)).value;
        final groups = clashConfig?.proxyGroups ?? const [];
        final proxies = clashConfig?.proxies ?? const [];
        final groupTypes = {
          for (final item in groups) item.name: item.type.name,
        };
        final proxyTypes = {for (final item in proxies) item.name: item.type};
        return SelectionSheet<String>(
          title: appLocalizations.routingTarget,
          sections: [
            SelectionSection(
              label: appLocalizations.basicStrategy,
              items: [
                for (final name in RuleTarget.ruleTargetNames)
                  if (!groupTypes.containsKey(name)) name,
              ],
            ),
            SelectionSection(
              label: appLocalizations.proxyGroup,
              items: groupTypes.keys.toList(),
              subtitleBuilder: (_, name) => groupTypes[name] ?? '',
            ),
            SelectionSection(
              label: appLocalizations.proxies,
              items: proxyTypes.keys.toList(),
              subtitleBuilder: (_, name) => proxyTypes[name] ?? '',
            ),
          ],
          labelBuilder: (item) => item,
          selectedOf: (_) => selected,
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    ),
  );
}

class CustomRoutingsView extends ConsumerStatefulWidget {
  const CustomRoutingsView({super.key});

  @override
  ConsumerState<CustomRoutingsView> createState() => _CustomRoutingsViewState();
}

class _CustomRoutingsViewState extends ConsumerState<CustomRoutingsView> {
  late final SetupAction _setupAction;

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

  Widget _buildItem(List<CustomRouting> routings, int index) {
    final routing = routings[index];
    final appLocalizations = context.appLocalizations;
    return SortableItem(
      key: ValueKey(routing.id),
      index: index,
      child: ContextMenuRegion(
        menuItems: [
          CommonPopupMenuItem(
            glyph: AppGlyphs.edit,
            label: appLocalizations.edit,
            onPressed: () {
              _handleEdit(routing);
            },
          ),
          CommonPopupMenuItem(
            glyph: AppGlyphs.copy,
            label: appLocalizations.copy,
            onPressed: () {
              ref.read(customRoutingsProvider.notifier).duplicate(routing);
            },
          ),
          CommonPopupMenuItem(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final routingsState = ref.watch(customRoutingsProvider);
    final routings = routingsState.value ?? [];
    return CommonScaffold(
      title: appLocalizations.customRouting,
      canSort: routings.length > 1,
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
        nullStatus: NullStatus(
          label: appLocalizations.nullTip(appLocalizations.customRouting),
          illustration: NullStatusIllustration.rules,
        ),
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(
            16,
          ).copyWith(top: context.contentTopPadding),
          buildDefaultDragHandles: false,
          itemCount: routings.length,
          itemBuilder: (_, index) => _buildItem(routings, index),
          proxyDecorator: (_, index, animation) {
            return commonProxyDecorator(
              _buildItem(routings, index),
              index,
              animation,
            );
          },
          onReorderItem: ref.read(customRoutingsProvider.notifier).order,
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
    final missing = isRoutingTargetMissing(clashConfig, target);
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
              style: captionStyle?.copyWith(
                color: missing || target.isEmpty
                    ? context.colorScheme.error
                    : context.colorScheme.tertiary,
              ),
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
    final res = await dialogs.showCommonDialog<RuleAction>(
      context: context,
      child: OptionsDialog<RuleAction>(
        title: context.appLocalizations.ruleName,
        options: CustomRoutingConditionExt.actions,
        textBuilder: (item) => item.value,
        value: draft.ruleAction,
      ),
    );
    if (res == null) {
      return;
    }
    setState(() {
      draft.ruleAction = res;
    });
  }

  Future<void> _handlePickTarget() async {
    final res = await showRoutingTargetSheet(context, selected: _target);
    if (res == null) {
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
    setState(() {
      _conditions.remove(draft);
    });
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
    return CommonCard(
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
                  child: FilledButton.tonal(
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
              style: context.textTheme.bodyMedium?.toJetBrainsMono,
              validator: _validateValues,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                border: AppShape.input,
                labelText: appLocalizations.value,
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
    return CommonScaffold(
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
              16 + BottomInsetScope.of(context),
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
                  labelText: appLocalizations.name,
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
              SegmentedButton<CustomRoutingLogic>(
                segments: [
                  ButtonSegment(
                    value: CustomRoutingLogic.or,
                    label: Text(appLocalizations.routingLogicOr),
                  ),
                  ButtonSegment(
                    value: CustomRoutingLogic.and,
                    label: Text(appLocalizations.routingLogicAnd),
                  ),
                ],
                selected: {_logic},
                onSelectionChanged: (value) {
                  setState(() {
                    _logic = value.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListHeader(
                title: appLocalizations.routingCondition,
                padding: EdgeInsets.zero,
                actions: [EntryButton.add(onPressed: _handleAddCondition)],
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
    final missing = isRoutingTargetMissing(clashConfig, name);
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
                style: context.textTheme.bodyMedium?.toJetBrainsMono.copyWith(
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
            child: generateSectionV3(
              items: [
                for (final routing in routings)
                  _CustomRoutingItem(
                    routing: routing,
                    isSelected: selected.contains(routing.id),
                    leading: SizedBox.square(
                      dimension: 24,
                      child: ExcludeFocus(
                        child: Checkbox(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
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
