import 'package:flutter/material.dart';
import '../controls/actions.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/primitives.dart';
import '../foundation/view_frame.dart';
import '../pages/overview_page.dart';

/// Full-page body; the host supplies its scaffold and navigation.
///
/// At 600 dp and wider the content sits in a centred column up to 640 dp;
/// a [PaymentOverviewPage] child with a secondary column keeps two columns
/// up to 1040 dp from 840 dp (D53). The header holds navigation only
/// ([pageLink]); the screen's priority action pins to the footer (D62).
class PaymentFullPageView extends StatelessWidget {
  const PaymentFullPageView({
    super.key,
    required this.title,
    required this.child,
    @Deprecated(
      'Use pageLink to open another screen or primaryAction for the main '
      'step. Removed in 0.2.0.',
    )
    this.pageAction,
    this.pageLink,
    this.primaryAction,
    this.secondaryAction,
  }) : assert(pageAction == null || pageLink == null);

  /// Heading displayed above the content.
  final String title;

  /// Content rendered inside this layout body.
  final Widget child;

  /// Supporting action alongside the page heading.
  @Deprecated(
    'Use pageLink to open another screen or primaryAction for the main '
    'step. Removed in 0.2.0.',
  )
  final PaymentButton? pageAction;

  /// Navigation on the title row, shown as "Label ›" (D59a).
  final PaymentLink? pageLink;

  /// The screen's priority action, pinned in the footer (D62).
  final PaymentButton? primaryAction;

  /// At most one quiet action under the primary.
  final PaymentButton? secondaryAction;
  @override
  Widget build(BuildContext context) {
    assert(
      secondaryAction == null ||
          secondaryAction!.variant != PaymentButtonVariant.primary,
    );
    // ignore: deprecated_member_use_from_same_package
    final legacy = pageAction;
    final content = child;
    final twoColumn =
        content is PaymentOverviewPage && content.secondary != null;
    final gutter = PaymentTheme.of(context).space(PaymentSpace.group);
    return LayoutBuilder(
      builder: (context, k) => ViewFrame(
        maxContentWidth:
            twoColumn && k.maxWidth - gutter * 2 >= kTwoColumnBreakpoint
            ? kTwoColumnMaxWidth
            : kContentMaxWidth,
        header: ViewHeader(
          title: title,
          link: pageLink,
          actions: [?legacy],
          inlineActions: true,
        ),
        body: child,
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
