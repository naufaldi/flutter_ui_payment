import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/main.dart';
import '../integration_test/support.dart';

void main() {
  testWidgets('K04 capture Take is reachable without scrolling (#139)', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final app = await launch(
      t,
      settings: const DemoSettings(locale: Locale('en')),
    );
    await runScenario(t, app, 'K04');
    await tapVisible(
      t,
      find.descendant(
        of: find.byKey(const Key('slot-idCard')),
        matching: find.text('Choose document'),
      ),
    );
    await settle(t);
    await tapVisible(t, find.text('Take a photo'));
    await settle(t);
    final take = find.widgetWithText(PaymentButton, 'Take photo');
    expect(take.hitTestable(), findsOneWidget);
    expect(
      find.ancestor(of: take, matching: find.byType(Scrollable)),
      findsNothing,
    );
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
