import 'package:fl_clash/enum/enum.dart';
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

  Map<String, Object> proxyDefinition(String name) => {
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
  rawConfig['proxies'] = [
    if (proxies is List) ...proxies,
    props.proxyDefinition(name),
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
