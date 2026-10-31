import 'package:flutter/material.dart';

import 'payment_theme.dart';

/// Public type foundation: nine closed roles, seven sizes and two weights.
/// Every role inherits the host font. Choose a role for hierarchy; there is
/// no weight modifier. Use [tabular] for numbers and [reference] for IDs.
@immutable
class PaymentType {
  const PaymentType._({
    required PaymentTheme theme,
    required this.display,
    required this.amountLarge,
    required this.title,
    required this.heading,
    required this.body,
    required this.label,
    required this.caption,
    required this.tag,
    required this.input,
  }) : _theme = theme;

  final PaymentTheme _theme;

  /// Resolves the nine roles from the ambient host font and payment theme.
  factory PaymentType.of(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final host = Theme.of(context).textTheme.bodyMedium;
    TextStyle role(
      double size,
      double line, {
      FontWeight weight = FontWeight.w400,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
      fontFamily: host?.fontFamily,
      fontFamilyFallback: host?.fontFamilyFallback,
    );

    return PaymentType._(
      theme: theme,
      display: theme.amountStyle(context),
      amountLarge: role(
        20,
        28,
        weight: theme.amountWeight,
        color: theme.textPrimary,
      ).tabular.copyWith(fontFamily: theme.amountFontFamily),
      title: role(17, 24, weight: FontWeight.w600, color: theme.textPrimary),
      heading: role(15, 20, weight: FontWeight.w600, color: theme.textPrimary),
      body: role(15, 22, color: theme.textPrimary),
      label: role(15, 20, color: theme.textPrimary),
      caption: role(13, 18, color: theme.textSecondary),
      tag: role(12, 16, weight: FontWeight.w600),
      input: role(16, 24, color: theme.textPrimary),
    );
  }

  /// Whether text is scaled above 1.5×, where rows wrap and paragraphs
  /// tighten their leading.
  static bool isLarge(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) > 15;

  /// Height of one 15/20 heading or label line at the current text scale.
  /// Center leading icons in a box this tall when text wraps.
  static double firstLineHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(15) * 20 / 15;

  /// [style] with tabular figures.
  TextStyle tabular(TextStyle style) => style.tabular;

  /// [style] with tabular figures in [PaymentTheme.referenceFontFamily].
  TextStyle reference(TextStyle style) => style.reference(_theme);

  /// The one display amount per screen: 32/36, tracking −0.32.
  final TextStyle display;

  /// Action-bar total, balance, VA number, entered amount: 20/28.
  final TextStyle amountLarge;

  /// Sheet, dialog and app-bar titles: 17/24 w600.
  final TextStyle title;

  /// Section and status titles, the Total row, buttons: 15/20 w600.
  final TextStyle heading;

  /// Paragraphs: 15/22. Use [bodyFor] so leading tightens at large text.
  final TextStyle body;

  /// Single-line row text, labels and values: 15/20.
  final TextStyle label;

  /// Supporting lines under a title: 13/18, muted.
  final TextStyle caption;

  /// Badges and tags: 12/16 w600. No color; the tone sets it.
  final TextStyle tag;

  /// Text fields: 16/24.
  final TextStyle input;

  /// [body], with 1.3 leading above 1.5× text so long paragraphs stay short.
  TextStyle bodyFor(BuildContext context) =>
      isLarge(context) ? body.copyWith(height: 1.3) : body;
}

/// Numeric modifiers for [PaymentType] roles.
extension PaymentTypeStyle on TextStyle {
  /// Tabular figures, so digits line up and do not shift as they change.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Tabular figures in [PaymentTheme.referenceFontFamily], for references
  /// people copy into another app.
  TextStyle reference(PaymentTheme theme) => tabular.copyWith(
    fontFamily: theme.referenceFontFamily,
    fontFamilyFallback: theme.referenceFontFamilyFallback,
  );
}
