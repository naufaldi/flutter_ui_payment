import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

// UI review follow-ups (#79, #80): the action bar follows the footer rule on
// wide windows, and a button's icon sits on its label's first line.

Widget screen(
  Widget body, {
  Widget? bar,
  double scale = 1,
  String language = 'en',
  TextDirection? direction,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: direction == null
        ? child!
        : Directionality(textDirection: direction, child: child!),
  ),
  home: Scaffold(body: body, bottomNavigationBar: bar),
);

void _surface(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

const _review = Key('review');

Widget _bar() => PaymentActionBar(
  action: PaymentButton(
    key: _review,
    label: 'Review and pay',
    onPressed: () {},
  ),
);

Widget _authorize() => AuthorizationPrompt(
  phase: AuthorizationPhase.ready,
  onStart: () {},
  onBackToReview: () {},
);

Finder _authorizeButton() => find.byWidgetPredicate(
  (w) => w is PaymentButton && w.icon == Icons.fingerprint,
);

Finder _inButton(Finder of) =>
    find.descendant(of: _authorizeButton(), matching: of);

void main() {
  group('PaymentActionBar on wide windows (#79)', () {
    testWidgets('1024x768: the action hugs at the end of the 640 column', (
      t,
    ) async {
      _surface(t, const Size(1024, 768));
      await t.pumpWidget(screen(const SizedBox.expand(), bar: _bar()));
      final rect = t.getRect(find.byKey(_review));
      // The 640 dp column spans 192–832 in a 1024 dp window (D53).
      expect(rect.right, moreOrLessEquals(832, epsilon: 0.5));
      expect(rect.width, lessThan(640));
      expect(rect.width, greaterThanOrEqualTo(112));
      // The bar keeps its height (12 dp, the 48 dp button, 12 dp), so the
      // body above it keeps the rest of the window.
      expect(t.getSize(find.byType(PaymentActionBar)).height, 72);
    });

    testWidgets('iPad mini 744x1133: hugs at the column end', (t) async {
      _surface(t, const Size(744, 1133));
      await t.pumpWidget(screen(const SizedBox.expand(), bar: _bar()));
      final rect = t.getRect(find.byKey(_review));
      expect(rect.right, moreOrLessEquals(744 - 52, epsilon: 0.5));
      expect(rect.width, lessThan(640));
    });

    testWidgets('1024x768 at 2x: full width, like ViewFooter', (t) async {
      _surface(t, const Size(1024, 768));
      await t.pumpWidget(
        screen(const SizedBox.expand(), bar: _bar(), scale: 2),
      );
      expect(t.getRect(find.byKey(_review)).width, 640);
    });

    testWidgets('phone 393x852: still full width', (t) async {
      _surface(t, const Size(393, 852));
      await t.pumpWidget(screen(const SizedBox.expand(), bar: _bar()));
      final rect = t.getRect(find.byKey(_review));
      expect(rect.width, 393 - 32);
      expect(rect.left, 16);
    });

    testWidgets('with a total, the total keeps the start side', (t) async {
      _surface(t, const Size(1024, 768));
      await t.pumpWidget(
        screen(
          const SizedBox.expand(),
          bar: PaymentActionBar(
            total: const Money.idr(102500),
            action: PaymentButton(key: _review, label: 'Pay', onPressed: () {}),
          ),
        ),
      );
      expect(
        t.getRect(find.byKey(_review)).right,
        moreOrLessEquals(832, epsilon: 0.5),
      );
      expect(
        t.getRect(find.byType(AmountText)).left,
        moreOrLessEquals(192, epsilon: 0.5),
      );
    });
  });

  // #84: a bar under a wider content column takes the same cap, so its
  // action ends where the content does.
  group('PaymentActionBar under a wide content column (#84)', () {
    const content = Key('content');
    // A page column like the example's: 16 dp gutters, centred, capped.
    Widget page(double cap) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cap),
          child: const SizedBox(key: content, height: 40, width: 2000),
        ),
      ),
    );
    Widget wideBar({Money? total}) => PaymentActionBar(
      maxContentWidth: 1040,
      total: total,
      action: PaymentButton(
        key: _review,
        label: 'Review and pay',
        onPressed: () {},
      ),
    );

    for (final size in [const Size(1024, 768), const Size(1194, 834)]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} ${direction.name}: '
          'the action ends at the content end edge',
          (t) async {
            _surface(t, size);
            await t.pumpWidget(
              screen(page(1040), bar: wideBar(), direction: direction),
            );
            final column = t.getRect(find.byKey(content));
            final rect = t.getRect(find.byKey(_review));
            // 16–1008 at 1024, 77–1117 at 1194.
            expect(column.width, size.width == 1024 ? 1024 - 32 : 1040);
            final bar = t.getRect(
              find
                  .descendant(
                    of: find.byType(PaymentActionBar),
                    matching: find.byType(LayoutBuilder),
                  )
                  .first,
            );
            expect(bar.left, moreOrLessEquals(column.left, epsilon: 1));
            expect(bar.width, moreOrLessEquals(column.width, epsilon: 1));
            if (direction == TextDirection.ltr) {
              expect(rect.right, moreOrLessEquals(column.right, epsilon: 1));
            } else {
              expect(rect.left, moreOrLessEquals(column.left, epsilon: 1));
            }
            expect(rect.width, lessThan(column.width / 2));
          },
        );
      }
    }

    for (final direction in TextDirection.values) {
      testWidgets('1194x834 ${direction.name}: the total keeps the start '
          'side of the 1040 column', (t) async {
        _surface(t, const Size(1194, 834));
        await t.pumpWidget(
          screen(
            page(1040),
            bar: wideBar(total: const Money.idr(102500)),
            direction: direction,
          ),
        );
        final column = t.getRect(find.byKey(content));
        final action = t.getRect(find.byKey(_review));
        final total = t.getRect(find.byType(AmountText));
        if (direction == TextDirection.ltr) {
          expect(total.left, moreOrLessEquals(column.left, epsilon: 1));
          expect(action.right, moreOrLessEquals(column.right, epsilon: 1));
        } else {
          expect(total.right, moreOrLessEquals(column.right, epsilon: 1));
          expect(action.left, moreOrLessEquals(column.left, epsilon: 1));
        }
      });
    }

    for (final width in [744.0, 871.0]) {
      testWidgets('${width.toInt()}dp: the default bar keeps 640', (t) async {
        _surface(t, Size(width, 1000));
        await t.pumpWidget(screen(page(640), bar: _bar()));
        final column = t.getRect(find.byKey(content));
        expect(column.width, 640);
        expect(
          t.getRect(find.byKey(_review)).right,
          moreOrLessEquals(column.right, epsilon: 0.5),
        );
      });
    }

    testWidgets('phone 393x852: full width whatever the cap', (t) async {
      _surface(t, const Size(393, 852));
      await t.pumpWidget(screen(page(1040), bar: wideBar()));
      final rect = t.getRect(find.byKey(_review));
      expect(rect.left, 16);
      expect(rect.width, 393 - 32);
    });
  });

  group('PaymentButton icon on the first line (#80)', () {
    testWidgets('2x, wrapped label: the icon centres on the first line', (
      t,
    ) async {
      _surface(t, const Size(375, 667));
      await t.pumpWidget(screen(_authorize(), scale: 2, language: 'id'));
      expect(t.takeException(), isNull);
      final icon = t.getRect(_inButton(find.byType(Icon)));
      final label = _inButton(find.text('Konfirmasi pembayaran'));
      final text = t.getRect(label);
      // One 15/20 line at 2x is 40 dp; the label wraps to two.
      const line = 40.0;
      expect(text.height, greaterThanOrEqualTo(line * 2 - 1));
      expect(icon.center.dy, moreOrLessEquals(text.top + line / 2, epsilon: 1));
      // The icon scales with the text up to 1.6x (the medium icon token).
      expect(icon.width, 32);
      // Icon and label stay one centred group beside each other.
      final button = t.getRect(_authorizeButton());
      expect(text.left - icon.right, moreOrLessEquals(8, epsilon: 0.5));
      expect(
        (icon.left + text.right) / 2,
        moreOrLessEquals(button.center.dx, epsilon: 1),
      );
    });

    testWidgets('1x: icon and label are one centred line, as before', (
      t,
    ) async {
      _surface(t, const Size(393, 852));
      await t.pumpWidget(screen(_authorize()));
      final icon = t.getRect(_inButton(find.byType(Icon)));
      final text = t.getRect(_inButton(find.text('Confirm payment')));
      final button = t.getRect(_authorizeButton());
      expect(icon.width, 20);
      expect(text.height, 20);
      expect(text.left - icon.right, moreOrLessEquals(8, epsilon: 0.5));
      expect(icon.center.dy, moreOrLessEquals(text.center.dy, epsilon: 0.5));
      expect(
        (icon.left + text.right) / 2,
        moreOrLessEquals(button.center.dx, epsilon: 1),
      );
    });

    testWidgets('1024x768, 1x: hug footer row lays out cleanly', (t) async {
      _surface(t, const Size(1024, 768));
      await t.pumpWidget(screen(_authorize()));
      expect(t.takeException(), isNull);
      final button = t.getRect(_authorizeButton());
      expect(button.width, lessThan(640));
      final icon = t.getRect(_inButton(find.byType(Icon)));
      final text = t.getRect(_inButton(find.text('Confirm payment')));
      expect(icon.center.dy, moreOrLessEquals(text.center.dy, epsilon: 0.5));
      expect(text.left - icon.right, moreOrLessEquals(8, epsilon: 0.5));
    });
  });
}
