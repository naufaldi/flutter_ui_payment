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
}

String keyOf(int row) => '$row';
