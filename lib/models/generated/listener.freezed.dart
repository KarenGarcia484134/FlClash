// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../listener.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListenerUser {

 String get username; String get password;
/// Create a copy of ListenerUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenerUserCopyWith<ListenerUser> get copyWith => _$ListenerUserCopyWithImpl<ListenerUser>(this as ListenerUser, _$identity);

  /// Serializes this ListenerUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ListenerUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenerUser&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.password, _this.password) || other.password == _this.password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ListenerUser;
  return Object.hash(runtimeType,_this.username,_this.password);
}

@override
String toString() {
  final _this = this as ListenerUser;
  return 'ListenerUser(username: ${_this.username}, password: ${_this.password})';
}


}

/// @nodoc
abstract mixin class $ListenerUserCopyWith<$Res>  {
  factory $ListenerUserCopyWith(ListenerUser value, $Res Function(ListenerUser) _then) = _$ListenerUserCopyWithImpl;
@useResult
$Res call({
 String username, String password
});




}
/// @nodoc
class _$ListenerUserCopyWithImpl<$Res>
    implements $ListenerUserCopyWith<$Res> {
  _$ListenerUserCopyWithImpl(this._self, this._then);

  final ListenerUser _self;
  final $Res Function(ListenerUser) _then;

/// Create a copy of ListenerUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? password = null,}) {
  return _then(ListenerUser(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ListenerUser].
extension ListenerUserPatterns on ListenerUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListenerUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListenerUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListenerUser value)  $default,){
final _that = this;
switch (_that) {
case _ListenerUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListenerUser value)?  $default,){
final _that = this;
switch (_that) {
case _ListenerUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListenerUser() when $default != null:
return $default(_that.username,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String password)  $default,) {final _that = this;
switch (_that) {
case _ListenerUser():
return $default(_that.username,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String password)?  $default,) {final _that = this;
switch (_that) {
case _ListenerUser() when $default != null:
return $default(_that.username,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListenerUser implements ListenerUser {
  const _ListenerUser({this.username = '', this.password = ''});
  factory _ListenerUser.fromJson(Map<String, dynamic> json) => _$ListenerUserFromJson(json);

@override@JsonKey() final  String username;
@override@JsonKey() final  String password;

/// Create a copy of ListenerUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListenerUserCopyWith<_ListenerUser> get copyWith => __$ListenerUserCopyWithImpl<_ListenerUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListenerUserToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListenerUser&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,username,password);
}

@override
String toString() {
    return 'ListenerUser(username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class _$ListenerUserCopyWith<$Res> implements $ListenerUserCopyWith<$Res> {
  factory _$ListenerUserCopyWith(_ListenerUser value, $Res Function(_ListenerUser) _then) = __$ListenerUserCopyWithImpl;
@override @useResult
$Res call({
 String username, String password
});




}
/// @nodoc
class __$ListenerUserCopyWithImpl<$Res>
    implements _$ListenerUserCopyWith<$Res> {
  __$ListenerUserCopyWithImpl(this._self, this._then);

  final _ListenerUser _self;
  final $Res Function(_ListenerUser) _then;

/// Create a copy of ListenerUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? password = null,}) {
  return _then(_ListenerUser(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InboundListenerProps {

 String get id; String get name; bool get enabled; ListenerType get type; String get listen; int get port; bool get udp; List<ListenerUser> get users; String get proxy; String get rule;
/// Create a copy of InboundListenerProps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboundListenerPropsCopyWith<InboundListenerProps> get copyWith => _$InboundListenerPropsCopyWithImpl<InboundListenerProps>(this as InboundListenerProps, _$identity);

  /// Serializes this InboundListenerProps to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InboundListenerProps;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboundListenerProps&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.listen, _this.listen) || other.listen == _this.listen)&&(identical(other.port, _this.port) || other.port == _this.port)&&(identical(other.udp, _this.udp) || other.udp == _this.udp)&&const DeepCollectionEquality().equals(other.users, _this.users)&&(identical(other.proxy, _this.proxy) || other.proxy == _this.proxy)&&(identical(other.rule, _this.rule) || other.rule == _this.rule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InboundListenerProps;
  return Object.hash(runtimeType,_this.id,_this.name,_this.enabled,_this.type,_this.listen,_this.port,_this.udp,const DeepCollectionEquality().hash(_this.users),_this.proxy,_this.rule);
}

@override
String toString() {
  final _this = this as InboundListenerProps;
  return 'InboundListenerProps(id: ${_this.id}, name: ${_this.name}, enabled: ${_this.enabled}, type: ${_this.type}, listen: ${_this.listen}, port: ${_this.port}, udp: ${_this.udp}, users: ${_this.users}, proxy: ${_this.proxy}, rule: ${_this.rule})';
}


}

/// @nodoc
abstract mixin class $InboundListenerPropsCopyWith<$Res>  {
  factory $InboundListenerPropsCopyWith(InboundListenerProps value, $Res Function(InboundListenerProps) _then) = _$InboundListenerPropsCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool enabled, ListenerType type, String listen, int port, bool udp, List<ListenerUser> users, String proxy, String rule
});




}
/// @nodoc
class _$InboundListenerPropsCopyWithImpl<$Res>
    implements $InboundListenerPropsCopyWith<$Res> {
  _$InboundListenerPropsCopyWithImpl(this._self, this._then);

  final InboundListenerProps _self;
  final $Res Function(InboundListenerProps) _then;

/// Create a copy of InboundListenerProps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? enabled = null,Object? type = null,Object? listen = null,Object? port = null,Object? udp = null,Object? users = null,Object? proxy = null,Object? rule = null,}) {
  return _then(InboundListenerProps(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ListenerType,listen: null == listen ? _self.listen : listen // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,udp: null == udp ? _self.udp : udp // ignore: cast_nullable_to_non_nullable
as bool,users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<ListenerUser>,proxy: null == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InboundListenerProps].
extension InboundListenerPropsPatterns on InboundListenerProps {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboundListenerProps value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboundListenerProps() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboundListenerProps value)  $default,){
final _that = this;
switch (_that) {
case _InboundListenerProps():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboundListenerProps value)?  $default,){
final _that = this;
switch (_that) {
case _InboundListenerProps() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool enabled,  ListenerType type,  String listen,  int port,  bool udp,  List<ListenerUser> users,  String proxy,  String rule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboundListenerProps() when $default != null:
return $default(_that.id,_that.name,_that.enabled,_that.type,_that.listen,_that.port,_that.udp,_that.users,_that.proxy,_that.rule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool enabled,  ListenerType type,  String listen,  int port,  bool udp,  List<ListenerUser> users,  String proxy,  String rule)  $default,) {final _that = this;
switch (_that) {
case _InboundListenerProps():
return $default(_that.id,_that.name,_that.enabled,_that.type,_that.listen,_that.port,_that.udp,_that.users,_that.proxy,_that.rule);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool enabled,  ListenerType type,  String listen,  int port,  bool udp,  List<ListenerUser> users,  String proxy,  String rule)?  $default,) {final _that = this;
switch (_that) {
case _InboundListenerProps() when $default != null:
return $default(_that.id,_that.name,_that.enabled,_that.type,_that.listen,_that.port,_that.udp,_that.users,_that.proxy,_that.rule);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboundListenerProps implements InboundListenerProps {
  const _InboundListenerProps({required this.id, this.name = '', this.enabled = true, this.type = ListenerType.mixed, this.listen = listenerLoopback, this.port = 0, this.udp = true,  List<ListenerUser> users = const [], this.proxy = '', this.rule = ''}): _users = users;
  factory _InboundListenerProps.fromJson(Map<String, dynamic> json) => _$InboundListenerPropsFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  ListenerType type;
@override@JsonKey() final  String listen;
@override@JsonKey() final  int port;
@override@JsonKey() final  bool udp;
 final  List<ListenerUser> _users;
@override@JsonKey() List<ListenerUser> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}

@override@JsonKey() final  String proxy;
@override@JsonKey() final  String rule;

/// Create a copy of InboundListenerProps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboundListenerPropsCopyWith<_InboundListenerProps> get copyWith => __$InboundListenerPropsCopyWithImpl<_InboundListenerProps>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboundListenerPropsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboundListenerProps&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.type, type) || other.type == type)&&(identical(other.listen, listen) || other.listen == listen)&&(identical(other.port, port) || other.port == port)&&(identical(other.udp, udp) || other.udp == udp)&&const DeepCollectionEquality().equals(other.users, _users)&&(identical(other.proxy, proxy) || other.proxy == proxy)&&(identical(other.rule, rule) || other.rule == rule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,enabled,type,listen,port,udp,const DeepCollectionEquality().hash(_users),proxy,rule);
}

@override
String toString() {
    return 'InboundListenerProps(id: $id, name: $name, enabled: $enabled, type: $type, listen: $listen, port: $port, udp: $udp, users: $users, proxy: $proxy, rule: $rule)';
}


}

/// @nodoc
abstract mixin class _$InboundListenerPropsCopyWith<$Res> implements $InboundListenerPropsCopyWith<$Res> {
  factory _$InboundListenerPropsCopyWith(_InboundListenerProps value, $Res Function(_InboundListenerProps) _then) = __$InboundListenerPropsCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool enabled, ListenerType type, String listen, int port, bool udp, List<ListenerUser> users, String proxy, String rule
});




}
/// @nodoc
class __$InboundListenerPropsCopyWithImpl<$Res>
    implements _$InboundListenerPropsCopyWith<$Res> {
  __$InboundListenerPropsCopyWithImpl(this._self, this._then);

  final _InboundListenerProps _self;
  final $Res Function(_InboundListenerProps) _then;

/// Create a copy of InboundListenerProps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? enabled = null,Object? type = null,Object? listen = null,Object? port = null,Object? udp = null,Object? users = null,Object? proxy = null,Object? rule = null,}) {
  return _then(_InboundListenerProps(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ListenerType,listen: null == listen ? _self.listen : listen // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,udp: null == udp ? _self.udp : udp // ignore: cast_nullable_to_non_nullable
as bool,users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<ListenerUser>,proxy: null == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ListenersProps {

 bool get enable; List<InboundListenerProps> get items;
/// Create a copy of ListenersProps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenersPropsCopyWith<ListenersProps> get copyWith => _$ListenersPropsCopyWithImpl<ListenersProps>(this as ListenersProps, _$identity);

  /// Serializes this ListenersProps to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ListenersProps;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenersProps&&(identical(other.enable, _this.enable) || other.enable == _this.enable)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ListenersProps;
  return Object.hash(runtimeType,_this.enable,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as ListenersProps;
  return 'ListenersProps(enable: ${_this.enable}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $ListenersPropsCopyWith<$Res>  {
  factory $ListenersPropsCopyWith(ListenersProps value, $Res Function(ListenersProps) _then) = _$ListenersPropsCopyWithImpl;
@useResult
$Res call({
 bool enable, List<InboundListenerProps> items
});




}
/// @nodoc
class _$ListenersPropsCopyWithImpl<$Res>
    implements $ListenersPropsCopyWith<$Res> {
  _$ListenersPropsCopyWithImpl(this._self, this._then);

  final ListenersProps _self;
  final $Res Function(ListenersProps) _then;

/// Create a copy of ListenersProps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enable = null,Object? items = null,}) {
  return _then(ListenersProps(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<InboundListenerProps>,
  ));
}

}


/// Adds pattern-matching-related methods to [ListenersProps].
extension ListenersPropsPatterns on ListenersProps {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListenersProps value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListenersProps() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListenersProps value)  $default,){
final _that = this;
switch (_that) {
case _ListenersProps():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListenersProps value)?  $default,){
final _that = this;
switch (_that) {
case _ListenersProps() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enable,  List<InboundListenerProps> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListenersProps() when $default != null:
return $default(_that.enable,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enable,  List<InboundListenerProps> items)  $default,) {final _that = this;
switch (_that) {
case _ListenersProps():
return $default(_that.enable,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enable,  List<InboundListenerProps> items)?  $default,) {final _that = this;
switch (_that) {
case _ListenersProps() when $default != null:
return $default(_that.enable,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListenersProps implements ListenersProps {
  const _ListenersProps({this.enable = true,  List<InboundListenerProps> items = const []}): _items = items;
  factory _ListenersProps.fromJson(Map<String, dynamic> json) => _$ListenersPropsFromJson(json);

@override@JsonKey() final  bool enable;
 final  List<InboundListenerProps> _items;
@override@JsonKey() List<InboundListenerProps> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ListenersProps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListenersPropsCopyWith<_ListenersProps> get copyWith => __$ListenersPropsCopyWithImpl<_ListenersProps>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListenersPropsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListenersProps&&(identical(other.enable, enable) || other.enable == enable)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enable,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'ListenersProps(enable: $enable, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ListenersPropsCopyWith<$Res> implements $ListenersPropsCopyWith<$Res> {
  factory _$ListenersPropsCopyWith(_ListenersProps value, $Res Function(_ListenersProps) _then) = __$ListenersPropsCopyWithImpl;
@override @useResult
$Res call({
 bool enable, List<InboundListenerProps> items
});




}
/// @nodoc
class __$ListenersPropsCopyWithImpl<$Res>
    implements _$ListenersPropsCopyWith<$Res> {
  __$ListenersPropsCopyWithImpl(this._self, this._then);

  final _ListenersProps _self;
  final $Res Function(_ListenersProps) _then;

/// Create a copy of ListenersProps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enable = null,Object? items = null,}) {
  return _then(_ListenersProps(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<InboundListenerProps>,
  ));
}


}

// dart format on
