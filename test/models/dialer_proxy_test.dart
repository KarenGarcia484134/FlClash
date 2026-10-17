import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _config() => {
  'proxies': [
    {'name': 'A', 'type': 'ss'},
    {'name': 'B', 'type': 'ss'},
    {'name': 'C', 'type': 'ss', 'dialer-proxy': 'B'},
  ],
  'proxy-groups': [
    {
      'name': 'HK',
      'type': 'select',
      'proxies': ['A', 'B'],
    },
    {
      'name': 'Other',
      'type': 'select',
      'proxies': ['B'],
    },
  ],
};

Map _proxy(Map<String, dynamic> config, String name) =>
    (config['proxies'] as List).cast<Map>().firstWhere(
      (item) => item['name'] == name,
    );

void main() {
  group('injectDialerProxies', () {
    test('sets dialer-proxy on the node', () {
      final config = _config();
      final skipped = injectDialerProxies(config, {'A': 'Other'});
      expect(skipped, isEmpty);
      expect(_proxy(config, 'A')['dialer-proxy'], 'Other');
      expect(_proxy(config, 'B').containsKey('dialer-proxy'), isFalse);
    });

    test('overrides and clears the profile own dialer-proxy', () {
      final config = _config();
      injectDialerProxies(config, {'C': 'A'});
      expect(_proxy(config, 'C')['dialer-proxy'], 'A');
      final cleared = _config();
      injectDialerProxies(cleared, {'C': dialerProxyDirect});
      expect(_proxy(cleared, 'C').containsKey('dialer-proxy'), isFalse);
    });

    test('skips missing nodes and targets', () {
      final config = _config();
      final skipped = injectDialerProxies(config, {'Gone': 'A', 'A': 'Gone'});
      expect(skipped, {
        'Gone': DialerProxyIssue.missingNode,
        'A': DialerProxyIssue.missingTarget,
      });
      expect(_proxy(config, 'A').containsKey('dialer-proxy'), isFalse);
    });

    test('skips settings that loop', () {
      expect(injectDialerProxies(_config(), {'A': 'A'}), {
        'A': DialerProxyIssue.cycle,
      });
      expect(injectDialerProxies(_config(), {'A': 'HK'}), {
        'A': DialerProxyIssue.cycle,
      });
      final skipped = injectDialerProxies(_config(), {'A': 'B', 'B': 'A'});
      expect(skipped, {'B': DialerProxyIssue.cycle});
      expect(injectDialerProxies(_config(), {'B': 'C'}), {
        'B': DialerProxyIssue.cycle,
      });
    });

    test('works with an injected Tailscale node and custom routings', () {
      final config = _config();
      injectTailscale(
        config,
        const TailscaleProps(enable: true, hostname: 'flclash'),
      );
      final name = tailscaleProxyName({'A', 'B', 'C', 'HK', 'Other'});
      final skipped = injectDialerProxies(config, {name: 'Other', 'A': name});
      expect(skipped, isEmpty);
      expect(_proxy(config, name)['dialer-proxy'], 'Other');
      expect(_proxy(config, 'A')['dialer-proxy'], name);
    });
  });

  test('dialerProxyCreatesCycle walks groups and dialers', () {
    final graph = DialerGraph.fromConfig(_config());
    expect(graph.existing, {'C': 'B'});
    expect(dialerProxyCreatesCycle(graph, {}, 'A', 'Other'), isFalse);
    expect(dialerProxyCreatesCycle(graph, {}, 'B', 'Other'), isTrue);
    expect(dialerProxyCreatesCycle(graph, {'C': 'B'}, 'B', 'C'), isTrue);
  });
}
