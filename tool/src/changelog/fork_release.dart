import 'models.dart';
import 'render.dart';

const upstreamRepository = 'chen08209/FlClash';

const forkHeader =
    '> 这是 [$upstreamRepository](https://github.com/$upstreamRepository) 的分支版本，'
    '在上游基础上增加了自定义分流、Tailscale 可视化配置、节点前置代理（dialer-proxy）、'
    '多端口监听等功能，并定期同步上游更新。\n'
    '> 安装包签名与上游不同：从上游版本切换过来需要先卸载，配置请提前备份。';

/// Release headings stay bilingual so the page reads in Chinese while the
/// group names still match `CHANGELOG.md`.
const _sections = <(String, List<ChangelogType>)>[
  ('⚠️ 不兼容变更 Breaking Changes', [ChangelogType.breaking]),
  ('✨ 新功能 Features', [ChangelogType.feat]),
  ('🐛 问题修复 Bug Fixes', [ChangelogType.fix]),
  ('🔧 其他 Other', [ChangelogType.perf, ChangelogType.revert]),
];

const forkEmptyVersionNote = '仅内部改进，无用户可见变化。';

class _Asset {
  const _Asset(this.label, this.suffix);

  final String label;
  final String suffix;
}

class _Platform {
  const _Platform(this.name, this.assets, this.hint, {this.partialHints});

  final String name;
  final List<_Asset> assets;
  final String hint;

  /// The hint for a release that published only the asset with this suffix,
  /// such as one from before the Intel Mac build.
  final Map<String, String>? partialHints;
}

const _platforms = <_Platform>[
  _Platform('Android', [
    _Asset('arm64-v8a', 'android-arm64-v8a.apk'),
    _Asset('armeabi-v7a', 'android-armeabi-v7a.apk'),
    _Asset('x86_64', 'android-x86_64.apk'),
  ], '绝大多数手机选 arm64-v8a；老旧 32 位设备选 armeabi-v7a；模拟器选 x86_64'),
  _Platform('Windows', [
    _Asset('安装版 setup.exe', 'windows-amd64-setup.exe'),
    _Asset('便携版 zip', 'windows-amd64.zip'),
  ], 'x64'),
  _Platform(
    'macOS',
    [
      _Asset('Apple 芯片 arm64', 'macos-arm64.dmg'),
      _Asset('Intel x64', 'macos-amd64.dmg'),
    ],
    'M1/M2/M3/M4 等 Apple 芯片选 arm64；Intel 处理器的 Mac 选 x64',
    partialHints: {
      'macos-arm64.dmg': '仅 Apple 芯片（arm64）',
      'macos-amd64.dmg': '仅 Intel 处理器（x64）',
    },
  ),
  _Platform('Linux', [
    _Asset('AppImage', 'linux-amd64.AppImage'),
    _Asset('deb', 'linux-amd64.deb'),
    _Asset('rpm', 'linux-amd64.rpm'),
  ], 'x64；Debian/Ubuntu 用 deb，Fedora/openSUSE 用 rpm，其他发行版用 AppImage'),
];

/// Release page body for the fork: header, generated notes between the
/// markers the app already parses, download hints and the JSON payload.
///
/// [assets] limits the download table to files that were really published;
/// null lists every platform the release workflow builds.
String renderForkRelease(
  ChangelogVersion version, {
  required String repository,
  String? previousTag,
  Set<String>? assets,
}) {
  final base = 'https://github.com/$repository';
  final buffer = StringBuffer()
    ..writeln(forkHeader)
    ..writeln()
    ..writeln('## 更新内容')
    ..writeln()
    ..writeln(releaseBeginMarker);
  if (version.isEmpty) {
    buffer.writeln('- $forkEmptyVersionNote');
  }
  for (final (title, types) in _sections) {
    final entries = version.groups
        .where((group) => types.contains(group.type))
        .expand((group) => group.entries)
        .toList();
    if (entries.isEmpty) {
      continue;
    }
    buffer.writeln('### $title');
    for (final entry in entries) {
      final scope = entry.scope == null ? '' : '**${entry.scope}** ';
      buffer.writeln('- $scope${entry.text}');
    }
    buffer.writeln();
  }
  buffer
    ..writeln(releaseEndMarker)
    ..writeln()
    ..writeln('## 下载')
    ..writeln()
    ..writeln('| 平台 | 安装包 | 说明 |')
    ..writeln('| --- | --- | --- |');
  for (final platform in _platforms) {
    final links = <String>[];
    final published = <String>[];
    for (final asset in platform.assets) {
      final file = 'FlClash-${version.version}-${asset.suffix}';
      if (assets == null || assets.contains(file)) {
        published.add(asset.suffix);
        links.add(
          '[${asset.label}]($base/releases/download/${version.tag}/$file)',
        );
      }
    }
    if (links.isNotEmpty) {
      final partialHints = platform.partialHints ?? const {};
      final hint =
          (published.length == 1 ? partialHints[published.single] : null) ??
          platform.hint;
      buffer.writeln('| ${platform.name} | ${links.join(' · ')} | $hint |');
    }
  }
  buffer
    ..writeln()
    ..writeln('校验：下载后可用 `SHA256SUMS` 核对文件完整性。')
    ..writeln();
  final compare = previousTag == null
      ? ''
      : '[$previousTag...${version.tag}]'
            '($base/compare/$previousTag...${version.tag}) · ';
  buffer
    ..writeln('**完整变更：** $compare[CHANGELOG.md]($base/blob/main/CHANGELOG.md)')
    ..writeln()
    ..write(renderReleaseJson(version));
  return buffer.toString();
}
