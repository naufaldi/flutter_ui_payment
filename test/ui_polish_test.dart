import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/foundation/view_frame.dart' show PinnedFooter;
import 'content_host.dart';

double toastBottom(WidgetTester t) => t
    .getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    )
    .bottom;

void main() {
  // #202, D95.
  testWidgets('a toast floats above a pinned footer; Report stays tappable', (
    t,
  ) async {
    await setSurface(t, const Size(360, 640));
    var reported = 0;
    late BuildContext page;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              page = context;
              return PaymentDetailPage(
                title: 'Payment',
                primaryAction: PaymentButton(
                  label: 'View receipt',
                  onPressed: () {},
                ),
                secondaryAction: PaymentButton(
                  label: 'Report a problem',
                  variant: PaymentButtonVariant.quiet,
                  onPressed: () => reported++,
                ),
                primary: const [
                  PaymentPageModule(title: 'Payment', child: Text('Body')),
                ],
              );
            },
          ),
        ),
      ),
    );
    showPaymentToast(page, message: 'Receipt opened');
    await t.pumpAndSettle();

    final toast = t.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    final footer = t.getRect(find.byType(PinnedFooter));
    expect(toast.bottom, lessThanOrEqualTo(footer.top - 16));

    await t.tap(find.text('Report a problem'));
    expect(reported, 1);
    expect(find.text('Receipt opened'), findsOneWidget);
  });

  // #204 R1: the toast's own scaffold already lifts it above a bottom
  // navigation bar, so a kit footer there adds nothing more.
  testWidgets('a toast keeps one 16 dp gap above an action bar in the '
      'bottom navigation slot', (t) async {
    await setSurface(t, const Size(360, 640));
    late BuildContext page;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
          bottomNavigationBar: PaymentActionBar(
            action: PaymentButton(label: 'Pay', onPressed: () {}),
          ),
        ),
      ),
    );
    showPaymentToast(page, message: 'Receipt opened');
    await t.pumpAndSettle();
    final gap = t.getRect(find.byType(PinnedFooter)).top - toastBottom(t);
    expect(gap, moreOrLessEquals(16, epsilon: 0.5));
  });

  // #204 R1: the outer scaffold shows the toast, so the clearance is measured
  // there, not on the nested scaffold with the navigation bar and footer.
  testWidgets('a toast clears a footer in a nested scaffold above its '
      'navigation bar', (t) async {
    await setSurface(t, const Size(360, 640));
    late BuildContext page;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        home: Scaffold(
          body: Scaffold(
            body: Builder(
              builder: (context) {
                page = context;
                return PaymentDetailPage(
                  title: 'Payment',
                  primaryAction: PaymentButton(
                    label: 'View receipt',
                    onPressed: () {},
                  ),
                  primary: const [
                    PaymentPageModule(title: 'Payment', child: Text('Body')),
                  ],
                );
              },
            ),
            bottomNavigationBar: const SizedBox(height: 80),
          ),
        ),
      ),
    );
    showPaymentToast(page, message: 'Receipt opened');
    await t.pumpAndSettle();
    final footer = t.getRect(find.byType(PinnedFooter));
    expect(toastBottom(t), moreOrLessEquals(footer.top - 16, epsilon: 0.5));
  });

  // #204 R3: the same widget instance in the body and the navigation slot
  // must not be mistaken for the slot.
  testWidgets('a toast still clears the footer when the navigation bar '
      'widget is also used in the body', (t) async {
    await setSurface(t, const Size(360, 640));
    const bar = SizedBox(height: 80);
    late BuildContext page;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        home: Scaffold(
          body: Column(
            children: [
              bar,
              Expanded(
                child: Builder(
                  builder: (context) {
                    page = context;
                    return PaymentDetailPage(
                      title: 'Payment',
                      primaryAction: PaymentButton(
                        label: 'View receipt',
                        onPressed: () {},
                      ),
                      primary: const [
                        PaymentPageModule(
                          title: 'Payment',
                          child: Text('Body'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: bar,
        ),
      ),
    );
    showPaymentToast(page, message: 'Receipt opened');
    await t.pumpAndSettle();
    final footer = t.getRect(find.byType(PinnedFooter));
    expect(toastBottom(t), moreOrLessEquals(footer.top - 16, epsilon: 0.5));
  });

  // #201, D96.
  testWidgets('a primary link is underlined, so it never reads as a heading', (
    t,
  ) async {
    await t.pumpWidget(
      contentHost(PaymentLink(label: 'Change', onPressed: () {})),
    );
    final text = t.widget<Text>(find.text('Change'));
    final style = DefaultTextStyle.of(
      t.element(find.text('Change')),
    ).style.merge(text.style);
    expect(style.decoration, TextDecoration.underline);
    expect(
      t.getSize(find.byType(PaymentLink)).height,
      greaterThanOrEqualTo(48),
    );
  });

  // #203, D97.
  Widget table(Set<String> selected) => PaymentDataTable<int>(
    columns: [
      PaymentDataColumn<int>(
        key: 'id',
        label: 'Settlement',
        value: (r) => 'STL-$r',
        pinned: true,
      ),
      PaymentDataColumn<int>(
        key: 'date',
        label: 'Date',
        value: (r) => DateTime(2026, 11, r),
        cell: PaymentCellType.date,
        sortable: true,
      ),
    ],
    rows: List.generate(10, (i) => i + 1),
    rowKey: (r) => '$r',
    selection: selected,
    onSelectionChanged: (_) {},
    batchActions: [
      PaymentButton(
        label: 'Download',
        variant: PaymentButtonVariant.secondary,
        size: PaymentSize.small,
        onPressed: () {},
      ),
    ],
  );
  final ten = {for (var i = 1; i <= 10; i++) '$i'};

  testWidgets('with 10 selected, the batch label stays on one line', (t) async {
    await setSurface(t, const Size(360, 1600));
    await t.pumpWidget(contentHost(table(ten)));
    await t.pump();
    final count = t.getRect(find.text('10 selected'));
    final label = t.getRect(find.text('Download'));
    // One line of the label's own text, beside the count.
    expect(label.height, lessThan(count.height * 1.5));
    expect((label.center.dy - count.center.dy).abs(), lessThan(1));
    expect(label.left, greaterThan(count.right));
  });

  testWidgets(
    'at 200% and 320 dp the actions drop under the count, unclipped',
    (t) async {
      await setSurface(t, const Size(320, 3000));
      await t.pumpWidget(contentHost(table(ten), scale: 2));
      await t.pump();
      expect(t.takeException(), isNull);
      final count = t.getRect(find.text('10 selected'));
      final button = t.getRect(find.byType(PaymentButton).first);
      expect(button.top, greaterThan(count.bottom));
      expect(button.right, lessThanOrEqualTo(320));
      expect(button.height, greaterThanOrEqualTo(48));
    },
  );
}
