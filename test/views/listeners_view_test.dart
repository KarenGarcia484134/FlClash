import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/listeners.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  testWidgets('lists listeners with their address and conflicts', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        listenersSettingProvider.overrideWithBuild(
          (_, _) => const ListenersProps(
            items: [
              InboundListenerProps(id: '1', name: 'socks', port: 7891),
              InboundListenerProps(id: '2', name: 'clash', port: 7890),
            ],
          ),
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
    expect(find.textContaining('socks5://127.0.0.1:7891'), findsOneWidget);
    expect(
      find.textContaining(AppLocalizations.current.listenerAppPort),
      findsOneWidget,
    );
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
    final l = AppLocalizations.current;
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
