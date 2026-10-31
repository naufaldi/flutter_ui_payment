import 'package:flutter/material.dart';
import 'focus_ring.dart';
import 'payment_theme.dart';

/// Internal list-row container. Content and semantics stay with each row.
class RowShell extends StatelessWidget {
  const RowShell({
    super.key,
    required this.onTap,
    required this.child,
    this.centerShortRows = true,
    this.minHeight = 48,
  });
  final VoidCallback? onTap;
  final Widget child;
  final bool centerShortRows;
  final double minHeight;
  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        vertical: PaymentTheme.of(context).spacing * 1.5,
      ),
      child: child,
    );
    return PaymentFocusRing(
      radius: BorderRadius.zero,
      child: InkWell(
        focusColor: Colors.transparent,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: centerShortRows
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: padded,
                )
              : padded,
        ),
      ),
    );
  }
}
