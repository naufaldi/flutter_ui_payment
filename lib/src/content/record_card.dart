import 'package:flutter/material.dart';

import '../foundation/first_line.dart';
import '../foundation/focus_ring.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';

/// Placement of the divider above a [PaymentRecordCard] footer.
enum PaymentRecordCardDivider {
  /// Draws the divider across the card, the default.
  fullWidth,

  /// Aligns the divider with the footer's horizontal inset.
  inset,

  /// Does not draw a divider.
  none,
}

/// Optional appearance overrides for a [PaymentRecordCard].
class PaymentRecordCardStyle {
  const PaymentRecordCardStyle({
    this.titleStyle,
    this.metadataStyle,
    this.inset,
    this.divider = PaymentRecordCardDivider.fullWidth,
    this.elevation = 0,
  }) : assert(inset == null || (inset >= 0 && inset < double.infinity)),
       assert(elevation >= 0 && elevation < double.infinity);

  /// Merged over the kit heading style for the title slot.
  final TextStyle? titleStyle;

  /// Merged over the kit caption style for the metadata slot.
  final TextStyle? metadataStyle;

  /// Outer inset in dp around the body row and footer. Defaults to the kit's
  /// block spacing. Horizontal inset yields to a 48 dp body or trailing target.
  final double? inset;

  /// Divider above the footer. Has no effect without a footer.
  final PaymentRecordCardDivider divider;

  /// Material elevation in dp. Defaults to a flat card.
  final double elevation;
}

/// A record surface with a separately actionable body, trailing slot and footer.
/// Only the body opens the record. Use passive widgets for the title, leading
/// visual and metadata, and put controls in [trailing] or [footer].
class PaymentRecordCard extends StatelessWidget {
  const PaymentRecordCard({
    super.key,
    required this.title,
    this.leading,
    this.metadata,
    this.trailing,
    this.footer,
    this.onOpen,
    this.openLabel,
    this.hugTrailing = false,
    this.style = const PaymentRecordCardStyle(),
  });

  /// A record title, styled as a heading by default.
  final Widget title;

  /// A decorative icon or thumbnail, limited to 40 × 40 dp and not spoken.
  final Widget? leading;

  /// Supporting content below the title, styled as a caption by default.
  final Widget? metadata;

  /// An independent end slot. It moves below the body at large text sizes
  /// or when the inline slot would be narrower than 48 dp.
  final Widget? trailing;

  /// An independent full-width slot below a divider.
  final Widget? footer;

  /// Opens the record from its body. If omitted, the body is read-only.
  final VoidCallback? onOpen;

  /// Replaces the open action's spoken title and metadata, when supplied.
  final String? openLabel;

  /// Lets an inline trailing slot take only the width its child needs, up to
  /// the default one-third allocation. Stacking and tap targets are unchanged.
  final bool hugTrailing;

  /// Appearance overrides. Unspecified properties keep the kit defaults.
  final PaymentRecordCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final gap = theme.space(PaymentSpace.related);
    final block = theme.space(PaymentSpace.block);
    final inset = style.inset ?? block;
    final radius = theme.controlBorderRadius;
    final titleStyle = type.heading.merge(style.titleStyle);
    Widget body = Padding(
      padding: EdgeInsets.all(gap),
      child: FirstLineRow(
        gap: block,
        line: style.titleStyle == null
            ? null
            : lineHeightOf(context, titleStyle),
        leading: leading == null
            ? null
            : ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kMediaTile,
                    maxHeight: kMediaTile,
                  ),
                  child: leading,
                ),
              ),
        text: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle.merge(style: titleStyle, child: title),
            if (metadata case final metadata?) ...[
              SizedBox(height: theme.space(PaymentSpace.inline)),
              DefaultTextStyle.merge(
                style: type.caption.merge(style.metadataStyle),
                child: metadata,
              ),
            ],
          ],
        ),
      ),
    );
    if (onOpen != null) {
      body = MergeSemantics(
        child: Semantics(
          button: true,
          enabled: true,
          label: openLabel,
          onTap: onOpen,
          child: PaymentFocusRing(
            radius: radius,
            child: InkWell(
              borderRadius: radius,
              excludeFromSemantics: true,
              focusColor: Colors.transparent,
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: openLabel == null
                      ? body
                      : ExcludeSemantics(child: body),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final end = trailing;
    double fitInset(double width) =>
        ((width - kMinInteractiveDimension) / 2).clamp(0.0, inset);

    Widget row(double horizontalInset, double width) {
      final trailingWidth = (width - 2 * horizontalInset - gap) / 3;
      final stacked =
          end != null &&
          (PaymentType.isLarge(context) ||
              trailingWidth < kMinInteractiveDimension);
      final hugs = !stacked && hugTrailing;
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: inset,
        ),
        child: end == null
            ? body
            : Flex(
                direction: stacked ? Axis.vertical : Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                spacing: gap,
                children: [
                  Expanded(flex: stacked ? 0 : 2, child: body),
                  Flexible(
                    flex: stacked || hugs ? 0 : 1,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: hugs ? trailingWidth : double.infinity,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        widthFactor: hugs ? 1 : null,
                        child: end,
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    Widget content([double? width]) {
      final horizontalInset = width == null ? inset : fitInset(width);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (width == null && end != null)
            LayoutBuilder(
              builder: (context, constraints) =>
                  row(fitInset(constraints.maxWidth), constraints.maxWidth),
            )
          else
            row(horizontalInset, width ?? double.infinity),
          if (footer case final footer?) ...[
            switch (style.divider) {
              PaymentRecordCardDivider.fullWidth => const PaymentDivider(),
              PaymentRecordCardDivider.inset => Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: const PaymentDivider(),
              ),
              PaymentRecordCardDivider.none => const SizedBox.shrink(),
            },
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: inset,
              ),
              child: footer,
            ),
          ],
        ],
      );
    }

    return Material(
      color: theme.surface,
      elevation: style.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: theme.borderRadius,
        side: BorderSide(color: theme.outline),
      ),
      child: style.inset == null
          ? content()
          : LayoutBuilder(
              builder: (context, constraints) => content(constraints.maxWidth),
            ),
    );
  }
}
