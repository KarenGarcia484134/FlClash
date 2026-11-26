import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/listeners.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<ProviderContainer> _pumpListeners(
  WidgetTester tester,
  List<InboundListenerProps> items,
) async {
  final container = ProviderContainer(
    overrides: [
      listenersSettingProvider.overrideWithBuild(
        (_, _) => ListenersProps(items: items),
      ),
    ],
  );
  addTearDown(container.dispose);
  globalState.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TestApp(child: ListenersView()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    loadAppLocalizations(const Locale('en'));
  });

  testWidgets('lists listeners with their address and conflicts', (
    tester,
  ) async {
    await _pumpListeners(tester, const [
      InboundListenerProps(id: '1', name: 'socks', port: 7891),
      InboundListenerProps(id: '2', name: 'clash', port: 7890),
    ]);
    expect(find.byType(SliverPrismList), findsOneWidget);
    expect(find.textContaining('socks5://127.0.0.1:7891'), findsOneWidget);
    expect(
      find.textContaining(currentAppLocalizations.listenerAppPort),
      findsOneWidget,
    );
  });

  testWidgets('searches listeners by metadata and hides passwords', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    await _pumpListeners(tester, const [
      InboundListenerProps(
        id: '1',
        name: 'Office',
        type: ListenerType.socks,
        listen: listenerAnyAddress,
        port: 1080,
        proxy: 'HK-01',
        users: [ListenerUser(username: 'alice', password: 'secret-value')],
      ),
      InboundListenerProps(
        id: '2',
        name: 'Browser',
        type: ListenerType.http,
        port: 8080,
        rule: 'media',
      ),
    ]);

    expect(find.text(l.listenersEnable), findsOneWidget);

    await tester.tap(find.byTooltip(l.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'socks 1080 alice');
    await tester.pumpAndSettle();
    expect(find.text('Office · socks'), findsOneWidget);
    expect(find.text('Browser · http'), findsNothing);
    expect(find.text(l.listenersEnable), findsNothing);

    await tester.enterText(find.byType(TextField), 'secret-value');
    await tester.pumpAndSettle();
    expect(find.text(l.noSearchResults), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Office · socks'), findsOneWidget);
    expect(find.text('Browser · http'), findsOneWidget);
    expect(find.text(l.listenersEnable), findsOneWidget);
  });

  testWidgets('filters listeners by status and protocol with removable chips', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    await _pumpListeners(tester, const [
      InboundListenerProps(
        id: '1',
        name: 'Active Socks',
        type: ListenerType.socks,
        port: 7891,
      ),
      InboundListenerProps(
        id: '2',
        name: 'Off HTTP',
        type: ListenerType.http,
        port: 7892,
        enabled: false,
      ),
      InboundListenerProps(
        id: '3',
        name: 'Conflict Mixed',
        type: ListenerType.mixed,
        port: 7890,
      ),
    ]);

    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.listenerFilterIssues));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, l.listenerFilterIssues), findsOneWidget);
    expect(find.text('Conflict Mixed · mixed'), findsOneWidget);
    expect(find.text('Active Socks · socks'), findsNothing);
    expect(find.text('Off HTTP · http'), findsNothing);

    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.protocol));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ListenerType.http.name));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, l.listenerFilterIssues), findsOneWidget);
    expect(find.widgetWithText(Chip, ListenerType.http.name), findsOneWidget);
    expect(find.text(l.noSearchResults), findsOneWidget);

    await tester.tap(find.widgetWithText(Chip, l.listenerFilterIssues));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, l.listenerFilterIssues), findsNothing);
    expect(find.text('Off HTTP · http'), findsOneWidget);
    expect(find.text('Active Socks · socks'), findsNothing);

    await tester.tap(find.widgetWithText(Chip, ListenerType.http.name));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNothing);
    expect(find.text('Active Socks · socks'), findsOneWidget);
    expect(find.text('Off HTTP · http'), findsOneWidget);
    expect(find.text('Conflict Mixed · mixed'), findsOneWidget);
  });

  testWidgets('the editor warns about LAN and rejects a taken port', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    globalState.container = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ListenerEditView()),
      ),
    );
    await tester.pumpAndSettle();
    final l = currentAppLocalizations;
    expect(find.text(l.listenerLanWarning), findsNothing);
    await tester.tap(find.text(l.listenerLan));
    await tester.pumpAndSettle();
    expect(find.text(l.listenerLanWarning), findsOneWidget);
    final port = find.widgetWithText(TextFormField, l.port);
    await tester.enterText(port, '7890');
    await tester.pumpAndSettle();
    expect(find.text(l.listenerAppPort), findsOneWidget);
  });
}
