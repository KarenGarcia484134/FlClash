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

  test('peer routing prefers the DNS name, else a host CIDR', () {
    final byName = tailscalePeerCondition(
      const TailscalePeer(dnsName: 'nas.tail.ts.net.', ips: ['100.64.0.2']),
    )!;
    expect(byName.ruleAction, RuleAction.DOMAIN);
    expect(byName.values, ['nas.tail.ts.net']);
    final byIp = tailscalePeerCondition(
      const TailscalePeer(ips: ['100.64.0.2']),
    )!;
    expect(byIp.ruleAction, RuleAction.IP_CIDR);
    expect(byIp.values, ['100.64.0.2/32']);
    expect(byIp.noResolve, isTrue);
    final byIp6 = tailscalePeerCondition(
      const TailscalePeer(ips: ['fd7a:115c:a1e9::2']),
    )!;
    expect(byIp6.values, ['fd7a:115c:a1e9::2/128']);
    expect(tailscalePeerCondition(const TailscalePeer()), isNull);
    expect(
      CustomRouting(id: 1, target: 'Tailscale', conditions: [byIp]).toRule(),
      'IP-CIDR,100.64.0.2/32,Tailscale,no-resolve',
    );
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
