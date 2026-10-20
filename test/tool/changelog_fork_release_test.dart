import 'dart:convert';

import 'package:test/test.dart';

import '../../tool/src/changelog/fork_release.dart';
import '../../tool/src/changelog/models.dart';
import '../../tool/src/changelog/render.dart';

const _version = ChangelogVersion(
  version: '0.9.13',
  tag: 'v0.9.13',
  date: '2026-10-17',
  groups: [
    ChangelogGroup(
      type: ChangelogType.fix,
      entries: [ChangelogEntry(id: '31807f0', scope: 'core', text: '修复')],
    ),
    ChangelogGroup(
      type: ChangelogType.feat,
      entries: [ChangelogEntry(id: 'aaaaaaa', text: 'New thing')],
    ),
    ChangelogGroup(
      type: ChangelogType.perf,
      entries: [ChangelogEntry(id: 'bbbbbbb', text: 'Faster')],
    ),
  ],
);

String _render({Set<String>? assets, String? previousTag = 'v0.9.12'}) =>
    renderForkRelease(
      _version,
      repository: 'owner/FlClash',
      previousTag: previousTag,
      assets: assets,
    );

void main() {
  test('groups entries under bilingual headings in a fixed order', () {
    final body = _render();
    final notes = body.substring(
      body.indexOf(releaseBeginMarker),
      body.indexOf(releaseEndMarker),
    );

    expect(body, startsWith(forkHeader));
    expect(
      RegExp(
        r'^### (.+)$',
        multiLine: true,
      ).allMatches(notes).map((match) => match.group(1)),
      ['✨ 新功能 Features', '🐛 问题修复 Bug Fixes', '🔧 其他 Other'],
    );
    expect(notes, contains('- **core** 修复\n'));
    expect(notes, contains('- Faster\n'));
  });

  test('links every platform the workflow builds and the compare range', () {
    final body = _render();

    for (final file in [
      'FlClash-0.9.13-android-arm64-v8a.apk',
      'FlClash-0.9.13-windows-amd64-setup.exe',
      'FlClash-0.9.13-macos-arm64.dmg',
      'FlClash-0.9.13-macos-amd64.dmg',
      'FlClash-0.9.13-linux-amd64.AppImage',
    ]) {
      expect(
        body,
        contains(
          'https://github.com/owner/FlClash/releases/download/v0.9.13/$file',
        ),
      );
    }
    expect(body, contains('/compare/v0.9.12...v0.9.13'));
  });

  test('only links published files when the asset list is known', () {
    final body = _render(
      assets: {'FlClash-0.9.13-android-arm64-v8a.apk'},
      previousTag: null,
    );

    expect(body, contains('| Android | [arm64-v8a]'));
    expect(body, isNot(contains('armeabi-v7a](')));
    expect(body, isNot(contains('| Windows |')));
    expect(body, isNot(contains('/compare/')));
  });

  test('macOS lists both chips, and an older release only its own', () {
    expect(
      _render(),
      contains('[Intel x64](https://github.com/owner/FlClash/releases/'),
    );
    expect(_render(), contains('Intel 处理器的 Mac 选 x64'));
    final old = _render(assets: {'FlClash-0.9.13-macos-arm64.dmg'});
    expect(old, contains('| macOS | [Apple 芯片 arm64]'));
    expect(old, isNot(contains('macos-amd64.dmg')));
    expect(old, contains('仅 Apple 芯片（arm64）'));
  });

  test('carries the structured payload the update dialog reads', () {
    final body = _render();
    final start =
        body.indexOf(releaseJsonBeginMarker) + releaseJsonBeginMarker.length;
    final payload = body.substring(start, body.indexOf('-->', start));
    final changelog = Changelog.fromJson(
      jsonDecode(payload) as Map<String, dynamic>,
    );

    expect(changelog.versions.single.tag, 'v0.9.13');
    expect(changelog.versions.single.groups.length, 3);
  });

  test('an empty version still says something', () {
    final body = renderForkRelease(
      const ChangelogVersion(
        version: '1.0.0',
        tag: 'v1.0.0',
        date: '',
        groups: [],
      ),
      repository: 'owner/FlClash',
    );

    expect(body, contains('- $forkEmptyVersionNote'));
  });
}
