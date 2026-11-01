import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  testWidgets(
    'horizontal detail properties keep facts in one horizontal list',
    (t) async {
      await setSurface(t, const Size(800, 1000));
      await t.pumpWidget(
        contentHost(
          const PaymentDetailPagePropertyList(
            title: 'Facts',
            pending: false,
            orientation: Axis.horizontal,
            items: [
              PaymentDetailProperty(
                label: 'Merchant name',
                values: [PaymentDetailValue('Toko Contoh')],
              ),
              PaymentDetailProperty(
                label: 'Order reference',
                values: [PaymentDetailValue('DEMO-42')],
              ),
            ],
          ),
        ),
      );
      expect(
        t.getTopLeft(find.text('Merchant name')).dy,
        t.getTopLeft(find.text('Order reference')).dy,
      );
    },
  );

  testWidgets('link-only detail value centers with its label', (t) async {
    await t.pumpWidget(
      contentHost(
        PaymentDetailPagePropertyList(
          title: 'Merchant',
          pending: false,
          items: [
            PaymentDetailProperty(
              label: 'Support',
              values: [
                PaymentDetailValue.link(
                  PaymentLink(label: 'Help centre', onPressed: () {}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(
      (t.getCenter(find.text('Support')).dy -
              t.getCenter(find.byType(PaymentLink)).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
  });

  testWidgets(
    'direct modules show each heading once and reject arbitrary bodies',
    (t) async {
      await t.pumpWidget(
        contentHost(
          const PaymentDetailPage(
            title: 'Transaction',
            primary: [
              PaymentDetailPagePropertyList(
                title: 'Payment details',
                pending: false,
              ),
              PaymentDetailPageTable<int>(
                title: 'Attempts',
                pending: false,
                columns: [
                  PaymentDataColumn<int>(key: 'id', label: 'ID', value: keyOf),
                ],
                rows: [],
                rowKey: keyOf,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Payment details'), findsOneWidget);
      expect(find.text('Attempts'), findsOneWidget);
      await t.pumpWidget(
        contentHost(
          const PaymentOverviewPage(
            primary: [ChartModule(title: 'Spending', state: ChartState.empty)],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(
        contentHost(const PaymentOverviewPage(primary: [Text('Invalid')])),
      );
      expect(t.takeException(), isAssertionError);
    },
  );

  const primary = [
    PaymentPageModule(title: 'Details', child: Text('Primary content')),
  ];
  const secondary = [
    PaymentPageModule(title: 'Merchant', child: Text('Secondary content')),
  ];
  testWidgets('detail columns and breadcrumb collapse follow available width', (
    t,
  ) async {
    var backs = 0;
    for (final width in [1024.0, 393.0]) {
      await setSurface(t, Size(width, 1000));
      await t.pumpWidget(
        contentHost(
          SizedBox(
            height: 800,
            child: PaymentDetailPage(
              title: 'Payment',
              primary: primary,
              secondary: secondary,
              breadcrumbs: [
                PaymentBreadcrumb(label: 'Home', onPressed: () {}),
                PaymentBreadcrumb(
                  label: 'Transactions',
                  onPressed: () => backs++,
                ),
              ],
            ),
          ),
        ),
      );
      if (width >= 840) {
        expect(
          t.getTopLeft(find.text('Secondary content')).dx,
          greaterThan(t.getTopLeft(find.text('Primary content')).dx),
        );
        expect(find.text('Home'), findsOneWidget);
      } else {
        expect(
          t.getTopLeft(find.text('Secondary content')).dy,
          greaterThan(t.getTopLeft(find.text('Primary content')).dy),
        );
        expect(find.text('Home'), findsNothing);
        await t.tap(find.text('Transactions'));
        expect(backs, 1);
      }
      expect(t.takeException(), isNull);
    }
  });
  testWidgets(
    'overview has no vertical scroll and pending keeps detail title',
    (t) async {
      await t.pumpWidget(
        contentHost(
          const SizedBox(
            height: 800,
            child: PaymentFullPageView(
              title: 'Spending',
              child: PaymentOverviewPage(
                primary: primary,
                secondary: secondary,
              ),
            ),
          ),
        ),
      );
      final scrolls = t
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where((s) => s.axisDirection == AxisDirection.down);
      expect(scrolls.length, 2);
      await t.pumpWidget(
        contentHost(
          const SizedBox(
            height: 800,
            child: PaymentDetailPage(
              title: 'Payment',
              primary: primary,
              secondary: secondary,
              pending: true,
            ),
          ),
        ),
      );
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Primary content'), findsNothing);
      expect(find.byType(LoadingSkeleton), findsNWidgets(3));
    },
  );
  testWidgets('property module link, create and retry delegate to host', (
    t,
  ) async {
    var called = 0;
    await t.pumpWidget(
      contentHost(
        PaymentDetailPagePropertyList(
          title: 'Details',
          pending: false,
          items: [
            PaymentDetailProperty(
              label: 'Merchant',
              values: [
                PaymentDetailValue.link(
                  PaymentLink(label: 'Toko Contoh', onPressed: () => called++),
                  subText: 'Jakarta',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('Toko Contoh'));
    await t.pump();
    expect(called, 1);
    await t.pumpWidget(
      contentHost(
        PaymentDetailPagePropertyList(
          title: 'Details',
          pending: false,
          errorText: 'Failed',
          onRetry: () => called++,
          onCreate: () => called++,
        ),
      ),
    );
    expect(
      t.widget<StateMessage>(find.byType(StateMessage)).tone,
      StatusTone.warning,
    );
    await t.tap(find.text('Retry'));
    await t.pump();
    expect(called, 2);
    await t.tap(find.text('Create'));
    await t.pump();
    expect(called, 3);
  });
  testWidgets('detail table omits paging and selection', (t) async {
    await t.pumpWidget(
      contentHost(
        PaymentDetailPageTable<String>(
          title: 'Attempts',
          pending: false,
          columns: [
            PaymentDataColumn<String>(
              key: 'method',
              label: 'Method',
              value: (r) => r,
            ),
          ],
          rows: const ['BCA'],
          rowKey: (r) => r,
        ),
      ),
    );
    final data = t.widget<PaymentDataTable<String>>(
      find.byType(PaymentDataTable<String>),
    );
    expect(data.pagination, isNull);
    expect(data.selection, isNull);
    expect(t.takeException(), isNull);
  });
  testWidgets('pages handle narrow large text light dark en id', (t) async {
    await setSurface(t, const Size(320, 1200));
    for (final dark in [false, true]) {
      for (final locale in [const Locale('en'), const Locale('id')]) {
        await t.pumpWidget(
          contentHost(
            const SizedBox(
              height: 900,
              child: PaymentDetailPage(
                title: 'Payment details for Toko Contoh',
                primary: primary,
                secondary: secondary,
              ),
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

  // UI review P5: D59a header actions, D62 footer actions, #66 gaps.
  Widget page({
    List<PaymentButton> actions = const [],
    PaymentButton? primaryAction,
    PaymentButton? secondaryAction,
    List<PaymentBreadcrumb> breadcrumbs = const [],
  }) => contentHostBoundedPage(
    PaymentDetailPage(
      title: 'Rp12.500 to Toko',
      breadcrumbs: breadcrumbs,
      actions: actions,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      primary: const [PaymentPageModule(title: 'Payment', child: Text('Body'))],
    ),
  );
  PaymentButton action(String label, [VoidCallback? onPressed]) =>
      PaymentButton(
        label: label,
        variant: PaymentButtonVariant.secondary,
        onPressed: onPressed ?? () {},
      );

  testWidgets('one header action is a title-row link on phones (D59a)', (
    t,
  ) async {
    await setSurface(t, const Size(393, 844));
    var calls = 0;
    await t.pumpWidget(page(actions: [action('Receipt', () => calls++)]));
    expect(find.byType(PaymentButton), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    final title = t.getRect(find.text('Rp12.500 to Toko'));
    final link = t.getRect(find.text('Receipt'));
    expect((link.center.dy - (title.top + 12)).abs(), lessThan(1));
    await t.tap(find.text('Receipt'));
    expect(calls, 1);
  });

  testWidgets('three header actions go behind ⋮, a sheet on phones', (t) async {
    await setSurface(t, const Size(393, 844));
    var calls = 0;
    await t.pumpWidget(
      page(
        actions: [
          action('Receipt'),
          action('Report', () => calls++),
          PaymentButton(
            label: 'Refund',
            variant: PaymentButtonVariant.destructive,
            onPressed: () {},
          ),
        ],
      ),
    );
    expect(find.text('Receipt'), findsNothing);
    await t.tap(find.byTooltip('More actions'));
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await t.tap(find.text('Report'));
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('wide header keeps its hug buttons', (t) async {
    await setSurface(t, const Size(1024, 768));
    await t.pumpWidget(page(actions: [action('Receipt'), action('Report')]));
    expect(find.widgetWithText(PaymentButton, 'Receipt'), findsOneWidget);
    expect(find.widgetWithText(PaymentButton, 'Report'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('footer holds the primary and one quiet action (D62)', (t) async {
    await setSurface(t, const Size(393, 844));
    var calls = 0;
    await t.pumpWidget(
      page(
        primaryAction: PaymentButton(
          label: 'View receipt',
          onPressed: () => calls++,
        ),
        secondaryAction: PaymentButton(
          label: 'Report a problem',
          variant: PaymentButtonVariant.quiet,
          onPressed: () {},
        ),
      ),
    );
    final primary = t.getRect(
      find.widgetWithText(PaymentButton, 'View receipt'),
    );
    final quiet = t.getRect(
      find.widgetWithText(PaymentButton, 'Report a problem'),
    );
    expect(primary.top, greaterThan(t.getRect(find.text('Body')).bottom));
    expect(primary.top, lessThan(quiet.top));
    expect(primary.width, quiet.width);
    expect(primary.width, greaterThan(393 - 33));
    await t.tap(find.text('View receipt'));
    expect(calls, 1);
  });

  testWidgets('breadcrumb chevron hangs at the title edge, one gap (#66)', (
    t,
  ) async {
    await setSurface(t, const Size(393, 844));
    await t.pumpWidget(
      page(
        breadcrumbs: [
          PaymentBreadcrumb(label: 'Transactions', onPressed: () {}),
        ],
      ),
    );
    final chevron = t.getRect(find.byIcon(Icons.chevron_left));
    final title = t.getRect(find.text('Rp12.500 to Toko'));
    final crumb = t.getRect(find.text('Transactions'));
    // The 24 dp glyph box starts 8 dp outside the column; the glyph's ink
    // starts on the title edge.
    expect(chevron.left, title.left - 8);
    expect(crumb.left, title.left + 16);
    expect(title.top - crumb.bottom, lessThan(20));
  });
}

Widget contentHostBoundedPage(Widget child) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.iOS),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: Scaffold(body: child),
);

String keyOf(int row) => '$row';
