// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../tailscale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TailscaleProps _$TailscalePropsFromJson(Map<String, dynamic> json) =>
    _TailscaleProps(
      enable: json['enable'] as bool? ?? false,
      hostname: json['hostname'] as String? ?? '',
      authKey: json['authKey'] as String? ?? '',
      controlUrl: json['controlUrl'] as String? ?? '',
      acceptRoutes: json['acceptRoutes'] as bool? ?? true,
      exitNode: json['exitNode'] as String? ?? '',
      ephemeral: json['ephemeral'] as bool? ?? false,
      udp: json['udp'] as bool? ?? true,
      dnsSuffixes:
          (json['dnsSuffixes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TailscalePropsToJson(_TailscaleProps instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'hostname': instance.hostname,
      'authKey': instance.authKey,
      'controlUrl': instance.controlUrl,
      'acceptRoutes': instance.acceptRoutes,
      'exitNode': instance.exitNode,
      'ephemeral': instance.ephemeral,
      'udp': instance.udp,
      'dnsSuffixes': instance.dnsSuffixes,
    };
