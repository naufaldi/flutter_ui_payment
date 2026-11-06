/// Visual size only; layout box and hit area stay at least 48×48 dp. Components document their heights.
enum PaymentSize {
  /// Module headers, table or chip rows; never the main action.
  small,

  /// Default, today's visual size.
  medium,

  /// One primary action on a full-screen wide view.
  large,
}

/// Width policy; labels wrap and never truncate.
enum PaymentWidth {
  /// Parent width, the default.
  fill,

  /// Content width.
  hug,
}

/// Spacing roles resolved by PaymentTheme.space; nothing else exists.
///
/// The scale is 4 / 8 / 12 / 16 / 24 / 32 on the 8 base (D46). Each role
/// below has one value; a gap that serves a listed role uses that role and
/// no other. Component sizes (36, 40, 48, 52, 56, 60, 64 dp) are sizes, not
/// spacing roles.
enum PaymentSpace {
  /// Zero gap.
  none,

  /// spacing × 0.5 (4): label → caption, title → message, title → meta,
  /// a small glyph beside its text, a field's label above its box at large
  /// text.
  inline,

  /// spacing (8): between stacked or adjacent actions and chips, text →
  /// trailing control, compact control padding.
  related,

  /// spacing × 1.5 (12): icon → text, band → title, list row and header
  /// padding, notice and banner padding.
  block,

  /// spacing × 2 (16): screen, sheet and field gutters, label → value,
  /// state message padding.
  group,

  /// spacing × 3 (24): content → primary action, between field groups,
  /// ruled section gaps.
  section,

  /// spacing × 4 (32): largest gap; unused by kit widgets today.
  major,
}

/// Corner roles for PaymentBox and PaymentImage.
enum PaymentRadius {
  /// BorderRadius.zero.
  none,

  /// tagBorderRadius (4 by default).
  tag,

  /// controlBorderRadius (6 by default).
  control,

  /// borderRadius (8 by default).
  box,

  /// sheetBorderRadius (12 by default).
  sheet,

  /// BorderRadius.circular(999), existing navigation pill.
  circle,
}

/// The nine PaymentType roles; no additional role exists.
enum PaymentTextRole {
  /// display: one display amount.
  display,

  /// amountLarge: totals and balances.
  amountLarge,

  /// title: sheet and app-bar titles.
  title,

  /// heading: section titles.
  heading,

  /// bodyFor(context): paragraphs.
  body,

  /// label: row labels and values.
  label,

  /// caption: supporting text.
  caption,

  /// tag: short status words.
  tag,

  /// input: field text.
  input,
}

/// Semantic text and icon colors.
enum PaymentTextColor {
  /// textPrimary.
  primary,

  /// textSecondary.
  secondary,

  /// disabled.
  disabled,

  /// accent.
  accent,

  /// info.foreground.
  info,

  /// success.foreground.
  success,

  /// warning.foreground.
  warning,

  /// danger.foreground.
  danger,
}

/// Running-text emphasis only; choose a PaymentType role for hierarchy.
enum PaymentFontWeight {
  /// FontWeight.w400.
  regular,

  /// FontWeight.w600.
  semibold,

  /// FontWeight.w700; emphasis inside running text only.
  bold,
}

/// Existing icon sizes; medium scales with text up to 1.6×.
enum PaymentIconSize {
  /// 14, existing badge.
  xsmall,

  /// 16, existing merchant mark.
  small,

  /// 20 scaled up to 1.6×, existing rows.
  medium,

  /// 32, existing video control.
  large,

  /// 48, existing state icon.
  xlarge,
}

/// A hidden field part stays in semantics; consumers arrive in later phases.
enum PaymentFieldPart {
  /// Label field part.
  label,

  /// Description field part.
  description,

  /// Error field part.
  error,
}
