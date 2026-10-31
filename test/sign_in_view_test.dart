import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  testWidgets(
    'every sign-in slot contains no credential editor and calls host',
    (t) async {
      var calls = 0;
      await t.pumpWidget(
        contentHost(
          SizedBox(
            height: 700,
            child: PaymentSignInView(
              primaryAction: PaymentButton(
                label: 'Continue with bank',
                onPressed: () {
                  calls++;
                },
              ),
              brand: const PaymentIcon(Icons.account_balance),
              description: 'Connect with your bank app',
              secondaryAction: PaymentButton(
                label: 'Another account',
                variant: PaymentButtonVariant.secondary,
                onPressed: () {
                  calls++;
                },
              ),
              learnMore: PaymentSignInLearnMore(
                label: 'What we can see',
                title: 'Permissions',
                builder: (_) => const Text('Payment history only'),
              ),
              legalLinks: [PaymentLink(label: 'Privacy', onPressed: () {})],
              footnote: 'We never ask for your PIN here.',
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(PaymentSignInView),
          matching: find.byType(EditableText),
        ),
        findsNothing,
      );
      expect(find.byType(PaymentListItem), findsOneWidget);
      expect(
        t.getTopLeft(find.byType(PaymentIcon).first).dx,
        t.getTopLeft(find.text('Sign in to continue')).dx,
      );
      await t.tap(find.text('Continue with bank'));
      await t.pumpAndSettle();
      expect(calls, 1);
      await t.tap(find.text('What we can see'));
      await t.pumpAndSettle();
      expect(find.byType(PaymentFocusView), findsOneWidget);
      expect(find.text('Permissions'), findsOneWidget);
    },
  );
  testWidgets('error banner is focused and default title is localized', (
    t,
  ) async {
    await t.pumpWidget(
      contentHost(
        SizedBox(
          height: 700,
          child: PaymentSignInView(
            primaryAction: PaymentButton(label: 'Continue', onPressed: () {}),
            errorText: 'Sign-in canceled',
          ),
        ),
        locale: const Locale('id'),
      ),
    );
    await t.pump();
    expect(find.text('Masuk untuk melanjutkan'), findsOneWidget);
    expect(find.byType(PaymentBanner), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(t.takeException(), isNull);
  });
}
