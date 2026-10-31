import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

Widget host(Widget child, double scale) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.iOS),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: Column(children: [child])),
  ),
);
const expected = <String, List<Rect>>{
  '1.0 primary false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(157.5, 14.0, 202.5, 34.0),
  ],
  '1.0 primary true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(171.5, 14.0, 216.5, 34.0),
  ],
  '1.0 secondary false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(157.5, 14.0, 202.5, 34.0),
  ],
  '1.0 secondary true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(171.5, 14.0, 216.5, 34.0),
  ],
  '1.0 quiet false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(157.5, 14.0, 202.5, 34.0),
  ],
  '1.0 quiet true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(171.5, 14.0, 216.5, 34.0),
  ],
  '1.0 destructive false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(157.5, 14.0, 202.5, 34.0),
  ],
  '1.0 destructive true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(171.5, 14.0, 216.5, 34.0),
  ],
  '1.0 action false': [Rect.fromLTRB(232.0, 12.0, 344.0, 60.0)],
  '2.0 primary false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(135.0, 4.0, 225.0, 44.0),
  ],
  '2.0 primary true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(149.0, 4.0, 239.0, 44.0),
  ],
  '2.0 secondary false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(135.0, 4.0, 225.0, 44.0),
  ],
  '2.0 secondary true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(149.0, 4.0, 239.0, 44.0),
  ],
  '2.0 quiet false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(135.0, 4.0, 225.0, 44.0),
  ],
  '2.0 quiet true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(149.0, 4.0, 239.0, 44.0),
  ],
  '2.0 destructive false': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(135.0, 4.0, 225.0, 44.0),
  ],
  '2.0 destructive true': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 48.0),
    Rect.fromLTRB(149.0, 4.0, 239.0, 44.0),
  ],
  '2.0 action false': [
    Rect.fromLTRB(16.0, 61.89999961853027, 344.0, 109.89999961853027),
  ],
};
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('medium geometry $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final variant in PaymentButtonVariant.values) {
        for (final icon in [false, true]) {
          await tester.pumpWidget(
            host(
              PaymentButton(
                label: 'Pay',
                variant: variant,
                icon: icon ? Icons.check : null,
                onPressed: () {},
              ),
              scale,
            ),
          );
          final button = find.byType(PaymentButton);
          final material = find.descendant(
            of: button,
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          final rects = [
            tester.getRect(button),
            tester.getRect(material),
            tester.getRect(find.text('Pay')),
          ];
          expect(rects, expected['$scale ${variant.name} $icon']);
        }
      }
      await tester.pumpWidget(
        host(
          PaymentActionBar(
            total: const Money.idr(1000),
            action: PaymentButton(label: 'Pay', onPressed: () {}),
          ),
          scale,
        ),
      );
      final r = tester.getRect(find.byType(PaymentButton));
      expect([r], expected['$scale action false']);
    });
  }
}
