import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_theme.dart';
import '../foundation/view_frame.dart';
import '../controls/button_group.dart';
import '../controls/actions.dart';
import '../layout/content.dart';

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

  /// Title supplied by the host.
  final String title;

  /// Child supplied by the host.
  final Widget child;

  /// Description supplied by the host.
  final String? description;

  /// Brand supplied by the host.
  final Widget? brand;

  /// Actions supplied by the host.
  final List<PaymentButton> actions;

  /// Banner supplied by the host.
  final PaymentBanner? banner;

  /// Externallink supplied by the host.
  final PaymentLink? externalLink;

  /// Primaryaction supplied by the host.
  final PaymentButton? primaryAction;

  /// Secondaryaction supplied by the host.
  final PaymentButton? secondaryAction;

  /// Footer supplied by the host.
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
        below: Column(
          children: [
            if (actions.isNotEmpty) PaymentButtonGroup(children: actions),
            ?banner,
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).spacing * 2,
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
