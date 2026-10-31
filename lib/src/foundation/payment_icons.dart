import 'package:flutter/material.dart';
import 'payment_theme.dart';
import 'payment_tokens.dart';
import 'payment_type.dart';
import 'token_resolvers.dart';

/// Fixed meanings for the kit icon vocabulary.
class PaymentIcons {
  const PaymentIcons._();

  /// Successful result.
  static const IconData success = Icons.check_circle_outline;

  /// Warning requiring attention.
  static const IconData warning = Icons.warning_amber_outlined;

  /// Error requiring recovery.
  static const IconData danger = Icons.error_outline;

  /// Informational or neutral message.
  static const IconData info = Icons.info_outline;

  /// Forward navigation; SDK matchTextDirection mirrors in RTL. Never swap by hand.
  static const IconData forward = Icons.chevron_right;

  /// External destination, handled by the host.
  static const IconData externalLink = Icons.open_in_new;

  /// Dismiss the current surface.
  static const IconData close = Icons.close;

  /// Copy action, handled by the host.
  static const IconData copy = Icons.copy_outlined;

  /// Copy completed.
  static const IconData copied = Icons.check;

  /// Content failed to load.
  static const IconData loadFailed = Icons.cloud_off_outlined;

  /// Search has no matches.
  static const IconData noMatches = Icons.search_off;

  /// Work in progress.
  static const IconData busy = Icons.hourglass_top_outlined;

  /// Content hidden.
  static const IconData hidden = Icons.lock_outline;
}

/// Material glyph at a semantic size, centered on the first text line.
class PaymentIcon extends StatelessWidget {
  const PaymentIcon(
    this.icon, {
    super.key,
    this.size = PaymentIconSize.medium,
    this.color,
    this.semanticLabel,
  }) : tone = null;
  const PaymentIcon.tone(
    this.tone, {
    super.key,
    this.icon,
    this.size = PaymentIconSize.medium,
  }) : color = null,
       semanticLabel = null;

  /// Custom glyph, or the tone default.
  final IconData? icon;

  /// Status tone.
  final StatusTone? tone;

  /// Glyph size.
  final PaymentIconSize size;

  /// Semantic color, otherwise inherited.
  final PaymentTextColor? color;

  /// Alt text; null makes the icon decorative.
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final s = size.resolve(context);
    Widget glyph = ExcludeSemantics(
      child: Icon(
        icon ?? toneIcon(tone!),
        size: s,
        color: tone == null ? color?.resolve(t) : t.tone(tone!).foreground,
      ),
    );
    if (semanticLabel != null) {
      glyph = Semantics(image: true, label: semanticLabel, child: glyph);
    }
    return size == PaymentIconSize.medium
        ? SizedBox(
            width: s,
            height: PaymentType.firstLineHeight(context),
            child: Center(child: glyph),
          )
        : glyph;
  }
}
