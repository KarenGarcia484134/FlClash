import 'dart:async';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
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

typedef _SaveSelectionCall = ({
  CustomRouting routing,
  int? applyProfileId,
  bool append,
});

class _FakeCustomRoutings extends TestCustomRoutings {
  final List<_SaveSelectionCall> saveCalls = [];
  Completer<void>? pendingSave;

  _FakeCustomRoutings([super.initial]);

  @override
  Future<void> saveWithSelection(
    CustomRouting routing, {
    int? applyProfileId,
    bool append = false,
  }) async {
    final link = ref.keepAlive();
    try {
      saveCalls.add((
        routing: routing,
        applyProfileId: applyProfileId,
        append: append,
      ));
      if (pendingSave != null) {
        await pendingSave!.future;
      }
      await super.saveWithSelection(
        routing,
        applyProfileId: applyProfileId,
        append: append,
      );
    } finally {
      link.close();
    }
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

  group('validateTrackerRoutingValue', () {
    test('rejects empty, commas, newlines, control chars, and parens', () {
      for (final action in const [
        RuleAction.DOMAIN,
        RuleAction.DOMAIN_SUFFIX,
        RuleAction.IP_CIDR,
        RuleAction.IP_CIDR6,
        RuleAction.DST_PORT,
        RuleAction.PROCESS_NAME,
      ]) {
        expect(validateTrackerRoutingValue(action, ''), isNotNull);
        expect(validateTrackerRoutingValue(action, '   '), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a,b'), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a\nb'), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a\rb'), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a\n'), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a(b)'), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a)b'), isNotNull);
        expect(validateTrackerRoutingValue(action, 'a\x00b'), isNotNull);
      }
    });

    test('validates DST-PORT strictly in 1..65535', () {
      expect(validateTrackerRoutingValue(RuleAction.DST_PORT, '1'), isNull);
      expect(validateTrackerRoutingValue(RuleAction.DST_PORT, '443'), isNull);
      expect(validateTrackerRoutingValue(RuleAction.DST_PORT, '65535'), isNull);

      for (final bad in const [
        '0',
        '65536',
        '-1',
        '+443',
        '0443',
        '80-443',
        'https',
      ]) {
        expect(
          validateTrackerRoutingValue(RuleAction.DST_PORT, bad),
          isNotNull,
          reason: 'Expected DST-PORT to reject $bad',
        );
      }
    });

    test('validates IP-CIDR and IP-CIDR6 strictly', () {
      expect(
        validateTrackerRoutingValue(RuleAction.IP_CIDR, '93.184.216.34/32'),
        isNull,
      );
      expect(
        validateTrackerRoutingValue(RuleAction.IP_CIDR, '0.0.0.0/0'),
        isNull,
      );
      for (final bad in const [
        '93.184.216.34',
        '93.184.216.34/33',
        '93.184.216.34/08',
        '999.1.1.1/32',
        '2001:db8::/32',
        '192.168.1.1/24/32',
      ]) {
        expect(
          validateTrackerRoutingValue(RuleAction.IP_CIDR, bad),
          isNotNull,
          reason: 'Expected IP-CIDR to reject $bad',
        );
      }

      expect(
        validateTrackerRoutingValue(RuleAction.IP_CIDR6, '2001:db8::1/128'),
        isNull,
      );
      expect(validateTrackerRoutingValue(RuleAction.IP_CIDR6, '::/0'), isNull);
      for (final bad in const [
        '2001:db8::1',
        '2001:db8::1/129',
        'fe80::1%eth0/64',
        '192.168.1.0/24',
      ]) {
        expect(
          validateTrackerRoutingValue(RuleAction.IP_CIDR6, bad),
          isNotNull,
          reason: 'Expected IP-CIDR6 to reject $bad',
        );
      }
    });

    test('validates DOMAIN, DOMAIN-SUFFIX, and PROCESS-NAME', () {
      for (final action in const [
        RuleAction.DOMAIN,
        RuleAction.DOMAIN_SUFFIX,
      ]) {
        expect(validateTrackerRoutingValue(action, 'api.example.com'), isNull);
        expect(validateTrackerRoutingValue(action, 'localhost'), isNull);
        expect(validateTrackerRoutingValue(action, 'xn--nxasmq6b.com'), isNull);
        for (final bad in const [
          'bad domain.com',
          'example.com/path',
          'example.com:443',
          '.example.com',
          'example.com.',
          'a..b.com',
          '-bad.com',
          'bad-.com',
          '*.example.com',
        ]) {
          expect(
            validateTrackerRoutingValue(action, bad),
            isNotNull,
            reason: 'Expected ${action.value} to reject $bad',
          );
        }
      }

      expect(
        validateTrackerRoutingValue(RuleAction.PROCESS_NAME, 'curl'),
        isNull,
      );
      expect(
        validateTrackerRoutingValue(
          RuleAction.PROCESS_NAME,
          'Google Chrome Helper',
        ),
        isNull,
      );
      expect(
        validateTrackerRoutingValue(RuleAction.PROCESS_NAME, 'app (1)'),
        isNotNull,
      );
    });
  });

  group('extractTrackerRoutingCandidates', () {
    test(
      'extracts domain, suffix, IPv4, process, and port and defaults to DOMAIN',
      () {
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
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DST_PORT,
            value: '443',
          ),
        ]);
        expect(
          defaultTrackerRoutingCandidate(candidates),
          const TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN,
            value: 'api.example.com',
          ),
        );
      },
    );

    test(
      'defaults shared hosting subdomains safely to exact DOMAIN while offering suffix',
      () {
        final candidates = extractTrackerRoutingCandidates(
          _tracker(host: 'alice.github.io'),
        );
        expect(candidates, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN,
            value: 'alice.github.io',
          ),
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'github.io',
          ),
        ]);
        expect(
          defaultTrackerRoutingCandidate(candidates),
          const TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN,
            value: 'alice.github.io',
          ),
        );
      },
    );

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
        RuleAction.DOMAIN,
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

    test(
      'does not fall back to remoteDestination IP and parses processPath',
      () {
        final unix = extractTrackerRoutingCandidates(
          _tracker(
            remoteDestination: '198.51.100.20:8443',
            processPath: '/usr/local/bin/my-app',
          ),
        );
        expect(unix, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.PROCESS_NAME,
            value: 'my-app',
          ),
        ]);

        expect(
          extractTrackerRoutingCandidates(
            _tracker(remoteDestination: '198.51.100.20:8443'),
          ),
          isEmpty,
        );

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
      },
    );

    test('ignores invalid ports and process names with parens', () {
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
      expect(
        extractTrackerRoutingCandidates(_tracker(process: 'app (helper)')),
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

    test(
      'detects duplicates across all groups and avoids widening ambiguous AND groups',
      () {
        const multiAnd = CustomRouting(
          id: 2,
          label: 'StrictAnd',
          logic: CustomRoutingLogic.and,
          target: 'Proxy',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN_SUFFIX,
              values: ['a.test', 'c.test'],
            ),
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN_SUFFIX,
              values: ['b.test', 'c.test'],
            ),
          ],
        );

        final dupInSecond = mergeCandidatesIntoRouting(multiAnd, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'B.TEST',
          ),
        ]);
        expect(dupInSecond.addedCount, 0);
        expect(dupInSecond.duplicateCount, 1);
        expect(dupInSecond.routing, multiAnd);

        final newValue = mergeCandidatesIntoRouting(multiAnd, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'd.test',
          ),
        ]);
        expect(newValue.addedCount, 1);
        expect(newValue.duplicateCount, 0);
        expect(newValue.routing.conditions, hasLength(3));
        expect(newValue.routing.conditions[0].values, ['a.test', 'c.test']);
        expect(newValue.routing.conditions[1].values, ['b.test', 'c.test']);
        expect(newValue.routing.conditions[2].values, ['d.test']);

        final multiOr = multiAnd.copyWith(logic: CustomRoutingLogic.or);
        final dupInOrSecond = mergeCandidatesIntoRouting(multiOr, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'b.test',
          ),
        ]);
        expect(dupInOrSecond.addedCount, 0);
        expect(dupInOrSecond.duplicateCount, 1);

        final addedInOr = mergeCandidatesIntoRouting(multiOr, const [
          TrackerRoutingCandidate(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            value: 'd.test',
          ),
        ]);
        expect(addedInOr.addedCount, 1);
        expect(addedInOr.routing.conditions, hasLength(2));
        expect(addedInOr.routing.conditions[0].values, [
          'a.test',
          'c.test',
          'd.test',
        ]);
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

  group('CustomRoutingsDao.saveWithSelection', () {
    late Database testDb;

    setUp(() async {
      testDb = Database(NativeDatabase.memory());
      await testDb.profilesDao.putAll([
        Profile.normal(label: 'P1').copyWith(id: 1).toCompanion(),
        Profile.normal(label: 'P2').copyWith(id: 2).toCompanion(),
      ]);
    });

    tearDown(() async {
      await testDb.close();
    });

    test(
      'saves routing and profile link atomically, stays idempotent, and keeps other profile links',
      () async {
        const routing = CustomRouting(
          id: 50,
          label: 'Api',
          target: 'DIRECT',
          order: 'a',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN,
              values: ['api.example.com'],
            ),
          ],
        );

        await testDb.customRoutingsDao.saveWithSelection(
          routing,
          profileId: 1,
          append: true,
        );
        await testDb.customRoutingsDao.putSelected(2, routing.id);

        final updated = routing.copyWith(
          conditions: const [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN,
              values: ['api.example.com', 'cdn.example.com'],
            ),
          ],
        );
        await testDb.customRoutingsDao.saveWithSelection(
          updated,
          profileId: 1,
          append: false,
        );

        expect(await testDb.customRoutingsDao.query().get(), [updated]);
        expect(await testDb.customRoutingsDao.querySelectedIds(1).get(), [50]);
        expect(await testDb.customRoutingsDao.querySelectedIds(2).get(), [50]);
      },
    );

    test('rolls back routing write if profile link FK fails', () async {
      const routing = CustomRouting(
        id: 51,
        label: 'Rollback',
        target: 'DIRECT',
        order: 'a',
        conditions: [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN,
            values: ['rollback.example.com'],
          ),
        ],
      );

      await expectLater(
        testDb.customRoutingsDao.saveWithSelection(
          routing,
          profileId: 999,
          append: true,
        ),
        throwsA(isA<Object>()),
      );
      expect(await testDb.customRoutingsDao.query().get(), isEmpty);
    });
  });

  group('QuickCustomRouting widgets & flows', () {
    late _FakeCustomRoutings fakeRoutings;
    late ProviderContainer container;

    void createContainer({
      List<CustomRouting> routings = const [],
      List<int> selectedIds = const [],
      int? profileId = _profileId,
      Profile? profile,
    }) {
      fakeRoutings = _FakeCustomRoutings(routings);
      final resolvedProfile =
          profile ?? Profile.normal(label: 'main').copyWith(id: _profileId);
      container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(() => TestProfiles([resolvedProfile])),
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

    testWidgets(
      'creates a new custom routing defaulting to DOMAIN and enables it for profile',
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

        expect(find.text('DOMAIN:api.example.com'), findsOneWidget);
        expect(find.text('DOMAIN-SUFFIX:example.com'), findsOneWidget);
        expect(find.text('IP-CIDR:93.184.216.34/32'), findsOneWidget);

        await tester.tap(find.text('REJECT'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();

        expect(fakeRoutings.saveCalls, hasLength(1));
        final call = fakeRoutings.saveCalls.single;
        expect(call.append, isTrue);
        expect(call.applyProfileId, _profileId);
        expect(call.routing.label, 'api.example.com');
        expect(call.routing.target, 'REJECT');
        expect(call.routing.conditions, const [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN,
            values: ['api.example.com'],
          ),
        ]);
        expect(
          container.read(profileCustomRoutingIdsProvider(_profileId)).value,
          contains(call.routing.id),
        );
      },
    );

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

      expect(fakeRoutings.saveCalls, hasLength(1));
      expect(fakeRoutings.saveCalls.single.applyProfileId, isNull);
      expect(
        container.read(profileCustomRoutingIdsProvider(_profileId)).value,
        isEmpty,
      );
    });

    testWidgets(
      'hides Use in current profile toggle and skips linking on ProfileType.custom',
      (tester) async {
        const existing = CustomRouting(
          id: 101,
          label: 'Work',
          target: 'DIRECT',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN,
              values: ['other.example.com'],
            ),
          ],
        );
        createContainer(
          routings: const [existing],
          profile: Profile.custom(label: 'Custom').copyWith(id: _profileId),
        );
        final info = _tracker(host: 'api.example.com');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Switch), findsNothing);
        await tester.tap(
          find.text(currentAppLocalizations.quickRoutingModeAppend),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Switch), findsNothing);
        await tester.tap(
          find.text(currentAppLocalizations.quickRoutingModeNew),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();

        expect(fakeRoutings.saveCalls, hasLength(1));
        expect(fakeRoutings.saveCalls.single.applyProfileId, isNull);
        expect(
          container.read(profileCustomRoutingIdsProvider(_profileId)).value,
          isEmpty,
        );
      },
    );

    testWidgets('blocks saving when final compiled routing toRule() is null', (
      tester,
    ) async {
      const brokenTarget = CustomRouting(
        id: 109,
        label: 'NoTarget',
        target: '',
        conditions: [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN,
            values: ['other.example.com'],
          ),
        ],
      );
      createContainer(routings: const [brokenTarget]);
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
      await tester.tap(find.byTooltip(currentAppLocalizations.save));
      await tester.pumpAndSettle();

      expect(fakeRoutings.saveCalls, isEmpty);
    });

    testWidgets(
      'blocks invalid per-action edits in both create and append modes',
      (tester) async {
        const existing = CustomRouting(
          id: 101,
          label: 'Ports',
          target: 'DIRECT',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DST_PORT,
              values: ['80'],
            ),
          ],
        );
        createContainer(routings: const [existing]);
        final info = _tracker(destinationPort: '443');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, '99999');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();
        expect(fakeRoutings.saveCalls, isEmpty);
        expect(
          find.text(currentAppLocalizations.listenerPortInvalid),
          findsOneWidget,
        );

        await tester.tap(
          find.text(currentAppLocalizations.quickRoutingModeAppend),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();
        expect(fakeRoutings.saveCalls, isEmpty);
      },
    );

    testWidgets(
      'completes transactional save and profile link even if sheet unmounts before completion',
      (tester) async {
        createContainer();
        final completer = Completer<void>();
        fakeRoutings.pendingSave = completer;
        final info = _tracker(host: 'api.example.com');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TestApp(child: QuickCustomRoutingSheet(trackerInfo: info)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pump();
        expect(fakeRoutings.saveCalls, hasLength(1));
        expect(fakeRoutings.saveCalls.single.applyProfileId, _profileId);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TestApp(child: SizedBox.shrink()),
          ),
        );
        completer.complete();
        await tester.pumpAndSettle();

        expect(
          container.read(profileCustomRoutingIdsProvider(_profileId)).value,
          contains(fakeRoutings.saveCalls.single.routing.id),
        );
      },
    );

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

        expect(fakeRoutings.saveCalls, hasLength(1));
        expect(fakeRoutings.saveCalls.single.routing.conditions, const [
          CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN,
            values: ['api.example.com'],
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

      expect(fakeRoutings.saveCalls, hasLength(1));
      expect(fakeRoutings.saveCalls.single.routing.label, 'sub.example.com');
      expect(fakeRoutings.saveCalls.single.routing.conditions, const [
        CustomRoutingCondition(
          ruleAction: RuleAction.DOMAIN,
          values: ['sub.example.com'],
        ),
      ]);
    });

    testWidgets(
      'appends without flipping disabled state, skips already-linked duplicates, and links unlinked duplicates',
      (tester) async {
        const existingA = CustomRouting(
          id: 101,
          label: 'Streaming',
          enabled: false,
          logic: CustomRoutingLogic.and,
          target: 'Proxy',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN,
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
              ruleAction: RuleAction.DOMAIN,
              values: ['api.example.com'],
            ),
          ],
        );
        createContainer(
          routings: const [existingA, existingB],
          selectedIds: const [102],
        );
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
        expect(fakeRoutings.saveCalls, isEmpty);

        await tester.tap(find.text('Streaming'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();

        expect(fakeRoutings.saveCalls, hasLength(1));
        final call = fakeRoutings.saveCalls.single;
        expect(call.append, isFalse);
        expect(call.applyProfileId, _profileId);
        expect(call.routing.id, 101);
        expect(call.routing.enabled, isFalse);
        expect(call.routing.conditions.single.values, [
          'media.test',
          'api.example.com',
        ]);
        expect(
          container.read(profileCustomRoutingIdsProvider(_profileId)).value,
          contains(101),
        );
      },
    );

    testWidgets(
      'links existing duplicate routing when not yet applied to current profile',
      (tester) async {
        const existing = CustomRouting(
          id: 102,
          label: 'AlreadyHas',
          target: 'DIRECT',
          conditions: [
            CustomRoutingCondition(
              ruleAction: RuleAction.DOMAIN,
              values: ['api.example.com'],
            ),
          ],
        );
        createContainer(routings: const [existing], selectedIds: const []);
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

        await tester.tap(find.byTooltip(currentAppLocalizations.save));
        await tester.pumpAndSettle();

        expect(fakeRoutings.saveCalls, hasLength(1));
        expect(fakeRoutings.saveCalls.single.routing, existing);
        expect(fakeRoutings.saveCalls.single.applyProfileId, _profileId);
        expect(
          container.read(profileCustomRoutingIdsProvider(_profileId)).value,
          contains(102),
        );
      },
    );

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
