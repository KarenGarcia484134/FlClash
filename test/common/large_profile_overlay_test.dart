import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Shared with core/profile_base_test.go, which merges it into the profile
/// in core/testdata/large_profile.yaml. Regenerate with UPDATE_GOLDEN=1.
const _golden = 'core/testdata/large_profile_overlay.yaml';

/// What getProfileBase returns for core/testdata/large_profile.yaml: the
/// base config and the outline of the sections the Core keeps.
Map<String, dynamic> _base() => withProfileOutline(
  {
    'mixed-port': 7890,
    'dns': <String, dynamic>{
      'enable': true,
      'nameserver': ['223.5.5.5'],
    },
    'listeners': [
      {'name': 'own', 'type': 'socks', 'port': 17000, 'listen': '127.0.0.1'},
    ],
    'rule-providers': <String, dynamic>{},
  },
  {
    'proxies': [
      {'name': 'HK', 'type': 'socks5'},
      {'name': 'JP', 'type': 'socks5', 'dialer-proxy': 'SG'},
      {'name': 'SG', 'type': 'socks5'},
    ],
    'proxy-groups': [
      {
        'name': 'Auto',
        'type': 'select',
        'proxies': ['JP', 'SG'],
      },
    ],
    'sub-rules': ['sub'],
  },
);

MakeRealProfileState _state() => MakeRealProfileState(
  profilesPath: '/profiles',
  profileId: 1,
  rawConfig: _base(),
  realPatchConfig: const PatchClashConfig(),
  appendSystemDns: false,
  proxyGroups: const [],
  rules: const [],
  addedRules: const [],
  customRoutings: const [
    CustomRouting(
      id: 1,
      target: 'Auto',
      conditions: [
        CustomRoutingCondition(values: ['routed.example']),
      ],
    ),
  ],
  dialerProxies: const {'HK': 'Auto', 'JP': dialerProxyDirect},
  listeners: const ListenersProps(
    items: [
      InboundListenerProps(
        id: 'l1',
        name: 'via-auto',
        port: 17001,
        proxy: 'Auto',
      ),
      InboundListenerProps(id: 'l2', name: 'via-sub', port: 17002, rule: 'sub'),
    ],
  ),
  tailscale: const TailscaleProps(
    enable: true,
    authKey: 'tskey-test',
    dialerProxy: 'HK',
  ),
  defaultUA: 'FlClash-Test',
  outlineOnly: true,
);

void main() {
  test('a large profile overlay keeps every fork injection', () async {
    final result = await makeRealProfileTask(_state());
    final overlay = loadYaml(result.yaml) as YamlMap;

    expect(overlay.containsKey('proxy-groups'), isFalse);
    expect(overlay.containsKey('sub-rules'), isFalse);
    final proxies = [
      for (final item in overlay['proxies'] as YamlList)
        Map<String, dynamic>.from(item as YamlMap),
    ];
    expect(proxies, [
      {'name': 'HK', 'dialer-proxy': 'Auto'},
      {'name': 'JP', 'dialer-proxy': null},
      containsPair('name', 'Tailscale'),
    ]);
    expect(proxies.last['type'], 'tailscale');
    expect(proxies.last['dialer-proxy'], 'HK');
    expect(result.counts.proxies, 1);

    final rules = List<String>.from(overlay['rules'] as YamlList);
    expect(rules.first, 'IP-CIDR,100.64.0.0/10,Tailscale,no-resolve');
    expect(rules, contains('DOMAIN-SUFFIX,routed.example,Auto'));

    final listeners = (overlay['listeners'] as YamlList)
        .map((item) => Map<String, dynamic>.from(item as YamlMap))
        .toList();
    expect(listeners.map((item) => item['name']), [
      'own',
      'via-auto',
      'via-sub',
    ]);
    expect(listeners[1]['proxy'], 'Auto');
    expect(listeners[2]['rule'], 'sub');

    final policy = (overlay['dns'] as YamlMap)['nameserver-policy'] as YamlMap;
    expect(policy['+.ts.net'], 'tailscale://Tailscale');

    final golden = File(_golden);
    if (Platform.environment['UPDATE_GOLDEN'] == '1') {
      golden.writeAsStringSync(result.yaml);
    }
    expect(result.yaml, golden.readAsStringSync());
  });

  test('a profile name clash moves the Tailscale node aside', () async {
    final base = _base();
    (base['proxies'] as List).add({'name': 'Tailscale', 'type': 'socks5'});
    final result = await makeRealProfileTask(
      _state().copyWith(rawConfig: base),
    );
    final overlay = loadYaml(result.yaml) as YamlMap;
    final names = (overlay['proxies'] as YamlList)
        .map((item) => (item as YamlMap)['name'])
        .toList();
    expect(names, contains('Tailscale-FlClash'));
    expect(
      List<String>.from(overlay['rules'] as YamlList).first,
      'IP-CIDR,100.64.0.0/10,Tailscale-FlClash,no-resolve',
    );
  });

  test('without changes the overlay sends no outline proxies', () async {
    final result = await makeRealProfileTask(
      _state().copyWith(
        dialerProxies: const {},
        tailscale: const TailscaleProps(),
      ),
    );
    final overlay = loadYaml(result.yaml) as YamlMap;
    expect(overlay['proxies'], isEmpty);
  });

  test('profile outbounds from the Core carry the sub-rule names', () async {
    final config = await clashConfigTask({
      'proxies': [
        {'name': 'HK', 'type': 'socks5'},
      ],
      'proxy-groups': [
        {'name': 'Auto', 'type': 'select'},
      ],
      'sub-rules': {'sub': <String>[]},
    });
    expect(config.subRules, ['sub']);
    expect(config.proxyGroups.single.name, 'Auto');
  });
}
