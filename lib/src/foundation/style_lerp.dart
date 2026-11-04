import 'package:flutter/painting.dart';

// Internal helpers shared by the family style layers (D100 buttons, D102
// fields). Not exported from the package barrel; the names are public only
// so the family libraries can share them.

/// Keeps only the typography of [style], dropping color, paint, background,
/// shadows, decorations and `inherit`, so family overrides cannot change
/// state colors and differing `inherit` cannot make interpolation throw.
TextStyle? styleTypography(TextStyle? style) => style == null
    ? null
    : TextStyle(
        fontFamily: style.fontFamily,
        fontFamilyFallback: style.fontFamilyFallback,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        letterSpacing: style.letterSpacing,
        wordSpacing: style.wordSpacing,
        textBaseline: style.textBaseline,
        height: style.height,
        leadingDistribution: style.leadingDistribution,
        fontFeatures: style.fontFeatures,
        fontVariations: style.fontVariations,
      );

/// Interpolates an optional override. Concrete pairs use [lerp]; a value
/// missing at either end switches at the midpoint, because null means
/// "inherit the semantic default", not transparent or zero.
T? lerpStyleOverride<T>(
  T? a,
  T? b,
  double t,
  T? Function(T?, T?, double) lerp,
) {
  if (a == null || b == null) return t < 0.5 ? a : b;
  return lerp(a, b, t);
}
