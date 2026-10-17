import 'dart:convert';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/dashboard/widgets/custom_routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new users get the custom routing card', () {
    expect(
      const AppSettingProps().dashboardWidgets,
      contains(DashboardWidget.customRouting),
    );
  });

  test('existing users get it once, appended', () {
    final props = AppSettingProps.fromJson({
      'dashboardWidgets': ['networkSpeed', 'outboundMode'],
    });
    expect(props.dashboardWidgets, [
      DashboardWidget.currentOutbound,
      DashboardWidget.networkSpeed,
      DashboardWidget.outboundMode,
      DashboardWidget.customRouting,
      DashboardWidget.restartCore,
    ]);
    expect(
      props.seededDashboardWidgets,
      containsAll(['customRouting', 'restartCore']),
    );
  });

  test('a removed card stays removed after the seed', () {
    final saved = AppSettingProps.fromJson({
      'dashboardWidgets': ['networkSpeed'],
      'seededDashboardWidgets': ['customRouting', 'restartCore'],
    });
    expect(saved.dashboardWidgets, [
      DashboardWidget.currentOutbound,
      DashboardWidget.networkSpeed,
    ]);
  });

  test('users seeded with the routing card get the restart card once', () {
    final saved = AppSettingProps.fromJson({
      'dashboardWidgets': ['networkSpeed'],
      'seededDashboardWidgets': ['customRouting'],
    });
    expect(saved.dashboardWidgets, [
      DashboardWidget.currentOutbound,
      DashboardWidget.networkSpeed,
      DashboardWidget.restartCore,
    ]);
    expect(saved.seededDashboardWidgets, contains('restartCore'));
  });

  test('round trip keeps the seed record', () {
    final first = AppSettingProps.fromJson({
      'dashboardWidgets': ['networkSpeed'],
    });
    final json = jsonDecode(jsonEncode(first)) as Map<String, dynamic>
      ..['dashboardWidgets'] = ['networkSpeed'];
    final again = AppSettingProps.fromJson(json);
    expect(again.dashboardWidgets, [
      DashboardWidget.currentOutbound,
      DashboardWidget.networkSpeed,
    ]);
  });

  test('card counts entries switched on and selected', () {
    final counts = customRoutingCounts(
      [(id: 1, enabled: true), (id: 2, enabled: false), (id: 3, enabled: true)],
      [1, 2],
    );
    expect(counts.applied, 1);
    expect(counts.total, 3);
  });
}
