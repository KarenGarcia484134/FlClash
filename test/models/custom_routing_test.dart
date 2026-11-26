import 'dart:convert';

import 'package:fl_clash/common/search.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

CustomRouting _routing(
  List<CustomRoutingCondition> conditions, {
  CustomRoutingLogic logic = CustomRoutingLogic.or,
  String? target = 'Proxy',
  bool enabled = true,
}) {
  return CustomRouting(
    id: 1,
    label: 'test',
    logic: logic,
    conditions: conditions,
    target: target,
    enabled: enabled,
  );
}

void main() {
  test('a single value becomes a plain rule with its params after target', () {
    expect(
      _routing([
        const CustomRoutingCondition(
          ruleAction: RuleAction.IP_CIDR,
          values: [' 10.0.0.0/8 '],
          noResolve: true,
        ),
      ]).toRule(),
      'IP-CIDR,10.0.0.0/8,Proxy,no-resolve',
    );
  });

  test('OR flattens every value of every condition', () {
    expect(
      _routing([
        const CustomRoutingCondition(values: ['a.com', 'b.com']),
        const CustomRoutingCondition(
          ruleAction: RuleAction.PROCESS_NAME,
          values: ['com.example.app'],
        ),
      ]).toRule(),
      'OR,((DOMAIN-SUFFIX,a.com),(DOMAIN-SUFFIX,b.com),'
      '(PROCESS-NAME,com.example.app)),Proxy',
    );
  });

  test('AND keeps the values of one condition as alternatives', () {
    expect(
      _routing(logic: CustomRoutingLogic.and, [
        const CustomRoutingCondition(values: ['a.com', 'b.com']),
        const CustomRoutingCondition(
          ruleAction: RuleAction.NETWORK,
          values: ['udp'],
        ),
      ]).toRule(),
      'AND,((OR,((DOMAIN-SUFFIX,a.com),(DOMAIN-SUFFIX,b.com))),'
      '(NETWORK,udp)),Proxy',
    );
  });

  test('entries the core would reject yield no rule', () {
    expect(_routing(const []).toRule(), isNull);
    expect(
      _routing([
        const CustomRoutingCondition(values: ['  ']),
      ]).toRule(),
      isNull,
    );
    expect(
      _routing(target: ' ', [
        const CustomRoutingCondition(values: ['a.com']),
      ]).toRule(),
      isNull,
    );
    expect(
      _routing([
        const CustomRoutingCondition(
          ruleAction: RuleAction.DOMAIN_REGEX,
          values: [r'^a{1,2}\.com$'],
        ),
      ]).toRule(),
      isNull,
    );
    expect(
      _routing([
        const CustomRoutingCondition(values: ['a.com']),
      ], target: 'US, Los Angeles').toRule(),
      isNull,
    );
    expect(
      _routing(logic: CustomRoutingLogic.and, [
        const CustomRoutingCondition(
          ruleAction: RuleAction.RULE_SET,
          values: ['missing'],
        ),
        const CustomRoutingCondition(
          ruleAction: RuleAction.DST_PORT,
          values: ['443'],
        ),
      ]).toRule(ruleProviders: {'other'}),
      isNull,
    );
    expect(
      _routing([
        const CustomRoutingCondition(
          ruleAction: RuleAction.PROCESS_PATH,
          values: ['foo(', 'bar'],
        ),
      ]).toRule(),
      isNull,
    );
    expect(
      _routing([
        const CustomRoutingCondition(
          ruleAction: RuleAction.PROCESS_PATH,
          values: [r'C:\Program Files (x86)\app.exe', 'other.exe'],
        ),
      ]).toRule(),
      r'OR,((PROCESS-PATH,C:\Program Files (x86)\app.exe),(PROCESS-PATH,other.exe)),Proxy',
    );
  });

  test('config resolution skips disabled entries and unknown targets', () {
    final rules = buildCustomRoutingRulesForConfig(
      {
        'proxies': [
          {'name': 'HK-01'},
        ],
        'proxy-groups': [
          {'name': 'Proxy'},
        ],
        'rule-providers': {'ads': <String, dynamic>{}},
      },
      [
        _routing([
          const CustomRoutingCondition(values: ['a.com']),
        ], target: 'HK-01'),
        _routing([
          const CustomRoutingCondition(values: ['off.com']),
        ], enabled: false),
        _routing([
          const CustomRoutingCondition(values: ['gone.com']),
        ], target: 'Missing'),
        _routing([
          const CustomRoutingCondition(
            ruleAction: RuleAction.RULE_SET,
            values: ['ads', 'unknown'],
          ),
        ], target: 'REJECT'),
        _routing([
          const CustomRoutingCondition(values: ['g.com']),
        ]),
      ],
    );
    expect(rules, [
      'DOMAIN-SUFFIX,a.com,HK-01',
      'RULE-SET,ads,REJECT',
      'DOMAIN-SUFFIX,g.com,Proxy',
    ]);
  });

  test('conditions survive a JSON round trip', () {
    final routing = _routing(logic: CustomRoutingLogic.and, [
      const CustomRoutingCondition(
        ruleAction: RuleAction.GEOIP,
        values: ['CN'],
        noResolve: true,
      ),
    ]);
    expect(
      CustomRouting.fromJson(
        jsonDecode(jsonEncode(routing)) as Map<String, Object?>,
      ),
      routing,
    );
  });

  test('a duplicate keeps everything but its identity and order', () {
    final original = _routing(logic: CustomRoutingLogic.and, [
      const CustomRoutingCondition(values: ['a.com']),
    ]).copyWith(label: '指纹1', order: 'a0');
    final copy = original.duplicated();
    expect(copy.id, isNot(original.id));
    expect(copy.label, '指纹1 copy');
    expect(copy.order, isNull);
    expect(
      copy.copyWith(id: original.id, label: original.label, order: 'a0'),
      original,
    );
  });

  test(
    'searchFields covers label, target, logic, conditions and no-resolve',
    () {
      final ipRouting = _routing(
        logic: CustomRoutingLogic.and,
        target: 'DIRECT',
        [
          const CustomRoutingCondition(
            ruleAction: RuleAction.IP_CIDR,
            values: [' 10.0.0.0/8 ', '  '],
            noResolve: true,
          ),
        ],
      ).copyWith(id: 1, label: 'Office LAN');
      final domainRouting = _routing(
        logic: CustomRoutingLogic.or,
        target: 'JP-Node',
        [
          const CustomRoutingCondition(
            ruleAction: RuleAction.DOMAIN_SUFFIX,
            values: ['example.com'],
            noResolve: true,
          ),
          const CustomRoutingCondition(
            ruleAction: RuleAction.PROCESS_NAME,
            values: ['curl'],
          ),
        ],
      ).copyWith(id: 2, label: 'Dev Traffic');

      expect(ipRouting.searchFields.toList(), [
        'Office LAN',
        'DIRECT',
        'and',
        'IP-CIDR',
        '10.0.0.0/8',
        'no-resolve',
      ]);
      expect(domainRouting.searchFields.toList(), [
        'Dev Traffic',
        'JP-Node',
        'or',
        'DOMAIN-SUFFIX',
        'example.com',
        'PROCESS-NAME',
        'curl',
      ]);

      final routings = [ipRouting, domainRouting];
      final cache = Expando<String>();
      List<int> matchIds(String text) => routings
          .whereMatches(
            SearchQuery(text),
            (item) => item.searchFields,
            texts: cache,
          )
          .map((item) => item.id)
          .toList();

      expect(matchIds('office direct 10.0.0.0/8'), [1]);
      expect(matchIds('no-resolve'), [1]);
      expect(matchIds('ip-cidr and'), [1]);
      expect(matchIds('EXAMPLE.COM curl jp-node'), [2]);
      expect(matchIds('domain-suffix'), [2]);
      expect(matchIds('nonexistent'), isEmpty);
    },
  );
}
