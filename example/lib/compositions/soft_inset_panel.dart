import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// Host styling for the Soft preset, not a kit component: a white panel
/// inset from the tinted page, with a thin outline and the sheet corners.
///
/// Wrap a whole scrolling block in it. The panel clips its child to the
/// rounded corners, so the block scrolls under its own edge. It adds no
/// shadow, no scale and no motion, and it keeps the kit's 48 dp targets and
/// text scaling, because it only frames the block.
class SoftInsetPanel extends StatelessWidget {
  const SoftInsetPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: theme.sheetBorderRadius,
      side: BorderSide(color: theme.outline),
    );
    final inset = theme.space(PaymentSpace.related);
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
      child: Material(
        color: theme.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
