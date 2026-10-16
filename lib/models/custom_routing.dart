import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/custom_routing.freezed.dart';
part 'generated/custom_routing.g.dart';

enum CustomRoutingLogic { or, and }

@freezed
abstract class CustomRoutingCondition with _$CustomRoutingCondition {
  const factory CustomRoutingCondition({
    @Default(RuleAction.DOMAIN_SUFFIX) RuleAction ruleAction,
    @Default([]) List<String> values,
    @Default(false) bool noResolve,
  }) = _CustomRoutingCondition;

  factory CustomRoutingCondition.fromJson(Map<String, Object?> json) =>
      _$CustomRoutingConditionFromJson(json);
}

@freezed
abstract class CustomRouting with _$CustomRouting {
  const factory CustomRouting({
    required int id,
    @Default('') String label,
    @Default(true) bool enabled,
    @Default(CustomRoutingLogic.or) CustomRoutingLogic logic,
    @Default([]) List<CustomRoutingCondition> conditions,
    String? target,
    String? order,
  }) = _CustomRouting;

  factory CustomRouting.fromJson(Map<String, Object?> json) =>
      _$CustomRoutingFromJson(json);

  factory CustomRouting.create() => CustomRouting(id: snowflake.id);
}

/// Logical rules split their operands on commas, so a value carrying one
/// cannot be expressed at all.
const customRoutingValueSeparator = ',';

extension CustomRoutingConditionExt on CustomRoutingCondition {
  static final List<RuleAction> actions = List.unmodifiable(
    RuleAction.values.where(
      (item) => !item.nestsRules && item != RuleAction.MATCH,
    ),
  );

  List<String> get cleanValues => [
    for (final value in values)
      if (value.trim() case final text when text.isNotEmpty) text,
  ];

  List<String> atoms({Set<String>? ruleProviders}) => [
    for (final value in cleanValues)
      if (ruleAction != RuleAction.RULE_SET ||
          ruleProviders == null ||
          ruleProviders.contains(value))
        [
          ruleAction.value,
          value,
          if (noResolve && ruleAction.hasParams) 'no-resolve',
        ].join(','),
  ];
}

extension CustomRoutingExt on CustomRouting {
  bool get hasTarget => target?.trim().isNotEmpty == true;

  bool get hasInvalidValue => conditions.any(
    (condition) => condition.cleanValues.any(
      (value) => value.contains(customRoutingValueSeparator),
    ),
  );

  /// Returns null when nothing usable is left, so the caller drops the entry
  /// instead of handing the core a rule it would reject with the whole
  /// config. [ruleProviders], when given, drops RULE-SET operands naming a
  /// provider the profile does not define.
  String? toRule({Set<String>? ruleProviders}) {
    final target = this.target?.trim();
    if (target == null || target.isEmpty || hasInvalidValue) {
      return null;
    }
    final groups = [
      for (final condition in conditions)
        if (condition.atoms(ruleProviders: ruleProviders) case final atoms
            when atoms.isNotEmpty)
          atoms,
    ];
    if (groups.isEmpty) {
      return null;
    }
    final flat = groups.expand((item) => item).toList();
    if (flat.length == 1) {
      final atom = flat.single.split(',');
      return [...atom.take(2), target, ...atom.skip(2)].join(',');
    }
    if (logic == CustomRoutingLogic.or || groups.length == 1) {
      return 'OR,(${flat.map((item) => '($item)').join(',')}),$target';
    }
    final operands = [
      for (final atoms in groups)
        atoms.length == 1
            ? '(${atoms.single})'
            : '(OR,(${atoms.map((item) => '($item)').join(',')}))',
    ];
    return 'AND,(${operands.join(',')}),$target';
  }
}

/// Entries come in user order and land ahead of every profile rule; one whose
/// target the profile cannot resolve is skipped rather than failing the load.
List<String> buildCustomRoutingRules(
  Iterable<CustomRouting> routings, {
  Set<String>? targets,
  Set<String>? ruleProviders,
}) {
  return [
    for (final routing in routings)
      if (routing.enabled &&
          (targets == null || targets.contains(routing.target?.trim())))
        ?routing.toRule(ruleProviders: ruleProviders),
  ];
}

Set<String> _namesOf(Object? section) => {
  if (section is List)
    for (final item in section)
      if (item is Map && item['name'] is String) item['name'] as String,
};

/// Resolves targets and rule sets against the config the core will load, after
/// scripts and overrides have run.
List<String> buildCustomRoutingRulesForConfig(
  Map<dynamic, dynamic> rawConfig,
  Iterable<CustomRouting> routings,
) {
  final providers = rawConfig['rule-providers'];
  return buildCustomRoutingRules(
    routings,
    targets: {
      ...RuleTarget.ruleTargets,
      ..._namesOf(rawConfig['proxies']),
      ..._namesOf(rawConfig['proxy-groups']),
    },
    ruleProviders: {
      if (providers is Map)
        for (final key in providers.keys)
          if (key is String) key,
    },
  );
}
