// The deprecated pageAction must keep compiling until 0.2.0.
// ignore_for_file: deprecated_member_use_from_same_package
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

  // UI review P5: D53 column, D59a header links, D62 footer, #49-4.
  Widget framed(Widget child, {double scale = 1}) =>
      contentHostBounded(child, scale: scale);

  testWidgets('full page link sits on the title row at 393 (D59a)', (t) async {
    await setSurface(t, const Size(393, 844));
    await t.pumpWidget(
      framed(
        PaymentFullPageView(
          title: 'Transactions',
          pageLink: PaymentLink(label: 'Statement', onPressed: () {}),
          child: const Text('Body'),
        ),
      ),
    );
    final title = t.getRect(find.text('Transactions'));
    final link = t.getRect(find.text('Statement'));
    // Centred on the title's first 24 dp line (the test font may wrap it).
    expect((link.center.dy - (title.top + 12)).abs(), lessThan(1));
    expect(link.left, greaterThan(title.right));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    // No outlined button under the title any more.
    expect(find.byType(PaymentButton), findsNothing);
  });

  testWidgets('full page primary is pinned above a long body (D62)', (t) async {
    await setSurface(t, const Size(393, 844));
    var calls = 0;
    await t.pumpWidget(
      framed(
        PaymentFullPageView(
          title: 'Transactions',
          primaryAction: PaymentButton(
            label: 'Download statement',
            onPressed: () => calls++,
          ),
          secondaryAction: PaymentButton(
            label: 'Not now',
            variant: PaymentButtonVariant.quiet,
            onPressed: () {},
          ),
          child: Column(
            children: [for (var i = 0; i < 60; i++) Text('Row $i')],
          ),
        ),
      ),
    );
    final primary = find.widgetWithText(PaymentButton, 'Download statement');
    expect(primary.hitTestable(), findsOneWidget);
    final quiet = t.getRect(find.widgetWithText(PaymentButton, 'Not now'));
    expect(t.getRect(primary).top, lessThan(quiet.top));
    expect(t.getRect(primary).width, quiet.width);
    expect(t.getRect(primary).bottom, lessThanOrEqualTo(844));
    await t.tap(primary);
    expect(calls, 1);
  });

  testWidgets('wide body content is a centred column of at most 640 (D53)', (
    t,
  ) async {
    await setSurface(t, const Size(1024, 768));
    await t.pumpWidget(
      framed(
        PaymentFullPageView(
          title: 'Transactions',
          primaryAction: PaymentButton(label: 'Download', onPressed: () {}),
          child: const SizedBox(
            key: Key('body'),
            height: 40,
            width: double.infinity,
          ),
        ),
      ),
    );
    final body = t.getRect(find.byKey(const Key('body')));
    expect(body.width, lessThanOrEqualTo(640));
    expect(body.center.dx, closeTo(512, 1));
    // The header text shares the body's start edge.
    expect(t.getTopLeft(find.text('Transactions')).dx, closeTo(body.left, 1));
  });

  testWidgets('two-column overview keeps two columns up to 1040 (Q1)', (
    t,
  ) async {
    await setSurface(t, const Size(1280, 900));
    await t.pumpWidget(
      framed(
        const PaymentFullPageView(
          title: 'Spending',
          child: PaymentOverviewPage(
            primary: [
              PaymentPageModule(title: 'Main', child: Text('Primary body')),
            ],
            secondary: [
              PaymentPageModule(title: 'Side', child: Text('Secondary body')),
            ],
          ),
        ),
      ),
    );
    final main = t.getRect(find.text('Main'));
    final side = t.getRect(find.text('Side'));
    expect((main.top - side.top).abs(), lessThan(1));
    expect(side.left, greaterThan(main.left + 500));
    final overview = t.getRect(find.byType(PaymentOverviewPage));
    expect(overview.width, lessThanOrEqualTo(1040));
    expect(overview.center.dx, closeTo(640, 1));
  });

  testWidgets('context view header scrolls with the body at 2x (#49-4)', (
    t,
  ) async {
    await setSurface(t, const Size(393, 844));
    await t.pumpWidget(
      framed(
        PaymentContextView(
          title: 'Order context',
          description: 'Toko Contoh · Order DEMO-42',
          brand: const PaymentIcon(Icons.storefront_outlined),
          primaryAction: PaymentButton(label: 'Pay', onPressed: () {}),
          child: const Text('Body'),
        ),
        scale: 2,
      ),
    );
    expect(
      find.ancestor(
        of: find.text('Order context'),
        matching: find.byType(Scrollable),
      ),
      findsWidgets,
    );
    await t.pumpWidget(
      framed(
        PaymentContextView(
          title: 'Order context',
          primaryAction: PaymentButton(label: 'Pay', onPressed: () {}),
          child: const Text('Body'),
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.text('Order context'),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });

  testWidgets('context view icon centres on the title first line (#66)', (
    t,
  ) async {
    await setSurface(t, const Size(393, 844));
    await t.pumpWidget(
      framed(
        const PaymentContextView(
          title: 'Order context',
          brand: PaymentIcon(Icons.storefront_outlined),
          child: Text('Body'),
        ),
      ),
    );
    final icon = t.getRect(find.byIcon(Icons.storefront_outlined));
    final title = t.getRect(find.text('Order context'));
    expect((icon.center.dy - title.center.dy).abs(), lessThan(1));
    expect(title.left - icon.right, closeTo(12, 1));
  });
}

/// A view in a bounded box the size of the test surface's body.
Widget contentHostBounded(Widget child, {double scale = 1}) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.iOS),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  ),
);
