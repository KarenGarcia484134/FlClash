// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../listener.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListenerUser _$ListenerUserFromJson(Map<String, dynamic> json) =>
    _ListenerUser(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );

Map<String, dynamic> _$ListenerUserToJson(_ListenerUser instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

_InboundListenerProps _$InboundListenerPropsFromJson(
  Map<String, dynamic> json,
) => _InboundListenerProps(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  enabled: json['enabled'] as bool? ?? true,
  type:
      $enumDecodeNullable(_$ListenerTypeEnumMap, json['type']) ??
      ListenerType.mixed,
  listen: json['listen'] as String? ?? listenerLoopback,
  port: (json['port'] as num?)?.toInt() ?? 0,
  udp: json['udp'] as bool? ?? true,
  users:
      (json['users'] as List<dynamic>?)
          ?.map((e) => ListenerUser.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  proxy: json['proxy'] as String? ?? '',
  rule: json['rule'] as String? ?? '',
);

Map<String, dynamic> _$InboundListenerPropsToJson(
  _InboundListenerProps instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'enabled': instance.enabled,
  'type': _$ListenerTypeEnumMap[instance.type]!,
  'listen': instance.listen,
  'port': instance.port,
  'udp': instance.udp,
  'users': instance.users,
  'proxy': instance.proxy,
  'rule': instance.rule,
};

const _$ListenerTypeEnumMap = {
  ListenerType.mixed: 'mixed',
  ListenerType.socks: 'socks',
  ListenerType.http: 'http',
  ListenerType.redir: 'redir',
  ListenerType.tproxy: 'tproxy',
};

_ListenersProps _$ListenersPropsFromJson(Map<String, dynamic> json) =>
    _ListenersProps(
      enable: json['enable'] as bool? ?? true,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => InboundListenerProps.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ListenersPropsToJson(_ListenersProps instance) =>
    <String, dynamic>{'enable': instance.enable, 'items': instance.items};
