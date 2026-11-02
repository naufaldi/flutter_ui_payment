import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'helpers/reduced_motion.dart';

void main() {
  late BuildContext context;
  Widget app() => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );

  // Device frames, 16 ms apart. Under reduced motion the next bar is fully
  // shown on the third frame after the old one starts to close, with one
  // blank frame between them (D89).
  Future<void> frames(WidgetTester tester, [int count = 1]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> hostQueueAfterToast(WidgetTester tester) async {
    final toast = showPaymentToast(context, message: 'Saved', pending: true);
    await tester.pump();
    final messenger = ScaffoldMessenger.of(context);
    final a = messenger.showSnackBar(const SnackBar(content: Text('Host A')));
    final b = messenger.showSnackBar(const SnackBar(content: Text('Host B')));
    final reasons = <String, SnackBarClosedReason>{};
    unawaited(a.closed.then((r) => reasons['A'] = r));
    unawaited(b.closed.then((r) => reasons['B'] = r));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);

    // The toast closes while host bars wait: the next one shows at once.
    toast.dismiss();
    await frames(tester, 3);
    expect(tester.takeException(), isNull);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Host A'), findsOneWidget);
    // Fully shown: the swap paints no in-between value: no in-between value is painted.
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).animation!.value, 1);

    // Host A times out with Host B waiting; B shows and times out too.
    await tester.pump(const Duration(seconds: 4));
    await frames(tester, 4);
    expect(tester.takeException(), isNull);
    expect(reasons['A'], SnackBarClosedReason.timeout);
    expect(find.text('Host B'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await frames(tester, 4);
    expect(tester.takeException(), isNull);
    expect(reasons['B'], SnackBarClosedReason.timeout);
    expect(find.byType(SnackBar), findsNothing);
  }

  for (final setup in ReducedMotion.values) {
    testWidgets('host bars waiting behind a toast show and time out under '
        'reduced motion (${setup.name})', (tester) async {
      await tester.pumpWidget(setup.apply(tester, app()));
      await hostQueueAfterToast(tester);
    });
  }

  testWidgets('host bars waiting behind a toast show and time out with a '
      'screen reader and reduced motion', (tester) async {
    // Platform flags reach the messenger, which sits above any MediaQuery a
    // MaterialApp builder adds.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(
          accessibleNavigation: true,
          reduceMotion: true,
        );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(app());
    await hostQueueAfterToast(tester);
  });
}
