// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('feedback aliases preserve constructors and types', (
    tester,
  ) async {
    expect(StatusBadge, PaymentBadge);
    expect(NoticeBanner, PaymentBanner);
    await tester.pumpWidget(
      host(
        const StatusBadge(
          tone: StatusTone.warning,
          label: 'Pending',
          icon: Icons.schedule,
        ),
        1,
      ),
    );
    expect(find.byType(PaymentBadge), findsOneWidget);
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                controller = showPaymentSnackBar(context, message: 'Copied'),
            child: const Text('Show'),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    controller.close();
    await tester.pumpAndSettle();
    await controller.closed;
    expect(find.byType(SnackBar), findsNothing);
  });
}
