part of 'database.dart';

@DataClassName('RawCustomRouting')
class CustomRoutings extends Table {
  @override
  String get tableName => 'custom_routings';

  IntColumn get id => integer()();

  TextColumn get label => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  TextColumn get logic => textEnum<CustomRoutingLogic>()();

  TextColumn get conditions =>
      text().map(const CustomRoutingConditionsConverter())();

  TextColumn get target => text().nullable()();

  TextColumn get order => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RawProfileCustomRouting')
class ProfileCustomRoutings extends Table {
  @override
  String get tableName => 'profile_custom_routings';

  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();

  IntColumn get routingId =>
      integer().references(CustomRoutings, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {profileId, routingId};
}

@DriftAccessor(tables: [CustomRoutings, ProfileCustomRoutings])
class CustomRoutingsDao extends DatabaseAccessor<Database>
    with _$CustomRoutingsDaoMixin {
  CustomRoutingsDao(super.attachedDatabase);

  Selectable<CustomRouting> query() {
    final query = customRoutings.select()
      ..orderBy([
        (t) => OrderingTerm(expression: t.order, nulls: NullsOrder.last),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.map((row) => row.toCustomRouting());
  }

  Selectable<int> querySelectedIds(int profileId) {
    final query = selectOnly(profileCustomRoutings)
      ..addColumns([profileCustomRoutings.routingId])
      ..where(profileCustomRoutings.profileId.equals(profileId));
    return query.map((row) => row.read(profileCustomRoutings.routingId)!);
  }

  /// What a profile injects: its selected entries that are switched on, in
  /// the global order.
  Selectable<CustomRouting> queryApplied(int profileId) {
    final selected = selectOnly(profileCustomRoutings)
      ..addColumns([profileCustomRoutings.routingId])
      ..where(profileCustomRoutings.profileId.equals(profileId));
    final query = customRoutings.select()
      ..where((t) => t.enabled.equals(true) & t.id.isInQuery(selected))
      ..orderBy([
        (t) => OrderingTerm(expression: t.order, nulls: NullsOrder.last),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.map((row) => row.toCustomRouting());
  }

  Future<int> put(CustomRouting routing) {
    return customRoutings.insertOnConflictUpdate(routing.toCompanion());
  }

  Future<int> order({required int id, required String order}) {
    final stmt = customRoutings.update()..where((t) => t.id.equals(id));
    return stmt.write(CustomRoutingsCompanion(order: Value(order)));
  }

  Future<int> del(int id) {
    return customRoutings.deleteWhere((t) => t.id.equals(id));
  }

  Future<int> putSelected(int profileId, int routingId) {
    return profileCustomRoutings.insertOnConflictUpdate(
      ProfileCustomRoutingsCompanion.insert(
        profileId: profileId,
        routingId: routingId,
      ),
    );
  }

  Future<int> delSelected(int profileId, int routingId) {
    return profileCustomRoutings.deleteWhere(
      (t) => t.profileId.equals(profileId) & t.routingId.equals(routingId),
    );
  }
}

extension RawCustomRoutingExt on RawCustomRouting {
  CustomRouting toCustomRouting() {
    return CustomRouting(
      id: id,
      label: label,
      enabled: enabled,
      logic: logic,
      conditions: conditions,
      target: target,
      order: order,
    );
  }
}

extension CustomRoutingsCompanionExt on CustomRouting {
  CustomRoutingsCompanion toCompanion() {
    return CustomRoutingsCompanion.insert(
      id: Value(id),
      label: label,
      enabled: Value(enabled),
      logic: logic,
      conditions: conditions,
      target: Value(target),
      order: Value(order),
    );
  }
}
