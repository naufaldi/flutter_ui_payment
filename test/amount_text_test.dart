import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'button_guard_test.dart' show host;

void main() {
  const money = Money.idr(102500);
  for (final weight in [FontWeight.w600, FontWeight.w700]) {
    testWidgets('variants preserve legacy styles with $weight', (tester) async {
      final theme = PaymentTheme.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.blue),
      ).copyWith(amountWeight: weight, amountFontFamily: 'X');
      for (final variant in AmountTextVariant.values) {
        late TextStyle legacy;
        late TextStyle actual;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [theme]),
            localizationsDelegates: const [PaymentLocalizations.delegate],
            home: Builder(
              builder: (context) {
                final t = PaymentType.of(context);
                final row = t
                    .tabular(t.label)
                    .copyWith(fontFamily: theme.amountFontFamily);
                legacy = switch (variant) {
                  AmountTextVariant.caption => row.merge(t.caption),
                  AmountTextVariant.row => row,
                  AmountTextVariant.total => row.merge(
                    const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  AmountTextVariant.large => row.merge(t.amountLarge),
                  AmountTextVariant.display => t.display,
                };
                return Scaffold(body: AmountText(money, variant: variant));
              },
            ),
          ),
        );
        actual = tester
            .widget<Text>(
              find.descendant(
                of: find.byType(AmountText),
                matching: find.byType(Text),
              ),
            )
            .style!;
        expect(actual, legacy);
        if (variant == AmountTextVariant.total) {
          expect(actual.fontWeight, FontWeight.w600);
        }
        if (variant == AmountTextVariant.large) {
          expect(actual.fontWeight, weight);
        }
        expect(
          find.bySemanticsLabel(
            PaymentLocalizations.of(
              tester.element(find.byType(AmountText)),
            ).moneyFormat.spoken(money),
          ),
          findsOneWidget,
        );
      }
    });
  }
  test('legacy display cannot be combined with another role', () {
    // ignore: deprecated_member_use_from_same_package
    expect(
      () =>
          AmountText(money, emphasis: true, variant: AmountTextVariant.caption),
      throwsAssertionError,
    );
  });
  testWidgets('legacy display equals display variant', (tester) async {
    // ignore: deprecated_member_use_from_same_package
    await tester.pumpWidget(host(const AmountText(money, emphasis: true), 1));
    final old = tester.widget<Text>(find.byType(Text)).style;
    await tester.pumpWidget(
      host(const AmountText(money, variant: AmountTextVariant.display), 1),
    );
    expect(tester.widget<Text>(find.byType(Text)).style, old);
  });
  testWidgets('large amount scaling is capped', (tester) async {
    for (final variant in [
      AmountTextVariant.large,
      AmountTextVariant.display,
    ]) {
      await tester.pumpWidget(host(AmountText(money, variant: variant), 1));
      final height = tester.getSize(find.byType(AmountText)).height;
      await tester.pumpWidget(host(AmountText(money, variant: variant), 2));
      expect(
        tester.getSize(find.byType(AmountText)).height,
        lessThanOrEqualTo(height * 1.6 + 1),
      );
    }
  });
  testWidgets('countdown defaults to label and always uses tabular figures', (
    tester,
  ) async {
    final now = DateTime.utc(2026);
    for (final heading in [false, true]) {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => CountdownText(
              expiresAt: now.add(const Duration(minutes: 2)),
              clock: () => now,
              style: heading
                  ? PaymentType.of(context).heading.copyWith(fontFeatures: [])
                  : null,
            ),
          ),
          1,
        ),
      );
      final style = tester.widget<Text>(find.byType(Text)).style!;
      expect(style.fontSize, 15);
      expect(style.height, 20 / 15);
      expect(style.fontWeight, heading ? FontWeight.w600 : FontWeight.w400);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(
        style.color,
        PaymentTheme.of(tester.element(find.byType(CountdownText))).textPrimary,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });
}
