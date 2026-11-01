import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_theme.dart';
import '../foundation/view_frame.dart';
import '../controls/actions.dart';
import '../layout/content.dart';
import '../foundation/payment_tokens.dart';

/// A contextual panel beside host content.
class PaymentContextView extends StatelessWidget {
  const PaymentContextView({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.brand,
    this.actions = const [],
    this.banner,
    this.externalLink,
    this.primaryAction,
    this.secondaryAction,
    this.footer,
  });

  /// Heading displayed above the content.
  final String title;

  /// Body content owned by the host.
  final Widget child;

  /// Supporting explanation below the heading.
  final String? description;

  /// Host brand icon or image.
  final Widget? brand;

  /// Header actions: on phones one shows as a title-row link and more go
  /// behind ⋮ (D59a). The task's own step belongs in [primaryAction].
  final List<PaymentButton> actions;

  final PaymentBanner? banner;

  final PaymentLink? externalLink;

  /// The single primary action for the contextual task.
  final PaymentButton? primaryAction;

  /// Optional supporting action below the primary action.
  final PaymentButton? secondaryAction;

  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 3);
    assert(brand == null || brand is PaymentImage || brand is PaymentIcon);
    assert(externalLink == null || externalLink!.external);
    assert(
      [
            ...actions,
            ?primaryAction,
            ?secondaryAction,
          ].where((a) => a.variant == PaymentButtonVariant.primary).length <=
          1,
    );
    assert(secondaryAction?.variant != PaymentButtonVariant.primary);
    return ViewFrame(
      header: ViewHeader(
        title: title,
        description: description,
        leading: brand,
        actions: actions,
        below: banner,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).space(PaymentSpace.group),
        children: [
          child,
          if (externalLink != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: externalLink!,
            ),
        ],
      ),
      footer: footer == null && primaryAction == null && secondaryAction == null
          ? null
          : ViewFooter(
              footer: footer,
              primaryAction: primaryAction,
              secondaryAction: secondaryAction,
            ),
    );
  }
}
