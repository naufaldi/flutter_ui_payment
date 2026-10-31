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
    'phone footer fills width with primary first and settings adapts',
    (t) async {
      await setSurface(t, const Size(360, 1000));
      await t.pumpWidget(
        bounded(
          PaymentContextView(
            title: 'Order',
            actions: [
              PaymentButton(
                label: 'Copy order',
                variant: PaymentButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
            primaryAction: PaymentButton(label: 'Pay', onPressed: () {}),
            secondaryAction: PaymentButton(
              label: 'Close',
              variant: PaymentButtonVariant.quiet,
              onPressed: () {},
            ),
            child: const Text('Body'),
          ),
        ),
      );
      expect(
        t.getTopLeft(find.text('Copy order')).dx,
        greaterThanOrEqualTo(t.getTopLeft(find.text('Body')).dx),
      );
      final pay = t.getRect(find.widgetWithText(PaymentButton, 'Pay'));
      final close = t.getRect(find.widgetWithText(PaymentButton, 'Close'));
      expect(pay.width, close.width);
      expect(pay.top, lessThan(close.top));
      for (final width in [360.0, 800.0]) {
        t.view.physicalSize = Size(width, 1000);
        await t.pumpWidget(
          bounded(
            PaymentSettingsView(
              title: 'Settings',
              child: const Text('Body'),
              onSave: () async {},
            ),
          ),
        );
        await t.pumpAndSettle();
        final save = t.getRect(find.byType(PaymentButton));
        expect(save.width, width == 360 ? greaterThan(300) : lessThan(200));
      }
    },
  );

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
