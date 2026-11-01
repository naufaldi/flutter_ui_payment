/// Visual size only; layout box and hit area stay at least 48×48 dp. Components document their heights.
enum PaymentSize {
  /// Module headers, table or chip rows; never the main action. Stripe small.
  small,

  /// Default, today's visual size. Stripe medium.
  medium,

  /// One primary action on a full-screen wide view. Stripe large.
  large,
}

/// Width policy; labels wrap and never truncate.
enum PaymentWidth {
  /// Parent width, the default. Stripe fill.
  fill,

  /// Content width. Stripe hug.
  hug,
}

/// Spacing roles resolved by PaymentTheme.space; nothing else exists.
///
/// The scale is 4 / 8 / 12 / 16 / 24 / 32 on the 8 base (D46). Each role
/// below has one value; a gap that serves a listed role uses that role and
/// no other. Component sizes (36, 40, 48, 52, 56, 60, 64 dp) are sizes, not
/// spacing roles.
enum PaymentSpace {
  /// Zero gap. Stripe has no equivalent.
  none,

  /// spacing × 0.5 (4): label → caption, title → message, title → meta,
  /// a small glyph beside its text, a field's label above its box at large
  /// text. Stripe xxsmall.
  inline,

  /// spacing (8): between stacked or adjacent actions and chips, text →
  /// trailing control, compact control padding. Stripe xsmall.
  related,

  /// spacing × 1.5 (12): icon → text, list row and header padding, notice
  /// and banner padding. Stripe small.
  block,

  /// spacing × 2 (16): screen, sheet and field gutters, label → value,
  /// state message padding. Stripe medium.
  group,

  /// spacing × 3 (24): content → primary action, between field groups,
  /// ruled section gaps. Stripe large.
  section,

  /// spacing × 4 (32): largest gap; unused by kit widgets today. Stripe
  /// xlarge and xxlarge.
  major,
}

/// Corner roles for PaymentBox and PaymentImage.
enum PaymentRadius {
  /// BorderRadius.zero. Stripe none.
  none,

  /// tagBorderRadius (4). Stripe xsmall.
  tag,

  /// controlBorderRadius (6). Stripe small.
  control,

  /// borderRadius (8). Stripe medium.
  box,

  /// sheetBorderRadius (12). Stripe large.
  sheet,

  /// BorderRadius.circular(999), existing navigation pill. Stripe rounded.
  circle,
}

/// The nine PaymentType roles; no additional role exists.
enum PaymentTextRole {
  /// display: one display amount. Stripe has no equivalent.
  display,

  /// amountLarge: totals and balances. Stripe has no equivalent.
  amountLarge,

  /// title: sheet and app-bar titles. Stripe title.
  title,

  /// heading: section titles. Stripe subtitle, heading and subheading.
  heading,

  /// bodyFor(context): paragraphs. Stripe lead, body and bodyEmphasized with semibold.
  body,

  /// label: row labels and values. Stripe has no equivalent.
  label,

  /// caption: supporting text. Stripe caption.
  caption,

  /// tag: short status words. Stripe kicker.
  tag,

  /// input: field text. Stripe has no equivalent.
  input,
}

/// Semantic text and icon colors.
enum PaymentTextColor {
  /// textPrimary. Stripe primary.
  primary,

  /// textSecondary. Stripe secondary.
  secondary,

  /// disabled. Stripe disabled.
  disabled,

  /// accent. Stripe brand.
  accent,

  /// info.foreground. Stripe info.
  info,

  /// success.foreground. Stripe success.
  success,

  /// warning.foreground. Stripe attention.
  warning,

  /// danger.foreground. Stripe critical.
  danger,
}

/// Running-text emphasis only; choose a PaymentType role for hierarchy.
enum PaymentFontWeight {
  /// FontWeight.w400. Stripe regular.
  regular,

  /// FontWeight.w600. Stripe semibold.
  semibold,

  /// FontWeight.w700; emphasis inside running text only. Stripe bold.
  bold,
}

/// Existing icon sizes; medium scales with text up to 1.6×.
enum PaymentIconSize {
  /// 14, existing badge. Stripe 12.
  xsmall,

  /// 16, existing merchant mark. Stripe 16.
  small,

  /// 20 scaled up to 1.6×, existing rows. Stripe 20.
  medium,

  /// 32, existing video control. Stripe 32.
  large,

  /// 48, existing state icon. Stripe 64.
  xlarge,
}

/// A hidden field part stays in semantics; consumers arrive in later phases.
enum PaymentFieldPart {
  /// Label field part. Stripe label.
  label,

  /// Description field part. Stripe description.
  description,

  /// Error field part. Stripe error.
  error,
}
