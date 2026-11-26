import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/connection/connection.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';
import '../helpers/test_profiles.dart';

const _profileId = 7;

class _FakeCustomRoutings extends CustomRoutings {
  final List<CustomRouting> initial;
  final List<CustomRouting> appended = [];
  final List<CustomRouting> updated = [];

  _FakeCustomRoutings([this.initial = const []]);

  @override
  Stream<List<CustomRouting>> build() => Stream.value(initial);

  @override
  Future<void> append(CustomRouting routing) async {
    appended.add(routing);
    state = AsyncData([...value, routing]);
  }

  @override
  void put(CustomRouting routing) {
    updated.add(routing);
    final next = List<CustomRouting>.from(value);
    final index = next.indexWhere((item) => item.id == routing.id);
    if (index == -1) {
      next.add(routing);
    } else {
      next[index] = routing;
    }
    state = AsyncData(next);
  }
}

TrackerInfo _tracker({
  String host = '',
  String destinationIP = '',
  String destinationPort = '',
  String remoteDestination = '',
  String process = '',
  String processPath = '',
  List<String> chains = const ['DIRECT'],
}) {
  return TrackerInfo(
    id: 'conn-1',
    start: DateTime(2026, 1, 1, 12, 0),
    metadata: Metadata(
      network: 'tcp',
      host: host,
      destinationIP: destinationIP,
      destinationPort: destinationPort,
      remoteDestination: remoteDestination,
      process: process,
      processPath: processPath,
    ),
    chains: chains,
    rule: 'MATCH',
    rulePayload: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    loadAppLocalizations(const Locale('en'));
  });

  group('extractTrackerRoutingCandidates', () {
    test('extracts domain, suffix, IPv4, process, and port in order', () {
      final info = _tracker(
        host: 'API.Example.COM.',
        destinationIP: '93.184.216.34',
        destinationPort: '443',
        process: 'curl',
      );

      final candidates = extractTrackerRoutingCandidates(info);
      expect(candidates, const [
        TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN,
          value: 'api.example.com',
        ),
        TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          value: 'example.com',
        ),
        TrackerRoutingCandidate(
          ruleAction: RuleAction.IP_CIDR,
          value: '93.184.216.34/32',
          noResolve: true,
        ),
        TrackerRoutingCandidate(
          ruleAction: RuleAction.PROCESS_NAME,
          value: 'curl',
        ),
        TrackerRoutingCandidate(ruleAction: RuleAction.DST_PORT, value: '443'),
      ]);
      expect(
        defaultTrackerRoutingCandidate(candidates),
        const TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          value: 'example.com',
        ),
      );
    });

    test('still offers DOMAIN-SUFFIX for 2-label host', () {
      final info = _tracker(host: 'example.com');
      final candidates = extractTrackerRoutingCandidates(info);
      expect(candidates, const [
        TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN,
          value: 'example.com',
        ),
        TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          value: 'example.com',
        ),
      ]);
      expect(
        defaultTrackerRoutingCandidate(candidates)?.ruleAction,
        RuleAction.DOMAIN_SUFFIX,
      );
    });

    test('handles multi-part public suffixes sensibly', () {
      final sub = extractTrackerRoutingCandidates(
        _tracker(host: 'api.service.co.uk'),
      );
      expect(
        sub.firstWhere((item) => item.ruleAction == RuleAction.DOMAIN_SUFFIX),
        const TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          value: 'service.co.uk',
        ),
      );

      final root = extractTrackerRoutingCandidates(
        _tracker(host: 'service.co.uk'),
      );
      expect(
        root.firstWhere((item) => item.ruleAction == RuleAction.DOMAIN_SUFFIX),
        const TrackerRoutingCandidate(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          value: 'service.co.uk',
        ),
      );
    });

    test('handles IPv4 and IPv6 literals without creating DOMAIN rules', () {
      final v4 = extractTrackerRoutingCandidates(
        _tracker(host: '198.51.100.10'),
      );
      expect(v4, const [
        TrackerRoutingCandidate(
          ruleAction: RuleAction.IP_CIDR,
          value: '198.51.100.10/32',
          noResolve: true,
        ),
      ]);
      expect(
        defaultTrackerRoutingCandidate(v4)?.ruleAction,
        RuleAction.IP_CIDR,
      );

      final v6 = extractTrackerRoutingCandidates(
        _tracker(host: '[2001:db8::1]', destinationIP: '2001:db8::2'),
      );
      expect(v6, const [
        TrackerRoutingCandidate(
          ruleAction: RuleAction.IP_CIDR6,
          value: '2001:db8::2/128',
          noResolve: true,
        ),
      ]);
      expect(
        defaultTrackerRoutingCandidate(v6)?.ruleAction,
        RuleAction.IP_CIDR6,
      );
    });

    test('falls back to remoteDestination IP and processPath basename', () {
      final unix = extractTrackerRoutingCandidates(
        _tracker(
          remoteDestination: '198.51.100.20:8443',
          processPath: '/usr/local/bin/my-app',
        ),
      );
      expect(unix, const [
        TrackerRoutingCandidate(
          ruleAction: RuleAction.IP_CIDR,
          value: '198.51.100.20/32',
          noResolve: true,
        ),
        TrackerRoutingCandidate(
          ruleAction: RuleAction.PROCESS_NAME,
          value: 'my-app',
        ),
      ]);

      final win = extractTrackerRoutingCandidates(
        _tracker(processPath: r'C:\Program Files\Demo\client.exe'),
      );
      expect(win, const [
        TrackerRoutingCandidate(
          ruleAction: RuleAction.PROCESS_NAME,
          value: 'client.exe',
        ),
      ]);
      expect(
        defaultTrackerRoutingCandidate(win)?.ruleAction,
        RuleAction.PROCESS_NAME,
      );
    });

    test('ignores invalid ports and returns empty for empty metadata', () {
      expect(
        extractTrackerRoutingCandidates(_tracker(destinationPort: '0')),
        isEmpty,
      );
      expect(
        extractTrackerRoutingCandidates(_tracker(destinationPort: '70000')),
        isEmpty,
      );
      expect(
        extractTrackerRoutingCandidates(_tracker(destinationPort: 'https')),
        isEmpty,
      );
      expect(extractTrackerRoutingCandidates(_tracker()), isEmpty);
      expect(defaultTrackerRoutingCandidate(const []), isNull);
    });
  });

  group('mergeCandidatesIntoRouting & target suggestions', () {
    test(
      'merges into matching condition and deduplicates case-insensitively',
      () {
        const existing = CustomRouting(
          id: 1,
          label: 'Work',
          target: 'Proxy',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN_SUFFIX,
              values: ['Example.COM'],
            ),
          ],
        );

        final allDup = mergeCandidatesIntoRouting(existing, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'example.com',
          ),
        ]);
        expect(allDup.addedCount, 0);
        expect(allDup.duplicateCount, 1);
        expect(allDup.routing, existing);

        final mixed = mergeCandidatesIntoRouting(existing, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'example.com',
          ),
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'other.test',
          ),
          TrackerRoutingCandidate(
            ruleAction: RuleAction.IP_CIDR,
            value: '198.51.100.1/32',
            noResolve: true,
          ),
        ]);
        expect(mixed.addedCount, 2);
        expect(mixed.duplicateCount, 1);
        expect(mixed.routing.conditions, hasLength(2));
        expect(mixed.routing.conditions.first.values, [
          'Example.COM',
          'other.test',
        ]);
        expect(
          mixed.routing.conditions.last,
          const CustomRoutingCondition(
            ruleAction: RuleAction.IP_CIDR,
            values: ['198.51.100.1/32'],
            noResolve: true,
          ),
        );
      },
    );

    test('suggests DIRECT, REJECT, and outermost proxy group from chains', () {
      final info = _tracker(
        host: 'api.example.com',
        chains: const ['Node-A', 'Auto', 'Proxy'],
      );
      expect(
        quickRoutingTargetSuggestions(
          info,
          groupNames: const ['Auto', 'Proxy'],
        ),
        const ['DIRECT', 'REJECT', 'Proxy'],
      );
      expect(
        defaultQuickRoutingTarget(info, groupNames: const ['Auto', 'Proxy']),
        'Proxy',
      );
      expect(
        defaultQuickRoutingTarget(_tracker(chains: const ['DIRECT'])),
        'DIRECT',
      );
    });
  });

  group('QuickCustomRouting widgets & flows', () {
    late _FakeCustomRoutings fakeRoutings;
    late ProviderContainer container;

    void createContainer({
      List<CustomRouting> routings = const [],
      List<int> selectedIds = const [],
      int? profileId = _profileId,
    }) {
      fakeRoutings = _FakeCustomRoutings(routings);
      container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(
            () => TestProfiles([
              Profile.normal(label: 'main').copyWith(id: _profileId),
            ]),
          ),
          currentProfileIdProvider.overrideWithBuild((_, _) => profileId),
          clashConfigProvider(_profileId).overrideWith(
            (_) async => const ClashConfig(
              proxyGroups: [
                ProxyGroup(id: 1, name: 'Proxy', type: GroupType.Selector),
              ],
            ),
          ),
          groupsProvider.overrideWithBuild(
            (_, _) => const [Group(type: GroupType.Selector, name: 'Proxy')],
          ),
          customRoutingsProvider.overrideWith(() => fakeRoutings),
          profileCustomRoutingIdsProvider(
            _profileId,
          ).overrideWith(() => TestProfileCustomRoutingIds(selectedIds)),
        ],
      );
      addTearDown(container.dispose);
      if (profileId != null) {
        container.listen(profileCustomRoutingIdsProvider(profileId), (_, _) {});
      }
      globalState.container = container;
    }

    testWidgets('creates a new custom routing and enables it for profile', (
      tester,
    ) async {
      createContainer();
      final info = _tracker(
        host: 'api.example.com',
        destinationIP: '93.184.216.34',
        chains: const ['Node-1', 'Proxy'],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DOMAIN-SUFFIX:example.com'), findsOneWidget);
      expect(find.text('DOMAIN:api.example.com'), findsOneWidget);
      expect(find.text('IP-CIDR:93.184.216.34/32'), findsOneWidget);

      await tester.tap(find.text('REJECT'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(currentAppLocalizations.save));
      await tester.pumpAndSettle();

      expect(fakeRoutings.appended, hasLength(1));
      final created = fakeRoutings.appended.single;
      expect(created.label, 'example.com');
      expect(created.target, 'REJECT');
      expect(created.conditions, const [
        CustomRoutingCondition(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          values: ['example.com'],
        ),
      ]);
      expect(
        container.read(profileCustomRoutingIdsProvider(_profileId)).value,
        contains(created.id),
      );
    });

    testWidgets('respects Use in current profile switch when turned off', (
      tester,
    ) async {
      createContainer();
      final info = _tracker(host: 'api.example.com');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(currentAppLocalizations.save));
      await tester.pumpAndSettle();

      expect(fakeRoutings.appended, hasLength(1));
      expect(
        container.read(profileCustomRoutingIdsProvider(_profileId)).value,
        isEmpty,
      );
    });

    testWidgets(
      'supports multi-selecting candidates and editing single value',
      (tester) async {
        createContainer();
        final info = _tracker(
          host: 'api.example.com',
          destinationIP: '93.184.216.34',
          chains: const ['Node-1', 'Proxy'],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('IP-CIDR:93.184.216.34/32'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();

        expect(fakeRoutings.appended, hasLength(1));
        expect(fakeRoutings.appended.single.conditions, const [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            values: ['example.com'],
          ),
          CustomRoutingCondition(
            ruleAction: RuleAction.IP_CIDR,
            values: ['93.184.216.34/32'],
            noResolve: true,
          ),
        ]);
      },
    );

    testWidgets('edits single candidate value and syncs untouched name', (
      tester,
    ) async {
      createContainer();
      final info = _tracker(host: 'api.example.com');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'sub.example.com',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(currentAppLocalizations.save));
      await tester.pumpAndSettle();

      expect(fakeRoutings.appended, hasLength(1));
      expect(fakeRoutings.appended.single.label, 'sub.example.com');
      expect(fakeRoutings.appended.single.conditions, const [
        CustomRoutingCondition(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          values: ['sub.example.com'],
        ),
      ]);
    });

    testWidgets('appends to an existing routing and skips duplicates', (
      tester,
    ) async {
      const existingA = CustomRouting(
        id: 101,
        label: 'Streaming',
        enabled: false,
        logic: CustomRoutingLogic.and,
        target: 'Proxy',
        conditions: [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            values: ['media.test'],
          ),
        ],
      );
      const existingB = CustomRouting(
        id: 102,
        label: 'AlreadyHas',
        target: 'DIRECT',
        conditions: [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            values: ['example.com'],
          ),
        ],
      );
      createContainer(routings: const [existingA, existingB]);
      final info = _tracker(host: 'api.example.com');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(currentAppLocalizations.quickRoutingModeAppend),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(currentAppLocalizations.quickRoutingAndLogicNote),
        findsOneWidget,
      );

      await tester.tap(find.text('AlreadyHas'));
      await tester.pumpAndSettle();
      expect(
        find.text(currentAppLocalizations.quickRoutingAlreadyExists),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip(currentAppLocalizations.save));
      await tester.pumpAndSettle();
      expect(fakeRoutings.updated, isEmpty);

      await tester.tap(find.text('Streaming'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(currentAppLocalizations.save));
      await tester.pumpAndSettle();

      expect(fakeRoutings.updated, hasLength(1));
      final updated = fakeRoutings.updated.single;
      expect(updated.id, 101);
      expect(updated.enabled, isTrue);
      expect(updated.conditions.single.values, ['media.test', 'example.com']);
      expect(
        container.read(profileCustomRoutingIdsProvider(_profileId)).value,
        contains(101),
      );
    });

    testWidgets(
      'entry points in TrackerInfoDetailView and trackerDetailMenuItems work',
      (tester) async {
        createContainer();
        final info = _tracker(host: 'api.example.com', process: 'curl');
        final empty = _tracker();

        List<PopupMenuItem>? populatedItems;
        List<PopupMenuItem>? emptyItems;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TestApp(
              child: Consumer(
                builder: (context, ref, _) {
                  populatedItems = trackerDetailMenuItems(context, ref, info);
                  emptyItems = trackerDetailMenuItems(context, ref, empty);
                  return TrackerInfoDetailView(trackerInfo: info);
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          populatedItems!.any(
            (item) => item.label == currentAppLocalizations.quickRoutingCreate,
          ),
          isTrue,
        );
        expect(
          emptyItems!.any(
            (item) => item.label == currentAppLocalizations.quickRoutingCreate,
          ),
          isFalse,
        );

        await tester.tap(find.text(currentAppLocalizations.connectionInfo));
        await tester.pumpAndSettle();

        expect(find.byType(QuickCustomRoutingSection), findsOneWidget);
        expect(
          find.text(currentAppLocalizations.quickRoutingCreate),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.text(currentAppLocalizations.quickRoutingCreate),
        );
        await tester.tap(find.text(currentAppLocalizations.quickRoutingCreate));
        await tester.pumpAndSettle();

        expect(find.byType(QuickCustomRoutingSheet), findsOneWidget);
      },
    );

    testWidgets('QuickCustomRoutingSection hides when no candidates exist', (
      tester,
    ) async {
      createContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            child: QuickCustomRoutingSection(trackerInfo: _tracker()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(currentAppLocalizations.quickRoutingCreate),
        findsNothing,
      );
    });
  });
}
