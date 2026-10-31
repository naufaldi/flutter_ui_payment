import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

Widget bounded(
  Widget child, {
  double scale = 1,
  bool dark = false,
  Locale locale = const Locale('en'),
}) => contentHost(
  SizedBox(height: 700, child: child),
  scale: scale,
  dark: dark,
  locale: locale,
);
void main() {
  testWidgets(
    'views are scrollable bodies with no scaffold or route of their own',
    (t) async {
      for (final view in [
        const PaymentContextView(title: 'Context', child: Text('Body')),
        const PaymentFullPageView(title: 'Full', child: Text('Body')),
        const PaymentSettingsView(title: 'Settings', child: Text('Body')),
        const PaymentOnboardingView(
          title: 'Setup',
          tasks: [],
          child: Text('Body'),
        ),
      ]) {
        await t.pumpWidget(bounded(view));
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Navigator), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(contentHost(view));
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets('settings waits for save and announces host status', (t) async {
    await setSurface(t, const Size(800, 1000));
    var calls = 0;
    await t.pumpWidget(
      bounded(
        PaymentSettingsView(
          title: 'Settings',
          statusMessage: 'Saved',
          onSave: () async {
            calls++;
          },
          child: const Text('Notifications'),
        ),
      ),
    );
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Saved'), findsOneWidget);
  });
  testWidgets(
    'context rejects arbitrary branding and multiple primary actions',
    (t) async {
      await t.pumpWidget(
        bounded(
          const PaymentContextView(
            title: 'Context',
            brand: Text('Invalid'),
            child: Text('Body'),
          ),
        ),
      );
      expect(t.takeException(), isAssertionError);
    },
  );
  testWidgets('narrow large text dark and localized views', (t) async {
    await setSurface(t, const Size(320, 1200));
    for (final dark in [false, true]) {
      for (final locale in [const Locale('en'), const Locale('id')]) {
        await t.pumpWidget(
          bounded(
            PaymentFullPageView(
              title: 'Transactions',
              pageAction: PaymentButton(
                label: 'Download statement',
                variant: PaymentButtonVariant.secondary,
                onPressed: () {},
              ),
              child: const Text('Body'),
            ),
            scale: 2,
            dark: dark,
            locale: locale,
          ),
        );
        expect(t.takeException(), isNull);
      }
    }
  });
}
