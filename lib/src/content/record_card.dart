import 'package:flutter/material.dart';

import '../foundation/first_line.dart';
import '../foundation/focus_ring.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final gap = theme.space(PaymentSpace.related);
    final inset = theme.space(PaymentSpace.block);
    final radius = theme.controlBorderRadius;
    Widget body = Padding(
      padding: EdgeInsets.all(gap),
      child: FirstLineRow(
        gap: inset,
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
            DefaultTextStyle.merge(style: type.heading, child: title),
            if (metadata case final metadata?) ...[
              SizedBox(height: theme.space(PaymentSpace.inline)),
              DefaultTextStyle.merge(style: type.caption, child: metadata),
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
    return Material(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: theme.borderRadius,
        side: BorderSide(color: theme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (end == null)
            Padding(padding: EdgeInsets.all(inset), child: body)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontalInset =
                    ((constraints.maxWidth - kMinInteractiveDimension) / 2)
                        .clamp(0.0, inset);
                final rowWidth = constraints.maxWidth - 2 * horizontalInset;
                // The trailing slot gets one third of the row after the gap.
                final stacked =
                    PaymentType.isLarge(context) ||
                    rowWidth - gap < 3 * kMinInteractiveDimension;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalInset,
                    vertical: inset,
                  ),
                  child: Flex(
                    direction: stacked ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.center,
                    spacing: gap,
                    children: [
                      Expanded(flex: stacked ? 0 : 2, child: body),
                      Flexible(
                        flex: stacked ? 0 : 1,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (footer case final footer?) ...[
            const PaymentDivider(),
            Padding(padding: EdgeInsets.all(inset), child: footer),
          ],
        ],
      ),
    );
  }
}
