import 'package:fl_clash/enum/enum.dart';

/// Stored to drop the profile's own dialer-proxy from a node.
const dialerProxyDirect = 'DIRECT';

enum DialerProxyIssue { missingNode, missingTarget, cycle }

/// What the profile's config says about chaining: its own nodes, the
/// members of each group, and the dialer-proxy a node already carries.
class DialerGraph {
  const DialerGraph({
    this.proxies = const {},
    this.groups = const {},
    this.existing = const {},
  });

  final Set<String> proxies;
  final Map<String, List<String>> groups;
  final Map<String, String> existing;

  factory DialerGraph.fromConfig(Map<dynamic, dynamic> config) {
    final proxies = <String>{};
    final existing = <String, String>{};
    final rawProxies = config['proxies'];
    if (rawProxies is List) {
      for (final item in rawProxies) {
        if (item is Map && item['name'] is String) {
          final name = item['name'] as String;
          proxies.add(name);
          if (item['dialer-proxy'] case final String via when via.isNotEmpty) {
            existing[name] = via;
          }
        }
      }
    }
    final groups = <String, List<String>>{};
    final rawGroups = config['proxy-groups'];
    if (rawGroups is List) {
      for (final item in rawGroups) {
        if (item is Map && item['name'] is String) {
          groups[item['name'] as String] = [
            if (item['proxies'] case final List members)
              ...members.whereType<String>(),
          ];
        }
      }
    }
    return DialerGraph(proxies: proxies, groups: groups, existing: existing);
  }

  DialerGraph withProxy(String? name) => name == null || proxies.contains(name)
      ? this
      : DialerGraph(
          proxies: {...proxies, name},
          groups: groups,
          existing: existing,
        );

  bool hasTarget(String name) =>
      proxies.contains(name) || groups.containsKey(name);
}

/// Whether routing [node] through [target] would make a node dial through
/// itself, directly, through another node's dialer-proxy, or through a group
/// that can pick it. [dialers] is the dialer-proxy every node ends up with.
bool dialerProxyCreatesCycle(
  DialerGraph graph,
  Map<String, String> dialers,
  String node,
  String target,
) {
  final visited = <String>{};
  final pending = [target];
  while (pending.isNotEmpty) {
    final name = pending.removeLast();
    if (name == node) {
      return true;
    }
    if (!visited.add(name)) {
      continue;
    }
    if (graph.groups[name] case final members?) {
      pending.addAll(members);
    }
    if (dialers[name] case final via?) {
      pending.add(via);
    }
  }
  return false;
}

/// The dialer-proxy each node ends up with: the profile's own, replaced by
/// the user's setting wherever the user set one.
Map<String, String> effectiveDialers(
  DialerGraph graph,
  Map<String, String> settings,
) => {...graph.existing, ...settings};

DialerProxyIssue? dialerProxyIssue(
  DialerGraph graph,
  Map<String, String> settings,
  String node,
) {
  final target = settings[node];
  if (target == null) {
    return null;
  }
  if (!graph.proxies.contains(node)) {
    return DialerProxyIssue.missingNode;
  }
  if (target == dialerProxyDirect) {
    return null;
  }
  if (!graph.hasTarget(target)) {
    return DialerProxyIssue.missingTarget;
  }
  final others = effectiveDialers(graph, settings)
    ..remove(node)
    ..removeWhere((_, via) => via == dialerProxyDirect);
  if (dialerProxyCreatesCycle(graph, others, node, target)) {
    return DialerProxyIssue.cycle;
  }
  return null;
}

/// Writes the user's dialer-proxy settings into the nodes of [rawConfig],
/// skipping any whose node or target is gone or that would loop. Returns the
/// skipped nodes.
Map<String, DialerProxyIssue> injectDialerProxies(
  Map<dynamic, dynamic> rawConfig,
  Map<String, String> settings,
) {
  if (settings.isEmpty) {
    return const {};
  }
  final graph = DialerGraph.fromConfig(rawConfig);
  final skipped = <String, DialerProxyIssue>{};
  final applied = <String, String>{};
  for (final MapEntry(key: node, value: target) in settings.entries) {
    final issue = dialerProxyIssue(graph, {...applied, node: target}, node);
    if (issue != null) {
      skipped[node] = issue;
      continue;
    }
    applied[node] = target;
  }
  final proxies = rawConfig['proxies'];
  if (proxies is List) {
    rawConfig['proxies'] = [
      for (final item in proxies)
        switch (item is Map ? applied[item['name']] : null) {
          dialerProxyDirect => {...item as Map}..remove('dialer-proxy'),
          final String via => {...item as Map, 'dialer-proxy': via},
          _ => item,
        },
    ];
  }
  return skipped;
}

/// Outbounds that can carry a node: not built-in policies, not itself.
bool isDialerTargetCandidate(String name, String node) =>
    name != node && !RuleTarget.ruleTargets.contains(name);
