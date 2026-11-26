import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';

class _NoopSetupAction extends SetupAction {
  @override
  void autoApplyProfile() {}
}

final _sampleRoutings = [
  const CustomRouting(
    id: 1,
    label: 'Work LAN',
    target: 'DIRECT',
    logic: CustomRoutingLogic.and,
    conditions: [
      CustomRoutingCondition(
        ruleAction: RuleAction.IP_CIDR,
        values: ['10.0.0.0/8'],
        noResolve: true,
      ),
    ],
  ),
  const CustomRouting(
    id: 2,
    label: 'Streaming',
    target: 'JP-Node',
    conditions: [
      CustomRoutingCondition(
        ruleAction: RuleAction.DOMAIN_SUFFIX,
        values: ['video.example.com'],
      ),
    ],
  ),
  const CustomRouting(
    id: 3,
    label: 'Legacy Rule',
    enabled: false,
    target: 'REJECT',
    conditions: [
      CustomRoutingCondition(
        ruleAction: RuleAction.PROCESS_NAME,
        values: ['old-app'],
      ),
    ],
  ),
];

Future<ProviderContainer> _pumpRoutings(
  WidgetTester tester, {
  required List<CustomRouting> routings,
  int? profileId = 1,
  List<int> appliedIds = const [1],
}) async {
  final container = ProviderContainer(
    overrides: [
      setupActionProvider.overrideWith(_NoopSetupAction.new),
      currentProfileIdProvider.overrideWithBuild((_, _) => profileId),
      customRoutingsProvider.overrideWith(() => TestCustomRoutings(routings)),
      if (profileId != null)
        profileCustomRoutingIdsProvider(
          profileId,
        ).overrideWith(() => TestProfileCustomRoutingIds(appliedIds)),
    ],
  );
  addTearDown(container.dispose);
  globalState.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TestApp(child: CustomRoutingsView()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    loadAppLocalizations(const Locale('en'));
  });

  testWidgets('searches custom routings and disables reorder while searching', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    await _pumpRoutings(tester, routings: _sampleRoutings);

    expect(find.byType(PrismReorderableListView), findsOneWidget);
    expect(find.byType(SortableItem), findsNWidgets(3));
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).canSort, isTrue);

    await tester.tap(find.byTooltip(l.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'VIDEO.EXAMPLE.COM jp-node');
    await tester.pumpAndSettle();
    expect(find.text('Streaming'), findsOneWidget);
    expect(find.text('Work LAN'), findsNothing);
    expect(find.text('Legacy Rule'), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).canSort, isFalse);
    expect(find.byType(PrismListView), findsOneWidget);
    expect(find.byType(PrismReorderableListView), findsNothing);
    expect(find.byType(SortableItem), findsNothing);

    await tester.enterText(find.byType(TextField), 'no-resolve 10.0.0.0/8');
    await tester.pumpAndSettle();
    expect(find.text('Work LAN'), findsOneWidget);
    expect(find.text('Streaming'), findsNothing);

    await tester.enterText(find.byType(TextField), 'missing-entry');
    await tester.pumpAndSettle();
    expect(find.text(l.noSearchResults), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.byType(PrismReorderableListView), findsOneWidget);
    expect(find.byType(SortableItem), findsNWidgets(3));
  });

  testWidgets('filters by status with removable chip and hides applied option '
      'without a profile', (tester) async {
    final l = currentAppLocalizations;
    await _pumpRoutings(tester, routings: _sampleRoutings);

    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.routingFilterApplied));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, l.routingFilterApplied), findsOneWidget);
    expect(find.text('Work LAN'), findsOneWidget);
    expect(find.text('Streaming'), findsNothing);
    expect(find.text('Legacy Rule'), findsNothing);
    expect(find.byType(PrismReorderableListView), findsNothing);
    expect(find.byType(SortableItem), findsNothing);

    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.disabled));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, l.disabled), findsOneWidget);
    expect(find.text('Legacy Rule'), findsOneWidget);
    expect(find.text('Work LAN'), findsNothing);

    await tester.tap(find.widgetWithText(Chip, l.disabled));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNothing);
    expect(find.text('Work LAN'), findsOneWidget);
    expect(find.text('Streaming'), findsOneWidget);
    expect(find.text('Legacy Rule'), findsOneWidget);
    expect(find.byType(PrismReorderableListView), findsOneWidget);

    await _pumpRoutings(tester, routings: _sampleRoutings, profileId: null);
    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    expect(find.text(l.routingFilterApplied), findsNothing);
  });
}
