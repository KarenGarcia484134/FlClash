import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

InboundListenerProps _item(
  String id, {
  String? name,
  int port = 7891,
  ListenerType type = ListenerType.mixed,
  String listen = listenerLoopback,
  String proxy = '',
  String rule = '',
  bool enabled = true,
  List<ListenerUser> users = const [],
}) => InboundListenerProps(
  id: id,
  name: name ?? id,
  port: port,
  type: type,
  listen: listen,
  proxy: proxy,
  rule: rule,
  enabled: enabled,
  users: users,
);

Map<String, dynamic> _config() => {
  'proxies': [
    {'name': 'HK', 'type': 'ss'},
  ],
  'proxy-groups': [
    {
      'name': 'Auto',
      'type': 'url-test',
      'proxies': ['HK'],
    },
  ],
  'sub-rules': {
    'video': ['MATCH,HK'],
  },
  'listeners': [
    {'name': 'own', 'type': 'socks', 'port': 9000},
    {'name': 'keep', 'type': 'http', 'port': 9001},
  ],
};

void main() {
  group('validation', () {
    test('ports, addresses and users', () {
      expect(isValidListenerPort(0), isFalse);
      expect(isValidListenerPort(65536), isFalse);
      expect(isValidListenerPort(7891), isTrue);
      expect(isValidListenAddress('127.0.0.1'), isTrue);
      expect(isValidListenAddress('0.0.0.0'), isTrue);
      expect(isValidListenAddress('::'), isTrue);
      expect(isValidListenAddress('256.0.0.1'), isFalse);
      expect(isValidListenAddress('localhost'), isFalse);
      expect(isLanListenAddress('0.0.0.0'), isTrue);
      expect(isLanListenAddress('127.0.0.1'), isFalse);
      expect(
        listenerFieldIssue(_item('a', port: 0), linux: true),
        ListenerIssue.invalidPort,
      );
      expect(
        listenerFieldIssue(
          _item('a', users: const [ListenerUser(password: 'x')]),
          linux: true,
        ),
        ListenerIssue.invalidUser,
      );
      expect(
        listenerFieldIssue(_item('a', type: ListenerType.tproxy), linux: false),
        ListenerIssue.unsupported,
      );
      expect(
        listenerFieldIssue(_item('a', type: ListenerType.tproxy), linux: true),
        isNull,
      );
    });

    test('conflicts with the app, each other and the profile', () {
      final issues = listenerIssues([
        _item('a', port: 7890),
        _item('b'),
        _item('c'),
        _item('d', name: 'b', port: 7892),
        _item('e', port: 7893, proxy: 'Gone'),
        _item('f', port: 7894, rule: 'nope'),
        _item('g', port: 7891, enabled: false),
      ], const ListenerContext(appPorts: {7890}, outbounds: {'HK'}));
      expect(issues, {
        'a': ListenerIssue.appPort,
        'c': ListenerIssue.duplicatePort,
        'd': ListenerIssue.duplicateName,
        'e': ListenerIssue.missingTarget,
        'f': ListenerIssue.missingRule,
      });
    });
  });

  group('injectListeners', () {
    test('adds listeners with proxy, rule, udp and users', () {
      final config = _config();
      final skipped = injectListeners(
        config,
        ListenersProps(
          items: [
            _item(
              'a',
              proxy: 'Auto',
              users: const [ListenerUser(username: 'u', password: 'p')],
            ),
            _item('b', port: 7892, type: ListenerType.http, rule: 'video'),
            _item('c', port: 7893, proxy: 'DIRECT', type: ListenerType.socks),
          ],
        ),
        appPorts: {7890},
      );
      expect(skipped, isEmpty);
      final listeners = (config['listeners'] as List).cast<Map>();
      expect(listeners.map((e) => e['name']), ['own', 'keep', 'a', 'b', 'c']);
      expect(listeners[2], {
        'name': 'a',
        'type': 'mixed',
        'listen': '127.0.0.1',
        'port': 7891,
        'udp': true,
        'users': [
          {'username': 'u', 'password': 'p'},
        ],
        'proxy': 'Auto',
      });
      expect(listeners[3].containsKey('udp'), isFalse);
      expect(listeners[3]['rule'], 'video');
      expect(listeners[4]['proxy'], 'DIRECT');
    });

    test('user listeners replace profile ones with the same name or port', () {
      final config = _config();
      injectListeners(
        config,
        ListenersProps(
          items: [_item('own', port: 7891), _item('x', port: 9001)],
        ),
      );
      final listeners = (config['listeners'] as List).cast<Map>();
      expect(listeners.map((e) => e['name']), ['own', 'x']);
      expect(listeners.first['port'], 7891);
    });

    test('skips invalid ones and leaves the config alone when disabled', () {
      final config = _config();
      final skipped = injectListeners(
        config,
        ListenersProps(items: [_item('a', port: 7890)]),
        appPorts: {7890},
      );
      expect(skipped, {'a': ListenerIssue.appPort});
      expect((config['listeners'] as List).length, 2);
      final off = _config();
      injectListeners(off, ListenersProps(enable: false, items: [_item('a')]));
      expect((off['listeners'] as List).length, 2);
    });

    test('a listener can target the injected Tailscale node', () {
      final config = _config();
      injectTailscale(config, const TailscaleProps(enable: true));
      final name = tailscaleProxyNameFor(_config());
      final skipped = injectListeners(
        config,
        ListenersProps(items: [_item('a', proxy: name)]),
      );
      expect(skipped, isEmpty);
    });
  });

  test('addresses to copy', () {
    expect(listenerAddresses(_item('a')), [
      'http://127.0.0.1:7891',
      'socks5://127.0.0.1:7891',
    ]);
    expect(
      listenerAddresses(
        _item('a', type: ListenerType.socks, listen: listenerAnyAddress),
      ),
      ['socks5://127.0.0.1:7891'],
    );
    expect(listenerAddresses(_item('a', type: ListenerType.redir)), [
      '127.0.0.1:7891',
    ]);
  });

  test('app ports skip disabled ones', () {
    expect(
      appInboundPorts(
        const PatchClashConfig(mixedPort: 7890, socksPort: 0, port: 0),
      ),
      {7890},
    );
  });
}
