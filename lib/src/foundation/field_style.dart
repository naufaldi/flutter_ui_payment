import 'package:flutter/material.dart';

import 'payment_theme.dart';
import 'payment_type.dart';
import 'style_lerp.dart';

/// Field-family appearance registered in `ThemeData.extensions` (D102).
///
/// Applies to the input box of text, search, text-area, select, date,
/// date-range-field and currency fields, and to fields composed from them
/// (promo code, identity form). Buttons, cards, sheets, chips, selection
/// controls and option lists or panels are unaffected.
///
/// Theme-only: there is no per-field style parameter. Scope a one-off with a
/// nested `Theme`, keeping unrelated extensions:
///
/// ```dart
/// Theme(
///   data: Theme.of(context).copyWith(
///     extensions: [
///       ...Theme.of(context).extensions.values,
///       PaymentFieldTheme(fillColor: PaymentTheme.of(context).surfaceMuted),
///     ],
///   ),
///   child: form,
/// )
/// ```
///
/// Every property is optional; null keeps the kit default, and an empty
/// theme renders exactly like no theme. The kit keeps the 2 dp accent focus
/// border, the danger error border, disabled and read-only behaviour, label,
/// helper and error typography, content padding and sizes, the 48 dp
/// minimum, prefix, suffix and clear controls, and focus semantics. Hosts
/// verify contrast for a custom fill against the text and border colors in
/// light and dark.
@immutable
class PaymentFieldTheme extends ThemeExtension<PaymentFieldTheme> {
  /// Creates optional field overrides; null properties keep the kit default.
  const PaymentFieldTheme({
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.textStyle,
  });

  /// Box fill while enabled or read-only. Unset, fields have no fill.
  ///
  /// A disabled field with a custom fill shows `PaymentTheme.surfaceMuted`.
  final Color? fillColor;

  /// Resting outline color while enabled; defaults to `PaymentTheme.border`.
  /// Focus, error and disabled outlines stay kit-owned.
  final Color? borderColor;

  /// Box corners for every outline state and the tap highlight; defaults to
  /// `PaymentTheme.controlBorderRadius` (D101).
  final BorderRadius? borderRadius;

  /// Typography merged over the input role for the entered value and the
  /// placeholder, keeping unspecified fields.
  ///
  /// Color, paint, background, shadows, decorations and `inherit` are
  /// ignored; the kit owns text colors per state. Font size and height must
  /// be positive when supplied. The box grows or shrinks with the text line,
  /// never below 48 dp. Currency fields keep the amount role for the entered
  /// amount and match the themed input line height. Labels, helper and
  /// error text keep their roles.
  final TextStyle? textStyle;

  /// Replaces supplied properties; null retains the existing value.
  @override
  PaymentFieldTheme copyWith({
    Color? fillColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
  }) => PaymentFieldTheme(
    fillColor: fillColor ?? this.fillColor,
    borderColor: borderColor ?? this.borderColor,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
  );

  /// Interpolates during a theme transition.
  ///
  /// Concrete pairs interpolate. A property set on one side only switches at
  /// the midpoint, keeping null as "use the kit default" instead of fading
  /// from transparent or zero. Typography is normalized first.
  @override
  PaymentFieldTheme lerp(PaymentFieldTheme? other, double t) {
    if (other == null) return this;
    return PaymentFieldTheme(
      fillColor: lerpStyleOverride(fillColor, other.fillColor, t, Color.lerp),
      borderColor: lerpStyleOverride(
        borderColor,
        other.borderColor,
        t,
        Color.lerp,
      ),
      borderRadius: lerpStyleOverride(
        borderRadius,
        other.borderRadius,
        t,
        BorderRadius.lerp,
      ),
      textStyle: lerpStyleOverride(
        styleTypography(textStyle),
        styleTypography(other.textStyle),
        t,
        TextStyle.lerp,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentFieldTheme &&
      other.fillColor == fillColor &&
      other.borderColor == borderColor &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle;

  @override
  int get hashCode =>
      Object.hash(fillColor, borderColor, borderRadius, textStyle);
}

/// Internal: the field appearance resolved for [context]. Not exported.
///
/// Order: semantic defaults (`PaymentTheme`, `PaymentType`), then the nearest
/// [PaymentFieldTheme].
class FieldAppearance {
  FieldAppearance._(this._theme, this._field, this._input);

  factory FieldAppearance.of(BuildContext context) {
    final field = Theme.of(context).extension<PaymentFieldTheme>();
    final input = PaymentType.of(context).input;
    final typography = styleTypography(field?.textStyle);
    return FieldAppearance._(
      PaymentTheme.of(context),
      field,
      typography == null ? input : input.merge(typography),
    );
  }

  final PaymentTheme _theme;
  final PaymentFieldTheme? _field;
  final TextStyle _input;

  /// Input role with the themed typography, before state color.
  TextStyle get input => _input;

  /// Box corners; the D101 control radius by default.
  BorderRadius get borderRadius =>
      _field?.borderRadius ?? _theme.controlBorderRadius;

  /// Resting enabled outline.
  Color get borderColor => _field?.borderColor ?? _theme.border;

  /// Box fill, or null for the default unfilled box.
  Color? fill({required bool enabled}) {
    final fill = _field?.fillColor;
    if (fill == null) return null;
    return enabled ? fill : _theme.surfaceMuted;
  }
}
