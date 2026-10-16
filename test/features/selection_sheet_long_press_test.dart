import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  testWidgets('long press runs its action without selecting', (tester) async {
    final selected = <String>[];
    final pressed = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: TestApp(
          child: SelectionSheet<String>(
            title: 'pick',
            sections: const [
              SelectionSection(items: ['HK', 'JP']),
            ],
            labelBuilder: (item) => item,
            trailingBuilder: (item) => Text('$item-badge'),
            selectedOf: (_) => null,
            onSelected: selected.add,
            onLongPress: pressed.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HK-badge'), findsOneWidget);
    await tester.longPress(find.text('HK'));
    await tester.pumpAndSettle();
    expect(pressed, ['HK']);
    expect(selected, isEmpty);
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    expect(selected, ['JP']);
  });
}
