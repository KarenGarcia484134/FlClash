import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

TrackerInfo _info(Map<String, Object?> metadata) => TrackerInfo.fromJson({
  'id': '1',
  'start': '2026-10-21T00:00:00Z',
  'metadata': metadata,
  'chains': <String>['DIRECT'],
  'rule': 'Match',
  'rulePayload': '',
});

void main() {
  test('the Core\'s process name wins', () {
    final info = _info({
      'process': 'chrome.exe',
      'processPath': r'C:\Program Files\Google\chrome.exe',
    });
    expect(info.metadata.processName, 'chrome.exe');
    expect(info.progressText, 'chrome.exe');
  });

  test('a Windows path alone still names the process', () {
    final info = _info({'processPath': r'C:\Windows\System32\svchost.exe'});
    expect(info.metadata.processName, 'svchost.exe');
    expect(info.progressText, 'svchost.exe');
    expect(info.searchFields, contains('svchost.exe'));
  });

  test('a POSIX path alone still names the process', () {
    expect(
      _info({'processPath': '/usr/bin/curl'}).metadata.processName,
      'curl',
    );
  });

  test('the Core\'s own connections are named after it', () {
    final info = _info({'type': 'Inner'});
    expect(info.metadata.processName, coreProcessName);
  });

  test('an unknown source stays empty and keeps the uid', () {
    expect(_info({'type': 'HTTP'}).metadata.processName, isEmpty);
    expect(
      _info({'process': 'com.example', 'uid': 10123}).progressText,
      'com.example(10123)',
    );
  });
}
