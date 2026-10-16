import 'package:fl_clash/views/config/outbound_delay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latency levels', () {
    expect(latencyLevelOf(null), isNull);
    expect(latencyLevelOf(-1), LatencyLevel.failed);
    expect(latencyLevelOf(120), LatencyLevel.good);
    expect(latencyLevelOf(500), LatencyLevel.fair);
    expect(latencyLevelOf(1200), LatencyLevel.poor);
  });

  test('built-in policies have no delay badge', () {
    expect(hasOutboundDelay('DIRECT'), isFalse);
    expect(hasOutboundDelay('REJECT'), isFalse);
    expect(hasOutboundDelay(''), isFalse);
    expect(hasOutboundDelay('Tailscale'), isTrue);
  });

  test('sorts by latency, failed then untested last, stable ties', () {
    final delays = {'a': null, 'b': 300, 'c': -1, 'd': 80, 'e': 300};
    expect(
      sortedOutbounds(
        ['a', 'b', 'c', 'd', 'e'],
        delays,
        sortByDelay: true,
        hideTimeout: false,
      ),
      ['d', 'b', 'e', 'c', 'a'],
    );
  });

  test('hiding timeouts keeps the current choice and untested nodes', () {
    final delays = {'a': null, 'b': -1, 'c': -1, 'd': 80};
    expect(
      sortedOutbounds(
        ['a', 'b', 'c', 'd'],
        delays,
        sortByDelay: false,
        hideTimeout: true,
        keep: 'c',
      ),
      ['a', 'c', 'd'],
    );
  });
}
