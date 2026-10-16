// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../custom_routing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomRoutingCondition _$CustomRoutingConditionFromJson(
  Map<String, dynamic> json,
) => _CustomRoutingCondition(
  ruleAction:
      $enumDecodeNullable(_$RuleActionEnumMap, json['ruleAction']) ??
      RuleAction.DOMAIN_SUFFIX,
  values:
      (json['values'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  noResolve: json['noResolve'] as bool? ?? false,
);

Map<String, dynamic> _$CustomRoutingConditionToJson(
  _CustomRoutingCondition instance,
) => <String, dynamic>{
  'ruleAction': _$RuleActionEnumMap[instance.ruleAction]!,
  'values': instance.values,
  'noResolve': instance.noResolve,
};

const _$RuleActionEnumMap = {
  RuleAction.DOMAIN: 'DOMAIN',
  RuleAction.DOMAIN_SUFFIX: 'DOMAIN_SUFFIX',
  RuleAction.DOMAIN_KEYWORD: 'DOMAIN_KEYWORD',
  RuleAction.DOMAIN_REGEX: 'DOMAIN_REGEX',
  RuleAction.DOMAIN_WILDCARD: 'DOMAIN_WILDCARD',
  RuleAction.GEOSITE: 'GEOSITE',
  RuleAction.IP_CIDR: 'IP_CIDR',
  RuleAction.IP_CIDR6: 'IP_CIDR6',
  RuleAction.IP_SUFFIX: 'IP_SUFFIX',
  RuleAction.IP_ASN: 'IP_ASN',
  RuleAction.GEOIP: 'GEOIP',
  RuleAction.SRC_GEOIP: 'SRC_GEOIP',
  RuleAction.SRC_IP_ASN: 'SRC_IP_ASN',
  RuleAction.SRC_IP_CIDR: 'SRC_IP_CIDR',
  RuleAction.SRC_IP_SUFFIX: 'SRC_IP_SUFFIX',
  RuleAction.DST_PORT: 'DST_PORT',
  RuleAction.SRC_PORT: 'SRC_PORT',
  RuleAction.IN_PORT: 'IN_PORT',
  RuleAction.IN_TYPE: 'IN_TYPE',
  RuleAction.IN_USER: 'IN_USER',
  RuleAction.IN_NAME: 'IN_NAME',
  RuleAction.REMATCH_NAME: 'REMATCH_NAME',
  RuleAction.PROCESS_PATH: 'PROCESS_PATH',
  RuleAction.PROCESS_PATH_REGEX: 'PROCESS_PATH_REGEX',
  RuleAction.PROCESS_PATH_WILDCARD: 'PROCESS_PATH_WILDCARD',
  RuleAction.PROCESS_NAME: 'PROCESS_NAME',
  RuleAction.PROCESS_NAME_REGEX: 'PROCESS_NAME_REGEX',
  RuleAction.PROCESS_NAME_WILDCARD: 'PROCESS_NAME_WILDCARD',
  RuleAction.UID: 'UID',
  RuleAction.NETWORK: 'NETWORK',
  RuleAction.DSCP: 'DSCP',
  RuleAction.RULE_SET: 'RULE_SET',
  RuleAction.AND: 'AND',
  RuleAction.OR: 'OR',
  RuleAction.NOT: 'NOT',
  RuleAction.SUB_RULE: 'SUB_RULE',
  RuleAction.MATCH: 'MATCH',
};

_CustomRouting _$CustomRoutingFromJson(Map<String, dynamic> json) =>
    _CustomRouting(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      logic:
          $enumDecodeNullable(_$CustomRoutingLogicEnumMap, json['logic']) ??
          CustomRoutingLogic.or,
      conditions:
          (json['conditions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CustomRoutingCondition.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      target: json['target'] as String?,
      order: json['order'] as String?,
    );

Map<String, dynamic> _$CustomRoutingToJson(_CustomRouting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'enabled': instance.enabled,
      'logic': _$CustomRoutingLogicEnumMap[instance.logic]!,
      'conditions': instance.conditions,
      'target': instance.target,
      'order': instance.order,
    };

const _$CustomRoutingLogicEnumMap = {
  CustomRoutingLogic.or: 'or',
  CustomRoutingLogic.and: 'and',
};
