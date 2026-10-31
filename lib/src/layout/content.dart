import '../foundation/edge_fade.dart';
import 'package:flutter/material.dart';
import '../controls/actions.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/token_resolvers.dart';
import 'layout.dart';

/// A host-supplied image with alt text, loading and error states.
class PaymentImage extends StatelessWidget {
  const PaymentImage({
    super.key,
    required this.image,
    required this.alt,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = PaymentRadius.none,
    this.bordered = false,
    this.placeholder,
    this.errorFallback,
  });

  /// The host supplies the image provider.
  final ImageProvider image;

  /// Image alternative; empty makes the image decorative.
  final String alt;

  /// Optional width.
  final double? width;

  /// Optional height.
  final double? height;

  /// Image fit.
  final BoxFit fit;

  /// Corner role.
  final PaymentRadius radius;

  /// Draw an outline over the image.
  final bool bordered;

  /// Host loading content.
  final Widget? placeholder;

  /// Host failure content, including its own semantics.
  final Widget? errorFallback;
  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    Widget semantics(Widget child, {bool error = false}) => alt.isEmpty
        ? ExcludeSemantics(child: child)
        : Semantics(
            image: true,
            label: error
                ? '$alt, ${PaymentLocalizations.of(context).imageUnavailable}'
                : alt,
            child: ExcludeSemantics(child: child),
          );
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        foregroundDecoration: bordered
            ? BoxDecoration(
                border: Border.all(color: t.outline),
                borderRadius: radius.resolve(t),
              )
            : null,
        child: ClipRRect(
          borderRadius: radius.resolve(t),
          child: Image(
            image: image,
            width: width,
            height: height,
            fit: fit,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, sync) {
              if (sync) return semantics(child);
              if (frame == null) {
                return semantics(
                  placeholder ?? ColoredBox(color: t.surfaceMuted),
                );
              }
              return semantics(
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: PaymentMotion.of(context).quick,
                  curve: PaymentMotion.easeOut,
                  builder: (_, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: child,
                ),
              );
            },
            errorBuilder: (context, error, stack) {
              if (errorFallback != null) {
                return alt.isEmpty
                    ? ExcludeSemantics(child: errorFallback!)
                    : errorFallback!;
              }
              return semantics(
                ColoredBox(
                  color: t.surfaceMuted,
                  child: LayoutBuilder(
                    builder: (_, constraints) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: PaymentType.firstLineHeight(
                              context,
                            ).clamp(0, constraints.maxHeight),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PaymentIcon(
                                Icons.broken_image_outlined,
                                color: PaymentTextColor.secondary,
                              ),
                            ),
                          ),
                          if (alt.isNotEmpty &&
                              constraints.maxWidth >= 96 &&
                              constraints.maxHeight >=
                                  PaymentType.firstLineHeight(context) +
                                      MediaQuery.textScalerOf(context).scale(
                                            PaymentType.of(
                                              context,
                                            ).caption.fontSize!,
                                          ) *
                                          PaymentType.of(
                                            context,
                                          ).caption.height! *
                                          2)
                            PaymentInline(
                              alt,
                              role: PaymentTextRole.caption,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                error: true,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Code presentation. Nothing else exists.
enum PaymentCodeKind {
  /// Inline reference tag.
  code,

  /// Multiline block.
  pre,

  /// Host output without a fill.
  samp,

  /// Nonselectable keyboard key.
  kbd,
}

/// Monospace, tabular text people read or copy.
class PaymentCode extends StatelessWidget {
  const PaymentCode(
    this.text, {
    super.key,
    this.kind = PaymentCodeKind.code,
    this.multiline = false,
    this.noWrap = false,
    this.size = PaymentSize.medium,
    this.onCopy,
    this.semanticLabel,
  }) : assert(kind != PaymentCodeKind.kbd || onCopy == null);

  /// Literal value.
  final String text;

  /// Presentation kind.
  final PaymentCodeKind kind;

  /// Allow multiple lines.
  final bool multiline;

  /// Keep one line and scroll inside the block; an edge fade shows there is more.
  final bool noWrap;

  /// Text role size.
  final PaymentSize size;

  /// Host copy callback; adds confirmation and failure feedback.
  final Future<bool> Function(String value)? onCopy;

  /// Spoken prefix before the value.
  final String? semanticLabel;
  String get _spoken {
    final digits = text.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d{5,}$').hasMatch(digits)) return text;
    return [
      for (var i = 0; i < digits.length; i += 4)
        digits.substring(i, (i + 4).clamp(0, digits.length)),
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final block = multiline || kind == PaymentCodeKind.pre;
    final style =
        (switch (size) {
              PaymentSize.small => type.caption,
              PaymentSize.medium => type.label,
              PaymentSize.large => type.amountLarge,
            })
            .reference(t)
            .copyWith(
              color: kind == PaymentCodeKind.samp
                  ? t.textSecondary
                  : t.textPrimary,
            );
    final label = [semanticLabel, _spoken].nonNulls.join(' ');
    Widget body = kind == PaymentCodeKind.kbd
        ? Text(text, style: style, semanticsLabel: label)
        : SelectableText(
            text,
            style: style,
            maxLines: noWrap ? 1 : null,
            semanticsLabel: label,
          );
    if (kind != PaymentCodeKind.samp) {
      body = Container(
        padding: block
            ? EdgeInsets.all(t.space(PaymentSpace.block))
            : EdgeInsets.symmetric(horizontal: t.space(PaymentSpace.inline)),
        decoration: BoxDecoration(
          color: kind == PaymentCodeKind.kbd ? null : t.surfaceMuted,
          borderRadius: block ? t.controlBorderRadius : t.tagBorderRadius,
          border: kind == PaymentCodeKind.kbd
              ? Border.all(color: t.border)
              : null,
        ),
        child: body,
      );
    }
    if (noWrap) {
      body = EdgeFadeScroll(child: body);
    }
    body = Align(alignment: AlignmentDirectional.centerStart, child: body);
    if (block) body = SizedBox(width: double.infinity, child: body);
    if (onCopy != null) {
      body = Row(
        children: [
          Expanded(child: body),
          PaymentCopyButton(value: text, onCopy: onCopy!),
        ],
      );
    }
    return size == PaymentSize.large
        ? MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6, child: body)
        : body;
  }
}
