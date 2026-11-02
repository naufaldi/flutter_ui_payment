import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

Future<void> routePopToast(WidgetTester tester, BuildContext context) async {
  final navigator = Navigator.of(context);
  final pushed = navigator.push<void>(
    MaterialPageRoute(builder: (_) => const Scaffold(body: SizedBox())),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  final toast = showPaymentToast(context, message: 'Pending', pending: true);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  expect(find.text('Pending', skipOffstage: false), findsNWidgets(2));
  navigator.pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await pushed;
  toast.update('Updated', pending: true);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  expect(find.text('Updated'), findsOneWidget);
  toast.dismiss();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await toast.closed;
  expect(find.byType(SnackBar), findsNothing);
}

void expectInvisibleToast(WidgetTester tester, String message) {
  final text = find.text(message);
  if (text.evaluate().isNotEmpty) {
    final bar = find.ancestor(of: text, matching: find.byType(SnackBar));
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(of: bar, matching: find.byType(FadeTransition)),
    );
    expect(fades.any((fade) => fade.opacity.value == 0), isTrue);
  }
  expect(find.bySemanticsLabel(message), findsNothing);
}
