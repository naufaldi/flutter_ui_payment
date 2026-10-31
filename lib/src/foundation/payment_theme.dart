import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Semantic tone of a status. Widgets always pair a tone with an icon and a
/// text label, so color is never the only signal.
enum StatusTone { neutral, info, success, warning, danger }

/// Foreground/container pair for one [StatusTone].
@immutable
class ToneColors {
  const ToneColors({required this.foreground, required this.container});

  final Color foreground;
  final Color container;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
    container: Color.lerp(a.container, b.container, t)!,
  );
}

/// Brand tokens for every flutter_ui_payment widget.
///
/// Register it on `ThemeData.extensions`. Widgets fall back to
/// [PaymentTheme.fromColorScheme] when no extension is installed, so the kit
/// follows the host [ColorScheme] by default and a full brand is opt-in.
@immutable
class PaymentTheme extends ThemeExtension<PaymentTheme> {
  const PaymentTheme({
    required this.accent,
    required this.onAccent,
    required this.surface,
    required this.surfaceMuted,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.neutral,
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
    this.radius = 8,
    this.spacing = 8,
    this.amountWeight = FontWeight.w600,
    this.amountFontFamily,
    this._border,
    this._disabled,
    this._referenceFontFamily,
  });

  /// Derives tokens from a Material [ColorScheme].
  factory PaymentTheme.fromColorScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    // Tone foregrounds are fixed, contrast-checked values (each at least
    // 5.8:1 on white in light mode and 7.6:1 on #131417 in dark mode), so
    // status text stays readable whatever the host's seed color is.
    ToneColors tone(Color light, Color darkForeground) {
      final foreground = dark ? darkForeground : light;
      return ToneColors(
        foreground: foreground,
        container: Color.lerp(foreground, scheme.surface, dark ? 0.84 : 0.9)!,
      );
    }

    return PaymentTheme(
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      surface: scheme.surface,
      surfaceMuted: scheme.surfaceContainerHighest,
      outline: scheme.outlineVariant,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      neutral: ToneColors(
        foreground: scheme.onSurfaceVariant,
        container: scheme.surfaceContainerHigh,
      ),
      info: tone(const Color(0xFF2A55A8), const Color(0xFF93B2F0)),
      success: tone(const Color(0xFF1D6B45), const Color(0xFF6FC79B)),
      warning: tone(const Color(0xFF8A5300), const Color(0xFFE3A64C)),
      danger: tone(const Color(0xFFA8231C), const Color(0xFFF2897F)),
    );
  }

  final Color accent;
  final Color onAccent;
  final Color surface;
  final Color surfaceMuted;

  /// Hairline rule, decorative: dividers, the method-group edge and the
  /// action-bar top. It may sit below 3:1; control edges use [border].
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final ToneColors neutral;
  final ToneColors info;
  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;

  /// Corner radius of selectable boxes such as the method list. Buttons and
  /// inputs use three quarters of it.
  final double radius;

  /// Base spacing unit; layouts use multiples of it, by role:
  ///
  /// * inline, `spacing * 0.5` (4): label → caption, title → meta.
  /// * related, `spacing` (8): row padding, between stacked actions.
  /// * block, `spacing * 1.5` (12): band → title, notice padding.
  /// * group, `spacing * 2` (16): screen and sheet gutter, groups.
  /// * section, `spacing * 3` (24): content → primary action, ruled gaps.
  /// * major, `spacing * 4` (32): empty and state message padding only.
  final double spacing;

  final FontWeight amountWeight;
  final String? amountFontFamily;

  final Color? _border;
  final Color? _disabled;
  final String? _referenceFontFamily;

  /// Edge of a control: inputs, secondary buttons, unselected checkboxes.
  /// Unlike [outline] it must reach 3:1 against [surface]. Defaults to
  /// [textSecondary] a quarter of the way to [surface].
  Color get border => _border ?? Color.lerp(textSecondary, surface, 0.25)!;

  /// Label and icon color of a disabled control, drawn on [surfaceMuted].
  /// Defaults to [textSecondary] 45% of the way to [surface].
  Color get disabled => _disabled ?? Color.lerp(textSecondary, surface, 0.45)!;

  /// Font for references people copy or compare: virtual account numbers,
  /// transaction IDs, promo codes. Defaults to the platform monospace.
  String get referenceFontFamily => _referenceFontFamily ?? 'Menlo';

  List<String> get referenceFontFamilyFallback => const [
    'monospace',
    'Courier',
  ];

  static PaymentTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PaymentTheme>() ??
        PaymentTheme.fromColorScheme(theme.colorScheme);
  }

  ToneColors tone(StatusTone tone) => switch (tone) {
    StatusTone.neutral => neutral,
    StatusTone.info => info,
    StatusTone.success => success,
    StatusTone.warning => warning,
    StatusTone.danger => danger,
  };

  BorderRadius get borderRadius => BorderRadius.circular(radius);

  /// Badges and tags.
  BorderRadius get tagBorderRadius => BorderRadius.circular(radius * 0.5);

  /// Buttons, inputs, notices and menus.
  BorderRadius get controlBorderRadius => BorderRadius.circular(radius * 0.75);

  /// The top of a sheet and dialogs.
  BorderRadius get sheetBorderRadius => BorderRadius.circular(radius * 1.5);

  /// Text style for amounts: the 32/36 display total when [large], otherwise
  /// a 15/20 row amount. Both use [amountWeight] and tabular figures, and the
  /// host's font unless [amountFontFamily] is set.
  TextStyle amountStyle(BuildContext context, {bool large = true}) {
    final host = Theme.of(context).textTheme.bodyMedium;
    return TextStyle(
      color: textPrimary,
      fontWeight: amountWeight,
      fontSize: large ? 32 : 15,
      height: large ? 36 / 32 : 20 / 15,
      letterSpacing: large ? -0.32 : 0,
      leadingDistribution: TextLeadingDistribution.even,
      fontFamily: amountFontFamily ?? host?.fontFamily,
      fontFamilyFallback: host?.fontFamilyFallback,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  @override
  PaymentTheme copyWith({
    Color? accent,
    Color? onAccent,
    Color? surface,
    Color? surfaceMuted,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    ToneColors? neutral,
    ToneColors? info,
    ToneColors? success,
    ToneColors? warning,
    ToneColors? danger,
    double? radius,
    double? spacing,
    FontWeight? amountWeight,
    String? amountFontFamily,
    Color? border,
    Color? disabled,
    String? referenceFontFamily,
  }) {
    return PaymentTheme(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      neutral: neutral ?? this.neutral,
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      radius: radius ?? this.radius,
      spacing: spacing ?? this.spacing,
      amountWeight: amountWeight ?? this.amountWeight,
      amountFontFamily: amountFontFamily ?? this.amountFontFamily,
      // The raw fields, so a later textSecondary or surface override still
      // re-derives an unset border and disabled color.
      border: border ?? _border,
      disabled: disabled ?? _disabled,
      referenceFontFamily: referenceFontFamily ?? _referenceFontFamily,
    );
  }

  @override
  PaymentTheme lerp(covariant PaymentTheme? other, double t) {
    if (other == null) return this;
    return PaymentTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      neutral: ToneColors.lerp(neutral, other.neutral, t),
      info: ToneColors.lerp(info, other.info, t),
      success: ToneColors.lerp(success, other.success, t),
      warning: ToneColors.lerp(warning, other.warning, t),
      danger: ToneColors.lerp(danger, other.danger, t),
      radius: lerpDouble(radius, other.radius, t)!,
      spacing: lerpDouble(spacing, other.spacing, t)!,
      amountWeight: t < 0.5 ? amountWeight : other.amountWeight,
      amountFontFamily: t < 0.5 ? amountFontFamily : other.amountFontFamily,
      border: Color.lerp(border, other.border, t),
      disabled: Color.lerp(disabled, other.disabled, t),
      referenceFontFamily: t < 0.5
          ? _referenceFontFamily
          : other._referenceFontFamily,
    );
  }
}
