import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/history_block_demo.dart';
import 'package:flutter_ui_payment_example/kyc_review_demo.dart';
import 'package:integration_test/integration_test.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native History and KYC host block proof', (tester) async {
    const refundOnly = bool.fromEnvironment('REFUND_ONLY');
    Future<void> start(Widget child) async {
      await tester.pumpWidget(child);
      await tester.pumpAndSettle();
    }

    Future<void> press(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    for (final dark in refundOnly ? <bool>[] : [false, true]) {
      await start(HistoryBlockDemo(key: UniqueKey(), initialDark: dark));
      await capture(
        binding,
        tester,
        'android_block_history${dark ? '_dark' : ''}',
      );
    }
    for (final (reference, name) in [
      ('INV-2047', 'unknown'),
      ('INV-2044', 'refund'),
    ]) {
      if (refundOnly && name != 'refund') continue;
      await start(HistoryBlockDemo(key: UniqueKey()));
      await tester.enterText(find.byType(EditableText), reference);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TransactionListItem, reference));
      await tester.pumpAndSettle();
      if (name == 'refund') {
        // Show the refund amount below the original payment facts. The body
        // scrolls independently of the pinned return action.
        await tester.drag(
          find.descendant(
            of: find.byType(PaymentSheet),
            matching: find.byType(SingleChildScrollView),
          ),
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
      }
      await capture(binding, tester, 'android_block_history_$name');
    }
    if (!refundOnly) {
      await start(
        HistoryBlockDemo(
          key: UniqueKey(),
          initialState: HistoryDemoState.error,
        ),
      );
      await capture(binding, tester, 'android_block_history_error');
    }
    for (final dark in refundOnly ? <bool>[] : [false, true]) {
      await start(
        KycReviewDemo(
          key: UniqueKey(),
          initialDark: dark,
          delay: Duration.zero,
        ),
      );
      if (!dark) await capture(binding, tester, 'android_block_kyc_action');
      await press('Perbarui data');
      if (!dark) await capture(binding, tester, 'android_block_kyc_document');
      final pick = find.text(PaymentLocalizations('id').tryAgain);
      await tester.scrollUntilVisible(
        pick,
        140,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(pick);
      await tester.pumpAndSettle();
      await press('Lanjutkan tinjauan');
      await capture(
        binding,
        tester,
        'android_block_kyc_review${dark ? '_dark' : ''}',
      );
      await press(PaymentLocalizations('id').submitVerification);
      if (!dark) await capture(binding, tester, 'android_block_kyc_pending');
    }
    expect(tester.takeException(), isNull);
  });
}
