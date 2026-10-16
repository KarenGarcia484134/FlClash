import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';
import '../helpers/test_profiles.dart';

const _profileId = 1;

CustomRouting _routing(int id, String label, {bool enabled = true}) {
  return CustomRouting(
    id: id,
    label: label,
    enabled: enabled,
    target: 'Proxy',
    conditions: const [
      CustomRoutingCondition(values: ['example.com']),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  setUp(() {
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(
          () => TestProfiles([
            Profile.normal(label: 'p').copyWith(id: _profileId),
          ]),
        ),
        currentProfileIdProvider.overrideWithBuild((_, _) => _profileId),
        clashConfigProvider(_profileId).overrideWith(
          (_) async => const ClashConfig(
            proxyGroups: [
              ProxyGroup(id: 1, name: 'Proxy', type: GroupType.Selector),
            ],
          ),
        ),
        customRoutingsProvider.overrideWith(
          () => TestCustomRoutings([
            _routing(10, 'alpha'),
            _routing(11, 'beta', enabled: false),
          ]),
        ),
        profileCustomRoutingIdsProvider(
          _profileId,
        ).overrideWith(TestProfileCustomRoutingIds.new),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(
          child: ProfileIdProvider(
            profileId: _profileId,
            child: CustomScrollView(slivers: [CustomRoutingContent()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers only the switched-on entries for selection', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsNothing);
    expect(
      find.text(currentAppLocalizations.goToConfigureCustomRouting),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an entry selects it for the profile', (tester) async {
    await pump(tester);

    await tester.tap(find.text('alpha'));
    await tester.pumpAndSettle();

    expect(container.read(profileCustomRoutingIdsProvider(_profileId)).value, [
      10,
    ]);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
