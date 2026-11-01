import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';

class SignInStep extends StatelessWidget {
  const SignInStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    void legal() => showPaymentToast(context, message: s.policyOpened);
    // Account linking (D61): who connects, what it can and can never do,
    // and one short action pinned at the bottom.
    return PaymentSignInView(
      requesterBrand: PaymentIcon(
        Icons.school_outlined,
        semanticLabel: s.signInRequester,
      ),
      brand: const PaymentIcon(Icons.account_balance_wallet_outlined),
      title: s.signInTitle,
      description: s.signInDescription,
      canDo: s.signInCanDo,
      cannotDo: s.signInCannotDo,
      legalNotice: s.signInLegal,
      legalLinks: [
        PaymentLink(label: s.terms, external: true, onPressed: legal),
        PaymentLink(label: s.privacy, external: true, onPressed: legal),
      ],
      primaryAction: PaymentButton(
        key: const Key('sign-in'),
        label: s.signInContinue,
        busy: c.signingIn,
        onPressed: c.signIn,
      ),
      secondaryAction: PaymentButton(
        key: const Key('sign-in-cancel'),
        label: s.signInCancel,
        variant: PaymentButtonVariant.quiet,
        onPressed: () => showPaymentToast(context, message: s.signInCanceled),
      ),
      errorText: c.signInError ? s.signInCanceled : null,
    );
  }
}
