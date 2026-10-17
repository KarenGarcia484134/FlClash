import 'package:fl_clash/models/clash_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/listener.freezed.dart';
part 'generated/listener.g.dart';

const listenerLoopback = '127.0.0.1';
const listenerAnyAddress = '0.0.0.0';

enum ListenerType {
  mixed,
  socks,
  http,
  redir,
  tproxy;

  /// redir and tproxy need Linux kernel support the app only has on desktop
  /// Linux.
  bool get linuxOnly => this == redir || this == tproxy;

  bool get supportsUdp => this == mixed || this == socks || this == tproxy;

  bool get supportsUsers => this == mixed || this == socks || this == http;
}

@freezed
abstract class ListenerUser with _$ListenerUser {
  const factory ListenerUser({
    @Default('') String username,
    @Default('') String password,
  }) = _ListenerUser;

  factory ListenerUser.fromJson(Map<String, Object?> json) =>
      _$ListenerUserFromJson(json);
}

@freezed
abstract class InboundListenerProps with _$InboundListenerProps {
  const factory InboundListenerProps({
    required String id,
    @Default('') String name,
    @Default(true) bool enabled,
    @Default(ListenerType.mixed) ListenerType type,
    @Default(listenerLoopback) String listen,
    @Default(0) int port,
    @Default(true) bool udp,
    @Default([]) List<ListenerUser> users,
    @Default('') String proxy,
    @Default('') String rule,
  }) = _InboundListenerProps;

  factory InboundListenerProps.fromJson(Map<String, Object?> json) =>
      _$InboundListenerPropsFromJson(json);
}

@freezed
abstract class ListenersProps with _$ListenersProps {
  const factory ListenersProps({
    @Default(true) bool enable,
    @Default([]) List<InboundListenerProps> items,
  }) = _ListenersProps;

  factory ListenersProps.fromJson(Map<String, Object?> json) =>
      _$ListenersPropsFromJson(json);
}

enum ListenerIssue {
  invalidName,
  invalidPort,
  invalidListen,
  invalidUser,
  duplicateName,
  duplicatePort,
  appPort,
  unsupported,
  missingTarget,
  missingRule,
}

bool isValidListenerPort(int port) => port >= 1 && port <= 65535;

bool isValidListenAddress(String value) {
  final parts = value.split('.');
  if (parts.length == 4) {
    return parts.every((part) {
      final n = int.tryParse(part);
      return n != null && n >= 0 && n <= 255 && '$n' == part;
    });
  }
  return value.contains(':') &&
      RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(value) &&
      Uri.tryParse('http://[$value]/') != null;
}

bool isLanListenAddress(String value) =>
    value != listenerLoopback && value != '::1' && value != 'localhost';

/// Problems with one listener that don't depend on the profile.
ListenerIssue? listenerFieldIssue(
  InboundListenerProps item, {
  required bool linux,
}) {
  if (item.name.trim().isEmpty) {
    return ListenerIssue.invalidName;
  }
  if (!isValidListenerPort(item.port)) {
    return ListenerIssue.invalidPort;
  }
  if (!isValidListenAddress(item.listen)) {
    return ListenerIssue.invalidListen;
  }
  if (item.type.supportsUsers &&
      item.users.any((user) => user.username.isEmpty)) {
    return ListenerIssue.invalidUser;
  }
  if (item.type.linuxOnly && !linux) {
    return ListenerIssue.unsupported;
  }
  return null;
}

/// Listeners named or bound like the profile's own, and outbounds the
/// profile knows, read from its raw config.
class ListenerContext {
  const ListenerContext({
    this.appPorts = const {},
    this.outbounds = const {},
    this.subRules = const {},
    this.linux = false,
  });

  factory ListenerContext.fromConfig(
    Map<dynamic, dynamic> config, {
    Set<int> appPorts = const {},
    bool linux = false,
  }) {
    Iterable<String> names(Object? list) => list is List
        ? list.whereType<Map>().map((e) => e['name']).whereType<String>()
        : const [];
    final subRules = config['sub-rules'];
    return ListenerContext(
      appPorts: appPorts,
      outbounds: {
        ...names(config['proxies']),
        ...names(config['proxy-groups']),
      },
      subRules: subRules is Map
          ? subRules.keys.whereType<String>().toSet()
          : {},
      linux: linux,
    );
  }

  final Set<int> appPorts;
  final Set<String> outbounds;
  final Set<String> subRules;
  final bool linux;
}

const _builtinOutbounds = {'DIRECT', 'REJECT', 'REJECT-DROP', 'PASS'};

/// Why each enabled listener is left out of the config, in list order; a
/// listener is checked against those before it.
Map<String, ListenerIssue> listenerIssues(
  List<InboundListenerProps> items,
  ListenerContext context,
) {
  final issues = <String, ListenerIssue>{};
  final names = <String>{};
  final ports = <int>{};
  for (final item in items.where((item) => item.enabled)) {
    final issue = _issueOf(item, context, names, ports);
    if (issue != null) {
      issues[item.id] = issue;
      continue;
    }
    names.add(item.name.trim());
    ports.add(item.port);
  }
  return issues;
}

ListenerIssue? _issueOf(
  InboundListenerProps item,
  ListenerContext context,
  Set<String> names,
  Set<int> ports,
) {
  final field = listenerFieldIssue(item, linux: context.linux);
  if (field != null) {
    return field;
  }
  if (names.contains(item.name.trim())) {
    return ListenerIssue.duplicateName;
  }
  if (ports.contains(item.port)) {
    return ListenerIssue.duplicatePort;
  }
  if (context.appPorts.contains(item.port)) {
    return ListenerIssue.appPort;
  }
  if (item.proxy.isNotEmpty &&
      !_builtinOutbounds.contains(item.proxy) &&
      !context.outbounds.contains(item.proxy)) {
    return ListenerIssue.missingTarget;
  }
  if (item.proxy.isEmpty &&
      item.rule.isNotEmpty &&
      !context.subRules.contains(item.rule)) {
    return ListenerIssue.missingRule;
  }
  return null;
}

Map<String, dynamic> listenerDefinition(InboundListenerProps item) => {
  'name': item.name.trim(),
  'type': item.type.name,
  'listen': item.listen,
  'port': item.port,
  if (item.type.supportsUdp) 'udp': item.udp,
  if (item.type.supportsUsers && item.users.isNotEmpty)
    'users': [
      for (final user in item.users)
        {'username': user.username, 'password': user.password},
    ],
  if (item.proxy.isNotEmpty)
    'proxy': item.proxy
  else if (item.rule.isNotEmpty)
    'rule': item.rule,
};

/// Adds the user's listeners to `listeners` of [rawConfig]. A profile
/// listener with the same name or port gives way to the user's. Returns the
/// listeners left out and why.
Map<String, ListenerIssue> injectListeners(
  Map<dynamic, dynamic> rawConfig,
  ListenersProps props, {
  Set<int> appPorts = const {},
  bool linux = false,
}) {
  if (!props.enable || props.items.isEmpty) {
    return const {};
  }
  final context = ListenerContext.fromConfig(
    rawConfig,
    appPorts: appPorts,
    linux: linux,
  );
  final issues = listenerIssues(props.items, context);
  final added = [
    for (final item in props.items)
      if (item.enabled && !issues.containsKey(item.id))
        listenerDefinition(item),
  ];
  if (added.isEmpty) {
    return issues;
  }
  final names = {for (final item in added) item['name']};
  final ports = {for (final item in added) '${item['port']}'};
  final existing = rawConfig['listeners'];
  rawConfig['listeners'] = [
    if (existing is List)
      for (final item in existing)
        if (item is! Map ||
            (!names.contains(item['name']) &&
                !ports.contains('${item['port']}')))
          item,
    ...added,
  ];
  return issues;
}

/// Where a client points at the listener, such as socks5://127.0.0.1:7891.
List<String> listenerAddresses(InboundListenerProps item) {
  final host = item.listen == listenerAnyAddress
      ? listenerLoopback
      : item.listen.contains(':')
      ? '[${item.listen}]'
      : item.listen;
  final address = '$host:${item.port}';
  return switch (item.type) {
    ListenerType.mixed => ['http://$address', 'socks5://$address'],
    ListenerType.socks => ['socks5://$address'],
    ListenerType.http => ['http://$address'],
    ListenerType.redir || ListenerType.tproxy => [address],
  };
}

/// The ports the app itself listens on, which a listener can't take.
Set<int> appInboundPorts(PatchClashConfig config) => {
  for (final port in [
    config.mixedPort,
    config.port,
    config.socksPort,
    config.redirPort,
    config.tproxyPort,
  ])
    if (port > 0) port,
};
