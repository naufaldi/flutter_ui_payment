import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;
import 'helpers/toast.dart';

void main() {
  late BuildContext context;
  Future<void> capture(WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        1,
      ),
    );
  }

  testWidgets('newest wins without painting the waiting toast', (tester) async {
    final semantics = tester.ensureSemantics();

    await capture(tester);
    // ignore: deprecated_member_use_from_same_package
    final a = showPaymentSnackBar(context, message: 'Toast A');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    // ignore: deprecated_member_use_from_same_package
    final b = showPaymentSnackBar(context, message: 'Toast B');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final c = showPaymentToast(context, message: 'Toast C');
    await tester.pump();
    for (var frame = 0; frame < 40; frame++) {
      expectInvisibleToast(tester, 'Toast B');
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Toast A'), findsNothing);
    expect(find.text('Toast C'), findsOneWidget);
    expect(await a.closed, SnackBarClosedReason.hide);
    expect(await b.closed, SnackBarClosedReason.hide);
    await tester.pump(const Duration(milliseconds: 3400));
    expect(find.text('Toast C'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await c.closed;
    semantics.dispose();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('newest preserves the 150 ms exit and 220 ms enter', (
    tester,
  ) async {
    await capture(tester);
    showPaymentToast(context, message: 'Toast A', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    showPaymentToast(context, message: 'Toast B', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final c = showPaymentToast(context, message: 'Toast C', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 129));
    expect(find.text('Toast A'), findsOneWidget);
    expect(find.text('Toast C'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1, microseconds: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text('Toast A'), findsNothing);
    expect(find.text('Toast C'), findsOneWidget);
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.animation!.value, lessThan(0.2));
    await tester.pump(const Duration(milliseconds: 221));
    expect(bar.animation!.value, 1);
    c.dismiss();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  });

  testWidgets('first kit toast replaces a host bar without freezing', (
    tester,
  ) async {
    await capture(tester);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Host')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    final c = showPaymentToast(context, message: 'Newest', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Host'), findsNothing);
    expect(find.text('Newest'), findsOneWidget);
    c.dismiss();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  });

  testWidgets('replaced toast behind a host bar never appears', (tester) async {
    final semantics = tester.ensureSemantics();

    await capture(tester);
    showPaymentToast(context, message: 'Kit K', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Host H')));
    await tester.pump();
    showPaymentToast(context, message: 'Toast Y', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 151));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 221));
    expect(find.text('Host H'), findsOneWidget);
    final z = showPaymentToast(context, message: 'Toast Z', pending: true);
    await tester.pump();
    for (var frame = 0; frame < 40; frame++) {
      expectInvisibleToast(tester, 'Toast Y');
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Host H'), findsNothing);
    expect(find.text('Toast Z'), findsOneWidget);
    semantics.dispose();
    z.dismiss();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  });

  testWidgets('controller survives a route pop', (tester) async {
    await capture(tester);
    await routePopToast(tester, context);
  });
  late PaymentToastController controller;
  Future<void> show(
    WidgetTester tester, {
    String message = 'Copied',
    bool pending = false,
    bool action = false,
    bool accessible = false,
    VoidCallback? onAction,
  }) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => controller = showPaymentToast(
              context,
              message: message,
              pending: pending,
              actionLabel: action ? 'Undo' : null,
              onAction: action ? onAction ?? () {} : null,
            ),
            child: const Text('Show'),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('update cross-fades icon and eases height', (tester) async {
    await show(tester, message: 'Waiting', pending: true);
    final size = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(AnimatedSize),
    );
    final oldHeight = tester.getSize(size).height;
    controller.update(
      List.filled(50, 'Updated').join(' '),
      tone: StatusTone.success,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(find.byType(PaymentSpinner), findsOneWidget);
    expect(find.byIcon(PaymentIcons.success), findsOneWidget);
    final middle = tester.getSize(size).height;
    await tester.pump(const Duration(milliseconds: 220));
    final newHeight = tester.getSize(size).height;
    expect(middle, inExclusiveRange(oldHeight, newHeight));
    controller.dismiss();
    await tester.pumpAndSettle();
  });
  testWidgets('toast enters at enter and leaves at exit', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        1,
      ),
    );
    controller = showPaymentToast(context, message: 'Copied');
    await tester.pump();
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    await tester.pump(const Duration(milliseconds: 219));
    expect(bar.animation!.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 1, microseconds: 1));
    await tester.pump();
    expect(bar.animation!.value, 1);
    controller.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 149));
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1, microseconds: 1));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('ink tokens and flat shape', (tester) async {
    await show(tester);
    final context = tester.element(find.byType(SnackBar));
    final theme = PaymentTheme.of(context);
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.backgroundColor, Colors.transparent);
    expect(bar.padding, EdgeInsets.zero);
    final surface = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          ),
        )
        .singleWhere((material) => material.color == theme.textPrimary);
    expect(surface.color, theme.textPrimary);
    expect(surface.shape, bar.shape);
    expect(surface.clipBehavior, bar.clipBehavior);
    expect(bar.elevation, 0);
    expect(bar.persist, true);
    expect(
      bar.shape,
      RoundedRectangleBorder(borderRadius: theme.controlBorderRadius),
    );
    expect(
      DefaultTextStyle.of(tester.element(find.text('Copied'))).style.color,
      theme.surface,
    );
  });
  for (final (message, seconds, action) in [
    ('Copied', 4, false),
    ('Copied', 6, true),
    (List.filled(20, 'word').join(' '), 7, false),
    (List.filled(60, 'word').join(' '), 10, false),
  ]) {
    testWidgets('reading timeout $seconds action=$action', (tester) async {
      await show(tester, message: message, action: action);
      await tester.pump(Duration(milliseconds: seconds * 1000 - 400));
      expect(find.text(message), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(message), findsNothing);
    });
  }
  testWidgets('pending updates the same element and then times out', (
    tester,
  ) async {
    await show(tester, message: 'Refreshing balance', pending: true);
    final element = tester.element(find.byType(SnackBar));
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(PaymentSpinner), findsOneWidget);
    controller.update('Balance updated', tone: StatusTone.success);
    await tester.pump();
    expect(tester.element(find.byType(SnackBar)), same(element));
    expect(find.byIcon(PaymentIcons.success), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150, microseconds: 1));
    await tester.pump();
    expect(find.byType(PaymentSpinner), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('action runs once and closes', (tester) async {
    var calls = 0;
    await show(tester, action: true, onAction: () => calls++);
    expect(
      tester.getSize(find.widgetWithText(TextButton, 'Undo')).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(SnackBar), findsNothing);
    controller.dismiss();
    controller.update('Ignored');
    await controller.closed;
  });
  testWidgets('teardown cancels timer', (tester) async {
    await show(tester);
    await tester.pumpWidget(const SizedBox());
    controller.update('Ignored');
    controller.dismiss();
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });
}
