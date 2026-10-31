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
    return PaymentSignInView(
      brand: const PaymentIcon(Icons.account_balance_wallet_outlined),
      description: s.signInDescription,
      primaryAction: PaymentButton(
        key: const Key('sign-in'),
        label: s.signInContinue,
        busy: c.signingIn,
        onPressed: c.signIn,
      ),
      learnMore: PaymentSignInLearnMore(
        label: s.signInLearnMore,
        title: s.signInLearnMore,
        builder: (_) => const PaymentPropertyList(
          items: [
            PaymentPropertyListItem(
              label: 'Payments and refunds',
              valueText: 'Amounts, dates, merchants',
            ),
            PaymentPropertyListItem(
              label: 'Identity status',
              valueText: 'Verified or not, never your documents',
            ),
            PaymentPropertyListItem(
              label: 'Not shared',
              valueText: 'PIN, OTP, card numbers',
            ),
          ],
        ),
      ),
      legalLinks: [
        PaymentLink(label: s.terms, external: true, onPressed: legal),
        PaymentLink(label: s.privacy, external: true, onPressed: legal),
      ],
      footnote: s.signInFootnote,
      errorText: c.signInError ? s.signInCanceled : null,
    );
  }
}
