import 'package:flutter/material.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/token_resolvers.dart';

/// Layout direction.
enum PaymentStack {
  /// horizontal.
  horizontal,

  /// vertical.
  vertical,

  /// layered.
  layered,
}

/// Sibling distribution.
enum PaymentDistribute {
  /// packed.
  packed,

  /// spaceBetween.
  spaceBetween,
}

/// Axis alignment.
enum PaymentAlign {
  /// start.
  start,

  /// center.
  center,

  /// end.
  end,

  /// stretch.
  stretch,

  /// baseline.
  baseline,
}

/// Semantic surface.
enum PaymentBoxBackground {
  /// none.
  none,

  /// surface.
  surface,

  /// muted.
  muted,
}

/// Semantic one-pixel edge.
enum PaymentKeyline {
  /// none.
  none,

  /// neutral.
  neutral,

  /// critical.
  critical,
}

/// Token-only layout container. Never merges child semantics.
class PaymentBox extends StatelessWidget {
  const PaymentBox({
    super.key,
    required this.children,
    this.stack = PaymentStack.vertical,
    this.padding = PaymentSpace.none,
    this.paddingX,
    this.paddingY,
    this.gap = PaymentSpace.none,
    this.distribute = PaymentDistribute.packed,
    this.alignX = PaymentAlign.stretch,
    this.alignY = PaymentAlign.start,
    this.wrap = false,
    this.background = PaymentBoxBackground.none,
    this.radius = PaymentRadius.none,
    this.keyline = PaymentKeyline.none,
    this.width = PaymentWidth.fill,
  });

  /// children; uses semantic tokens.
  final List<Widget> children;

  /// stack; uses semantic tokens.
  final PaymentStack stack;

  /// padding; uses semantic tokens.
  final PaymentSpace padding;

  /// gap; uses semantic tokens.
  final PaymentSpace gap;

  /// paddingX; uses semantic tokens.
  final PaymentSpace? paddingX;

  /// paddingY; uses semantic tokens.
  final PaymentSpace? paddingY;

  /// distribute; uses semantic tokens.
  final PaymentDistribute distribute;

  /// alignX; uses semantic tokens.
  final PaymentAlign alignX;

  /// alignY; uses semantic tokens.
  final PaymentAlign alignY;

  /// wrap; uses semantic tokens.
  final bool wrap;

  /// background; uses semantic tokens.
  final PaymentBoxBackground background;

  /// radius; uses semantic tokens.
  final PaymentRadius radius;

  /// keyline; uses semantic tokens.
  final PaymentKeyline keyline;

  /// width; uses semantic tokens.
  final PaymentWidth width;
  CrossAxisAlignment _cross(PaymentAlign a) => switch (a) {
    PaymentAlign.start => CrossAxisAlignment.start,
    PaymentAlign.center => CrossAxisAlignment.center,
    PaymentAlign.end => CrossAxisAlignment.end,
    PaymentAlign.stretch => CrossAxisAlignment.stretch,
    PaymentAlign.baseline => CrossAxisAlignment.baseline,
  };
  MainAxisAlignment _main(PaymentAlign a) =>
      distribute == PaymentDistribute.spaceBetween
      ? MainAxisAlignment.spaceBetween
      : switch (a) {
          PaymentAlign.center => MainAxisAlignment.center,
          PaymentAlign.end => MainAxisAlignment.end,
          _ => MainAxisAlignment.start,
        };
  double _position(PaymentAlign a) => a == PaymentAlign.center
      ? 0
      : a == PaymentAlign.end
      ? 1
      : -1;
  @override
  Widget build(BuildContext context) {
    assert(alignX != PaymentAlign.baseline);
    assert(alignY != PaymentAlign.baseline || stack == PaymentStack.horizontal);
    assert(!wrap || stack == PaymentStack.horizontal);
    final t = PaymentTheme.of(context);
    final g = t.space(gap);
    final Widget body = switch (stack) {
      PaymentStack.vertical => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: g,
        crossAxisAlignment: _cross(
          width == PaymentWidth.hug && alignX == PaymentAlign.stretch
              ? PaymentAlign.start
              : alignX,
        ),
        mainAxisAlignment: _main(alignY),
        children: children,
      ),
      PaymentStack.horizontal when wrap => Wrap(
        spacing: g,
        runSpacing: g,
        alignment: switch (alignX) {
          PaymentAlign.center => WrapAlignment.center,
          PaymentAlign.end => WrapAlignment.end,
          _ => WrapAlignment.start,
        },
        crossAxisAlignment: switch (alignY) {
          PaymentAlign.center => WrapCrossAlignment.center,
          PaymentAlign.end => WrapCrossAlignment.end,
          _ => WrapCrossAlignment.start,
        },
        children: children,
      ),
      PaymentStack.horizontal => Row(
        mainAxisSize: width == PaymentWidth.hug
            ? MainAxisSize.min
            : MainAxisSize.max,
        spacing: g,
        mainAxisAlignment: _main(alignX),
        crossAxisAlignment: _cross(alignY),
        textBaseline: alignY == PaymentAlign.baseline
            ? TextBaseline.alphabetic
            : null,
        children: children,
      ),
      PaymentStack.layered => Stack(
        alignment: AlignmentDirectional(_position(alignX), _position(alignY)),
        fit: alignX == PaymentAlign.stretch && alignY == PaymentAlign.stretch
            ? StackFit.expand
            : StackFit.loose,
        children: children,
      ),
    };
    return Container(
      width: width == PaymentWidth.fill ? double.infinity : null,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: t.space(paddingX ?? padding),
        vertical: t.space(paddingY ?? padding),
      ),
      clipBehavior: radius == PaymentRadius.none ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: switch (background) {
          PaymentBoxBackground.none => null,
          PaymentBoxBackground.surface => t.surface,
          PaymentBoxBackground.muted => t.surfaceMuted,
        },
        borderRadius: radius.resolve(t),
        border: keyline == PaymentKeyline.none
            ? null
            : Border.all(
                color: keyline == PaymentKeyline.critical
                    ? t.danger.foreground
                    : t.outline,
              ),
      ),
      child: body,
    );
  }
}

/// One styled run in rich inline text.
@immutable
class PaymentSpan {
  const PaymentSpan(
    this.text, {
    this.weight,
    this.color,
    this.reference = false,
  });

  /// Text content.
  final String text;

  /// Running emphasis.
  final PaymentFontWeight? weight;

  /// Semantic color.
  final PaymentTextColor? color;

  /// Use the reference face.
  final bool reference;
}

/// Text in one type role.
class PaymentInline extends StatelessWidget {
  const PaymentInline(
    this.text, {
    super.key,
    this.role = PaymentTextRole.body,
    this.weight,
    this.color,
    this.tabular = false,
    this.reference = false,
    this.maxLines,
    this.textAlign,
  }) : spans = const [];
  const PaymentInline.rich(
    this.spans, {
    super.key,
    this.role = PaymentTextRole.body,
  }) : text = null,
       weight = null,
       color = null,
       tabular = false,
       reference = false,
       maxLines = null,
       textAlign = null;

  /// text for this text.
  final String? text;

  /// spans for this text.
  final List<PaymentSpan> spans;

  /// role for this text.
  final PaymentTextRole role;

  /// weight for this text.
  final PaymentFontWeight? weight;

  /// color for this text.
  final PaymentTextColor? color;

  /// tabular for this text.
  final bool tabular;

  /// reference for this text.
  final bool reference;

  /// maxLines for this text.
  final int? maxLines;

  /// textAlign for this text.
  final TextAlign? textAlign;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    var style = role
        .resolve(context)
        .copyWith(color: color?.resolve(theme), fontWeight: weight?.fontWeight);
    if (tabular) style = style.tabular;
    if (reference) style = style.reference(theme);
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style:
                  (span.reference
                          ? const TextStyle().reference(theme)
                          : const TextStyle())
                      .copyWith(
                        fontWeight: span.weight?.fontWeight,
                        color: span.color?.resolve(theme),
                      ),
            ),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}
