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
}
