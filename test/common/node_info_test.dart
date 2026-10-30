import 'dart:convert';

import 'package:fl_clash/common/node_info.dart';
import 'package:flutter_test/flutter_test.dart';

const _node = {
  'name': 'HK',
  'type': 'vless',
  'server': 'hk.example.com',
  'port': 443,
  'uuid': '11111111-2222-3333-4444-555555555555',
  'network': 'ws',
  'tls': true,
  'flow': 'xtls-rprx-vision',
  'servername': 'sni.example.com',
  'reality-opts': {'public-key': 'PUB', 'short-id': 'abcd'},
  'ws-opts': {
    'path': '/ray',
    'headers': {'Host': 'cdn.example.com'},
  },
  'alpn': ['h2', 'http/1.1'],
  'udp': true,
};

void main() {
  test('finds the node in the profile proxies', () {
    final config = {
      'proxies': [
        {'name': 'A', 'type': 'ss'},
        _node,
      ],
    };
    expect(findNodeConfig(config, 'HK')?['server'], 'hk.example.com');
    expect(findNodeConfig(config, 'missing'), isNull);
    expect(findNodeConfig(null, 'HK'), isNull);
    expect(findNodeConfig({'proxies': 'bad'}, 'HK'), isNull);
  });

  test('flattens fields with the main ones first', () {
    final fields = nodeFields(_node);
    final paths = [for (final field in fields) field.path];
    expect(paths.take(4), ['server', 'port', 'network', 'udp']);
    expect(paths, isNot(contains('name')));
    expect(paths, contains('ws-opts.headers.Host'));
    expect(
      fields.firstWhere((field) => field.path == 'alpn').value,
      'h2, http/1.1',
    );
  });

  test('marks credentials as secret', () {
    final secret = {
      for (final field in nodeFields(_node))
        if (field.secret) field.path,
    };
    expect(secret, {'uuid', 'reality-opts.short-id'});
    for (final key in [
      'password',
      'private-key',
      'psk',
      'pre-shared-key',
      'auth-str',
      'obfs-password',
    ]) {
      expect(isSecretNodeKey(key), isTrue, reason: key);
    }
    expect(isSecretNodeKey('server'), isFalse);
    expect(isSecretNodeKey('public-key'), isFalse);
    expect(maskSecret('abc'), isNot(contains('abc')));
  });

  test('copies the whole node as YAML or JSON', () {
    expect(jsonDecode(nodeConfigJson(_node)), _node);
    final yaml = nodeConfigYaml(_node);
    expect(yaml, contains('hk.example.com'));
    expect(yaml, contains('11111111-2222-3333-4444-555555555555'));
  });
}
