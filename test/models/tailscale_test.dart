import 'package:fl_clash/models/models.dart';
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
}
