import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/compositions/kyc_onboarding_block.dart';
import 'package:rakit_ui_example/kyc_capture_demo.dart';
import 'package:rakit_ui_example/kyc_onboarding_demo.dart';
import 'package:rakit_ui_example/manual_transfer_demo.dart';
import 'package:rakit_ui_example/method_quote_demo.dart';
import 'package:rakit_ui_example/payment_preferences_demo.dart';
import 'package:rakit_ui_example/refund_detail_demo.dart';
import 'package:integration_test/integration_test.dart';
import 'support.dart';

/// Native Android proof for the six Payment/KYC host blocks (#217–#222).
/// `--dart-define=CAPTURE_ONLY=<block>` limits a run to one block.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native Payment and KYC host block proof', (tester) async {
    const only = String.fromEnvironment('CAPTURE_ONLY');
    bool wants(String block) => only.isEmpty || only == block;

    Future<void> start(Widget child) async {
      await tester.pumpWidget(child);
      await tester.pumpAndSettle();
    }

    Future<void> press(String label) async {
      final target = find.text(label).last;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    /// Scrolls the page by [dy] logical pixels; a large value reaches an end.
    Future<void> scroll(double dy) async {
      final page = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.drag(page.first, Offset(0, -dy));
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) => capture(binding, tester, name);

    if (wants('transfer')) {
      final fixed = manualTransferIssuedAt.add(const Duration(minutes: 18));
      for (final dark in [false, true]) {
        await start(
          ManualTransferDemo(
            key: UniqueKey(),
            initialDark: dark,
            delay: Duration.zero,
            clock: () => fixed,
          ),
        );
        await shot('android_block_transfer${dark ? '_dark' : ''}');
      }
      final late = manualTransferIssuedAt.add(const Duration(minutes: 75));
      await start(
        ManualTransferDemo(
          key: UniqueKey(),
          initialScenario: ManualTransferScenario.elapsed,
          delay: Duration.zero,
          clock: () => late,
        ),
      );
      await scroll(2000);
      await shot('android_block_transfer_elapsed');
      await start(
        ManualTransferDemo(
          key: UniqueKey(),
          initialScenario: ManualTransferScenario.issueUnknown,
          delay: Duration.zero,
          clock: () => fixed,
        ),
      );
      await shot('android_block_transfer_unknown');
    }

    if (wants('quote')) {
      for (final dark in [false, true]) {
        await start(
          MethodQuoteDemo(
            key: UniqueKey(),
            initialDark: dark,
            delay: Duration.zero,
          ),
        );
        await press('Virtual account');
        await shot('android_block_quote${dark ? '_dark' : ''}');
      }
      await start(
        MethodQuoteDemo(
          key: UniqueKey(),
          initialScenario: MethodQuoteScenario.repriced,
          delay: Duration.zero,
        ),
      );
      await press('Virtual account');
      await press('Lanjutkan · Rp254.000');
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is PaymentButton && w.label.startsWith('Bayar '),
        ),
      );
      await tester.pumpAndSettle();
      await scroll(2000);
      await shot('android_block_quote_changed');
      await start(
        MethodQuoteDemo(
          key: UniqueKey(),
          initialScenario: MethodQuoteScenario.quoteError,
          delay: Duration.zero,
        ),
      );
      await press('Virtual account');
      await scroll(2000);
      await shot('android_block_quote_error');
    }

    if (wants('refund')) {
      for (final dark in [false, true]) {
        await start(
          RefundDetailDemo(
            key: UniqueKey(),
            initialDark: dark,
            delay: Duration.zero,
          ),
        );
        await shot('android_block_refund${dark ? '_dark' : ''}');
      }
      await start(RefundDetailDemo(key: UniqueKey(), delay: Duration.zero));
      await press('Perbarui status refund');
      await scroll(2000);
      await shot('android_block_refund_partial');
      await press('Lihat struk');
      await shot('android_block_refund_receipt');
    }

    if (wants('onboarding')) {
      for (final dark in [false, true]) {
        await start(
          KycOnboardingDemo(
            key: UniqueKey(),
            initialDark: dark,
            delay: Duration.zero,
          ),
        );
        await shot('android_block_onboarding${dark ? '_dark' : ''}');
      }
      await start(
        KycOnboardingDemo(
          key: UniqueKey(),
          initialScenario: KycOnboardingScenario.hostRejectsId,
          initialStep: KycOnboardingStep.details,
          delay: Duration.zero,
        ),
      );
      await press('Lanjutkan');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await scroll(-2000);
      await shot('android_block_onboarding_rejected');
      await start(
        KycOnboardingDemo(
          key: UniqueKey(),
          initialStep: KycOnboardingStep.review,
          initialScenario: KycOnboardingScenario.saveFails,
          delay: Duration.zero,
        ),
      );
      await shot('android_block_onboarding_review');
      await press('Simpan data');
      await shot('android_block_onboarding_save_error');
      await press('Simpan data');
      await shot('android_block_onboarding_saved');
    }

    if (wants('capture')) {
      for (final dark in [false, true]) {
        await start(
          KycCaptureDemo(
            key: UniqueKey(),
            initialDark: dark,
            delay: Duration.zero,
          ),
        );
        await shot('android_block_capture${dark ? '_dark' : ''}');
      }
      await start(
        KycCaptureDemo(
          key: UniqueKey(),
          initialScenario: KycCaptureScenario.permissionDenied,
          delay: Duration.zero,
        ),
      );
      await press('Ambil foto');
      await shot('android_block_capture_permission');
      await start(
        KycCaptureDemo(
          key: UniqueKey(),
          initialScenario: KycCaptureScenario.blurry,
          delay: Duration.zero,
        ),
      );
      await press('Ambil foto');
      await press('Ambil foto');
      await press('Pakai foto');
      await shot('android_block_capture_rejected');
      await press('Ulangi');
      await press('Ambil foto');
      await press('Ambil foto');
      await press('Pakai foto');
      await shot('android_block_capture_uploaded');
    }

    if (wants('preferences')) {
      for (final dark in [false, true]) {
        await start(
          PaymentPreferencesDemo(
            key: UniqueKey(),
            initialDark: dark,
            delay: Duration.zero,
          ),
        );
        await shot('android_block_preferences${dark ? '_dark' : ''}');
      }
      await start(
        PaymentPreferencesDemo(
          key: UniqueKey(),
          initialScenario: PreferencesScenario.firstSaveFails,
          delay: Duration.zero,
        ),
      );
      await press('Virtual account');
      await press('Simpan');
      await scroll(-2000);
      await shot('android_block_preferences_error');
      await press('Simpan');
      await scroll(-2000);
      await shot('android_block_preferences_saved');
    }
    expect(tester.takeException(), isNull);
  });
}
