import 'dart:async';

import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/listeners.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

class _TestProxyGroups extends ProxyGroups {
  _TestProxyGroups(this.stream);

  final Stream<List<ProxyGroup>> stream;

  @override
  Stream<List<ProxyGroup>> build(int profileId) => stream;

  @override
  bool updateShouldNotify(
    AsyncValue<List<ProxyGroup>> previous,
    AsyncValue<List<ProxyGroup>> next,
  ) => previous != next;
}

class _TestCustomProxies extends CustomProxies {
  _TestCustomProxies(this.stream);

  final Stream<List<CustomProxy>> stream;

  @override
  Stream<List<CustomProxy>> build() => stream;

  @override
  bool updateShouldNotify(
    AsyncValue<List<CustomProxy>> previous,
    AsyncValue<List<CustomProxy>> next,
  ) => previous != next;
}

Future<ProviderContainer> _pumpListeners(
  WidgetTester tester,
  List<InboundListenerProps> items, {
  int? profileId,
  Profile? profile,
  Future<ClashConfig> Function(Ref ref)? clashConfig,
  ProxyGroups Function()? proxyGroups,
  CustomProxies Function()? customProxies,
}) async {
  final container = ProviderContainer(
    overrides: [
      listenersSettingProvider.overrideWithBuild(
        (_, _) => ListenersProps(items: items),
      ),
      if (profileId != null)
        currentProfileIdProvider.overrideWithBuild((_, _) => profileId),
      if (profileId != null && profile != null)
        profileProvider(profileId).overrideWithValue(profile),
      if (profileId != null && clashConfig != null)
        clashConfigProvider(profileId).overrideWith(clashConfig),
      if (profileId != null && proxyGroups != null)
        proxyGroupsProvider(profileId).overrideWith(proxyGroups),
      if (customProxies != null)
        customProxiesProvider.overrideWith(customProxies),
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

  testWidgets('keeps global toggle visible when listener list is empty', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    final container = await _pumpListeners(tester, const []);
    expect(find.text(l.listenersEnable), findsOneWidget);
    expect(find.text(l.listenersDesc), findsOneWidget);
    expect(find.text(l.nullTip(l.listeners)), findsOneWidget);
    expect(container.read(listenersSettingProvider).enable, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(container.read(listenersSettingProvider).enable, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(container.read(listenersSettingProvider).enable, isTrue);

    await tester.tap(find.byTooltip(l.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'socks');
    await tester.pumpAndSettle();
    expect(find.text(l.noSearchResults), findsOneWidget);
    expect(find.text(l.listenersEnable), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text(l.listenersEnable), findsOneWidget);
    expect(find.text(l.nullTip(l.listeners)), findsOneWidget);
  });

  testWidgets('keeps global toggle visible after removing the last listener', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    final container = await _pumpListeners(tester, const [
      InboundListenerProps(id: '1', name: 'Only', port: 7891),
    ]);
    container.read(listenersSettingProvider.notifier).remove('1');
    await tester.pumpAndSettle();

    expect(find.text(l.listenersEnable), findsOneWidget);
    expect(find.text(l.listenersDesc), findsOneWidget);
    expect(find.text(l.nullTip(l.listeners)), findsOneWidget);
    expect(container.read(listenersSettingProvider).enable, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(container.read(listenersSettingProvider).enable, isFalse);
  });

  testWidgets('defers profile issue checks while normal profile is loading', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    final completer = Completer<ClashConfig>();
    await _pumpListeners(
      tester,
      const [
        InboundListenerProps(
          id: '1',
          name: 'Outbound Proxy',
          port: 7891,
          proxy: 'HK-01',
        ),
        InboundListenerProps(
          id: '2',
          name: 'Sub Rule',
          port: 7892,
          rule: 'video',
        ),
        InboundListenerProps(id: '3', name: 'Port Conflict', port: 7890),
      ],
      profileId: 1,
      profile: const Profile(id: 1, autoUpdateDuration: Duration.zero),
      clashConfig: (_) => completer.future,
    );

    expect(find.textContaining(l.listenerMissingTarget), findsNothing);
    expect(find.textContaining(l.listenerMissingRule), findsNothing);
    expect(find.textContaining(l.listenerAppPort), findsOneWidget);

    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.listenerFilterIssues));
    await tester.pumpAndSettle();

    expect(find.text('Port Conflict · mixed'), findsOneWidget);
    expect(find.text('Outbound Proxy · mixed'), findsNothing);
    expect(find.text('Sub Rule · mixed'), findsNothing);
  });

  testWidgets('defers profile issue checks when normal profile load errors', (
    tester,
  ) async {
    final l = currentAppLocalizations;
    await _pumpListeners(
      tester,
      const [
        InboundListenerProps(
          id: '1',
          name: 'Outbound Proxy',
          port: 7891,
          proxy: 'HK-01',
        ),
        InboundListenerProps(
          id: '2',
          name: 'Sub Rule',
          port: 7892,
          rule: 'video',
        ),
        InboundListenerProps(id: '3', name: 'Port Conflict', port: 7890),
      ],
      profileId: 1,
      profile: const Profile(id: 1, autoUpdateDuration: Duration.zero),
      clashConfig: (_) => Future<ClashConfig>.error(Exception('load failed')),
    );

    expect(find.textContaining(l.listenerMissingTarget), findsNothing);
    expect(find.textContaining(l.listenerMissingRule), findsNothing);
    expect(find.textContaining(l.listenerAppPort), findsOneWidget);

    await tester.tap(find.byTooltip(l.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.listenerFilterIssues));
    await tester.pumpAndSettle();

    expect(find.text('Port Conflict · mixed'), findsOneWidget);
    expect(find.text('Outbound Proxy · mixed'), findsNothing);
    expect(find.text('Sub Rule · mixed'), findsNothing);
  });

  testWidgets(
    'defers profile issue checks when custom profile providers are not ready',
    (tester) async {
      final l = currentAppLocalizations;
      final groupsController = StreamController<List<ProxyGroup>>();
      addTearDown(groupsController.close);
      await _pumpListeners(
        tester,
        const [
          InboundListenerProps(
            id: '1',
            name: 'Custom Outbound',
            port: 7891,
            proxy: 'Group-A',
          ),
          InboundListenerProps(id: '2', name: 'Port Conflict', port: 7890),
        ],
        profileId: 2,
        profile: const Profile(
          id: 2,
          type: ProfileType.custom,
          autoUpdateDuration: Duration.zero,
        ),
        proxyGroups: () => _TestProxyGroups(groupsController.stream),
        customProxies: () => _TestCustomProxies(
          Stream<List<CustomProxy>>.error(Exception('db error')),
        ),
      );

      expect(find.textContaining(l.listenerMissingTarget), findsNothing);
      expect(find.textContaining(l.listenerAppPort), findsOneWidget);

      await tester.tap(find.byTooltip(l.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.listenerFilterIssues));
      await tester.pumpAndSettle();

      expect(find.text('Port Conflict · mixed'), findsOneWidget);
      expect(find.text('Custom Outbound · mixed'), findsNothing);
    },
  );
}
