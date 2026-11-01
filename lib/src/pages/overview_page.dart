import 'package:flutter/material.dart';
import '../foundation/payment_theme.dart';
import '../interaction/interaction.dart';
import 'page_module.dart';
import 'detail_page_property_list.dart';
import 'detail_page_table.dart';
import '../charts/charts.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/layout_rules.dart';

/// Non-scrolling page modules; place inside a FullPageView.
class PaymentOverviewPage extends StatelessWidget {
  const PaymentOverviewPage({
    super.key,
    required this.primary,
    this.secondary,
    this.pending = false,
  });

  /// Primary page modules, in reading order.
  final List<Widget> primary;

  /// Supporting page modules, below the primary on phones.
  final List<Widget>? secondary;

  /// Shows placeholders while the host loads content.
  final bool pending;
  @override
  Widget build(BuildContext context) {
    assert(
      [...primary, ...?secondary].every(
        (w) =>
            w is PaymentPageModule ||
            w is PaymentDetailPagePropertyList ||
            w is PaymentDetailPageTable ||
            w is ChartModule,
      ),
    );
    // Page modules end with `section` under their content; a chart module
    // (a section with `related` padding) gets the rest of it, so every
    // module → module gap is equal (#66).
    final theme = PaymentTheme.of(context);
    final after =
        theme.space(PaymentSpace.section) - theme.space(PaymentSpace.related);
    Widget column(List<Widget> items, int count) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: pending
          ? [
              for (var i = 0; i < count; i++)
                const LoadingSkeleton(rows: 3, leading: false),
            ]
          : [
              for (final item in items)
                if (item is ChartModule)
                  Padding(
                    padding: EdgeInsets.only(bottom: after),
                    child: item,
                  )
                else
                  item,
            ],
    );
    return LayoutBuilder(
      builder: (context, k) {
        if (k.maxWidth >= kTwoColumnBreakpoint && secondary != null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PaymentTheme.of(context).space(PaymentSpace.section),
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
