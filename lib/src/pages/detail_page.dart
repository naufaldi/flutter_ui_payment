import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../controls/actions.dart';
import '../foundation/view_frame.dart';
import '../controls/button_group.dart';
import 'page_module.dart';
import 'detail_page_property_list.dart';
import 'detail_page_table.dart';
import '../charts/charts.dart';
import 'overview_page.dart';
import '../foundation/payment_tokens.dart';

/// Detail body owning one scroll region; do not nest in FullPageView.
class PaymentDetailPage extends StatelessWidget {
  const PaymentDetailPage({
    super.key,
    required this.title,
    required this.primary,
    this.secondary,
    this.breadcrumbs = const [],
    this.description,
    this.actions = const [],
    this.pending = false,
  });

  /// Heading displayed above the content.
  final String title;

  /// Primary page modules, in reading order.
  final List<Widget> primary;

  /// Supporting page modules, below the primary on phones.
  final List<Widget>? secondary;

  /// Host destinations leading back to the parent page.
  final List<PaymentBreadcrumb> breadcrumbs;

  /// Supporting explanation below the heading.
  final String? description;

  /// Host actions displayed in the page header.
  final List<PaymentButton> actions;

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
    final l = PaymentLocalizations.of(context);
    return ViewFrame(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (breadcrumbs.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(
                PaymentTheme.of(context).space(PaymentSpace.group),
              ),
              child: LayoutBuilder(
                builder: (context, k) {
                  if (k.maxWidth < kCompactBreakpoint ||
                      PaymentType.isLarge(context)) {
                    final b = breadcrumbs.last;
                    return Row(
                      children: [
                        const Icon(Icons.chevron_left),
                        Flexible(
                          child: PaymentLink(
                            label: b.label,
                            semanticLabel: l.backTo(b.label),
                            onPressed: b.onPressed,
                          ),
                        ),
                      ],
                    );
                  }
                  return Wrap(
                    children: [
                      for (final b in breadcrumbs)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PaymentLink(label: b.label, onPressed: b.onPressed),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ViewHeader(
            title: title,
            description: description,
            below: actions.isEmpty
                ? null
                : PaymentButtonGroup(children: actions),
          ),
        ],
      ),
      body: PaymentOverviewPage(
        primary: primary,
        secondary: secondary,
        pending: pending,
      ),
    );
  }
}
