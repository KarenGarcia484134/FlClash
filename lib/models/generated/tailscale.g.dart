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
      dialerProxy: json['dialerProxy'] as String? ?? '',
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
      'dialerProxy': instance.dialerProxy,
    };

_TailscalePeer _$TailscalePeerFromJson(Map<String, dynamic> json) =>
    _TailscalePeer(
      id: json['id'] as String? ?? '',
      hostName: json['hostName'] as String? ?? '',
      dnsName: json['dnsName'] as String? ?? '',
      os: json['os'] as String? ?? '',
      ips:
          (json['ips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      online: json['online'] as bool? ?? false,
      exitNode: json['exitNode'] as bool? ?? false,
      exitNodeOption: json['exitNodeOption'] as bool? ?? false,
      lastSeen: json['lastSeen'] as String?,
    );

Map<String, dynamic> _$TailscalePeerToJson(_TailscalePeer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hostName': instance.hostName,
      'dnsName': instance.dnsName,
      'os': instance.os,
      'ips': instance.ips,
      'online': instance.online,
      'exitNode': instance.exitNode,
      'exitNodeOption': instance.exitNodeOption,
      'lastSeen': instance.lastSeen,
    };

_TailscaleNetStatus _$TailscaleNetStatusFromJson(Map<String, dynamic> json) =>
    _TailscaleNetStatus(
      started: json['started'] as bool? ?? false,
      backendState: json['backendState'] as String? ?? '',
      authUrl: json['authUrl'] as String?,
      health:
          (json['health'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      magicDnsSuffix: json['magicDnsSuffix'] as String? ?? '',
      self: json['self'] == null
          ? null
          : TailscalePeer.fromJson(json['self'] as Map<String, dynamic>),
      peers:
          (json['peers'] as List<dynamic>?)
              ?.map((e) => TailscalePeer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      error: json['error'] as String?,
      dialerProxy: json['dialerProxy'] as String?,
      derpRoutes:
          (json['derpRoutes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      exitNodeError: json['exitNodeError'] as String?,
    );

Map<String, dynamic> _$TailscaleNetStatusToJson(_TailscaleNetStatus instance) =>
    <String, dynamic>{
      'started': instance.started,
      'backendState': instance.backendState,
      'authUrl': instance.authUrl,
      'health': instance.health,
      'magicDnsSuffix': instance.magicDnsSuffix,
      'self': instance.self,
      'peers': instance.peers,
      'error': instance.error,
      'dialerProxy': instance.dialerProxy,
      'derpRoutes': instance.derpRoutes,
      'exitNodeError': instance.exitNodeError,
    };

_TailscalePingResult _$TailscalePingResultFromJson(Map<String, dynamic> json) =>
    _TailscalePingResult(
      target: json['target'] as String? ?? '',
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? -1,
      endpoint: json['endpoint'] as String?,
      derpRegionId: (json['derpRegionId'] as num?)?.toInt(),
      derpRegionCode: json['derpRegionCode'] as String?,
      peerRelay: json['peerRelay'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$TailscalePingResultToJson(
  _TailscalePingResult instance,
) => <String, dynamic>{
  'target': instance.target,
  'latencyMs': instance.latencyMs,
  'endpoint': instance.endpoint,
  'derpRegionId': instance.derpRegionId,
  'derpRegionCode': instance.derpRegionCode,
  'peerRelay': instance.peerRelay,
  'error': instance.error,
};
