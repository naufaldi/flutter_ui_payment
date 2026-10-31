import 'package:flutter/material.dart';
import 'payment_icons.dart';
import 'payment_theme.dart';
import 'payment_tokens.dart';
import 'payment_type.dart';

IconData toneIcon(StatusTone tone) => switch (tone) {
  StatusTone.success => PaymentIcons.success,
  StatusTone.warning => PaymentIcons.warning,
  StatusTone.danger => PaymentIcons.danger,
  StatusTone.info || StatusTone.neutral => PaymentIcons.info,
};

extension PaymentRadiusResolver on PaymentRadius {
  BorderRadius resolve(PaymentTheme theme) => switch (this) {
    PaymentRadius.none => BorderRadius.zero,
    PaymentRadius.tag => theme.tagBorderRadius,
    PaymentRadius.control => theme.controlBorderRadius,
    PaymentRadius.box => theme.borderRadius,
    PaymentRadius.sheet => theme.sheetBorderRadius,
    PaymentRadius.circle => BorderRadius.circular(999),
  };
}

extension PaymentTextRoleResolver on PaymentTextRole {
  TextStyle resolve(BuildContext context) => switch (this) {
    PaymentTextRole.display => PaymentType.of(context).display,
    PaymentTextRole.amountLarge => PaymentType.of(context).amountLarge,
    PaymentTextRole.title => PaymentType.of(context).title,
    PaymentTextRole.heading => PaymentType.of(context).heading,
    PaymentTextRole.body => PaymentType.of(context).bodyFor(context),
    PaymentTextRole.label => PaymentType.of(context).label,
    PaymentTextRole.caption => PaymentType.of(context).caption,
    PaymentTextRole.tag => PaymentType.of(context).tag,
    PaymentTextRole.input => PaymentType.of(context).input,
  };
}

extension PaymentTextColorResolver on PaymentTextColor {
  Color resolve(PaymentTheme theme) => switch (this) {
    PaymentTextColor.primary => theme.textPrimary,
    PaymentTextColor.secondary => theme.textSecondary,
    PaymentTextColor.disabled => theme.disabled,
    PaymentTextColor.accent => theme.accent,
    PaymentTextColor.info => theme.info.foreground,
    PaymentTextColor.success => theme.success.foreground,
    PaymentTextColor.warning => theme.warning.foreground,
    PaymentTextColor.danger => theme.danger.foreground,
  };
}

extension PaymentFontWeightResolver on PaymentFontWeight {
  FontWeight get fontWeight => switch (this) {
    PaymentFontWeight.regular => FontWeight.w400,
    PaymentFontWeight.semibold => FontWeight.w600,
    PaymentFontWeight.bold => FontWeight.w700,
  };
}

extension PaymentIconSizeResolver on PaymentIconSize {
  double resolve(BuildContext context) => switch (this) {
    PaymentIconSize.xsmall => 14,
    PaymentIconSize.small => 16,
    PaymentIconSize.medium => MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.6).scale(20),
    PaymentIconSize.large => 32,
    PaymentIconSize.xlarge => 48,
  };
}
