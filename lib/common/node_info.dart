import 'dart:convert';

import 'yaml_writer.dart';

const _secretKeys = {
  'uuid',
  'password',
  'passwd',
  'private-key',
  'short-id',
  'psk',
  'pre-shared-key',
  'auth',
  'auth-str',
  'token',
  'obfs-password',
  'secret',
  'seed',
};

/// Whether [key], the last segment of a field path, holds a credential.
bool isSecretNodeKey(String key) {
  final name = key.toLowerCase();
  return _secretKeys.contains(name) ||
      name.contains('password') ||
      name.contains('private') ||
      name.contains('secret') ||
      name.contains('token');
}

/// The `proxies` entry of [config] named [name], if the profile defines it.
Map<String, Object?>? findNodeConfig(
  Map<String, dynamic>? config,
  String name,
) {
  final proxies = config?['proxies'];
  if (proxies is! List) {
    return null;
  }
  for (final item in proxies) {
    if (item is Map && item['name'] == name) {
      return Map<String, Object?>.from(item);
    }
  }
  return null;
}

/// Fields read first, in this order; the rest follow as the profile has them.
const nodeFieldOrder = [
  'server',
  'port',
  'network',
  'udp',
  'tls',
  'sni',
  'servername',
  'flow',
  'alpn',
  'client-fingerprint',
  'skip-cert-verify',
  'reality-opts.public-key',
  'reality-opts.short-id',
  'cipher',
  'uuid',
  'password',
];

class NodeField {
  const NodeField(this.path, this.value);

  final String path;
  final String value;

  String get key => path.split('.').last.replaceAll(RegExp(r'\[\d+\]$'), '');

  bool get secret => isSecretNodeKey(key);
}

/// Every scalar of [node] but its name and type, as `a.b` paths.
List<NodeField> nodeFields(Map<String, Object?> node) {
  final fields = <NodeField>[];
  void walk(String path, Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        walk(path.isEmpty ? '${entry.key}' : '$path.${entry.key}', entry.value);
      }
    } else if (value is List) {
      if (value.every((item) => item is! Map && item is! List)) {
        fields.add(NodeField(path, value.join(', ')));
      } else {
        for (final (index, item) in value.indexed) {
          walk('$path[$index]', item);
        }
      }
    } else if (value != null) {
      fields.add(NodeField(path, '$value'));
    }
  }

  for (final entry in node.entries) {
    if (entry.key == 'name' || entry.key == 'type') {
      continue;
    }
    walk(entry.key, entry.value);
  }
  int rank(NodeField field) {
    final index = nodeFieldOrder.indexOf(field.path);
    return index == -1 ? nodeFieldOrder.length : index;
  }

  final indexed = fields.indexed.toList()
    ..sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
  return [for (final (_, field) in indexed) field];
}

String maskSecret(String value) => value.isEmpty ? '' : '••••••••';

String nodeConfigYaml(Map<String, Object?> node) => writeYaml(node);

String nodeConfigJson(Map<String, Object?> node) =>
    const JsonEncoder.withIndent('  ').convert(node);
