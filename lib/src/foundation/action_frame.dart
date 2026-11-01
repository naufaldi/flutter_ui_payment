import 'package:flutter/material.dart';
import 'primitives.dart';
import 'payment_theme.dart';
import 'payment_tokens.dart';
import 'view_frame.dart';

/// Internal: the payment-path frame (D62). Given a bounded height, [header]
/// and the content scroll above a pinned footer holding [primaryAction] and
/// at most one quiet [secondaryAction], inside the bottom safe area. Inside
/// a host's scroll view the height is unbounded and [builder] lays the
/// actions out inline, as before, with [header] above.
class ActionFrame extends StatelessWidget {
  const ActionFrame({
    super.key,
    this.header,
    required this.builder,
    this.primaryAction,
    this.secondaryAction,
    this.note,
  });

  /// Host content above the widget's own, inside the scroll region.
  final Widget? header;

  /// The content; `pinned` is true when the footer holds the actions, so
  /// the builder leaves them out.
  final Widget Function(BuildContext context, bool pinned) builder;
  final PaymentButton? primaryAction;

  /// Quiet only (D59).
  final PaymentButton? secondaryAction;

  /// Shown with the pinned actions, e.g. why the primary is disabled.
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    assert(
      secondaryAction == null ||
          secondaryAction!.variant == PaymentButtonVariant.quiet,
    );
    final theme = PaymentTheme.of(context);
    return LayoutBuilder(
      builder: (context, k) {
        final pinned = k.hasBoundedHeight;
        final body = builder(context, pinned);
        final content = header == null
            ? body
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header!,
                  SizedBox(height: theme.space(PaymentSpace.block)),
                  body,
                ],
              );
        if (!pinned) return content;
        final hasFooter =
            primaryAction != null || secondaryAction != null || note != null;
        return ViewFrame(
          bodyPadding: EdgeInsets.all(theme.space(PaymentSpace.group)),
          body: content,
          footer: hasFooter
              ? ViewFooter(
                  primaryAction: primaryAction,
                  secondaryAction: secondaryAction,
                  footer: note,
                )
              : null,
        );
      },
    );
  }
}
