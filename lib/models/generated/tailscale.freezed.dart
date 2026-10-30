// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../tailscale.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TailscaleProps {

 bool get enable; String get hostname; String get authKey; String get controlUrl; bool get acceptRoutes; String get exitNode; bool get ephemeral; bool get udp; List<String> get dnsSuffixes; String get dialerProxy;
/// Create a copy of TailscaleProps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscalePropsCopyWith<TailscaleProps> get copyWith => _$TailscalePropsCopyWithImpl<TailscaleProps>(this as TailscaleProps, _$identity);

  /// Serializes this TailscaleProps to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TailscaleProps;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleProps&&(identical(other.enable, _this.enable) || other.enable == _this.enable)&&(identical(other.hostname, _this.hostname) || other.hostname == _this.hostname)&&(identical(other.authKey, _this.authKey) || other.authKey == _this.authKey)&&(identical(other.controlUrl, _this.controlUrl) || other.controlUrl == _this.controlUrl)&&(identical(other.acceptRoutes, _this.acceptRoutes) || other.acceptRoutes == _this.acceptRoutes)&&(identical(other.exitNode, _this.exitNode) || other.exitNode == _this.exitNode)&&(identical(other.ephemeral, _this.ephemeral) || other.ephemeral == _this.ephemeral)&&(identical(other.udp, _this.udp) || other.udp == _this.udp)&&const DeepCollectionEquality().equals(other.dnsSuffixes, _this.dnsSuffixes)&&(identical(other.dialerProxy, _this.dialerProxy) || other.dialerProxy == _this.dialerProxy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TailscaleProps;
  return Object.hash(runtimeType,_this.enable,_this.hostname,_this.authKey,_this.controlUrl,_this.acceptRoutes,_this.exitNode,_this.ephemeral,_this.udp,const DeepCollectionEquality().hash(_this.dnsSuffixes),_this.dialerProxy);
}

@override
String toString() {
  final _this = this as TailscaleProps;
  return 'TailscaleProps(enable: ${_this.enable}, hostname: ${_this.hostname}, authKey: ${_this.authKey}, controlUrl: ${_this.controlUrl}, acceptRoutes: ${_this.acceptRoutes}, exitNode: ${_this.exitNode}, ephemeral: ${_this.ephemeral}, udp: ${_this.udp}, dnsSuffixes: ${_this.dnsSuffixes}, dialerProxy: ${_this.dialerProxy})';
}


}

/// @nodoc
abstract mixin class $TailscalePropsCopyWith<$Res>  {
  factory $TailscalePropsCopyWith(TailscaleProps value, $Res Function(TailscaleProps) _then) = _$TailscalePropsCopyWithImpl;
@useResult
$Res call({
 bool enable, String hostname, String authKey, String controlUrl, bool acceptRoutes, String exitNode, bool ephemeral, bool udp, List<String> dnsSuffixes, String dialerProxy
});




}
/// @nodoc
class _$TailscalePropsCopyWithImpl<$Res>
    implements $TailscalePropsCopyWith<$Res> {
  _$TailscalePropsCopyWithImpl(this._self, this._then);

  final TailscaleProps _self;
  final $Res Function(TailscaleProps) _then;

/// Create a copy of TailscaleProps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enable = null,Object? hostname = null,Object? authKey = null,Object? controlUrl = null,Object? acceptRoutes = null,Object? exitNode = null,Object? ephemeral = null,Object? udp = null,Object? dnsSuffixes = null,Object? dialerProxy = null,}) {
  return _then(TailscaleProps(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,authKey: null == authKey ? _self.authKey : authKey // ignore: cast_nullable_to_non_nullable
as String,controlUrl: null == controlUrl ? _self.controlUrl : controlUrl // ignore: cast_nullable_to_non_nullable
as String,acceptRoutes: null == acceptRoutes ? _self.acceptRoutes : acceptRoutes // ignore: cast_nullable_to_non_nullable
as bool,exitNode: null == exitNode ? _self.exitNode : exitNode // ignore: cast_nullable_to_non_nullable
as String,ephemeral: null == ephemeral ? _self.ephemeral : ephemeral // ignore: cast_nullable_to_non_nullable
as bool,udp: null == udp ? _self.udp : udp // ignore: cast_nullable_to_non_nullable
as bool,dnsSuffixes: null == dnsSuffixes ? _self.dnsSuffixes : dnsSuffixes // ignore: cast_nullable_to_non_nullable
as List<String>,dialerProxy: null == dialerProxy ? _self.dialerProxy : dialerProxy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscaleProps].
extension TailscalePropsPatterns on TailscaleProps {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleProps value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleProps() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleProps value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleProps():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleProps value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleProps() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enable,  String hostname,  String authKey,  String controlUrl,  bool acceptRoutes,  String exitNode,  bool ephemeral,  bool udp,  List<String> dnsSuffixes,  String dialerProxy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleProps() when $default != null:
return $default(_that.enable,_that.hostname,_that.authKey,_that.controlUrl,_that.acceptRoutes,_that.exitNode,_that.ephemeral,_that.udp,_that.dnsSuffixes,_that.dialerProxy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enable,  String hostname,  String authKey,  String controlUrl,  bool acceptRoutes,  String exitNode,  bool ephemeral,  bool udp,  List<String> dnsSuffixes,  String dialerProxy)  $default,) {final _that = this;
switch (_that) {
case _TailscaleProps():
return $default(_that.enable,_that.hostname,_that.authKey,_that.controlUrl,_that.acceptRoutes,_that.exitNode,_that.ephemeral,_that.udp,_that.dnsSuffixes,_that.dialerProxy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enable,  String hostname,  String authKey,  String controlUrl,  bool acceptRoutes,  String exitNode,  bool ephemeral,  bool udp,  List<String> dnsSuffixes,  String dialerProxy)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleProps() when $default != null:
return $default(_that.enable,_that.hostname,_that.authKey,_that.controlUrl,_that.acceptRoutes,_that.exitNode,_that.ephemeral,_that.udp,_that.dnsSuffixes,_that.dialerProxy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleProps implements TailscaleProps {
  const _TailscaleProps({this.enable = false, this.hostname = '', this.authKey = '', this.controlUrl = '', this.acceptRoutes = true, this.exitNode = '', this.ephemeral = false, this.udp = true,  List<String> dnsSuffixes = const [], this.dialerProxy = ''}): _dnsSuffixes = dnsSuffixes;
  factory _TailscaleProps.fromJson(Map<String, dynamic> json) => _$TailscalePropsFromJson(json);

@override@JsonKey() final  bool enable;
@override@JsonKey() final  String hostname;
@override@JsonKey() final  String authKey;
@override@JsonKey() final  String controlUrl;
@override@JsonKey() final  bool acceptRoutes;
@override@JsonKey() final  String exitNode;
@override@JsonKey() final  bool ephemeral;
@override@JsonKey() final  bool udp;
 final  List<String> _dnsSuffixes;
@override@JsonKey() List<String> get dnsSuffixes {
  if (_dnsSuffixes is EqualUnmodifiableListView) return _dnsSuffixes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dnsSuffixes);
}

@override@JsonKey() final  String dialerProxy;

/// Create a copy of TailscaleProps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscalePropsCopyWith<_TailscaleProps> get copyWith => __$TailscalePropsCopyWithImpl<_TailscaleProps>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscalePropsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleProps&&(identical(other.enable, enable) || other.enable == enable)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.authKey, authKey) || other.authKey == authKey)&&(identical(other.controlUrl, controlUrl) || other.controlUrl == controlUrl)&&(identical(other.acceptRoutes, acceptRoutes) || other.acceptRoutes == acceptRoutes)&&(identical(other.exitNode, exitNode) || other.exitNode == exitNode)&&(identical(other.ephemeral, ephemeral) || other.ephemeral == ephemeral)&&(identical(other.udp, udp) || other.udp == udp)&&const DeepCollectionEquality().equals(other.dnsSuffixes, _dnsSuffixes)&&(identical(other.dialerProxy, dialerProxy) || other.dialerProxy == dialerProxy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enable,hostname,authKey,controlUrl,acceptRoutes,exitNode,ephemeral,udp,const DeepCollectionEquality().hash(_dnsSuffixes),dialerProxy);
}

@override
String toString() {
    return 'TailscaleProps(enable: $enable, hostname: $hostname, authKey: $authKey, controlUrl: $controlUrl, acceptRoutes: $acceptRoutes, exitNode: $exitNode, ephemeral: $ephemeral, udp: $udp, dnsSuffixes: $dnsSuffixes, dialerProxy: $dialerProxy)';
}


}

/// @nodoc
abstract mixin class _$TailscalePropsCopyWith<$Res> implements $TailscalePropsCopyWith<$Res> {
  factory _$TailscalePropsCopyWith(_TailscaleProps value, $Res Function(_TailscaleProps) _then) = __$TailscalePropsCopyWithImpl;
@override @useResult
$Res call({
 bool enable, String hostname, String authKey, String controlUrl, bool acceptRoutes, String exitNode, bool ephemeral, bool udp, List<String> dnsSuffixes, String dialerProxy
});




}
/// @nodoc
class __$TailscalePropsCopyWithImpl<$Res>
    implements _$TailscalePropsCopyWith<$Res> {
  __$TailscalePropsCopyWithImpl(this._self, this._then);

  final _TailscaleProps _self;
  final $Res Function(_TailscaleProps) _then;

/// Create a copy of TailscaleProps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enable = null,Object? hostname = null,Object? authKey = null,Object? controlUrl = null,Object? acceptRoutes = null,Object? exitNode = null,Object? ephemeral = null,Object? udp = null,Object? dnsSuffixes = null,Object? dialerProxy = null,}) {
  return _then(_TailscaleProps(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,authKey: null == authKey ? _self.authKey : authKey // ignore: cast_nullable_to_non_nullable
as String,controlUrl: null == controlUrl ? _self.controlUrl : controlUrl // ignore: cast_nullable_to_non_nullable
as String,acceptRoutes: null == acceptRoutes ? _self.acceptRoutes : acceptRoutes // ignore: cast_nullable_to_non_nullable
as bool,exitNode: null == exitNode ? _self.exitNode : exitNode // ignore: cast_nullable_to_non_nullable
as String,ephemeral: null == ephemeral ? _self.ephemeral : ephemeral // ignore: cast_nullable_to_non_nullable
as bool,udp: null == udp ? _self.udp : udp // ignore: cast_nullable_to_non_nullable
as bool,dnsSuffixes: null == dnsSuffixes ? _self._dnsSuffixes : dnsSuffixes // ignore: cast_nullable_to_non_nullable
as List<String>,dialerProxy: null == dialerProxy ? _self.dialerProxy : dialerProxy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TailscaleStatus {

 TailscalePhase get phase; String? get loginUrl; String? get proxyName; List<String> get health;/// What the running node's own traffic really goes through, as the Core
/// reports it: empty for directly, null while unknown.
 String? get dialerProxy;/// Why the configured exit node could not be set, as the Core reports.
 String? get exitNodeError;
/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleStatusCopyWith<TailscaleStatus> get copyWith => _$TailscaleStatusCopyWithImpl<TailscaleStatus>(this as TailscaleStatus, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TailscaleStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleStatus&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.loginUrl, _this.loginUrl) || other.loginUrl == _this.loginUrl)&&(identical(other.proxyName, _this.proxyName) || other.proxyName == _this.proxyName)&&const DeepCollectionEquality().equals(other.health, _this.health)&&(identical(other.dialerProxy, _this.dialerProxy) || other.dialerProxy == _this.dialerProxy)&&(identical(other.exitNodeError, _this.exitNodeError) || other.exitNodeError == _this.exitNodeError));
}


@override
int get hashCode {
  final _this = this as TailscaleStatus;
  return Object.hash(runtimeType,_this.phase,_this.loginUrl,_this.proxyName,const DeepCollectionEquality().hash(_this.health),_this.dialerProxy,_this.exitNodeError);
}

@override
String toString() {
  final _this = this as TailscaleStatus;
  return 'TailscaleStatus(phase: ${_this.phase}, loginUrl: ${_this.loginUrl}, proxyName: ${_this.proxyName}, health: ${_this.health}, dialerProxy: ${_this.dialerProxy}, exitNodeError: ${_this.exitNodeError})';
}


}

/// @nodoc
abstract mixin class $TailscaleStatusCopyWith<$Res>  {
  factory $TailscaleStatusCopyWith(TailscaleStatus value, $Res Function(TailscaleStatus) _then) = _$TailscaleStatusCopyWithImpl;
@useResult
$Res call({
 TailscalePhase phase, String? loginUrl, String? proxyName, List<String> health, String? dialerProxy, String? exitNodeError
});




}
/// @nodoc
class _$TailscaleStatusCopyWithImpl<$Res>
    implements $TailscaleStatusCopyWith<$Res> {
  _$TailscaleStatusCopyWithImpl(this._self, this._then);

  final TailscaleStatus _self;
  final $Res Function(TailscaleStatus) _then;

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? loginUrl = freezed,Object? proxyName = freezed,Object? health = null,Object? dialerProxy = freezed,Object? exitNodeError = freezed,}) {
  return _then(TailscaleStatus(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TailscalePhase,loginUrl: freezed == loginUrl ? _self.loginUrl : loginUrl // ignore: cast_nullable_to_non_nullable
as String?,proxyName: freezed == proxyName ? _self.proxyName : proxyName // ignore: cast_nullable_to_non_nullable
as String?,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as List<String>,dialerProxy: freezed == dialerProxy ? _self.dialerProxy : dialerProxy // ignore: cast_nullable_to_non_nullable
as String?,exitNodeError: freezed == exitNodeError ? _self.exitNodeError : exitNodeError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscaleStatus].
extension TailscaleStatusPatterns on TailscaleStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleStatus value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleStatus value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TailscalePhase phase,  String? loginUrl,  String? proxyName,  List<String> health,  String? dialerProxy,  String? exitNodeError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that.phase,_that.loginUrl,_that.proxyName,_that.health,_that.dialerProxy,_that.exitNodeError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TailscalePhase phase,  String? loginUrl,  String? proxyName,  List<String> health,  String? dialerProxy,  String? exitNodeError)  $default,) {final _that = this;
switch (_that) {
case _TailscaleStatus():
return $default(_that.phase,_that.loginUrl,_that.proxyName,_that.health,_that.dialerProxy,_that.exitNodeError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TailscalePhase phase,  String? loginUrl,  String? proxyName,  List<String> health,  String? dialerProxy,  String? exitNodeError)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that.phase,_that.loginUrl,_that.proxyName,_that.health,_that.dialerProxy,_that.exitNodeError);case _:
  return null;

}
}

}

/// @nodoc


class _TailscaleStatus implements TailscaleStatus {
  const _TailscaleStatus({this.phase = TailscalePhase.idle, this.loginUrl, this.proxyName,  List<String> health = const [], this.dialerProxy, this.exitNodeError}): _health = health;
  

@override@JsonKey() final  TailscalePhase phase;
@override final  String? loginUrl;
@override final  String? proxyName;
 final  List<String> _health;
@override@JsonKey() List<String> get health {
  if (_health is EqualUnmodifiableListView) return _health;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_health);
}

/// What the running node's own traffic really goes through, as the Core
/// reports it: empty for directly, null while unknown.
@override final  String? dialerProxy;
/// Why the configured exit node could not be set, as the Core reports.
@override final  String? exitNodeError;

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleStatusCopyWith<_TailscaleStatus> get copyWith => __$TailscaleStatusCopyWithImpl<_TailscaleStatus>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleStatus&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.loginUrl, loginUrl) || other.loginUrl == loginUrl)&&(identical(other.proxyName, proxyName) || other.proxyName == proxyName)&&const DeepCollectionEquality().equals(other.health, _health)&&(identical(other.dialerProxy, dialerProxy) || other.dialerProxy == dialerProxy)&&(identical(other.exitNodeError, exitNodeError) || other.exitNodeError == exitNodeError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,loginUrl,proxyName,const DeepCollectionEquality().hash(_health),dialerProxy,exitNodeError);
}

@override
String toString() {
    return 'TailscaleStatus(phase: $phase, loginUrl: $loginUrl, proxyName: $proxyName, health: $health, dialerProxy: $dialerProxy, exitNodeError: $exitNodeError)';
}


}

/// @nodoc
abstract mixin class _$TailscaleStatusCopyWith<$Res> implements $TailscaleStatusCopyWith<$Res> {
  factory _$TailscaleStatusCopyWith(_TailscaleStatus value, $Res Function(_TailscaleStatus) _then) = __$TailscaleStatusCopyWithImpl;
@override @useResult
$Res call({
 TailscalePhase phase, String? loginUrl, String? proxyName, List<String> health, String? dialerProxy, String? exitNodeError
});




}
/// @nodoc
class __$TailscaleStatusCopyWithImpl<$Res>
    implements _$TailscaleStatusCopyWith<$Res> {
  __$TailscaleStatusCopyWithImpl(this._self, this._then);

  final _TailscaleStatus _self;
  final $Res Function(_TailscaleStatus) _then;

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? loginUrl = freezed,Object? proxyName = freezed,Object? health = null,Object? dialerProxy = freezed,Object? exitNodeError = freezed,}) {
  return _then(_TailscaleStatus(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TailscalePhase,loginUrl: freezed == loginUrl ? _self.loginUrl : loginUrl // ignore: cast_nullable_to_non_nullable
as String?,proxyName: freezed == proxyName ? _self.proxyName : proxyName // ignore: cast_nullable_to_non_nullable
as String?,health: null == health ? _self._health : health // ignore: cast_nullable_to_non_nullable
as List<String>,dialerProxy: freezed == dialerProxy ? _self.dialerProxy : dialerProxy // ignore: cast_nullable_to_non_nullable
as String?,exitNodeError: freezed == exitNodeError ? _self.exitNodeError : exitNodeError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TailscalePeer {

 String get id; String get hostName; String get dnsName; String get os; List<String> get ips; bool get online; bool get exitNode; bool get exitNodeOption; String? get lastSeen;
/// Create a copy of TailscalePeer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscalePeerCopyWith<TailscalePeer> get copyWith => _$TailscalePeerCopyWithImpl<TailscalePeer>(this as TailscalePeer, _$identity);

  /// Serializes this TailscalePeer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TailscalePeer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscalePeer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.hostName, _this.hostName) || other.hostName == _this.hostName)&&(identical(other.dnsName, _this.dnsName) || other.dnsName == _this.dnsName)&&(identical(other.os, _this.os) || other.os == _this.os)&&const DeepCollectionEquality().equals(other.ips, _this.ips)&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.exitNode, _this.exitNode) || other.exitNode == _this.exitNode)&&(identical(other.exitNodeOption, _this.exitNodeOption) || other.exitNodeOption == _this.exitNodeOption)&&(identical(other.lastSeen, _this.lastSeen) || other.lastSeen == _this.lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TailscalePeer;
  return Object.hash(runtimeType,_this.id,_this.hostName,_this.dnsName,_this.os,const DeepCollectionEquality().hash(_this.ips),_this.online,_this.exitNode,_this.exitNodeOption,_this.lastSeen);
}

@override
String toString() {
  final _this = this as TailscalePeer;
  return 'TailscalePeer(id: ${_this.id}, hostName: ${_this.hostName}, dnsName: ${_this.dnsName}, os: ${_this.os}, ips: ${_this.ips}, online: ${_this.online}, exitNode: ${_this.exitNode}, exitNodeOption: ${_this.exitNodeOption}, lastSeen: ${_this.lastSeen})';
}


}

/// @nodoc
abstract mixin class $TailscalePeerCopyWith<$Res>  {
  factory $TailscalePeerCopyWith(TailscalePeer value, $Res Function(TailscalePeer) _then) = _$TailscalePeerCopyWithImpl;
@useResult
$Res call({
 String id, String hostName, String dnsName, String os, List<String> ips, bool online, bool exitNode, bool exitNodeOption, String? lastSeen
});




}
/// @nodoc
class _$TailscalePeerCopyWithImpl<$Res>
    implements $TailscalePeerCopyWith<$Res> {
  _$TailscalePeerCopyWithImpl(this._self, this._then);

  final TailscalePeer _self;
  final $Res Function(TailscalePeer) _then;

/// Create a copy of TailscalePeer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hostName = null,Object? dnsName = null,Object? os = null,Object? ips = null,Object? online = null,Object? exitNode = null,Object? exitNodeOption = null,Object? lastSeen = freezed,}) {
  return _then(TailscalePeer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,dnsName: null == dnsName ? _self.dnsName : dnsName // ignore: cast_nullable_to_non_nullable
as String,os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,ips: null == ips ? _self.ips : ips // ignore: cast_nullable_to_non_nullable
as List<String>,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,exitNode: null == exitNode ? _self.exitNode : exitNode // ignore: cast_nullable_to_non_nullable
as bool,exitNodeOption: null == exitNodeOption ? _self.exitNodeOption : exitNodeOption // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscalePeer].
extension TailscalePeerPatterns on TailscalePeer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscalePeer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscalePeer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscalePeer value)  $default,){
final _that = this;
switch (_that) {
case _TailscalePeer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscalePeer value)?  $default,){
final _that = this;
switch (_that) {
case _TailscalePeer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String hostName,  String dnsName,  String os,  List<String> ips,  bool online,  bool exitNode,  bool exitNodeOption,  String? lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscalePeer() when $default != null:
return $default(_that.id,_that.hostName,_that.dnsName,_that.os,_that.ips,_that.online,_that.exitNode,_that.exitNodeOption,_that.lastSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String hostName,  String dnsName,  String os,  List<String> ips,  bool online,  bool exitNode,  bool exitNodeOption,  String? lastSeen)  $default,) {final _that = this;
switch (_that) {
case _TailscalePeer():
return $default(_that.id,_that.hostName,_that.dnsName,_that.os,_that.ips,_that.online,_that.exitNode,_that.exitNodeOption,_that.lastSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String hostName,  String dnsName,  String os,  List<String> ips,  bool online,  bool exitNode,  bool exitNodeOption,  String? lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _TailscalePeer() when $default != null:
return $default(_that.id,_that.hostName,_that.dnsName,_that.os,_that.ips,_that.online,_that.exitNode,_that.exitNodeOption,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscalePeer implements TailscalePeer {
  const _TailscalePeer({this.id = '', this.hostName = '', this.dnsName = '', this.os = '',  List<String> ips = const [], this.online = false, this.exitNode = false, this.exitNodeOption = false, this.lastSeen}): _ips = ips;
  factory _TailscalePeer.fromJson(Map<String, dynamic> json) => _$TailscalePeerFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String hostName;
@override@JsonKey() final  String dnsName;
@override@JsonKey() final  String os;
 final  List<String> _ips;
@override@JsonKey() List<String> get ips {
  if (_ips is EqualUnmodifiableListView) return _ips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ips);
}

@override@JsonKey() final  bool online;
@override@JsonKey() final  bool exitNode;
@override@JsonKey() final  bool exitNodeOption;
@override final  String? lastSeen;

/// Create a copy of TailscalePeer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscalePeerCopyWith<_TailscalePeer> get copyWith => __$TailscalePeerCopyWithImpl<_TailscalePeer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscalePeerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscalePeer&&(identical(other.id, id) || other.id == id)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.dnsName, dnsName) || other.dnsName == dnsName)&&(identical(other.os, os) || other.os == os)&&const DeepCollectionEquality().equals(other.ips, _ips)&&(identical(other.online, online) || other.online == online)&&(identical(other.exitNode, exitNode) || other.exitNode == exitNode)&&(identical(other.exitNodeOption, exitNodeOption) || other.exitNodeOption == exitNodeOption)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,hostName,dnsName,os,const DeepCollectionEquality().hash(_ips),online,exitNode,exitNodeOption,lastSeen);
}

@override
String toString() {
    return 'TailscalePeer(id: $id, hostName: $hostName, dnsName: $dnsName, os: $os, ips: $ips, online: $online, exitNode: $exitNode, exitNodeOption: $exitNodeOption, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$TailscalePeerCopyWith<$Res> implements $TailscalePeerCopyWith<$Res> {
  factory _$TailscalePeerCopyWith(_TailscalePeer value, $Res Function(_TailscalePeer) _then) = __$TailscalePeerCopyWithImpl;
@override @useResult
$Res call({
 String id, String hostName, String dnsName, String os, List<String> ips, bool online, bool exitNode, bool exitNodeOption, String? lastSeen
});




}
/// @nodoc
class __$TailscalePeerCopyWithImpl<$Res>
    implements _$TailscalePeerCopyWith<$Res> {
  __$TailscalePeerCopyWithImpl(this._self, this._then);

  final _TailscalePeer _self;
  final $Res Function(_TailscalePeer) _then;

/// Create a copy of TailscalePeer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hostName = null,Object? dnsName = null,Object? os = null,Object? ips = null,Object? online = null,Object? exitNode = null,Object? exitNodeOption = null,Object? lastSeen = freezed,}) {
  return _then(_TailscalePeer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,dnsName: null == dnsName ? _self.dnsName : dnsName // ignore: cast_nullable_to_non_nullable
as String,os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,ips: null == ips ? _self._ips : ips // ignore: cast_nullable_to_non_nullable
as List<String>,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,exitNode: null == exitNode ? _self.exitNode : exitNode // ignore: cast_nullable_to_non_nullable
as bool,exitNodeOption: null == exitNodeOption ? _self.exitNodeOption : exitNodeOption // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TailscaleNetStatus {

 bool get started; String get backendState; String? get authUrl; List<String> get health; String get magicDnsSuffix; TailscalePeer? get self; List<TailscalePeer> get peers; String? get error; String? get dialerProxy;/// How the node last reached each DERP region, by region code: `direct`
/// or `proxy`.
 Map<String, String> get derpRoutes; String? get exitNodeError;
/// Create a copy of TailscaleNetStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleNetStatusCopyWith<TailscaleNetStatus> get copyWith => _$TailscaleNetStatusCopyWithImpl<TailscaleNetStatus>(this as TailscaleNetStatus, _$identity);

  /// Serializes this TailscaleNetStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TailscaleNetStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleNetStatus&&(identical(other.started, _this.started) || other.started == _this.started)&&(identical(other.backendState, _this.backendState) || other.backendState == _this.backendState)&&(identical(other.authUrl, _this.authUrl) || other.authUrl == _this.authUrl)&&const DeepCollectionEquality().equals(other.health, _this.health)&&(identical(other.magicDnsSuffix, _this.magicDnsSuffix) || other.magicDnsSuffix == _this.magicDnsSuffix)&&(identical(other.self, _this.self) || other.self == _this.self)&&const DeepCollectionEquality().equals(other.peers, _this.peers)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.dialerProxy, _this.dialerProxy) || other.dialerProxy == _this.dialerProxy)&&const DeepCollectionEquality().equals(other.derpRoutes, _this.derpRoutes)&&(identical(other.exitNodeError, _this.exitNodeError) || other.exitNodeError == _this.exitNodeError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TailscaleNetStatus;
  return Object.hash(runtimeType,_this.started,_this.backendState,_this.authUrl,const DeepCollectionEquality().hash(_this.health),_this.magicDnsSuffix,_this.self,const DeepCollectionEquality().hash(_this.peers),_this.error,_this.dialerProxy,const DeepCollectionEquality().hash(_this.derpRoutes),_this.exitNodeError);
}

@override
String toString() {
  final _this = this as TailscaleNetStatus;
  return 'TailscaleNetStatus(started: ${_this.started}, backendState: ${_this.backendState}, authUrl: ${_this.authUrl}, health: ${_this.health}, magicDnsSuffix: ${_this.magicDnsSuffix}, self: ${_this.self}, peers: ${_this.peers}, error: ${_this.error}, dialerProxy: ${_this.dialerProxy}, derpRoutes: ${_this.derpRoutes}, exitNodeError: ${_this.exitNodeError})';
}


}

/// @nodoc
abstract mixin class $TailscaleNetStatusCopyWith<$Res>  {
  factory $TailscaleNetStatusCopyWith(TailscaleNetStatus value, $Res Function(TailscaleNetStatus) _then) = _$TailscaleNetStatusCopyWithImpl;
@useResult
$Res call({
 bool started, String backendState, String? authUrl, List<String> health, String magicDnsSuffix, TailscalePeer? self, List<TailscalePeer> peers, String? error, String? dialerProxy, Map<String, String> derpRoutes, String? exitNodeError
});


$TailscalePeerCopyWith<$Res>? get self;

}
/// @nodoc
class _$TailscaleNetStatusCopyWithImpl<$Res>
    implements $TailscaleNetStatusCopyWith<$Res> {
  _$TailscaleNetStatusCopyWithImpl(this._self, this._then);

  final TailscaleNetStatus _self;
  final $Res Function(TailscaleNetStatus) _then;

/// Create a copy of TailscaleNetStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? started = null,Object? backendState = null,Object? authUrl = freezed,Object? health = null,Object? magicDnsSuffix = null,Object? self = freezed,Object? peers = null,Object? error = freezed,Object? dialerProxy = freezed,Object? derpRoutes = null,Object? exitNodeError = freezed,}) {
  return _then(TailscaleNetStatus(
started: null == started ? _self.started : started // ignore: cast_nullable_to_non_nullable
as bool,backendState: null == backendState ? _self.backendState : backendState // ignore: cast_nullable_to_non_nullable
as String,authUrl: freezed == authUrl ? _self.authUrl : authUrl // ignore: cast_nullable_to_non_nullable
as String?,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as List<String>,magicDnsSuffix: null == magicDnsSuffix ? _self.magicDnsSuffix : magicDnsSuffix // ignore: cast_nullable_to_non_nullable
as String,self: freezed == self ? _self.self : self // ignore: cast_nullable_to_non_nullable
as TailscalePeer?,peers: null == peers ? _self.peers : peers // ignore: cast_nullable_to_non_nullable
as List<TailscalePeer>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,dialerProxy: freezed == dialerProxy ? _self.dialerProxy : dialerProxy // ignore: cast_nullable_to_non_nullable
as String?,derpRoutes: null == derpRoutes ? _self.derpRoutes : derpRoutes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,exitNodeError: freezed == exitNodeError ? _self.exitNodeError : exitNodeError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TailscaleNetStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TailscalePeerCopyWith<$Res>? get self {
    if (_self.self == null) {
    return null;
  }

  return $TailscalePeerCopyWith<$Res>(_self.self!, (value) {
    return _then(_self.copyWith(self: value));
  });
}
}


/// Adds pattern-matching-related methods to [TailscaleNetStatus].
extension TailscaleNetStatusPatterns on TailscaleNetStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleNetStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleNetStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleNetStatus value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleNetStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleNetStatus value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleNetStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool started,  String backendState,  String? authUrl,  List<String> health,  String magicDnsSuffix,  TailscalePeer? self,  List<TailscalePeer> peers,  String? error,  String? dialerProxy,  Map<String, String> derpRoutes,  String? exitNodeError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleNetStatus() when $default != null:
return $default(_that.started,_that.backendState,_that.authUrl,_that.health,_that.magicDnsSuffix,_that.self,_that.peers,_that.error,_that.dialerProxy,_that.derpRoutes,_that.exitNodeError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool started,  String backendState,  String? authUrl,  List<String> health,  String magicDnsSuffix,  TailscalePeer? self,  List<TailscalePeer> peers,  String? error,  String? dialerProxy,  Map<String, String> derpRoutes,  String? exitNodeError)  $default,) {final _that = this;
switch (_that) {
case _TailscaleNetStatus():
return $default(_that.started,_that.backendState,_that.authUrl,_that.health,_that.magicDnsSuffix,_that.self,_that.peers,_that.error,_that.dialerProxy,_that.derpRoutes,_that.exitNodeError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool started,  String backendState,  String? authUrl,  List<String> health,  String magicDnsSuffix,  TailscalePeer? self,  List<TailscalePeer> peers,  String? error,  String? dialerProxy,  Map<String, String> derpRoutes,  String? exitNodeError)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleNetStatus() when $default != null:
return $default(_that.started,_that.backendState,_that.authUrl,_that.health,_that.magicDnsSuffix,_that.self,_that.peers,_that.error,_that.dialerProxy,_that.derpRoutes,_that.exitNodeError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleNetStatus implements TailscaleNetStatus {
  const _TailscaleNetStatus({this.started = false, this.backendState = '', this.authUrl,  List<String> health = const [], this.magicDnsSuffix = '', this.self,  List<TailscalePeer> peers = const [], this.error, this.dialerProxy,  Map<String, String> derpRoutes = const {}, this.exitNodeError}): _health = health,_peers = peers,_derpRoutes = derpRoutes;
  factory _TailscaleNetStatus.fromJson(Map<String, dynamic> json) => _$TailscaleNetStatusFromJson(json);

@override@JsonKey() final  bool started;
@override@JsonKey() final  String backendState;
@override final  String? authUrl;
 final  List<String> _health;
@override@JsonKey() List<String> get health {
  if (_health is EqualUnmodifiableListView) return _health;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_health);
}

@override@JsonKey() final  String magicDnsSuffix;
@override final  TailscalePeer? self;
 final  List<TailscalePeer> _peers;
@override@JsonKey() List<TailscalePeer> get peers {
  if (_peers is EqualUnmodifiableListView) return _peers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_peers);
}

@override final  String? error;
@override final  String? dialerProxy;
/// How the node last reached each DERP region, by region code: `direct`
/// or `proxy`.
 final  Map<String, String> _derpRoutes;
/// How the node last reached each DERP region, by region code: `direct`
/// or `proxy`.
@override@JsonKey() Map<String, String> get derpRoutes {
  if (_derpRoutes is EqualUnmodifiableMapView) return _derpRoutes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_derpRoutes);
}

@override final  String? exitNodeError;

/// Create a copy of TailscaleNetStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleNetStatusCopyWith<_TailscaleNetStatus> get copyWith => __$TailscaleNetStatusCopyWithImpl<_TailscaleNetStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscaleNetStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleNetStatus&&(identical(other.started, started) || other.started == started)&&(identical(other.backendState, backendState) || other.backendState == backendState)&&(identical(other.authUrl, authUrl) || other.authUrl == authUrl)&&const DeepCollectionEquality().equals(other.health, _health)&&(identical(other.magicDnsSuffix, magicDnsSuffix) || other.magicDnsSuffix == magicDnsSuffix)&&(identical(other.self, self) || other.self == self)&&const DeepCollectionEquality().equals(other.peers, _peers)&&(identical(other.error, error) || other.error == error)&&(identical(other.dialerProxy, dialerProxy) || other.dialerProxy == dialerProxy)&&const DeepCollectionEquality().equals(other.derpRoutes, _derpRoutes)&&(identical(other.exitNodeError, exitNodeError) || other.exitNodeError == exitNodeError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,started,backendState,authUrl,const DeepCollectionEquality().hash(_health),magicDnsSuffix,self,const DeepCollectionEquality().hash(_peers),error,dialerProxy,const DeepCollectionEquality().hash(_derpRoutes),exitNodeError);
}

@override
String toString() {
    return 'TailscaleNetStatus(started: $started, backendState: $backendState, authUrl: $authUrl, health: $health, magicDnsSuffix: $magicDnsSuffix, self: $self, peers: $peers, error: $error, dialerProxy: $dialerProxy, derpRoutes: $derpRoutes, exitNodeError: $exitNodeError)';
}


}

/// @nodoc
abstract mixin class _$TailscaleNetStatusCopyWith<$Res> implements $TailscaleNetStatusCopyWith<$Res> {
  factory _$TailscaleNetStatusCopyWith(_TailscaleNetStatus value, $Res Function(_TailscaleNetStatus) _then) = __$TailscaleNetStatusCopyWithImpl;
@override @useResult
$Res call({
 bool started, String backendState, String? authUrl, List<String> health, String magicDnsSuffix, TailscalePeer? self, List<TailscalePeer> peers, String? error, String? dialerProxy, Map<String, String> derpRoutes, String? exitNodeError
});


@override $TailscalePeerCopyWith<$Res>? get self;

}
/// @nodoc
class __$TailscaleNetStatusCopyWithImpl<$Res>
    implements _$TailscaleNetStatusCopyWith<$Res> {
  __$TailscaleNetStatusCopyWithImpl(this._self, this._then);

  final _TailscaleNetStatus _self;
  final $Res Function(_TailscaleNetStatus) _then;

/// Create a copy of TailscaleNetStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? started = null,Object? backendState = null,Object? authUrl = freezed,Object? health = null,Object? magicDnsSuffix = null,Object? self = freezed,Object? peers = null,Object? error = freezed,Object? dialerProxy = freezed,Object? derpRoutes = null,Object? exitNodeError = freezed,}) {
  return _then(_TailscaleNetStatus(
started: null == started ? _self.started : started // ignore: cast_nullable_to_non_nullable
as bool,backendState: null == backendState ? _self.backendState : backendState // ignore: cast_nullable_to_non_nullable
as String,authUrl: freezed == authUrl ? _self.authUrl : authUrl // ignore: cast_nullable_to_non_nullable
as String?,health: null == health ? _self._health : health // ignore: cast_nullable_to_non_nullable
as List<String>,magicDnsSuffix: null == magicDnsSuffix ? _self.magicDnsSuffix : magicDnsSuffix // ignore: cast_nullable_to_non_nullable
as String,self: freezed == self ? _self.self : self // ignore: cast_nullable_to_non_nullable
as TailscalePeer?,peers: null == peers ? _self._peers : peers // ignore: cast_nullable_to_non_nullable
as List<TailscalePeer>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,dialerProxy: freezed == dialerProxy ? _self.dialerProxy : dialerProxy // ignore: cast_nullable_to_non_nullable
as String?,derpRoutes: null == derpRoutes ? _self._derpRoutes : derpRoutes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,exitNodeError: freezed == exitNodeError ? _self.exitNodeError : exitNodeError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TailscaleNetStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TailscalePeerCopyWith<$Res>? get self {
    if (_self.self == null) {
    return null;
  }

  return $TailscalePeerCopyWith<$Res>(_self.self!, (value) {
    return _then(_self.copyWith(self: value));
  });
}
}


/// @nodoc
mixin _$TailscalePingResult {

 String get target; int get latencyMs; String? get endpoint; int? get derpRegionId; String? get derpRegionCode; String? get peerRelay; String? get error;
/// Create a copy of TailscalePingResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscalePingResultCopyWith<TailscalePingResult> get copyWith => _$TailscalePingResultCopyWithImpl<TailscalePingResult>(this as TailscalePingResult, _$identity);

  /// Serializes this TailscalePingResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TailscalePingResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscalePingResult&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.latencyMs, _this.latencyMs) || other.latencyMs == _this.latencyMs)&&(identical(other.endpoint, _this.endpoint) || other.endpoint == _this.endpoint)&&(identical(other.derpRegionId, _this.derpRegionId) || other.derpRegionId == _this.derpRegionId)&&(identical(other.derpRegionCode, _this.derpRegionCode) || other.derpRegionCode == _this.derpRegionCode)&&(identical(other.peerRelay, _this.peerRelay) || other.peerRelay == _this.peerRelay)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TailscalePingResult;
  return Object.hash(runtimeType,_this.target,_this.latencyMs,_this.endpoint,_this.derpRegionId,_this.derpRegionCode,_this.peerRelay,_this.error);
}

@override
String toString() {
  final _this = this as TailscalePingResult;
  return 'TailscalePingResult(target: ${_this.target}, latencyMs: ${_this.latencyMs}, endpoint: ${_this.endpoint}, derpRegionId: ${_this.derpRegionId}, derpRegionCode: ${_this.derpRegionCode}, peerRelay: ${_this.peerRelay}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $TailscalePingResultCopyWith<$Res>  {
  factory $TailscalePingResultCopyWith(TailscalePingResult value, $Res Function(TailscalePingResult) _then) = _$TailscalePingResultCopyWithImpl;
@useResult
$Res call({
 String target, int latencyMs, String? endpoint, int? derpRegionId, String? derpRegionCode, String? peerRelay, String? error
});




}
/// @nodoc
class _$TailscalePingResultCopyWithImpl<$Res>
    implements $TailscalePingResultCopyWith<$Res> {
  _$TailscalePingResultCopyWithImpl(this._self, this._then);

  final TailscalePingResult _self;
  final $Res Function(TailscalePingResult) _then;

/// Create a copy of TailscalePingResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? latencyMs = null,Object? endpoint = freezed,Object? derpRegionId = freezed,Object? derpRegionCode = freezed,Object? peerRelay = freezed,Object? error = freezed,}) {
  return _then(TailscalePingResult(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,derpRegionId: freezed == derpRegionId ? _self.derpRegionId : derpRegionId // ignore: cast_nullable_to_non_nullable
as int?,derpRegionCode: freezed == derpRegionCode ? _self.derpRegionCode : derpRegionCode // ignore: cast_nullable_to_non_nullable
as String?,peerRelay: freezed == peerRelay ? _self.peerRelay : peerRelay // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscalePingResult].
extension TailscalePingResultPatterns on TailscalePingResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscalePingResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscalePingResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscalePingResult value)  $default,){
final _that = this;
switch (_that) {
case _TailscalePingResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscalePingResult value)?  $default,){
final _that = this;
switch (_that) {
case _TailscalePingResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String target,  int latencyMs,  String? endpoint,  int? derpRegionId,  String? derpRegionCode,  String? peerRelay,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscalePingResult() when $default != null:
return $default(_that.target,_that.latencyMs,_that.endpoint,_that.derpRegionId,_that.derpRegionCode,_that.peerRelay,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String target,  int latencyMs,  String? endpoint,  int? derpRegionId,  String? derpRegionCode,  String? peerRelay,  String? error)  $default,) {final _that = this;
switch (_that) {
case _TailscalePingResult():
return $default(_that.target,_that.latencyMs,_that.endpoint,_that.derpRegionId,_that.derpRegionCode,_that.peerRelay,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String target,  int latencyMs,  String? endpoint,  int? derpRegionId,  String? derpRegionCode,  String? peerRelay,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _TailscalePingResult() when $default != null:
return $default(_that.target,_that.latencyMs,_that.endpoint,_that.derpRegionId,_that.derpRegionCode,_that.peerRelay,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscalePingResult implements TailscalePingResult {
  const _TailscalePingResult({this.target = '', this.latencyMs = -1, this.endpoint, this.derpRegionId, this.derpRegionCode, this.peerRelay, this.error});
  factory _TailscalePingResult.fromJson(Map<String, dynamic> json) => _$TailscalePingResultFromJson(json);

@override@JsonKey() final  String target;
@override@JsonKey() final  int latencyMs;
@override final  String? endpoint;
@override final  int? derpRegionId;
@override final  String? derpRegionCode;
@override final  String? peerRelay;
@override final  String? error;

/// Create a copy of TailscalePingResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscalePingResultCopyWith<_TailscalePingResult> get copyWith => __$TailscalePingResultCopyWithImpl<_TailscalePingResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscalePingResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscalePingResult&&(identical(other.target, target) || other.target == target)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.derpRegionId, derpRegionId) || other.derpRegionId == derpRegionId)&&(identical(other.derpRegionCode, derpRegionCode) || other.derpRegionCode == derpRegionCode)&&(identical(other.peerRelay, peerRelay) || other.peerRelay == peerRelay)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,target,latencyMs,endpoint,derpRegionId,derpRegionCode,peerRelay,error);
}

@override
String toString() {
    return 'TailscalePingResult(target: $target, latencyMs: $latencyMs, endpoint: $endpoint, derpRegionId: $derpRegionId, derpRegionCode: $derpRegionCode, peerRelay: $peerRelay, error: $error)';
}


}

/// @nodoc
abstract mixin class _$TailscalePingResultCopyWith<$Res> implements $TailscalePingResultCopyWith<$Res> {
  factory _$TailscalePingResultCopyWith(_TailscalePingResult value, $Res Function(_TailscalePingResult) _then) = __$TailscalePingResultCopyWithImpl;
@override @useResult
$Res call({
 String target, int latencyMs, String? endpoint, int? derpRegionId, String? derpRegionCode, String? peerRelay, String? error
});




}
/// @nodoc
class __$TailscalePingResultCopyWithImpl<$Res>
    implements _$TailscalePingResultCopyWith<$Res> {
  __$TailscalePingResultCopyWithImpl(this._self, this._then);

  final _TailscalePingResult _self;
  final $Res Function(_TailscalePingResult) _then;

/// Create a copy of TailscalePingResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? latencyMs = null,Object? endpoint = freezed,Object? derpRegionId = freezed,Object? derpRegionCode = freezed,Object? peerRelay = freezed,Object? error = freezed,}) {
  return _then(_TailscalePingResult(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,derpRegionId: freezed == derpRegionId ? _self.derpRegionId : derpRegionId // ignore: cast_nullable_to_non_nullable
as int?,derpRegionCode: freezed == derpRegionCode ? _self.derpRegionCode : derpRegionCode // ignore: cast_nullable_to_non_nullable
as String?,peerRelay: freezed == peerRelay ? _self.peerRelay : peerRelay // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
