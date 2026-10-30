import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled leaves config untouched', () {
    final raw = <String, dynamic>{'proxies': []};
    expect(injectTailscale(raw, const TailscaleProps()), isEmpty);
    expect(raw['proxies'], isEmpty);
  });

  // Rules that name Tailscale without the matching proxy make the core reject
  // the config ("proxy [Tailscale] not found"); injection must keep them paired.
  test('injectTailscale never emits rules without the proxy', () {
    final raw = <String, dynamic>{
      'proxies': [
        {'name': 'HK', 'type': 'direct'},
      ],
      'dns': <String, dynamic>{'enable': true},
    };
    final rules = injectTailscale(
      raw,
      const TailscaleProps(enable: true, authKey: 'tskey'),
    );
    expect(rules, isNotEmpty);
    expect(
      rules.every((rule) => rule.contains(',Tailscale')),
      isTrue,
      reason: 'every injected rule must target the injected proxy name',
    );
    final proxies = raw['proxies'] as List;
    expect(
      proxies.whereType<Map>().any(
        (item) => item['name'] == 'Tailscale' && item['type'] == 'tailscale',
      ),
      isTrue,
    );
  });

  test('injects proxy, rules and nameserver policy', () {
    final raw = <String, dynamic>{
      'proxies': [
        {'name': 'a', 'type': 'ss'},
      ],
      'dns': <String, dynamic>{
        'nameserver-policy': {'+.lan': '192.168.1.1'},
      },
    };
    final rules = injectTailscale(
      raw,
      const TailscaleProps(
        enable: true,
        authKey: ' key ',
        controlUrl: 'https://hs.example',
        dnsSuffixes: ['.Corp.example', ''],
      ),
    );
    expect(rules, [
      'IP-CIDR,100.64.0.0/10,Tailscale,no-resolve',
      'IP-CIDR6,fd7a:115c:a1e9::/48,Tailscale,no-resolve',
      'DOMAIN-SUFFIX,ts.net,Tailscale',
      'DOMAIN-SUFFIX,corp.example,Tailscale',
    ]);
    final proxy = (raw['proxies'] as List).last as Map;
    expect(proxy['type'], 'tailscale');
    expect(proxy['auth-key'], 'key');
    expect(proxy['control-url'], 'https://hs.example');
    expect(proxy['state-dir'], tailscaleStateDir);
    expect(raw['dns']['nameserver-policy'], {
      '+.lan': '192.168.1.1',
      '+.ts.net': 'tailscale://Tailscale',
      '+.corp.example': 'tailscale://Tailscale',
    });
  });

  test('avoids clashing with profile names', () {
    final raw = <String, dynamic>{
      'proxies': [
        {'name': 'Tailscale', 'type': 'tailscale'},
      ],
      'proxy-groups': [
        {'name': 'Tailscale-FlClash', 'type': 'select'},
      ],
    };
    final rules = injectTailscale(raw, const TailscaleProps(enable: true));
    expect(rules.first, endsWith('Tailscale-FlClash2,no-resolve'));
  });

  test('parses login url and running state', () {
    const idle = TailscaleStatus();
    final login = parseTailscaleLog(
      '[Tailscale](Tailscale) To start this tsnet server, restart with '
      'TS_AUTHKEY set, or go to: https://login.tailscale.com/a/abc',
      idle,
    )!;
    expect(login.phase, TailscalePhase.needsLogin);
    expect(login.loginUrl, 'https://login.tailscale.com/a/abc');
    final running = parseTailscaleLog(
      '[Tailscale](Tailscale) AuthLoop: state is Running; done',
      login,
    )!;
    expect(running.phase, TailscalePhase.running);
    expect(running.loginUrl, isNull);
    expect(parseTailscaleLog('other', idle), isNull);
  });

  test('decodes the core status payload', () {
    final status = TailscaleNetStatus.fromJson({
      'started': true,
      'backendState': 'Running',
      'magicDnsSuffix': 'tail.ts.net',
      'self': {
        'hostName': 'phone',
        'ips': ['100.64.0.1', 'fd7a:115c:a1e9::1'],
        'online': true,
      },
      'peers': [
        {
          'hostName': 'nas',
          'dnsName': 'nas.tail.ts.net.',
          'os': 'linux',
          'ips': ['100.64.0.2'],
          'online': true,
          'exitNodeOption': true,
        },
      ],
    });
    expect(status.self!.ipv4, '100.64.0.1');
    expect(status.self!.ipv6, 'fd7a:115c:a1e9::1');
    final peer = status.peers.single;
    expect(peer.shortDnsName, 'nas.tail.ts.net');
    expect(peer.exitNodeOption, isTrue);
    expect(peer.matches('LINUX'), isTrue);
    expect(peer.matches('100.64.0.2'), isTrue);
    expect(peer.matches('mac'), isFalse);
  });

  test('peer routing ORs the DNS name with every address', () {
    final conditions = tailscalePeerConditions(
      const TailscalePeer(
        dnsName: 'nas.tail.ts.net.',
        ips: ['100.64.0.2', 'fd7a:115c:a1e9::2'],
      ),
    );
    expect(conditions.map((item) => item.ruleAction), [
      RuleAction.DOMAIN,
      RuleAction.IP_CIDR,
      RuleAction.IP_CIDR6,
    ]);
    expect(conditions[1].values, ['100.64.0.2/32']);
    expect(conditions[2].values, ['fd7a:115c:a1e9::2/128']);
    expect(conditions.skip(1).every((item) => item.noResolve), isTrue);
    final rule = CustomRouting(
      id: 1,
      target: 'Tailscale',
      conditions: conditions,
    ).toRule();
    expect(rule, contains('DOMAIN,nas.tail.ts.net'));
    expect(rule, contains('IP-CIDR,100.64.0.2/32,no-resolve'));
    expect(rule, contains('IP-CIDR6,fd7a:115c:a1e9::2/128,no-resolve'));
    expect(rule, startsWith('OR,'));
    expect(rule, endsWith(',Tailscale'));
    expect(
      tailscalePeerConditions(
        const TailscalePeer(ips: ['100.64.0.3']),
      ).single.values,
      ['100.64.0.3/32'],
    );
    expect(tailscalePeerConditions(const TailscalePeer()), isEmpty);
  });

  test('connection proxy is set only when the profile has it', () {
    Map<dynamic, dynamic> nodeFor(String via) {
      final raw = <String, dynamic>{
        'proxies': [
          {'name': 'HK', 'type': 'ss'},
        ],
        'proxy-groups': [
          {'name': 'Proxy', 'type': 'select'},
        ],
      };
      injectTailscale(raw, TailscaleProps(enable: true, dialerProxy: via));
      return (raw['proxies'] as List).last as Map;
    }

    expect(nodeFor('Proxy')['dialer-proxy'], 'Proxy');
    expect(nodeFor('HK')['dialer-proxy'], 'HK');
    expect(nodeFor('Gone').containsKey('dialer-proxy'), isFalse);
    expect(nodeFor('').containsKey('dialer-proxy'), isFalse);
  });

  test('only a refused key is blamed on the key', () {
    expect(
      classifyTailscaleHealth([
        // ignore: no_adjacent_strings_in_list
        'You are logged out. The last login error was: register request: '
            'Post "https://controlplane.tailscale.com/machine/register": '
            'connection attempts aborted by context: context deadline exceeded',
      ]),
      TailscaleIssue.network,
    );
    expect(
      classifyTailscaleHealth(['register request: invalid key: not found']),
      TailscaleIssue.authKey,
    );
    expect(classifyTailscaleHealth(const []), TailscaleIssue.none);
  });

  test('the auth key survives the saved config', () {
    const props = TailscaleProps(enable: true, authKey: 'tskey-auth-1');
    final config = Config.fromJson(
      jsonDecode(
            jsonEncode(
              const Config(themeProps: ThemeProps(), tailscaleProps: props),
            ),
          )
          as Map<String, dynamic>,
    );
    expect(config.tailscaleProps.authKey, 'tskey-auth-1');
  });

  test('node status drives the phase over stale log lines', () {
    const stale = TailscaleStatus(
      phase: TailscalePhase.needsLogin,
      loginUrl: 'https://login.tailscale.com/a/old',
    );
    final running = applyTailscaleNetStatus(
      stale,
      const TailscaleNetStatus(started: true, backendState: 'Running'),
      'Tailscale',
    );
    expect(running.phase, TailscalePhase.running);
    expect(running.loginUrl, isNull);
    final login = applyTailscaleNetStatus(
      stale,
      const TailscaleNetStatus(
        started: true,
        backendState: 'NeedsLogin',
        authUrl: 'https://login.tailscale.com/a/new',
        health: ['invalid key'],
      ),
      'Tailscale',
    );
    expect(login.loginUrl, 'https://login.tailscale.com/a/new');
    expect(login.health, ['invalid key']);
    expect(
      applyTailscaleNetStatus(stale, const TailscaleNetStatus(), 'Tailscale'),
      stale,
    );
  });

  group('connecting', () {
    const name = 'Tailscale';
    const passing = TailscaleNetStatus(
      started: true,
      backendState: 'NeedsLogin',
    );

    test(
      'a node with a saved key passing through NeedsLogin is not settled',
      () {
        expect(isTailscaleSettled(passing), isFalse);
        for (final state in ['', 'NoState', 'Starting']) {
          expect(
            isTailscaleSettled(
              TailscaleNetStatus(started: true, backendState: state),
            ),
            isFalse,
            reason: state,
          );
        }
        for (final state in ['Running', 'NeedsMachineAuth', 'Stopped']) {
          expect(
            isTailscaleSettled(
              TailscaleNetStatus(started: true, backendState: state),
            ),
            isTrue,
            reason: state,
          );
        }
        expect(
          isTailscaleSettled(
            passing.copyWith(authUrl: 'https://login.tailscale.com/a/x'),
          ),
          isTrue,
        );
        expect(isTailscaleSettled(passing.copyWith(error: 'boom')), isTrue);
      },
    );

    test('while settling a passing state reads as connecting', () {
      const idle = TailscaleStatus();
      final connecting = applyTailscaleNetStatus(
        idle,
        passing,
        name,
        settling: true,
      );
      expect(connecting.phase, TailscalePhase.connecting);
      expect(connecting.loginUrl, isNull);
      expect(
        applyTailscaleNetStatus(
          idle,
          const TailscaleNetStatus(started: true, backendState: 'Starting'),
          name,
        ).phase,
        TailscalePhase.connecting,
      );
    });

    test('a real NeedsLogin still shows the login', () {
      final login = applyTailscaleNetStatus(
        const TailscaleStatus(phase: TailscalePhase.connecting),
        passing.copyWith(authUrl: 'https://login.tailscale.com/a/x'),
        name,
        settling: true,
      );
      expect(login.phase, TailscalePhase.needsLogin);
      expect(login.loginUrl, 'https://login.tailscale.com/a/x');
      final timedOut = applyTailscaleNetStatus(
        const TailscaleStatus(phase: TailscalePhase.connecting),
        passing,
        name,
      );
      expect(timedOut.phase, TailscalePhase.needsLogin);
    });

    test('a node that never started leaves connecting once settled', () {
      expect(
        applyTailscaleNetStatus(
          const TailscaleStatus(phase: TailscalePhase.connecting),
          const TailscaleNetStatus(),
          name,
        ).phase,
        TailscalePhase.idle,
      );
    });

    test('the login loop ending on Starting is not a login prompt', () {
      final next = parseTailscaleLog(
        '[Tailscale](Tailscale) AuthLoop: state is Starting; done',
        const TailscaleStatus(),
      )!;
      expect(next.phase, TailscalePhase.connecting);
    });
  });

  group('ping', () {
    test('decodes a direct, relayed and failed result', () {
      final direct = TailscalePingResult.fromJson({
        'target': '100.64.0.2',
        'latencyMs': 12,
        'endpoint': '1.2.3.4:41641',
      });
      expect(direct.ok, isTrue);
      expect(direct.path, TailscalePath.direct);
      final relayed = TailscalePingResult.fromJson({
        'target': '100.64.0.3',
        'latencyMs': 180,
        'derpRegionId': 11,
        'derpRegionCode': 'tok',
      });
      expect(relayed.path, TailscalePath.derp);
      expect(relayed.derpLabel, 'DERP-tok');
      expect(
        const TailscalePingResult(latencyMs: 90, derpRegionId: 7).derpLabel,
        'DERP-7',
      );
      expect(
        const TailscalePingResult(latencyMs: 30, peerRelay: '5.6.7.8:7').path,
        TailscalePath.peerRelay,
      );
      final failed = TailscalePingResult.fromJson({
        'target': '100.64.0.4',
        'latencyMs': -1,
        'error': 'timeout',
      });
      expect(failed.ok, isFalse);
    });

    test('a peer is pinged at its IPv4 address first', () {
      expect(
        tailscalePingTarget(
          const TailscalePeer(ips: ['fd7a:115c:a1e9::2', '100.64.0.2']),
        ),
        '100.64.0.2',
      );
      expect(
        tailscalePingTarget(const TailscalePeer(ips: ['fd7a:115c:a1e9::2'])),
        'fd7a:115c:a1e9::2',
      );
      expect(tailscalePingTarget(const TailscalePeer()), isNull);
    });
  });

  group('route hint', () {
    const error =
        'You are logged out. The last login error was: fetch control key: '
        'read tcp 1.2.3.4:1->192.200.0.115:443: read: connection reset by peer';
    const reset = [error];
    test(
      'a direct node whose control dial is reset is told to pick a proxy',
      () {
        expect(
          tailscaleRouteHint(
            configured: '',
            available: null,
            effective: '',
            health: reset,
          ),
          TailscaleRouteHint.direct,
        );
        expect(
          tailscaleRouteHint(
            configured: '',
            available: null,
            effective: '',
            health: const [],
          ),
          TailscaleRouteHint.none,
        );
      },
    );
    test('only a pick the profile really lacks is dropped', () {
      expect(
        tailscaleRouteHint(
          configured: '[自建]香港-yt1',
          available: false,
          effective: '',
          health: const [],
        ),
        TailscaleRouteHint.dropped,
      );
    });
    test(
      'a pick the running node does not use yet is pending, not missing',
      () {
        // The regression: picking a node and tapping Reconnect without leaving
        // the page used to claim the node was not in the profile.
        expect(
          tailscaleRouteHint(
            configured: '[自建]香港-yt1',
            available: true,
            effective: '',
            health: reset,
          ),
          TailscaleRouteHint.pending,
        );
        expect(
          tailscaleRouteHint(
            configured: '[自建]美国-dmit',
            available: true,
            effective: '[自建]香港-yt1',
            health: const [],
          ),
          TailscaleRouteHint.pending,
        );
        expect(
          tailscaleRouteHint(
            configured: '[自建]美国-dmit',
            available: true,
            effective: '[自建]美国-dmit',
            health: reset,
          ),
          TailscaleRouteHint.none,
        );
        expect(
          tailscaleRouteHint(
            configured: 'Proxy',
            available: null,
            effective: null,
            health: reset,
          ),
          TailscaleRouteHint.none,
        );
      },
    );
    test('the status keeps what the core says the node dials through', () {
      final next = applyTailscaleNetStatus(
        const TailscaleStatus(),
        TailscaleNetStatus.fromJson({
          'started': true,
          'backendState': 'Running',
          'dialerProxy': 'Proxy',
          'derpRoutes': {'tx-cd-derp': 'direct', 'fra': 'proxy'},
          'exitNodeError': 'node 100.64.0.9 is not advertising an exit node',
        }),
        'Tailscale',
      );
      expect(next.dialerProxy, 'Proxy');
      expect(next.exitNodeError, contains('not advertising'));
      final direct = applyTailscaleNetStatus(
        const TailscaleStatus(),
        const TailscaleNetStatus(started: true, backendState: 'Starting'),
        'Tailscale',
      );
      expect(direct.dialerProxy, '');
    });
  });

  group('dialer candidates', () {
    test('match bracketed names exactly and skip the injected node', () {
      final candidates = TailscaleDialerCandidates.fromConfig({
        'proxies': [
          {'name': '[自建]香港-yt1', 'type': 'vless'},
          {'name': '[自建]美国-dmit', 'type': 'trojan'},
          {'name': 'ts-own', 'type': 'tailscale'},
        ],
        'proxy-groups': [
          {'name': 'Tailscale', 'type': 'select'},
          {'name': '🚀 节点选择', 'type': 'select'},
        ],
      }, own: 'Tailscale-FlClash');
      expect(candidates.contains('[自建]香港-yt1'), isTrue);
      expect(candidates.contains('[自建]美国-dmit'), isTrue);
      expect(candidates.contains('自建]香港-yt1'), isFalse);
      expect(candidates.contains('ts-own'), isFalse);
      expect(candidates.groups.keys, contains('🚀 节点选择'));
      expect(isSelectGroupType(candidates.groups['Tailscale']!), isTrue);
    });
    test('a provider proxy is not a top-level candidate, as for the core', () {
      final config = {
        'proxies': [
          {'name': '[自建]美国-dmit', 'type': 'trojan'},
        ],
        'proxy-providers': {
          'sub': {'type': 'http', 'url': 'https://example.com'},
        },
        'proxy-groups': [
          {
            'name': 'Auto',
            'type': 'url-test',
            'use': ['sub'],
          },
        ],
      };
      final candidates = TailscaleDialerCandidates.fromConfig(config);
      // A node only a provider brings is reached through its group.
      expect(candidates.contains('Auto'), isTrue);
      expect(candidates.contains('[自建]香港-yt1'), isFalse);
      // The injection keeps exactly what the picker offers.
      for (final pick in ['Auto', '[自建]美国-dmit']) {
        final raw = Map<String, dynamic>.from(config);
        injectTailscale(raw, TailscaleProps(enable: true, dialerProxy: pick));
        final node = (raw['proxies'] as List).firstWhere(
          (item) => item['type'] == 'tailscale',
        );
        expect(node['dialer-proxy'], pick);
      }
    });
  });

  test('exit node values come from peers offering one', () {
    expect(
      tailscaleExitNodeValue(
        const TailscalePeer(ips: ['fd7a:115c:a1e9::2', '100.64.0.2']),
      ),
      '100.64.0.2',
    );
    expect(tailscaleAutoExitNode, 'auto:any');
  });
}
