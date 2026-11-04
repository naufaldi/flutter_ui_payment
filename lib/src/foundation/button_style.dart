import 'package:flutter/material.dart';

import 'style_lerp.dart';

/// Partial button appearance, resolved after semantic and family defaults.
///
/// Disabled colors, focus color, padding, sizing, state layers and motion stay
/// kit-owned. Hosts verify contrast for custom enabled color pairs in light and
/// dark. This type deliberately does not forward unrestricted `ButtonStyle`.
@immutable
class PaymentButtonStyle {
  /// Creates optional overrides; null properties preserve preceding layers.
  const PaymentButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.textStyle,
  });

  /// Enabled fill; secondary and quiet variants have no fill by default.
  final Color? backgroundColor;

  /// Enabled label, icon and spinner color, also used for pressed/hover layers.
  final Color? foregroundColor;

  /// Enabled secondary outline; ignored by the other variants.
  final Color? borderColor;

  /// Button corners; the keyboard focus ring follows the same radii.
  final BorderRadius? borderRadius;

  /// Typography merged over the heading role, keeping unspecified fields.
  ///
  /// Color, paint, background, shadows, decorations and `inherit` are ignored;
  /// use [foregroundColor]. Font size and height must be positive when supplied.
  final TextStyle? textStyle;

  /// Overlays non-null properties from [other], merging its typography.
  PaymentButtonStyle merge(PaymentButtonStyle? other) {
    if (other == null) return this;
    return PaymentButtonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle:
          styleTypography(textStyle)?.merge(styleTypography(other.textStyle)) ??
          styleTypography(other.textStyle),
    );
  }

  /// Interpolates partial appearance during Flutter theme transitions.
  ///
  /// Concrete pairs interpolate. A field missing from either endpoint switches
  /// at the midpoint, retaining null as semantic inheritance instead of fading
  /// from transparent or zero. Unsupported text properties are ignored first.
  static PaymentButtonStyle? lerp(
    PaymentButtonStyle? a,
    PaymentButtonStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    return PaymentButtonStyle(
      backgroundColor: lerpStyleOverride(
        a?.backgroundColor,
        b?.backgroundColor,
        t,
        Color.lerp,
      ),
      foregroundColor: lerpStyleOverride(
        a?.foregroundColor,
        b?.foregroundColor,
        t,
        Color.lerp,
      ),
      borderColor: lerpStyleOverride(
        a?.borderColor,
        b?.borderColor,
        t,
        Color.lerp,
      ),
      borderRadius: lerpStyleOverride(
        a?.borderRadius,
        b?.borderRadius,
        t,
        BorderRadius.lerp,
      ),
      textStyle: lerpStyleOverride(
        styleTypography(a?.textStyle),
        styleTypography(b?.textStyle),
        t,
        TextStyle.lerp,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentButtonStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderRadius,
    textStyle,
  );
}

/// Button-family overrides registered in `ThemeData.extensions`.
///
/// Resolution is token defaults, shared [style], variant style, then instance.
/// A scoped `Theme` may change buttons without changing input or sheet corners.
/// Preserve unrelated parent extensions. Nested themes replace this extension;
/// derive them with [copyWith] when parent values should remain.
@immutable
class PaymentButtonTheme extends ThemeExtension<PaymentButtonTheme> {
  /// Creates optional shared and variant-specific overrides.
  const PaymentButtonTheme({
    this.style,
    this.primary,
    this.secondary,
    this.quiet,
    this.destructive,
  });

  /// Shared appearance applied before variant overrides.
  final PaymentButtonStyle? style;

  /// Primary appearance.
  final PaymentButtonStyle? primary;

  /// Secondary appearance.
  final PaymentButtonStyle? secondary;

  /// Quiet appearance.
  final PaymentButtonStyle? quiet;

  /// Destructive appearance.
  final PaymentButtonStyle? destructive;

  /// Replaces supplied styles; null retains the existing corresponding style.
  @override
  PaymentButtonTheme copyWith({
    PaymentButtonStyle? style,
    PaymentButtonStyle? primary,
    PaymentButtonStyle? secondary,
    PaymentButtonStyle? quiet,
    PaymentButtonStyle? destructive,
  }) => PaymentButtonTheme(
    style: style ?? this.style,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    quiet: quiet ?? this.quiet,
    destructive: destructive ?? this.destructive,
  );

  /// Interpolates shared and variant styles during a theme transition.
  @override
  PaymentButtonTheme lerp(PaymentButtonTheme? other, double t) {
    if (other == null) return this;
    return PaymentButtonTheme(
      style: PaymentButtonStyle.lerp(style, other.style, t),
      primary: PaymentButtonStyle.lerp(primary, other.primary, t),
      secondary: PaymentButtonStyle.lerp(secondary, other.secondary, t),
      quiet: PaymentButtonStyle.lerp(quiet, other.quiet, t),
      destructive: PaymentButtonStyle.lerp(destructive, other.destructive, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentButtonTheme &&
      other.style == style &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.quiet == quiet &&
      other.destructive == destructive;

  @override
  int get hashCode =>
      Object.hash(style, primary, secondary, quiet, destructive);
}
