import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

final _nodes = [for (var i = 1; i <= sheetSearchMinItemCount; i++) 'Node $i'];

void main() {
  testWidgets('a desktop sheet returns an item picked from search results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? result;
    var closed = false;
    await tester.pumpWidget(
      TestApp(
        wrapInProviderScope: true,
        overrides: [
          viewSizeProvider.overrideWithBuild((_, _) => const Size(1400, 900)),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showSheet<String>(
                  context: context,
                  builder: (sheetContext) => SelectionSheet<String>(
                    title: 'Outbound',
                    sections: [SelectionSection(items: _nodes)],
                    labelBuilder: (item) => item,
                    selectedOf: (_) => null,
                    onSelected: (item) => Navigator.of(sheetContext).pop(item),
                  ),
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    if (find.byType(TextField).evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField), 'Node 7');
    await tester.pumpAndSettle();
    expect(find.text('Node 2'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Node 7'),
      ),
    );
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, 'Node 7');
  });

  testWidgets('a pick that keeps the sheet open keeps its search layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picked = <String>[];
    var closed = false;
    await tester.pumpWidget(
      TestApp(
        wrapInProviderScope: true,
        overrides: [
          viewSizeProvider.overrideWithBuild((_, _) => const Size(1400, 900)),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showSheet<void>(
                  context: context,
                  builder: (_) => SelectionSheet<String>(
                    title: 'Outbound',
                    sections: [SelectionSection(items: _nodes)],
                    labelBuilder: (item) => item,
                    selectedOf: (_) => null,
                    onSelected: picked.add,
                  ),
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (find.byType(TextField).evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField), 'Node 7');
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Node 7'),
      ),
    );
    await tester.pumpAndSettle();
    expect(picked, ['Node 7']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(find.text('Node 2'), findsOneWidget);
  });
}
