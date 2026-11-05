import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
final base = PaymentTheme.fromColorScheme(scheme);

Widget app(PaymentTheme payment, Widget child) => MaterialApp(
  theme: ThemeData(colorScheme: scheme, extensions: [payment]),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: Scaffold(body: child),
);

BorderRadiusGeometry? decorationRadius(WidgetTester tester, Finder of) =>
    (tester
                .widget<Container>(
                  find.ancestor(of: of, matching: find.byType(Container)).first,
                )
                .decoration!
            as BoxDecoration)
        .borderRadius;

void main() {
  test('without role overrides every corner keeps its existing multiple', () {
    for (final theme in [base, base.copyWith(radius: 10)]) {
      final r = theme.radius;
      expect(theme.tagRadius, isNull);
      expect(theme.controlRadius, isNull);
      expect(theme.sheetRadius, isNull);
      expect(theme.borderRadius, BorderRadius.circular(r));
      expect(theme.tagBorderRadius, BorderRadius.circular(r * 0.5));
      expect(theme.controlBorderRadius, BorderRadius.circular(r * 0.75));
      expect(theme.sheetBorderRadius, BorderRadius.circular(r * 1.5));
    }

    // copyWith keeps a set role and lets an unset role follow the base.
    final pills = base.copyWith(tagRadius: 999).copyWith(radius: 12);
    expect(pills.tagBorderRadius, BorderRadius.circular(999));
    expect(pills.controlBorderRadius, BorderRadius.circular(9));
    expect(pills.copyWith(accent: Colors.red).tagRadius, 999);
  });

  testWidgets(
    'a host gets square boxes, pill tags and rounder sheets while controls '
    'keep their corners',
    (tester) async {
      // Square boxes would square controls too (8 → 0 derives 0), so the
      // host pins controls at their default 6.
      final brand = base.copyWith(
        radius: 0,
        tagRadius: 999,
        controlRadius: 6,
        sheetRadius: 20,
      );
      await tester.pumpWidget(
        app(
          brand,
          Builder(
            builder: (context) => Column(
              children: [
                const PaymentBox(
                  radius: PaymentRadius.box,
                  background: PaymentBoxBackground.muted,
                  children: [Text('Box')],
                ),
                const PaymentBadge(tone: StatusTone.success, label: 'Paid'),
                PaymentButton(label: 'Pay', onPressed: () {}),
                const PaymentTextField(label: 'Name'),
                TextButton(
                  onPressed: () => showPaymentSheet<void>(
                    context: context,
                    builder: (_) => const PaymentSheet(body: Text('Sheet')),
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(decorationRadius(tester, find.text('Box')), BorderRadius.zero);
      expect(
        decorationRadius(tester, find.text('Paid')),
        BorderRadius.circular(999),
      );
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Pay'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(
        (button.style!.shape!.resolve({})! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(6),
      );
      final field = tester.widget<InputDecorator>(find.byType(InputDecorator));
      expect(
        (field.decoration.enabledBorder! as OutlineInputBorder).borderRadius,
        BorderRadius.circular(6),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(
        (sheet.shape! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(20)),
      );
    },
  );

  test('lerp animates the radii each side draws, never from zero', () {
    final light = base; // radius 8, every role derived
    final dark = PaymentTheme.fromColorScheme(
      ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
    ).copyWith(radius: 16, tagRadius: 0);

    // One side sets the tag role: interpolate 4 (derived) → 0 (set).
    expect(light.lerp(dark, 0).tagBorderRadius, BorderRadius.circular(4));
    expect(light.lerp(dark, 0.5).tagBorderRadius, BorderRadius.circular(2));
    expect(light.lerp(dark, 1).tagBorderRadius, BorderRadius.zero);
    // Reverse direction starts from the set side.
    expect(dark.lerp(light, 0).tagBorderRadius, BorderRadius.zero);
    expect(dark.lerp(light, 1).tagBorderRadius, BorderRadius.circular(4));

    // Neither side sets the control or sheet role: they stay derived from
    // the animating base radius (8 → 16).
    final mid = light.lerp(dark, 0.5);
    expect(mid.radius, 12);
    expect(mid.controlRadius, isNull);
    expect(mid.sheetRadius, isNull);
    expect(mid.controlBorderRadius, BorderRadius.circular(9));
    expect(mid.sheetBorderRadius, BorderRadius.circular(18));
    expect(light.lerp(dark, 0).sheetBorderRadius, BorderRadius.circular(12));
    expect(light.lerp(dark, 1).sheetBorderRadius, BorderRadius.circular(24));
  });
}
