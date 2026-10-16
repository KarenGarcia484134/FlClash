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

 bool get enable; String get hostname; String get authKey; String get controlUrl; bool get acceptRoutes; String get exitNode; bool get ephemeral; bool get udp; List<String> get dnsSuffixes;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleProps&&(identical(other.enable, _this.enable) || other.enable == _this.enable)&&(identical(other.hostname, _this.hostname) || other.hostname == _this.hostname)&&(identical(other.authKey, _this.authKey) || other.authKey == _this.authKey)&&(identical(other.controlUrl, _this.controlUrl) || other.controlUrl == _this.controlUrl)&&(identical(other.acceptRoutes, _this.acceptRoutes) || other.acceptRoutes == _this.acceptRoutes)&&(identical(other.exitNode, _this.exitNode) || other.exitNode == _this.exitNode)&&(identical(other.ephemeral, _this.ephemeral) || other.ephemeral == _this.ephemeral)&&(identical(other.udp, _this.udp) || other.udp == _this.udp)&&const DeepCollectionEquality().equals(other.dnsSuffixes, _this.dnsSuffixes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TailscaleProps;
  return Object.hash(runtimeType,_this.enable,_this.hostname,_this.authKey,_this.controlUrl,_this.acceptRoutes,_this.exitNode,_this.ephemeral,_this.udp,const DeepCollectionEquality().hash(_this.dnsSuffixes));
}

@override
String toString() {
  final _this = this as TailscaleProps;
  return 'TailscaleProps(enable: ${_this.enable}, hostname: ${_this.hostname}, authKey: ${_this.authKey}, controlUrl: ${_this.controlUrl}, acceptRoutes: ${_this.acceptRoutes}, exitNode: ${_this.exitNode}, ephemeral: ${_this.ephemeral}, udp: ${_this.udp}, dnsSuffixes: ${_this.dnsSuffixes})';
}


}

/// @nodoc
abstract mixin class $TailscalePropsCopyWith<$Res>  {
  factory $TailscalePropsCopyWith(TailscaleProps value, $Res Function(TailscaleProps) _then) = _$TailscalePropsCopyWithImpl;
@useResult
$Res call({
 bool enable, String hostname, String authKey, String controlUrl, bool acceptRoutes, String exitNode, bool ephemeral, bool udp, List<String> dnsSuffixes
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
@pragma('vm:prefer-inline') @override $Res call({Object? enable = null,Object? hostname = null,Object? authKey = null,Object? controlUrl = null,Object? acceptRoutes = null,Object? exitNode = null,Object? ephemeral = null,Object? udp = null,Object? dnsSuffixes = null,}) {
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
as List<String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enable,  String hostname,  String authKey,  String controlUrl,  bool acceptRoutes,  String exitNode,  bool ephemeral,  bool udp,  List<String> dnsSuffixes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleProps() when $default != null:
return $default(_that.enable,_that.hostname,_that.authKey,_that.controlUrl,_that.acceptRoutes,_that.exitNode,_that.ephemeral,_that.udp,_that.dnsSuffixes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enable,  String hostname,  String authKey,  String controlUrl,  bool acceptRoutes,  String exitNode,  bool ephemeral,  bool udp,  List<String> dnsSuffixes)  $default,) {final _that = this;
switch (_that) {
case _TailscaleProps():
return $default(_that.enable,_that.hostname,_that.authKey,_that.controlUrl,_that.acceptRoutes,_that.exitNode,_that.ephemeral,_that.udp,_that.dnsSuffixes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enable,  String hostname,  String authKey,  String controlUrl,  bool acceptRoutes,  String exitNode,  bool ephemeral,  bool udp,  List<String> dnsSuffixes)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleProps() when $default != null:
return $default(_that.enable,_that.hostname,_that.authKey,_that.controlUrl,_that.acceptRoutes,_that.exitNode,_that.ephemeral,_that.udp,_that.dnsSuffixes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleProps implements TailscaleProps {
  const _TailscaleProps({this.enable = false, this.hostname = '', this.authKey = '', this.controlUrl = '', this.acceptRoutes = true, this.exitNode = '', this.ephemeral = false, this.udp = true,  List<String> dnsSuffixes = const []}): _dnsSuffixes = dnsSuffixes;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleProps&&(identical(other.enable, enable) || other.enable == enable)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.authKey, authKey) || other.authKey == authKey)&&(identical(other.controlUrl, controlUrl) || other.controlUrl == controlUrl)&&(identical(other.acceptRoutes, acceptRoutes) || other.acceptRoutes == acceptRoutes)&&(identical(other.exitNode, exitNode) || other.exitNode == exitNode)&&(identical(other.ephemeral, ephemeral) || other.ephemeral == ephemeral)&&(identical(other.udp, udp) || other.udp == udp)&&const DeepCollectionEquality().equals(other.dnsSuffixes, _dnsSuffixes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enable,hostname,authKey,controlUrl,acceptRoutes,exitNode,ephemeral,udp,const DeepCollectionEquality().hash(_dnsSuffixes));
}

@override
String toString() {
    return 'TailscaleProps(enable: $enable, hostname: $hostname, authKey: $authKey, controlUrl: $controlUrl, acceptRoutes: $acceptRoutes, exitNode: $exitNode, ephemeral: $ephemeral, udp: $udp, dnsSuffixes: $dnsSuffixes)';
}


}

/// @nodoc
abstract mixin class _$TailscalePropsCopyWith<$Res> implements $TailscalePropsCopyWith<$Res> {
  factory _$TailscalePropsCopyWith(_TailscaleProps value, $Res Function(_TailscaleProps) _then) = __$TailscalePropsCopyWithImpl;
@override @useResult
$Res call({
 bool enable, String hostname, String authKey, String controlUrl, bool acceptRoutes, String exitNode, bool ephemeral, bool udp, List<String> dnsSuffixes
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
@override @pragma('vm:prefer-inline') $Res call({Object? enable = null,Object? hostname = null,Object? authKey = null,Object? controlUrl = null,Object? acceptRoutes = null,Object? exitNode = null,Object? ephemeral = null,Object? udp = null,Object? dnsSuffixes = null,}) {
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
as List<String>,
  ));
}


}

/// @nodoc
mixin _$TailscaleStatus {

 TailscalePhase get phase; String? get loginUrl; String? get proxyName;
/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleStatusCopyWith<TailscaleStatus> get copyWith => _$TailscaleStatusCopyWithImpl<TailscaleStatus>(this as TailscaleStatus, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TailscaleStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleStatus&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.loginUrl, _this.loginUrl) || other.loginUrl == _this.loginUrl)&&(identical(other.proxyName, _this.proxyName) || other.proxyName == _this.proxyName));
}


@override
int get hashCode {
  final _this = this as TailscaleStatus;
  return Object.hash(runtimeType,_this.phase,_this.loginUrl,_this.proxyName);
}

@override
String toString() {
  final _this = this as TailscaleStatus;
  return 'TailscaleStatus(phase: ${_this.phase}, loginUrl: ${_this.loginUrl}, proxyName: ${_this.proxyName})';
}


}

/// @nodoc
abstract mixin class $TailscaleStatusCopyWith<$Res>  {
  factory $TailscaleStatusCopyWith(TailscaleStatus value, $Res Function(TailscaleStatus) _then) = _$TailscaleStatusCopyWithImpl;
@useResult
$Res call({
 TailscalePhase phase, String? loginUrl, String? proxyName
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
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? loginUrl = freezed,Object? proxyName = freezed,}) {
  return _then(TailscaleStatus(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TailscalePhase,loginUrl: freezed == loginUrl ? _self.loginUrl : loginUrl // ignore: cast_nullable_to_non_nullable
as String?,proxyName: freezed == proxyName ? _self.proxyName : proxyName // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TailscalePhase phase,  String? loginUrl,  String? proxyName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that.phase,_that.loginUrl,_that.proxyName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TailscalePhase phase,  String? loginUrl,  String? proxyName)  $default,) {final _that = this;
switch (_that) {
case _TailscaleStatus():
return $default(_that.phase,_that.loginUrl,_that.proxyName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TailscalePhase phase,  String? loginUrl,  String? proxyName)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleStatus() when $default != null:
return $default(_that.phase,_that.loginUrl,_that.proxyName);case _:
  return null;

}
}

}

/// @nodoc


class _TailscaleStatus implements TailscaleStatus {
  const _TailscaleStatus({this.phase = TailscalePhase.idle, this.loginUrl, this.proxyName});
  

@override@JsonKey() final  TailscalePhase phase;
@override final  String? loginUrl;
@override final  String? proxyName;

/// Create a copy of TailscaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleStatusCopyWith<_TailscaleStatus> get copyWith => __$TailscaleStatusCopyWithImpl<_TailscaleStatus>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleStatus&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.loginUrl, loginUrl) || other.loginUrl == loginUrl)&&(identical(other.proxyName, proxyName) || other.proxyName == proxyName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,loginUrl,proxyName);
}

@override
String toString() {
    return 'TailscaleStatus(phase: $phase, loginUrl: $loginUrl, proxyName: $proxyName)';
}


}

/// @nodoc
abstract mixin class _$TailscaleStatusCopyWith<$Res> implements $TailscaleStatusCopyWith<$Res> {
  factory _$TailscaleStatusCopyWith(_TailscaleStatus value, $Res Function(_TailscaleStatus) _then) = __$TailscaleStatusCopyWithImpl;
@override @useResult
$Res call({
 TailscalePhase phase, String? loginUrl, String? proxyName
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
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? loginUrl = freezed,Object? proxyName = freezed,}) {
  return _then(_TailscaleStatus(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TailscalePhase,loginUrl: freezed == loginUrl ? _self.loginUrl : loginUrl // ignore: cast_nullable_to_non_nullable
as String?,proxyName: freezed == proxyName ? _self.proxyName : proxyName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
