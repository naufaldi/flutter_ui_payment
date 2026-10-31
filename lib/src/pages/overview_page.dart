import 'package:flutter/material.dart';
import '../foundation/payment_theme.dart';
import '../interaction/interaction.dart';
import 'page_module.dart';

/// Non-scrolling page modules; place inside a FullPageView.
class PaymentOverviewPage extends StatelessWidget {
  const PaymentOverviewPage({
    super.key,
    required this.primary,
    this.secondary,
    this.pending = false,
  });

  /// Primary supplied by the host.
  final List<PaymentPageModule> primary;

  /// Secondary supplied by the host.
  final List<PaymentPageModule>? secondary;

  /// Pending supplied by the host.
  final bool pending;
  @override
  Widget build(BuildContext context) {
    Widget column(List<PaymentPageModule> items, int count) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: pending
          ? [
              for (var i = 0; i < count; i++)
                const LoadingSkeleton(rows: 3, leading: false),
            ]
          : items,
    );
    return LayoutBuilder(
      builder: (context, k) {
        if (k.maxWidth >= 840 && secondary != null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PaymentTheme.of(context).spacing * 3,
            children: [
              Expanded(flex: 2, child: column(primary, 2)),
              Expanded(child: column(secondary!, 1)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            column(primary, 2),
            if (secondary != null) column(secondary!, 1),
          ],
        );
      },
    );
  }
}
