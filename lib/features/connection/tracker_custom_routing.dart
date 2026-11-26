import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/views/config/outbound_delay.dart';
import 'package:fl_clash/views/config/tailscale.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _multiPartPublicSuffixes = {
  'ac.jp',
  'ac.uk',
  'co.id',
  'co.in',
  'co.jp',
  'co.kr',
  'co.nz',
  'co.th',
  'co.uk',
  'co.za',
  'com.ar',
  'com.au',
  'com.br',
  'com.cn',
  'com.hk',
  'com.mx',
  'com.my',
  'com.pl',
  'com.ru',
  'com.sg',
  'com.tr',
  'com.tw',
  'com.ua',
  'com.vn',
  'edu.au',
  'edu.cn',
  'go.jp',
  'gov.au',
  'gov.cn',
  'gov.uk',
  'ne.jp',
  'net.au',
  'net.cn',
  'net.tw',
  'or.jp',
  'or.kr',
  'org.au',
  'org.cn',
  'org.hk',
  'org.tw',
  'org.uk',
};

class TrackerRoutingCandidate {
  final RuleAction ruleAction;
  final String value;
  final bool noResolve;

  const TrackerRoutingCandidate({
    required this.ruleAction,
    required this.value,
    this.noResolve = false,
  });

  bool get effectiveNoResolve => noResolve && ruleAction.hasParams;

  String get display => '${ruleAction.value}:$value';

  TrackerRoutingCandidate withValue(String nextValue) =>
      TrackerRoutingCandidate(
        ruleAction: ruleAction,
        value: nextValue,
        noResolve: noResolve,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TrackerRoutingCandidate &&
        other.ruleAction == ruleAction &&
        other.value == value &&
        other.noResolve == noResolve;
  }

  @override
  int get hashCode => Object.hash(ruleAction, value, noResolve);

  @override
  String toString() =>
      'TrackerRoutingCandidate($ruleAction, $value, noResolve: $noResolve)';
}

typedef CustomRoutingMergeResult = ({
  CustomRouting routing,
  int addedCount,
  int duplicateCount,
});

bool _isInvalidRoutingValue(String value) =>
    value.isEmpty ||
    value.contains(customRoutingValueSeparator) ||
    value.contains('\n') ||
    value.contains('\r');

InternetAddress? _parseIpLiteral(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final direct = InternetAddress.tryParse(trimmed);
  if (direct != null) {
    return direct;
  }
  if (trimmed.startsWith('[')) {
    final end = trimmed.indexOf(']');
    if (end > 1) {
      final inside = trimmed.substring(1, end);
      return InternetAddress.tryParse(inside);
    }
    return null;
  }
  final colonIndex = trimmed.indexOf(':');
  if (colonIndex > 0 && colonIndex == trimmed.lastIndexOf(':')) {
    return InternetAddress.tryParse(trimmed.substring(0, colonIndex));
  }
  return null;
}

String? _registrableDomainOf(String host) {
  final labels = host
      .split('.')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (labels.length < 2) {
    return null;
  }
  if (labels.length == 2) {
    return labels.join('.');
  }
  final tail2 = '${labels[labels.length - 2]}.${labels.last}';
  if (_multiPartPublicSuffixes.contains(tail2)) {
    return labels.sublist(labels.length - 3).join('.');
  }
  return tail2;
}

String _processNameOf(Metadata metadata) {
  final name = metadata.process.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final path = metadata.processPath.trim();
  if (path.isEmpty) {
    return '';
  }
  final parts = path.split(RegExp(r'[\\/]+')).where((part) => part.isNotEmpty);
  return parts.lastOrNull ?? '';
}

List<TrackerRoutingCandidate> extractTrackerRoutingCandidates(
  TrackerInfo trackerInfo,
) {
  final metadata = trackerInfo.metadata;
  final candidates = <TrackerRoutingCandidate>[];

  final rawHost = metadata.host.trim();
  final hostIp = _parseIpLiteral(rawHost);
  if (rawHost.isNotEmpty && hostIp == null) {
    final normalizedHost = rawHost
        .replaceAll(RegExp(r'\.+$'), '')
        .toLowerCase();
    if (!_isInvalidRoutingValue(normalizedHost) &&
        !normalizedHost.contains(RegExp(r'\s'))) {
      candidates.add(
        TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN,
          value: normalizedHost,
        ),
      );
      final suffix = _registrableDomainOf(normalizedHost);
      if (suffix != null && !_isInvalidRoutingValue(suffix)) {
        candidates.add(
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: suffix,
          ),
        );
      }
    }
  }

  final ip =
      _parseIpLiteral(metadata.destinationIP) ??
      hostIp ??
      _parseIpLiteral(metadata.remoteDestination);
  if (ip != null) {
    final isV6 = ip.type == InternetAddressType.IPv6;
    candidates.add(
      TrackerRoutingCandidate(
        ruleAction: isV6 ? RuleAction.IP_CIDR6 : RuleAction.IP_CIDR,
        value: isV6 ? '${ip.address}/128' : '${ip.address}/32',
        noResolve: true,
      ),
    );
  }

  final processName = _processNameOf(metadata);
  if (!_isInvalidRoutingValue(processName)) {
    candidates.add(
      TrackerRoutingCandidate(
        ruleAction: RuleAction.PROCESS_NAME,
        value: processName,
      ),
    );
  }

  final port = int.tryParse(metadata.destinationPort.trim());
  if (port != null && port >= 1 && port <= 65535) {
    candidates.add(
      TrackerRoutingCandidate(ruleAction: RuleAction.DST_PORT, value: '$port'),
    );
  }

  return candidates;
}

TrackerRoutingCandidate? defaultTrackerRoutingCandidate(
  List<TrackerRoutingCandidate> candidates,
) {
  if (candidates.isEmpty) {
    return null;
  }
  for (final action in const [
    RuleAction.DOMAIN_SUFFIX,
    RuleAction.DOMAIN,
    RuleAction.IP_CIDR,
    RuleAction.IP_CIDR6,
    RuleAction.PROCESS_NAME,
  ]) {
    final match = candidates.firstWhereOrNull(
      (candidate) => candidate.ruleAction == action,
    );
    if (match != null) {
      return match;
    }
  }
  return candidates.first;
}

List<CustomRoutingCondition> buildConditionsFromCandidates(
  Iterable<TrackerRoutingCandidate> candidates,
) {
  final conditions = <CustomRoutingCondition>[];
  for (final candidate in candidates) {
    final value = candidate.value.trim();
    if (_isInvalidRoutingValue(value)) {
      continue;
    }
    final noResolve = candidate.effectiveNoResolve;
    final existingIndex = conditions.indexWhere(
      (item) =>
          item.ruleAction == candidate.ruleAction &&
          (item.noResolve && item.ruleAction.hasParams) == noResolve,
    );
    if (existingIndex == -1) {
      conditions.add(
        CustomRoutingCondition(
          ruleAction: candidate.ruleAction,
          values: [value],
          noResolve: noResolve,
        ),
      );
      continue;
    }
    final existing = conditions[existingIndex];
    final lower = value.toLowerCase();
    final duplicate = existing.cleanValues.any(
      (item) => item.toLowerCase() == lower,
    );
    if (!duplicate) {
      conditions[existingIndex] = existing.copyWith(
        values: [...existing.cleanValues, value],
      );
    }
  }
  return conditions;
}

CustomRoutingMergeResult mergeCandidatesIntoRouting(
  CustomRouting routing,
  Iterable<TrackerRoutingCandidate> candidates,
) {
  final conditions = List<CustomRoutingCondition>.from(routing.conditions);
  var addedCount = 0;
  var duplicateCount = 0;

  for (final candidate in candidates) {
    final value = candidate.value.trim();
    if (_isInvalidRoutingValue(value)) {
      continue;
    }
    final noResolve = candidate.effectiveNoResolve;
    final lower = value.toLowerCase();
    final matchingIndex = conditions.indexWhere(
      (item) =>
          item.ruleAction == candidate.ruleAction &&
          (item.noResolve && item.ruleAction.hasParams) == noResolve,
    );
    if (matchingIndex == -1) {
      conditions.add(
        CustomRoutingCondition(
          ruleAction: candidate.ruleAction,
          values: [value],
          noResolve: noResolve,
        ),
      );
      addedCount++;
      continue;
    }
    final existing = conditions[matchingIndex];
    final exists = existing.cleanValues.any(
      (item) => item.toLowerCase() == lower,
    );
    if (exists) {
      duplicateCount++;
      continue;
    }
    conditions[matchingIndex] = existing.copyWith(
      values: [...existing.cleanValues, value],
    );
    addedCount++;
  }

  return (
    routing: addedCount == 0
        ? routing
        : routing.copyWith(conditions: conditions),
    addedCount: addedCount,
    duplicateCount: duplicateCount,
  );
}

bool routingContainsCandidate(
  CustomRouting routing,
  TrackerRoutingCandidate candidate,
) {
  final value = candidate.value.trim().toLowerCase();
  if (value.isEmpty) {
    return false;
  }
  final noResolve = candidate.effectiveNoResolve;
  return routing.conditions.any(
    (condition) =>
        condition.ruleAction == candidate.ruleAction &&
        (condition.noResolve && condition.ruleAction.hasParams) == noResolve &&
        condition.cleanValues.any((item) => item.toLowerCase() == value),
  );
}

List<String> quickRoutingTargetSuggestions(
  TrackerInfo trackerInfo, {
  Iterable<String> groupNames = const [],
}) {
  final availableGroups = groupNames.toSet();
  final suggestions = <String>[
    RuleTarget.DIRECT.value,
    RuleTarget.REJECT.value,
  ];
  for (final hop in trackerInfo.chains.reversed) {
    final name = hop.trim();
    if (name.isEmpty ||
        RuleTarget.ruleTargets.contains(name) ||
        suggestions.contains(name)) {
      continue;
    }
    if (availableGroups.contains(name)) {
      suggestions.add(name);
      break;
    }
  }
  return suggestions;
}

String defaultQuickRoutingTarget(
  TrackerInfo trackerInfo, {
  Iterable<String> groupNames = const [],
}) {
  final suggestions = quickRoutingTargetSuggestions(
    trackerInfo,
    groupNames: groupNames,
  );
  if (suggestions.length > 2) {
    return suggestions[2];
  }
  for (final hop in trackerInfo.chains.reversed) {
    final name = hop.trim();
    if (name == RuleTarget.REJECT.value || name == RuleTarget.DIRECT.value) {
      return name;
    }
  }
  return RuleTarget.DIRECT.value;
}

Future<CustomRouting?> showQuickCustomRoutingSheet(
  BuildContext context,
  TrackerInfo trackerInfo,
) {
  return showNestedSheet<CustomRouting>(
    context,
    builder: (_) => QuickCustomRoutingSheet(trackerInfo: trackerInfo),
  );
}

class QuickCustomRoutingSection extends StatelessWidget {
  final TrackerInfo trackerInfo;
  final bool last;

  const QuickCustomRoutingSection({
    super.key,
    required this.trackerInfo,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final candidates = extractTrackerRoutingCandidates(trackerInfo);
    if (candidates.isEmpty) {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    final primary = defaultTrackerRoutingCandidate(candidates);
    return generateSection(
      title: appLocalizations.customRouting,
      items: [
        ListItem(
          title: Text(appLocalizations.quickRoutingCreate),
          subtitle: primary == null
              ? null
              : Text(
                  primary.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.listCaptionStyle.toJetBrainsMono,
                ),
          trailing: const GlyphIcon(Glyphs.chevronForward),
          onTap: () => showQuickCustomRoutingSheet(context, trackerInfo),
        ),
      ],
      last: last,
    );
  }
}

enum _QuickRoutingMode { create, append }

class QuickCustomRoutingSheet extends ConsumerStatefulWidget {
  final TrackerInfo trackerInfo;

  const QuickCustomRoutingSheet({super.key, required this.trackerInfo});

  @override
  ConsumerState<QuickCustomRoutingSheet> createState() =>
      _QuickCustomRoutingSheetState();
}

class _QuickCustomRoutingSheetState
    extends ConsumerState<QuickCustomRoutingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final List<TrackerRoutingCandidate> _candidates;
  late final Set<int> _selectedIndices;
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  _QuickRoutingMode _mode = _QuickRoutingMode.create;
  bool _nameEdited = false;
  bool _useInCurrentProfile = true;
  bool _saving = false;
  String? _target;
  int? _selectedRoutingId;

  @override
  void initState() {
    super.initState();
    _candidates = extractTrackerRoutingCandidates(widget.trackerInfo);
    final defaultCandidate = defaultTrackerRoutingCandidate(_candidates);
    final defaultIndex = defaultCandidate == null
        ? -1
        : _candidates.indexOf(defaultCandidate);
    _selectedIndices = {if (defaultIndex != -1) defaultIndex};
    final initialValue = defaultCandidate?.value ?? '';
    _nameController = TextEditingController(text: initialValue);
    _valueController = TextEditingController(text: initialValue);
    final groupNames = _readAvailableGroupNames();
    _target = defaultQuickRoutingTarget(
      widget.trackerInfo,
      groupNames: groupNames,
    );
    _useInCurrentProfile = ref.read(currentProfileIdProvider) != null;
    final routings = ref.read(customRoutingsProvider).value ?? const [];
    if (routings.isNotEmpty) {
      _selectedRoutingId = routings.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Set<String> _readAvailableGroupNames() {
    final profileId = ref.read(currentProfileIdProvider);
    final clashConfig = profileId == null
        ? null
        : ref.read(clashConfigProvider(profileId)).value;
    final liveGroups = ref.read(groupsProvider);
    return {
      ...?clashConfig?.proxyGroups.map((item) => item.name),
      ...liveGroups.map((item) => item.name),
    };
  }

  List<TrackerRoutingCandidate> _effectiveSelectedCandidates() {
    final sorted = _selectedIndices.toList()..sort();
    if (sorted.length == 1) {
      return [
        _candidates[sorted.single].withValue(_valueController.text.trim()),
      ];
    }
    return [for (final index in sorted) _candidates[index]];
  }

  void _syncNameIfUntouched() {
    if (_nameEdited) {
      return;
    }
    final selected = _effectiveSelectedCandidates();
    if (selected.isEmpty) {
      return;
    }
    _nameController.text = selected.first.value;
  }

  void _toggleCandidate(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      if (_selectedIndices.length == 1) {
        _valueController.text = _candidates[_selectedIndices.single].value;
      }
      _syncNameIfUntouched();
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

  String? _validateValue(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return context.appLocalizations.routingConditionsEmptyTip;
    }
    if (text.contains(customRoutingValueSeparator)) {
      return context.appLocalizations.routingValueCommaTip;
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    final selected = _effectiveSelectedCandidates();
    if (selected.isEmpty || selected.any((item) => item.value.isEmpty)) {
      dialogs.showBanner(
        appLocalizations.routingConditionsEmptyTip,
        level: BannerLevel.warning,
      );
      return;
    }
    if (selected.any((item) => _isInvalidRoutingValue(item.value))) {
      dialogs.showBanner(
        appLocalizations.routingValueCommaTip,
        level: BannerLevel.warning,
      );
      return;
    }

    final routings = ref.read(customRoutingsProvider).value ?? const [];
    final effectiveMode = routings.isEmpty ? _QuickRoutingMode.create : _mode;
    if (effectiveMode == _QuickRoutingMode.create) {
      await _saveNewRouting(selected);
      return;
    }
    _saveAppendRouting(routings, selected);
  }

  Future<void> _saveNewRouting(List<TrackerRoutingCandidate> selected) async {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    final target = _target?.trim() ?? '';
    if (target.isEmpty) {
      await dialogs.showMessage(
        message: TextSpan(text: appLocalizations.routingTargetEmptyTip),
      );
      return;
    }
    final conditions = buildConditionsFromCandidates(selected);
    if (conditions.isEmpty) {
      dialogs.showBanner(
        appLocalizations.routingConditionsEmptyTip,
        level: BannerLevel.warning,
      );
      return;
    }
    final routing = CustomRouting(
      id: snowflake.id,
      label: _nameController.text.trim(),
      logic: CustomRoutingLogic.or,
      conditions: conditions,
      target: target,
    );
    setState(() => _saving = true);
    try {
      await ref.read(customRoutingsProvider.notifier).append(routing);
      if (!mounted) {
        return;
      }
      _ensureAppliedToCurrentProfile(routing.id);
      dialogs.showBanner(
        appLocalizations.quickRoutingCreated(routing.label),
        level: BannerLevel.success,
      );
      Navigator.of(context).pop(routing);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _saveAppendRouting(
    List<CustomRouting> routings,
    List<TrackerRoutingCandidate> selected,
  ) {
    final appLocalizations = context.appLocalizations;
    final targetRouting =
        routings.firstWhereOrNull((item) => item.id == _selectedRoutingId) ??
        routings.firstOrNull;
    if (targetRouting == null) {
      return;
    }
    final merged = mergeCandidatesIntoRouting(targetRouting, selected);
    if (merged.addedCount == 0) {
      dialogs.showBanner(
        appLocalizations.quickRoutingAlreadyExists,
        level: BannerLevel.warning,
      );
      return;
    }
    final updated = _useInCurrentProfile && !merged.routing.enabled
        ? merged.routing.copyWith(enabled: true)
        : merged.routing;
    ref.read(customRoutingsProvider.notifier).put(updated);
    _ensureAppliedToCurrentProfile(updated.id);
    dialogs.showBanner(
      appLocalizations.quickRoutingAppended(updated.label),
      level: BannerLevel.success,
    );
    Navigator.of(context).pop(updated);
  }

  void _ensureAppliedToCurrentProfile(int routingId) {
    final profileId = ref.read(currentProfileIdProvider);
    if (!_useInCurrentProfile || profileId == null) {
      return;
    }
    final selectedIds =
        ref.read(profileCustomRoutingIdsProvider(profileId)).value ??
        const <int>[];
    if (!selectedIds.contains(routingId)) {
      ref
          .read(profileCustomRoutingIdsProvider(profileId).notifier)
          .toggle(routingId);
    }
  }

  Widget _buildTargetRow(BuildContext context, ClashConfig? clashConfig) {
    final appLocalizations = context.appLocalizations;
    final name = _target?.trim() ?? '';
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
        onPressed: _handlePickTarget,
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

  Widget _buildProfileSwitch(BuildContext context) {
    return ItemPositionProvider(
      position: ItemPosition.startAndEnd,
      child: FormRow(
        title: context.appLocalizations.customRoutingUseInProfile,
        trailing: Switch(
          value: _useInCurrentProfile,
          onChanged: (value) {
            setState(() {
              _useInCurrentProfile = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildExistingRoutingRow(
    BuildContext context,
    CustomRouting routing,
    int index,
    int total, {
    required ClashConfig? clashConfig,
    required bool selected,
  }) {
    final target = routing.target?.trim() ?? '';
    final missing = isRoutingTargetMissing(
      clashConfig,
      target,
      injected: currentTailscaleProxyName(ref),
    );
    final captionStyle = context.listCaptionStyle;
    return ItemPositionProvider(
      position: ItemPosition.get(index, total),
      child: DecorationListItem(
        isSelected: selected,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          routing.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
        trailing: selected ? const SelectionCheck() : null,
        onPressed: () {
          setState(() {
            _selectedRoutingId = routing.id;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final routings = ref.watch(customRoutingsProvider).value ?? const [];
    final profileId = ref.watch(currentProfileIdProvider);
    if (profileId != null) {
      ref.watch(profileCustomRoutingIdsProvider(profileId));
    }
    final clashConfig = profileId == null
        ? null
        : ref.watch(clashConfigProvider(profileId)).value;
    final liveGroups = ref.watch(groupsProvider);
    final groupNames = {
      ...?clashConfig?.proxyGroups.map((item) => item.name),
      ...liveGroups.map((item) => item.name),
    };
    final quickTargets = quickRoutingTargetSuggestions(
      widget.trackerInfo,
      groupNames: groupNames,
    );
    final effectiveMode = routings.isEmpty ? _QuickRoutingMode.create : _mode;
    final effectiveCandidates = _effectiveSelectedCandidates();
    final matchedRoutings = [
      for (final routing in routings)
        if (effectiveCandidates.any(
          (candidate) => routingContainsCandidate(routing, candidate),
        ))
          routing.label,
    ];
    final selectedExisting =
        routings.firstWhereOrNull((item) => item.id == _selectedRoutingId) ??
        routings.firstOrNull;
    final allDuplicateInSelected =
        effectiveMode == _QuickRoutingMode.append &&
        selectedExisting != null &&
        effectiveCandidates.isNotEmpty &&
        effectiveCandidates.every(
          (candidate) => routingContainsCandidate(selectedExisting, candidate),
        );

    return Scaffold(
      title: appLocalizations.quickRoutingCreate,
      actions: [
        IconButton(
          tooltip: appLocalizations.save,
          onPressed: _saving ? null : _handleSave,
          icon: const GlyphIcon(AppGlyphs.check),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Builder(
          builder: (context) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  context.contentTopPadding,
                  16,
                  effectiveMode == _QuickRoutingMode.append
                      ? 8
                      : 16 + context.bottomInset,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListHeader(
                        title: appLocalizations.routingCondition,
                        padding: EdgeInsets.zero,
                        atTop: true,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (index, candidate) in _candidates.indexed)
                            Chip(
                              label: candidate.display,
                              selected: _selectedIndices.contains(index),
                              onPressed: () => _toggleCandidate(index),
                            ),
                        ],
                      ),
                      if (_selectedIndices.length == 1) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _valueController,
                          autocorrect: false,
                          style: AppTextStyle.subheadline
                              .of(context)
                              .toJetBrainsMono,
                          validator: _validateValue,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (_) {
                            setState(_syncNameIfUntouched);
                          },
                          decoration: InputDecoration(
                            border: AppShape.input,
                            helperText: _candidates[_selectedIndices.single]
                                .ruleAction
                                .value,
                          ),
                        ),
                      ],
                      if (matchedRoutings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          appLocalizations.quickRoutingMatchedExisting(
                            matchedRoutings.join(', '),
                          ),
                          style: context.listCaptionStyle,
                        ),
                      ],
                      if (routings.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SegmentedControl<_QuickRoutingMode>(
                          segments: [
                            (
                              _QuickRoutingMode.create,
                              appLocalizations.quickRoutingModeNew,
                            ),
                            (
                              _QuickRoutingMode.append,
                              appLocalizations.quickRoutingModeAppend,
                            ),
                          ],
                          value: effectiveMode,
                          onChanged: (value) {
                            setState(() {
                              _mode = value;
                              _selectedRoutingId ??= routings.firstOrNull?.id;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (effectiveMode == _QuickRoutingMode.create) ...[
                        TextFormField(
                          controller: _nameController,
                          inputFormatters: TextInputLimits.limit(
                            TextInputLimits.name,
                          ),
                          validator: (value) => value?.trim().isNotEmpty == true
                              ? null
                              : appLocalizations.emptyTip(
                                  appLocalizations.name,
                                ),
                          onChanged: (_) {
                            _nameEdited = true;
                          },
                          decoration: InputDecoration(
                            border: AppShape.input,
                            helperText: appLocalizations.name,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTargetRow(context, clashConfig),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in quickTargets)
                              Chip(
                                label: option,
                                selected: _target == option,
                                onPressed: () {
                                  setState(() {
                                    _target = option;
                                  });
                                },
                              ),
                          ],
                        ),
                        if (profileId != null) ...[
                          const SizedBox(height: 16),
                          _buildProfileSwitch(context),
                        ],
                      ] else ...[
                        if (profileId != null) ...[
                          _buildProfileSwitch(context),
                          const SizedBox(height: 16),
                        ],
                        ListHeader(
                          title: appLocalizations.quickRoutingTargetRouting,
                          padding: EdgeInsets.zero,
                          atTop: true,
                        ),
                        if (selectedExisting?.logic ==
                            CustomRoutingLogic.and) ...[
                          const SizedBox(height: 6),
                          Text(
                            appLocalizations.quickRoutingAndLogicNote,
                            style: context.listCaptionStyle,
                          ),
                        ],
                        if (allDuplicateInSelected) ...[
                          const SizedBox(height: 6),
                          Text(
                            appLocalizations.quickRoutingAlreadyExists,
                            style: context.listCaptionStyle.copyWith(
                              color: context.colorScheme.warning,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (effectiveMode == _QuickRoutingMode.append)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16 + context.bottomInset,
                  ),
                  sliver: SliverPrismList(
                    itemCount: routings.length,
                    itemBuilder: (context, index) => _buildExistingRoutingRow(
                      context,
                      routings[index],
                      index,
                      routings.length,
                      clashConfig: clashConfig,
                      selected: routings[index].id == selectedExisting?.id,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
