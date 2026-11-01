import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../controls/actions.dart';
import '../foundation/view_frame.dart';
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
    this.primaryAction,
    this.secondaryAction,
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

  /// Header actions: on phones one shows as a title-row link and more go
  /// behind ⋮ (D59a). Put the page's priority action in [primaryAction].
  final List<PaymentButton> actions;

  /// Shows placeholders while the host loads content.
  final bool pending;

  /// The page's priority action, pinned in the footer (D62).
  final PaymentButton? primaryAction;

  /// At most one quiet action under the primary.
  final PaymentButton? secondaryAction;
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
    assert(
      secondaryAction == null ||
          secondaryAction!.variant != PaymentButtonVariant.primary,
    );
    final l = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final gutter = theme.space(PaymentSpace.group);
    final crumbs = breadcrumbs.isEmpty
        ? null
        : LayoutBuilder(
            builder: (context, k) {
              if (k.maxWidth < kCompactBreakpoint ||
                  PaymentType.isLarge(context)) {
                final b = breadcrumbs.last;
                return Row(
                  children: [
                    // The chevron hangs outside the column: its glyph, not
                    // its 24 dp box, starts on the title edge (#63-6).
                    const SizedBox(
                      width: 16,
                      height: 24,
                      child: OverflowBox(
                        minWidth: 24,
                        maxWidth: 24,
                        alignment: AlignmentDirectional.centerEnd,
                        child: ExcludeSemantics(
                          child: Icon(Icons.chevron_left),
                        ),
                      ),
                    ),
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
          );
    return LayoutBuilder(
      builder: (context, k) => ViewFrame(
        // Two columns keep their layout up to 1040 dp; one column is capped
        // at 640 (D53, Q1).
        maxContentWidth:
            secondary != null && k.maxWidth - gutter * 2 >= kTwoColumnBreakpoint
            ? kTwoColumnMaxWidth
            : kContentMaxWidth,
        header: ViewHeader(
          title: title,
          description: description,
          above: crumbs,
          actions: actions,
        ),
        body: PaymentOverviewPage(
          primary: primary,
          secondary: secondary,
          pending: pending,
        ),
        footer: primaryAction == null && secondaryAction == null
            ? null
            : ViewFooter(
                primaryAction: primaryAction,
                secondaryAction: secondaryAction,
              ),
      ),
    );
  }
}
