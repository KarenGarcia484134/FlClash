import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/custom_routing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';

void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  testWidgets('shows how many routings the profile uses', (tester) async {
    final container = ProviderContainer(
      overrides: [
        currentProfileIdProvider.overrideWithBuild((_, _) => 1),
        customRoutingsProvider.overrideWith(
          () => TestCustomRoutings(const [
            CustomRouting(id: 10, label: 'a'),
            CustomRouting(id: 11, label: 'b'),
          ]),
        ),
        profileCustomRoutingIdsProvider(
          1,
        ).overrideWith(() => TestProfileCustomRoutingIds([10])),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: CustomRoutingCard()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizations.current.customRoutingCardCount(1, 2)),
      findsOneWidget,
    );
  });
}
