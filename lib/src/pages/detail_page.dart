import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../controls/actions.dart';
import '../foundation/view_frame.dart';
import '../controls/button_group.dart';
import 'page_module.dart';
import 'overview_page.dart';

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

  /// Title supplied by the host.
  final String title;

  /// Primary supplied by the host.
  final List<PaymentPageModule> primary;

  /// Secondary supplied by the host.
  final List<PaymentPageModule>? secondary;

  /// Breadcrumbs supplied by the host.
  final List<PaymentBreadcrumb> breadcrumbs;

  /// Description supplied by the host.
  final String? description;

  /// Actions supplied by the host.
  final List<PaymentButton> actions;

  /// Pending supplied by the host.
  final bool pending;
  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    return ViewFrame(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (breadcrumbs.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(PaymentTheme.of(context).spacing * 2),
              child: LayoutBuilder(
                builder: (context, k) {
                  if (k.maxWidth < 600 || PaymentType.isLarge(context)) {
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
