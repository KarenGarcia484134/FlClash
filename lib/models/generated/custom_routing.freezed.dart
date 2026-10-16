// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../custom_routing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomRoutingCondition {

 RuleAction get ruleAction; List<String> get values; bool get noResolve;
/// Create a copy of CustomRoutingCondition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomRoutingConditionCopyWith<CustomRoutingCondition> get copyWith => _$CustomRoutingConditionCopyWithImpl<CustomRoutingCondition>(this as CustomRoutingCondition, _$identity);

  /// Serializes this CustomRoutingCondition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CustomRoutingCondition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomRoutingCondition&&(identical(other.ruleAction, _this.ruleAction) || other.ruleAction == _this.ruleAction)&&const DeepCollectionEquality().equals(other.values, _this.values)&&(identical(other.noResolve, _this.noResolve) || other.noResolve == _this.noResolve));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CustomRoutingCondition;
  return Object.hash(runtimeType,_this.ruleAction,const DeepCollectionEquality().hash(_this.values),_this.noResolve);
}

@override
String toString() {
  final _this = this as CustomRoutingCondition;
  return 'CustomRoutingCondition(ruleAction: ${_this.ruleAction}, values: ${_this.values}, noResolve: ${_this.noResolve})';
}


}

/// @nodoc
abstract mixin class $CustomRoutingConditionCopyWith<$Res>  {
  factory $CustomRoutingConditionCopyWith(CustomRoutingCondition value, $Res Function(CustomRoutingCondition) _then) = _$CustomRoutingConditionCopyWithImpl;
@useResult
$Res call({
 RuleAction ruleAction, List<String> values, bool noResolve
});




}
/// @nodoc
class _$CustomRoutingConditionCopyWithImpl<$Res>
    implements $CustomRoutingConditionCopyWith<$Res> {
  _$CustomRoutingConditionCopyWithImpl(this._self, this._then);

  final CustomRoutingCondition _self;
  final $Res Function(CustomRoutingCondition) _then;

/// Create a copy of CustomRoutingCondition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruleAction = null,Object? values = null,Object? noResolve = null,}) {
  return _then(CustomRoutingCondition(
ruleAction: null == ruleAction ? _self.ruleAction : ruleAction // ignore: cast_nullable_to_non_nullable
as RuleAction,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as List<String>,noResolve: null == noResolve ? _self.noResolve : noResolve // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomRoutingCondition].
extension CustomRoutingConditionPatterns on CustomRoutingCondition {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomRoutingCondition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomRoutingCondition() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomRoutingCondition value)  $default,){
final _that = this;
switch (_that) {
case _CustomRoutingCondition():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomRoutingCondition value)?  $default,){
final _that = this;
switch (_that) {
case _CustomRoutingCondition() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RuleAction ruleAction,  List<String> values,  bool noResolve)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomRoutingCondition() when $default != null:
return $default(_that.ruleAction,_that.values,_that.noResolve);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RuleAction ruleAction,  List<String> values,  bool noResolve)  $default,) {final _that = this;
switch (_that) {
case _CustomRoutingCondition():
return $default(_that.ruleAction,_that.values,_that.noResolve);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RuleAction ruleAction,  List<String> values,  bool noResolve)?  $default,) {final _that = this;
switch (_that) {
case _CustomRoutingCondition() when $default != null:
return $default(_that.ruleAction,_that.values,_that.noResolve);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomRoutingCondition implements CustomRoutingCondition {
  const _CustomRoutingCondition({this.ruleAction = RuleAction.DOMAIN_SUFFIX,  List<String> values = const [], this.noResolve = false}): _values = values;
  factory _CustomRoutingCondition.fromJson(Map<String, dynamic> json) => _$CustomRoutingConditionFromJson(json);

@override@JsonKey() final  RuleAction ruleAction;
 final  List<String> _values;
@override@JsonKey() List<String> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}

@override@JsonKey() final  bool noResolve;

/// Create a copy of CustomRoutingCondition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomRoutingConditionCopyWith<_CustomRoutingCondition> get copyWith => __$CustomRoutingConditionCopyWithImpl<_CustomRoutingCondition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomRoutingConditionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomRoutingCondition&&(identical(other.ruleAction, ruleAction) || other.ruleAction == ruleAction)&&const DeepCollectionEquality().equals(other.values, _values)&&(identical(other.noResolve, noResolve) || other.noResolve == noResolve));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ruleAction,const DeepCollectionEquality().hash(_values),noResolve);
}

@override
String toString() {
    return 'CustomRoutingCondition(ruleAction: $ruleAction, values: $values, noResolve: $noResolve)';
}


}

/// @nodoc
abstract mixin class _$CustomRoutingConditionCopyWith<$Res> implements $CustomRoutingConditionCopyWith<$Res> {
  factory _$CustomRoutingConditionCopyWith(_CustomRoutingCondition value, $Res Function(_CustomRoutingCondition) _then) = __$CustomRoutingConditionCopyWithImpl;
@override @useResult
$Res call({
 RuleAction ruleAction, List<String> values, bool noResolve
});




}
/// @nodoc
class __$CustomRoutingConditionCopyWithImpl<$Res>
    implements _$CustomRoutingConditionCopyWith<$Res> {
  __$CustomRoutingConditionCopyWithImpl(this._self, this._then);

  final _CustomRoutingCondition _self;
  final $Res Function(_CustomRoutingCondition) _then;

/// Create a copy of CustomRoutingCondition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruleAction = null,Object? values = null,Object? noResolve = null,}) {
  return _then(_CustomRoutingCondition(
ruleAction: null == ruleAction ? _self.ruleAction : ruleAction // ignore: cast_nullable_to_non_nullable
as RuleAction,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<String>,noResolve: null == noResolve ? _self.noResolve : noResolve // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CustomRouting {

 int get id; String get label; bool get enabled; CustomRoutingLogic get logic; List<CustomRoutingCondition> get conditions; String? get target; String? get order;
/// Create a copy of CustomRouting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomRoutingCopyWith<CustomRouting> get copyWith => _$CustomRoutingCopyWithImpl<CustomRouting>(this as CustomRouting, _$identity);

  /// Serializes this CustomRouting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CustomRouting;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomRouting&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.logic, _this.logic) || other.logic == _this.logic)&&const DeepCollectionEquality().equals(other.conditions, _this.conditions)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.order, _this.order) || other.order == _this.order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CustomRouting;
  return Object.hash(runtimeType,_this.id,_this.label,_this.enabled,_this.logic,const DeepCollectionEquality().hash(_this.conditions),_this.target,_this.order);
}

@override
String toString() {
  final _this = this as CustomRouting;
  return 'CustomRouting(id: ${_this.id}, label: ${_this.label}, enabled: ${_this.enabled}, logic: ${_this.logic}, conditions: ${_this.conditions}, target: ${_this.target}, order: ${_this.order})';
}


}

/// @nodoc
abstract mixin class $CustomRoutingCopyWith<$Res>  {
  factory $CustomRoutingCopyWith(CustomRouting value, $Res Function(CustomRouting) _then) = _$CustomRoutingCopyWithImpl;
@useResult
$Res call({
 int id, String label, bool enabled, CustomRoutingLogic logic, List<CustomRoutingCondition> conditions, String? target, String? order
});




}
/// @nodoc
class _$CustomRoutingCopyWithImpl<$Res>
    implements $CustomRoutingCopyWith<$Res> {
  _$CustomRoutingCopyWithImpl(this._self, this._then);

  final CustomRouting _self;
  final $Res Function(CustomRouting) _then;

/// Create a copy of CustomRouting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? enabled = null,Object? logic = null,Object? conditions = null,Object? target = freezed,Object? order = freezed,}) {
  return _then(CustomRouting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,logic: null == logic ? _self.logic : logic // ignore: cast_nullable_to_non_nullable
as CustomRoutingLogic,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<CustomRoutingCondition>,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomRouting].
extension CustomRoutingPatterns on CustomRouting {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomRouting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomRouting() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomRouting value)  $default,){
final _that = this;
switch (_that) {
case _CustomRouting():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomRouting value)?  $default,){
final _that = this;
switch (_that) {
case _CustomRouting() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label,  bool enabled,  CustomRoutingLogic logic,  List<CustomRoutingCondition> conditions,  String? target,  String? order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomRouting() when $default != null:
return $default(_that.id,_that.label,_that.enabled,_that.logic,_that.conditions,_that.target,_that.order);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label,  bool enabled,  CustomRoutingLogic logic,  List<CustomRoutingCondition> conditions,  String? target,  String? order)  $default,) {final _that = this;
switch (_that) {
case _CustomRouting():
return $default(_that.id,_that.label,_that.enabled,_that.logic,_that.conditions,_that.target,_that.order);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label,  bool enabled,  CustomRoutingLogic logic,  List<CustomRoutingCondition> conditions,  String? target,  String? order)?  $default,) {final _that = this;
switch (_that) {
case _CustomRouting() when $default != null:
return $default(_that.id,_that.label,_that.enabled,_that.logic,_that.conditions,_that.target,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomRouting implements CustomRouting {
  const _CustomRouting({required this.id, this.label = '', this.enabled = true, this.logic = CustomRoutingLogic.or,  List<CustomRoutingCondition> conditions = const [], this.target, this.order}): _conditions = conditions;
  factory _CustomRouting.fromJson(Map<String, dynamic> json) => _$CustomRoutingFromJson(json);

@override final  int id;
@override@JsonKey() final  String label;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  CustomRoutingLogic logic;
 final  List<CustomRoutingCondition> _conditions;
@override@JsonKey() List<CustomRoutingCondition> get conditions {
  if (_conditions is EqualUnmodifiableListView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conditions);
}

@override final  String? target;
@override final  String? order;

/// Create a copy of CustomRouting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomRoutingCopyWith<_CustomRouting> get copyWith => __$CustomRoutingCopyWithImpl<_CustomRouting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomRoutingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomRouting&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.logic, logic) || other.logic == logic)&&const DeepCollectionEquality().equals(other.conditions, _conditions)&&(identical(other.target, target) || other.target == target)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,enabled,logic,const DeepCollectionEquality().hash(_conditions),target,order);
}

@override
String toString() {
    return 'CustomRouting(id: $id, label: $label, enabled: $enabled, logic: $logic, conditions: $conditions, target: $target, order: $order)';
}


}

/// @nodoc
abstract mixin class _$CustomRoutingCopyWith<$Res> implements $CustomRoutingCopyWith<$Res> {
  factory _$CustomRoutingCopyWith(_CustomRouting value, $Res Function(_CustomRouting) _then) = __$CustomRoutingCopyWithImpl;
@override @useResult
$Res call({
 int id, String label, bool enabled, CustomRoutingLogic logic, List<CustomRoutingCondition> conditions, String? target, String? order
});




}
/// @nodoc
class __$CustomRoutingCopyWithImpl<$Res>
    implements _$CustomRoutingCopyWith<$Res> {
  __$CustomRoutingCopyWithImpl(this._self, this._then);

  final _CustomRouting _self;
  final $Res Function(_CustomRouting) _then;

/// Create a copy of CustomRouting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? enabled = null,Object? logic = null,Object? conditions = null,Object? target = freezed,Object? order = freezed,}) {
  return _then(_CustomRouting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,logic: null == logic ? _self.logic : logic // ignore: cast_nullable_to_non_nullable
as CustomRoutingLogic,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<CustomRoutingCondition>,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
