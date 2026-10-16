import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the injected tailscale node is a valid routing target', () {
    const config = ClashConfig();
    expect(isRoutingTargetMissing(config, 'Tailscale'), isTrue);
    expect(
      isRoutingTargetMissing(config, 'Tailscale', injected: 'Tailscale'),
      isFalse,
    );
    expect(
      isRoutingTargetMissing(config, 'Other', injected: 'Tailscale'),
      isTrue,
    );
    expect(isRoutingTargetMissing(config, 'DIRECT'), isFalse);
  });
}
