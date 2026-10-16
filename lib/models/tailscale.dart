import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/custom_routing.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/tailscale.freezed.dart';
part 'generated/tailscale.g.dart';

/// Relative to the Core home directory, which the app keeps across restarts,
/// so a login made once is reused instead of asking again.
const tailscaleStateDir = 'tailscale/flclash';

const tailscaleBaseProxyName = 'Tailscale';

const tailscaleIpv4Range = '100.64.0.0/10';

const tailscaleIpv6Range = 'fd7a:115c:a1e9::/48';

const tailscaleMagicDnsSuffix = 'ts.net';

@freezed
abstract class TailscaleProps with _$TailscaleProps {
  const factory TailscaleProps({
    @Default(false) bool enable,
    @Default('') String hostname,
    @Default('') String authKey,
    @Default('') String controlUrl,
    @Default(true) bool acceptRoutes,
    @Default('') String exitNode,
    @Default(false) bool ephemeral,
    @Default(true) bool udp,
    @Default([]) List<String> dnsSuffixes,
    @Default('') String dialerProxy,
  }) = _TailscaleProps;

  factory TailscaleProps.fromJson(Map<String, Object?> json) =>
      _$TailscalePropsFromJson(json);
}

enum TailscalePhase { idle, needsLogin, running }

@freezed
abstract class TailscaleStatus with _$TailscaleStatus {
  const factory TailscaleStatus({
    @Default(TailscalePhase.idle) TailscalePhase phase,
    String? loginUrl,
    String? proxyName,
    @Default([]) List<String> health,
  }) = _TailscaleStatus;
}

final _logPattern = RegExp(r'^\[Tailscale\]\(([^)]*)\) (.*)$', dotAll: true);
final _loginUrlPattern = RegExp(r'go to: (\S+)');
final _authLoopPattern = RegExp(r'AuthLoop: state is (\w+)');

/// Reads the two lines tsnet prints while it logs in: the interactive login
/// URL, and the state it settles in once the login loop ends.
TailscaleStatus? parseTailscaleLog(String payload, TailscaleStatus current) {
  final match = _logPattern.firstMatch(payload.trim());
  if (match == null) {
    return null;
  }
  final name = match.group(1);
  final message = match.group(2)!;
  if (_loginUrlPattern.firstMatch(message) case final url?) {
    return TailscaleStatus(
      phase: TailscalePhase.needsLogin,
      loginUrl: url.group(1),
      proxyName: name,
    );
  }
  if (_authLoopPattern.firstMatch(message) case final state?) {
    return current.copyWith(
      phase: state.group(1) == 'Running'
          ? TailscalePhase.running
          : TailscalePhase.needsLogin,
      loginUrl: state.group(1) == 'Running' ? null : current.loginUrl,
      proxyName: name,
    );
  }
  return null;
}

extension TailscalePropsExt on TailscaleProps {
  List<String> get realDnsSuffixes => {
    tailscaleMagicDnsSuffix,
    for (final suffix in dnsSuffixes)
      if (_cleanSuffix(suffix) case final text when text.isNotEmpty) text,
  }.toList();

  Map<String, Object> proxyDefinition(String name, {String? dialerProxy}) => {
    'name': name,
    'type': 'tailscale',
    if (hostname.trim().isNotEmpty) 'hostname': hostname.trim(),
    if (authKey.trim().isNotEmpty) 'auth-key': authKey.trim(),
    if (controlUrl.trim().isNotEmpty) 'control-url': controlUrl.trim(),
    'state-dir': tailscaleStateDir,
    'ephemeral': ephemeral,
    'udp': udp,
    'accept-routes': acceptRoutes,
    if (exitNode.trim().isNotEmpty) 'exit-node': exitNode.trim(),
    'dialer-proxy': ?dialerProxy,
  };
}

String _cleanSuffix(String value) {
  var text = value.trim().toLowerCase();
  while (text.startsWith('.') || text.startsWith('+')) {
    text = text.substring(1);
  }
  return text;
}

Set<String> _namesIn(Object? section) => {
  if (section is List)
    for (final item in section)
      if (item is Map && item['name'] is String) item['name'] as String,
};

/// A profile may bring a proxy or group of the same name, possibly its own
/// Tailscale node, so the injected one takes the first free name instead.
String tailscaleProxyName(Set<String> taken) {
  if (!taken.contains(tailscaleBaseProxyName) &&
      !RuleTarget.ruleTargets.contains(tailscaleBaseProxyName)) {
    return tailscaleBaseProxyName;
  }
  for (var index = 1; ; index++) {
    final name = '$tailscaleBaseProxyName-FlClash${index == 1 ? '' : index}';
    if (!taken.contains(name)) {
      return name;
    }
  }
}

String tailscaleProxyNameFor(Map<dynamic, dynamic> rawConfig) =>
    tailscaleProxyName({
      ..._namesIn(rawConfig['proxies']),
      ..._namesIn(rawConfig['proxy-groups']),
    });

/// Adds the node to [rawConfig] and routes MagicDNS names through its DNS;
/// returns the rules that send tailnet traffic to it.
List<String> injectTailscale(
  Map<dynamic, dynamic> rawConfig,
  TailscaleProps props,
) {
  if (!props.enable) {
    return const [];
  }
  final name = tailscaleProxyNameFor(rawConfig);
  final proxies = rawConfig['proxies'];
  final via = props.dialerProxy.trim();
  final known = {
    ..._namesIn(rawConfig['proxies']),
    ..._namesIn(rawConfig['proxy-groups']),
  };
  rawConfig['proxies'] = [
    if (proxies is List) ...proxies,
    props.proxyDefinition(
      name,
      // A profile without that node would make every control dial fail, so
      // fall back to dialing directly.
      dialerProxy: via.isNotEmpty && via != name && known.contains(via)
          ? via
          : null,
    ),
  ];
  final suffixes = props.realDnsSuffixes;
  final dns = rawConfig['dns'];
  if (dns is Map) {
    final policy = dns['nameserver-policy'];
    dns['nameserver-policy'] = {
      if (policy is Map) ...policy,
      for (final suffix in suffixes) '+.$suffix': 'tailscale://$name',
    };
  }
  return [
    'IP-CIDR,$tailscaleIpv4Range,$name,no-resolve',
    'IP-CIDR6,$tailscaleIpv6Range,$name,no-resolve',
    for (final suffix in suffixes) 'DOMAIN-SUFFIX,$suffix,$name',
  ];
}

@freezed
abstract class TailscalePeer with _$TailscalePeer {
  const factory TailscalePeer({
    @Default('') String id,
    @Default('') String hostName,
    @Default('') String dnsName,
    @Default('') String os,
    @Default([]) List<String> ips,
    @Default(false) bool online,
    @Default(false) bool exitNode,
    @Default(false) bool exitNodeOption,
    String? lastSeen,
  }) = _TailscalePeer;

  factory TailscalePeer.fromJson(Map<String, Object?> json) =>
      _$TailscalePeerFromJson(json);
}

@freezed
abstract class TailscaleNetStatus with _$TailscaleNetStatus {
  const factory TailscaleNetStatus({
    @Default(false) bool started,
    @Default('') String backendState,
    String? authUrl,
    @Default([]) List<String> health,
    @Default('') String magicDnsSuffix,
    TailscalePeer? self,
    @Default([]) List<TailscalePeer> peers,
    String? error,
  }) = _TailscaleNetStatus;

  factory TailscaleNetStatus.fromJson(Map<String, Object?> json) =>
      _$TailscaleNetStatusFromJson(json);
}

extension TailscalePeerExt on TailscalePeer {
  String get shortDnsName {
    final name = dnsName.endsWith('.')
        ? dnsName.substring(0, dnsName.length - 1)
        : dnsName;
    return name;
  }

  String get displayName =>
      hostName.isNotEmpty ? hostName : shortDnsName.split('.').first;

  String? get ipv4 => ips.where((ip) => !ip.contains(':')).firstOrNull;

  String? get ipv6 => ips.where((ip) => ip.contains(':')).firstOrNull;

  bool matches(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) {
      return true;
    }
    return [
      hostName,
      dnsName,
      os,
      ...ips,
    ].any((value) => value.toLowerCase().contains(text));
  }
}

/// The conditions matching one peer, OR-ed in one routing: its MagicDNS
/// name and each of its addresses as a single-host CIDR.
List<CustomRoutingCondition> tailscalePeerConditions(TailscalePeer peer) {
  final v4 = [
    for (final ip in peer.ips)
      if (!ip.contains(':')) '$ip/32',
  ];
  final v6 = [
    for (final ip in peer.ips)
      if (ip.contains(':')) '$ip/128',
  ];
  return [
    if (peer.shortDnsName.isNotEmpty)
      CustomRoutingCondition(
        ruleAction: RuleAction.DOMAIN,
        values: [peer.shortDnsName],
      ),
    if (v4.isNotEmpty)
      CustomRoutingCondition(
        ruleAction: RuleAction.IP_CIDR,
        values: v4,
        noResolve: true,
      ),
    if (v6.isNotEmpty)
      CustomRoutingCondition(
        ruleAction: RuleAction.IP_CIDR6,
        values: v6,
        noResolve: true,
      ),
  ];
}

/// Folds a status read from the node into the phase the page shows, so it
/// follows the node itself rather than only the log lines.
TailscaleStatus applyTailscaleNetStatus(
  TailscaleStatus current,
  TailscaleNetStatus net,
  String proxyName,
) {
  if (!net.started) {
    return current;
  }
  return switch (net.backendState) {
    'Running' => TailscaleStatus(
      phase: TailscalePhase.running,
      proxyName: proxyName,
      health: net.health,
    ),
    'NeedsLogin' || 'NeedsMachineAuth' => TailscaleStatus(
      phase: TailscalePhase.needsLogin,
      loginUrl: net.authUrl?.isNotEmpty == true
          ? net.authUrl
          : current.loginUrl,
      proxyName: proxyName,
      health: net.health,
    ),
    _ => current.copyWith(proxyName: proxyName, health: net.health),
  };
}

enum TailscaleIssue { none, authKey, network }

final _authIssuePattern = RegExp(
  r'invalid key|auth ?key|expired|revoked|not valid|unauthori[sz]ed|'
  r'forbidden|not authorized|key has been|reusable|ephemeral key',
  caseSensitive: false,
);

final _networkIssuePattern = RegExp(
  r'deadline exceeded|timeout|timed out|connection|dial|no route|refused|'
  r'reset by peer|EOF|tls|handshake|network is unreachable|no such host|'
  r'i/o',
  caseSensitive: false,
);

/// Tells a rejected key apart from a control server that cannot be reached,
/// so the page only blames the key when the server actually refused it.
TailscaleIssue classifyTailscaleHealth(List<String> messages) {
  final text = messages.join('\n');
  if (text.isEmpty) {
    return TailscaleIssue.none;
  }
  if (_networkIssuePattern.hasMatch(text)) {
    return TailscaleIssue.network;
  }
  if (_authIssuePattern.hasMatch(text)) {
    return TailscaleIssue.authKey;
  }
  return TailscaleIssue.none;
}
