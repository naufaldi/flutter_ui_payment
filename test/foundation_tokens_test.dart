import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

Widget host(Widget child, {ThemeData? theme, double textScale = 1}) =>
    MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: const [PaymentLocalizations.delegate],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

TextStyle labelStyle(WidgetTester tester, String label) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style;

void main() {
  testWidgets('each role has its size, leading, weight and tracking', (
    tester,
  ) async {
    late PaymentType type;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            type = PaymentType.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    // size, line, weight, tracking
    final expected = <String, (TextStyle, double, double, FontWeight, double)>{
      'display': (type.display, 32, 36, FontWeight.w600, -0.32),
      'amountLarge': (type.amountLarge, 20, 28, FontWeight.w600, 0),
      'title': (type.title, 17, 24, FontWeight.w600, 0),
      'heading': (type.heading, 15, 20, FontWeight.w600, 0),
      'body': (type.body, 15, 22, FontWeight.w400, 0),
      'label': (type.label, 15, 20, FontWeight.w400, 0),
      'caption': (type.caption, 13, 18, FontWeight.w400, 0),
      'tag': (type.tag, 12, 16, FontWeight.w600, 0),
      'input': (type.input, 16, 24, FontWeight.w400, 0),
    };
    for (final MapEntry(key: name, value: (style, size, line, weight, track))
        in expected.entries) {
      expect(style.fontSize, size, reason: name);
      expect(
        style.fontSize! * style.height!,
        closeTo(line, 0.001),
        reason: name,
      );
      expect(style.fontWeight, weight, reason: name);
      expect(style.letterSpacing, track, reason: name);
      expect(
        style.leadingDistribution,
        TextLeadingDistribution.even,
        reason: name,
      );
    }
  });

  test('derived border is a 3:1 control edge in light and dark', () {
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1F36),
        brightness: brightness,
      );
      final theme = PaymentTheme.fromColorScheme(scheme);
      expect(
        contrast(theme.border, theme.surface),
        greaterThanOrEqualTo(3),
        reason: '$brightness on surface',
      );
      expect(
        contrast(theme.border, theme.surfaceMuted),
        greaterThanOrEqualTo(3),
        reason: '$brightness on surfaceMuted',
      );
    }
  });

  testWidgets('a disabled PaymentButton paints its label in disabled', (
    tester,
  ) async {
    for (final variant in PaymentButtonVariant.values) {
      await tester.pumpWidget(
        host(PaymentButton(label: 'Pay', onPressed: null, variant: variant)),
      );
      final theme = PaymentTheme.of(tester.element(find.text('Pay')));
      expect(
        labelStyle(tester, 'Pay').color,
        theme.disabled,
        reason: '$variant',
      );
    }
  });

  testWidgets('a 20 px AmountText stops growing at 1.6×', (tester) async {
    Future<double> height(double scale) async {
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topLeft,
            child: AmountText(
              Money.idr(102500),
              style: TextStyle(fontSize: 20),
            ),
          ),
          textScale: scale,
        ),
      );
      return tester.getSize(find.byType(Text)).height;
    }

    final normal = await height(1);
    final doubled = await height(2);
    expect(doubled, lessThanOrEqualTo(normal * 1.6 + 1));
  });

  test('copyWith re-derives border and disabled from textSecondary', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1A1F36));
    const muted = Color(0xFF5E6678);
    final theme = PaymentTheme.fromColorScheme(
      scheme,
    ).copyWith(textSecondary: muted);
    expect(theme.border, Color.lerp(muted, scheme.surface, 0.25));
    expect(theme.disabled, Color.lerp(muted, scheme.surface, 0.45));

    // An explicit value survives a later override.
    const edge = Color(0xFF868C9A);
    final explicit = PaymentTheme.fromColorScheme(
      scheme,
    ).copyWith(border: edge).copyWith(textSecondary: muted);
    expect(explicit.border, edge);
  });

  testWidgets('the PaymentButton label uses the host font', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentButton(label: 'Pay', onPressed: () {}),
        theme: ThemeData(fontFamily: 'X'),
      ),
    );
    expect(labelStyle(tester, 'Pay').fontFamily, 'X');
  });
}
