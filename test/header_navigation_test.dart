import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/view_frame.dart';
import 'content_host.dart';

void main() {
  Future<void> page(
    WidgetTester t, {
    double scale = 2,
    bool external = false,
  }) async {
    await setSurface(t, const Size(360, 640));
    await t.pumpWidget(
      contentHost(
        PaymentFullPageView(
          title: 'Transactions',
          pageLink: PaymentLink(
            label: 'Statement',
            semanticLabel: 'Open monthly statement',
            external: external,
            onPressed: () {},
          ),
          child: const Text('History'),
        ),
        scale: scale,
      ),
    );
  }

  testWidgets('large text moves a non-fitting page link into the menu', (
    t,
  ) async {
    await page(t);
    expect(find.byType(HeaderLink), findsNothing);
    final menu = find.byType(PaymentMenu);
    expect(menu, findsOneWidget);
    final title = t.getRect(find.text('Transactions'));
    final trigger = t.getRect(menu);
    expect(
      trigger.center.dy,
      inInclusiveRange(title.top, title.top + title.height / 2),
    );
    expect(trigger.width, greaterThanOrEqualTo(48));
    expect(trigger.height, greaterThanOrEqualTo(48));
    await t.tap(menu);
    await t.pumpAndSettle();
    expect(find.text('Statement'), findsOneWidget);
    // The menu entry keeps the link's screen-reader label (#163).
    expect(find.bySemanticsLabel('Open monthly statement'), findsOneWidget);
  });

  testWidgets('normal text keeps a fitting link on the title row', (t) async {
    // A short title fits even with the deliberately wide FlutterTest glyphs.
    await setSurface(t, const Size(360, 640));
    await t.pumpWidget(
      contentHost(
        PaymentFullPageView(
          title: 'History',
          pageLink: PaymentLink(label: 'Statement', onPressed: () {}),
          child: const Text('Body'),
        ),
      ),
    );
    expect(find.byType(HeaderLink), findsOneWidget);
    expect(find.byType(PaymentMenu), findsNothing);
    expect(
      t.getRect(find.byType(HeaderLink)).top,
      lessThan(t.getRect(find.text('History')).bottom),
    );
  });

  testWidgets('a fitting external link keeps its own line at normal text', (
    t,
  ) async {
    // D83: the external cue keeps its own line even where it would fit.
    await setSurface(t, const Size(360, 640));
    await t.pumpWidget(
      contentHost(
        PaymentFullPageView(
          title: 'History',
          pageLink: PaymentLink(
            label: 'Statement',
            external: true,
            onPressed: () {},
          ),
          child: const Text('Body'),
        ),
      ),
    );
    expect(find.byType(HeaderLink), findsOneWidget);
    expect(find.byType(PaymentMenu), findsNothing);
    expect(
      t.getRect(find.byType(HeaderLink)).top,
      greaterThan(t.getRect(find.text('History')).bottom),
    );
  });

  testWidgets('external links keep their own line at large text', (t) async {
    await page(t, external: true);
    expect(find.byType(HeaderLink), findsOneWidget);
    expect(find.byType(PaymentMenu), findsNothing);
    expect(
      t.getRect(find.byType(HeaderLink)).top,
      greaterThan(t.getRect(find.text('Transactions')).bottom),
    );
  });

  testWidgets('normal text keeps a non-fitting link below the title', (
    t,
  ) async {
    await page(t, scale: 1);
    expect(find.byType(HeaderLink), findsOneWidget);
    expect(find.byType(PaymentMenu), findsNothing);
    expect(
      t.getRect(find.byType(HeaderLink)).top,
      greaterThan(t.getRect(find.text('Transactions')).bottom),
    );
  });

  testWidgets('large text keeps a fitting link beside the title', (t) async {
    await setSurface(t, const Size(360, 640));
    await t.pumpWidget(
      contentHost(
        ViewHeader(
          title: 'A',
          link: PaymentLink(label: 'B', onPressed: () {}),
        ),
        scale: 2,
      ),
    );
    expect(find.byType(HeaderLink), findsOneWidget);
    expect(find.byType(PaymentMenu), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('wide large-text overflow merges actions without duplicates', (
    t,
  ) async {
    await setSurface(t, const Size(800, 640));
    await t.pumpWidget(
      contentHost(
        const ViewHeader(
          title: 'Transactions and transfers',
          link: PaymentLink(label: 'Statement', onPressed: null),
          actions: [PaymentButton(label: 'Export', onPressed: null)],
        ),
        scale: 2,
      ),
    );
    expect(find.byType(HeaderLink), findsNothing);
    expect(find.byType(PaymentButton), findsNothing);
    final entries = t.widget<PaymentMenu>(find.byType(PaymentMenu)).entries;
    expect(entries.map((e) => (e as PaymentMenuItem).label), [
      'Statement',
      'Export',
    ]);
    expect((entries.first as PaymentMenuItem).onSelected, isNull);
  });

  testWidgets('overflow merges page navigation before existing actions', (
    t,
  ) async {
    var selected = false;
    await setSurface(t, const Size(360, 640));
    await t.pumpWidget(
      contentHost(
        ViewHeader(
          title: 'Transactions',
          link: PaymentLink(
            label: 'Statement',
            onPressed: () => selected = true,
          ),
          actions: [PaymentButton(label: 'Export', onPressed: () {})],
        ),
        scale: 2,
      ),
    );
    expect(find.byType(HeaderLink), findsNothing);
    expect(find.byType(PaymentMenu), findsOneWidget);
    await t.tap(find.byType(PaymentMenu));
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.text('Statement')).dy,
      lessThan(t.getTopLeft(find.text('Export')).dy),
    );
    await t.tap(find.text('Statement'));
    await t.pumpAndSettle();
    expect(selected, isTrue);
  });
}
