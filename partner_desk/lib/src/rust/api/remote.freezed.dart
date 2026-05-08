// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InputCommand {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCommand);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InputCommand()';
}


}

/// @nodoc
class $InputCommandCopyWith<$Res>  {
$InputCommandCopyWith(InputCommand _, $Res Function(InputCommand) __);
}


/// Adds pattern-matching-related methods to [InputCommand].
extension InputCommandPatterns on InputCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InputCommand_MouseMove value)?  mouseMove,TResult Function( InputCommand_MouseLeftClick value)?  mouseLeftClick,TResult Function( InputCommand_MouseRightClick value)?  mouseRightClick,TResult Function( InputCommand_KeyboardType value)?  keyboardType,TResult Function( InputCommand_KeyboardSpecial value)?  keyboardSpecial,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InputCommand_MouseMove() when mouseMove != null:
return mouseMove(_that);case InputCommand_MouseLeftClick() when mouseLeftClick != null:
return mouseLeftClick(_that);case InputCommand_MouseRightClick() when mouseRightClick != null:
return mouseRightClick(_that);case InputCommand_KeyboardType() when keyboardType != null:
return keyboardType(_that);case InputCommand_KeyboardSpecial() when keyboardSpecial != null:
return keyboardSpecial(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InputCommand_MouseMove value)  mouseMove,required TResult Function( InputCommand_MouseLeftClick value)  mouseLeftClick,required TResult Function( InputCommand_MouseRightClick value)  mouseRightClick,required TResult Function( InputCommand_KeyboardType value)  keyboardType,required TResult Function( InputCommand_KeyboardSpecial value)  keyboardSpecial,}){
final _that = this;
switch (_that) {
case InputCommand_MouseMove():
return mouseMove(_that);case InputCommand_MouseLeftClick():
return mouseLeftClick(_that);case InputCommand_MouseRightClick():
return mouseRightClick(_that);case InputCommand_KeyboardType():
return keyboardType(_that);case InputCommand_KeyboardSpecial():
return keyboardSpecial(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InputCommand_MouseMove value)?  mouseMove,TResult? Function( InputCommand_MouseLeftClick value)?  mouseLeftClick,TResult? Function( InputCommand_MouseRightClick value)?  mouseRightClick,TResult? Function( InputCommand_KeyboardType value)?  keyboardType,TResult? Function( InputCommand_KeyboardSpecial value)?  keyboardSpecial,}){
final _that = this;
switch (_that) {
case InputCommand_MouseMove() when mouseMove != null:
return mouseMove(_that);case InputCommand_MouseLeftClick() when mouseLeftClick != null:
return mouseLeftClick(_that);case InputCommand_MouseRightClick() when mouseRightClick != null:
return mouseRightClick(_that);case InputCommand_KeyboardType() when keyboardType != null:
return keyboardType(_that);case InputCommand_KeyboardSpecial() when keyboardSpecial != null:
return keyboardSpecial(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double x,  double y,  double monitorWidth,  double monitorHeight)?  mouseMove,TResult Function()?  mouseLeftClick,TResult Function()?  mouseRightClick,TResult Function( String text)?  keyboardType,TResult Function( String keyName)?  keyboardSpecial,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InputCommand_MouseMove() when mouseMove != null:
return mouseMove(_that.x,_that.y,_that.monitorWidth,_that.monitorHeight);case InputCommand_MouseLeftClick() when mouseLeftClick != null:
return mouseLeftClick();case InputCommand_MouseRightClick() when mouseRightClick != null:
return mouseRightClick();case InputCommand_KeyboardType() when keyboardType != null:
return keyboardType(_that.text);case InputCommand_KeyboardSpecial() when keyboardSpecial != null:
return keyboardSpecial(_that.keyName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double x,  double y,  double monitorWidth,  double monitorHeight)  mouseMove,required TResult Function()  mouseLeftClick,required TResult Function()  mouseRightClick,required TResult Function( String text)  keyboardType,required TResult Function( String keyName)  keyboardSpecial,}) {final _that = this;
switch (_that) {
case InputCommand_MouseMove():
return mouseMove(_that.x,_that.y,_that.monitorWidth,_that.monitorHeight);case InputCommand_MouseLeftClick():
return mouseLeftClick();case InputCommand_MouseRightClick():
return mouseRightClick();case InputCommand_KeyboardType():
return keyboardType(_that.text);case InputCommand_KeyboardSpecial():
return keyboardSpecial(_that.keyName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double x,  double y,  double monitorWidth,  double monitorHeight)?  mouseMove,TResult? Function()?  mouseLeftClick,TResult? Function()?  mouseRightClick,TResult? Function( String text)?  keyboardType,TResult? Function( String keyName)?  keyboardSpecial,}) {final _that = this;
switch (_that) {
case InputCommand_MouseMove() when mouseMove != null:
return mouseMove(_that.x,_that.y,_that.monitorWidth,_that.monitorHeight);case InputCommand_MouseLeftClick() when mouseLeftClick != null:
return mouseLeftClick();case InputCommand_MouseRightClick() when mouseRightClick != null:
return mouseRightClick();case InputCommand_KeyboardType() when keyboardType != null:
return keyboardType(_that.text);case InputCommand_KeyboardSpecial() when keyboardSpecial != null:
return keyboardSpecial(_that.keyName);case _:
  return null;

}
}

}

/// @nodoc


class InputCommand_MouseMove extends InputCommand {
  const InputCommand_MouseMove({required this.x, required this.y, required this.monitorWidth, required this.monitorHeight}): super._();
  

 final  double x;
 final  double y;
 final  double monitorWidth;
 final  double monitorHeight;

/// Create a copy of InputCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputCommand_MouseMoveCopyWith<InputCommand_MouseMove> get copyWith => _$InputCommand_MouseMoveCopyWithImpl<InputCommand_MouseMove>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCommand_MouseMove&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.monitorWidth, monitorWidth) || other.monitorWidth == monitorWidth)&&(identical(other.monitorHeight, monitorHeight) || other.monitorHeight == monitorHeight));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,monitorWidth,monitorHeight);

@override
String toString() {
  return 'InputCommand.mouseMove(x: $x, y: $y, monitorWidth: $monitorWidth, monitorHeight: $monitorHeight)';
}


}

/// @nodoc
abstract mixin class $InputCommand_MouseMoveCopyWith<$Res> implements $InputCommandCopyWith<$Res> {
  factory $InputCommand_MouseMoveCopyWith(InputCommand_MouseMove value, $Res Function(InputCommand_MouseMove) _then) = _$InputCommand_MouseMoveCopyWithImpl;
@useResult
$Res call({
 double x, double y, double monitorWidth, double monitorHeight
});




}
/// @nodoc
class _$InputCommand_MouseMoveCopyWithImpl<$Res>
    implements $InputCommand_MouseMoveCopyWith<$Res> {
  _$InputCommand_MouseMoveCopyWithImpl(this._self, this._then);

  final InputCommand_MouseMove _self;
  final $Res Function(InputCommand_MouseMove) _then;

/// Create a copy of InputCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? monitorWidth = null,Object? monitorHeight = null,}) {
  return _then(InputCommand_MouseMove(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,monitorWidth: null == monitorWidth ? _self.monitorWidth : monitorWidth // ignore: cast_nullable_to_non_nullable
as double,monitorHeight: null == monitorHeight ? _self.monitorHeight : monitorHeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class InputCommand_MouseLeftClick extends InputCommand {
  const InputCommand_MouseLeftClick(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCommand_MouseLeftClick);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InputCommand.mouseLeftClick()';
}


}




/// @nodoc


class InputCommand_MouseRightClick extends InputCommand {
  const InputCommand_MouseRightClick(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCommand_MouseRightClick);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InputCommand.mouseRightClick()';
}


}




/// @nodoc


class InputCommand_KeyboardType extends InputCommand {
  const InputCommand_KeyboardType({required this.text}): super._();
  

 final  String text;

/// Create a copy of InputCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputCommand_KeyboardTypeCopyWith<InputCommand_KeyboardType> get copyWith => _$InputCommand_KeyboardTypeCopyWithImpl<InputCommand_KeyboardType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCommand_KeyboardType&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'InputCommand.keyboardType(text: $text)';
}


}

/// @nodoc
abstract mixin class $InputCommand_KeyboardTypeCopyWith<$Res> implements $InputCommandCopyWith<$Res> {
  factory $InputCommand_KeyboardTypeCopyWith(InputCommand_KeyboardType value, $Res Function(InputCommand_KeyboardType) _then) = _$InputCommand_KeyboardTypeCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$InputCommand_KeyboardTypeCopyWithImpl<$Res>
    implements $InputCommand_KeyboardTypeCopyWith<$Res> {
  _$InputCommand_KeyboardTypeCopyWithImpl(this._self, this._then);

  final InputCommand_KeyboardType _self;
  final $Res Function(InputCommand_KeyboardType) _then;

/// Create a copy of InputCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(InputCommand_KeyboardType(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InputCommand_KeyboardSpecial extends InputCommand {
  const InputCommand_KeyboardSpecial({required this.keyName}): super._();
  

 final  String keyName;

/// Create a copy of InputCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputCommand_KeyboardSpecialCopyWith<InputCommand_KeyboardSpecial> get copyWith => _$InputCommand_KeyboardSpecialCopyWithImpl<InputCommand_KeyboardSpecial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCommand_KeyboardSpecial&&(identical(other.keyName, keyName) || other.keyName == keyName));
}


@override
int get hashCode => Object.hash(runtimeType,keyName);

@override
String toString() {
  return 'InputCommand.keyboardSpecial(keyName: $keyName)';
}


}

/// @nodoc
abstract mixin class $InputCommand_KeyboardSpecialCopyWith<$Res> implements $InputCommandCopyWith<$Res> {
  factory $InputCommand_KeyboardSpecialCopyWith(InputCommand_KeyboardSpecial value, $Res Function(InputCommand_KeyboardSpecial) _then) = _$InputCommand_KeyboardSpecialCopyWithImpl;
@useResult
$Res call({
 String keyName
});




}
/// @nodoc
class _$InputCommand_KeyboardSpecialCopyWithImpl<$Res>
    implements $InputCommand_KeyboardSpecialCopyWith<$Res> {
  _$InputCommand_KeyboardSpecialCopyWithImpl(this._self, this._then);

  final InputCommand_KeyboardSpecial _self;
  final $Res Function(InputCommand_KeyboardSpecial) _then;

/// Create a copy of InputCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? keyName = null,}) {
  return _then(InputCommand_KeyboardSpecial(
keyName: null == keyName ? _self.keyName : keyName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
