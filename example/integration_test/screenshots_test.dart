import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Native visual proof: key screens in light, dark and 200% text.
/// Run with `flutter drive` and test_driver/integration_driver.dart.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const looks = {
    'light': DemoSettings(),
    'dark': DemoSettings(themeMode: ThemeMode.dark),
    'light_200': DemoSettings(textScale: 2),
  };

  testWidgets('capture key screens', (tester) async {
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final app = await launch(tester);
    // CAPTURE_DEVICE (se, ipad) names a device set: ios_<device>_<screen>.
    const device = String.fromEnvironment('CAPTURE_DEVICE');
    final platform = [
      Platform.isIOS ? 'ios' : 'android',
      if (device.isNotEmpty) device,
    ].join('_');

    Future<void> shot(String screen, String look) async {
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot('${platform}_${screen}_$look');
    }

    // Every capture, in order; each entry sets up its own screen.
    final screens = <String, Future<void> Function()>{
      'kyc_review': () async {
        await runScenario(tester, app, 'K07', variant: 2);
      },
      'kyc_intro': () async {
        final c = await runScenario(tester, app, 'H01');
        await tapVisible(tester, find.byKey(const Key('buy')));
        await pumpUntil(tester, () => c.step == FlowStep.kycIntro);
        final consent = PaymentLocalizations.of(
          tester.element(find.byType(VerificationIntro)),
        ).consentLabel;
        await Scrollable.ensureVisible(
          tester.element(find.text(consent)),
          alignment: 0.5,
        );
      },
      'methods_unavailable': () async {
        final c = await runScenario(tester, app, 'P03', variant: 1);
        await pumpUntil(tester, () => c.quote != null && !c.quoting);
        await Scrollable.ensureVisible(
          tester.element(find.textContaining('4242')),
          alignment: 0.5,
        );
      },
      'checkout': () async {
        final c = await runScenario(tester, app, 'H02');
        await pumpUntil(tester, () => c.quote != null && !c.quoting);
      },
      // A changed total: the confirmation with the old → new notice and the
      // consent checkbox.
      'requote': () async {
        final c = await runScenario(tester, app, 'P02', variant: 2);
        await pumpUntil(tester, () => c.quote != null && !c.quoting);
        c.reviewOrder();
        await c.confirm();
        await pumpUntil(tester, () => c.quote?.revision == 2 && !c.confirming);
        if (MediaQuery.textScalerOf(
              tester.element(find.byType(PaymentConfirmation)),
            ).scale(1) >
            1) {
          await settle(tester);
          await Scrollable.ensureVisible(
            tester.element(find.byType(PaymentCheckbox)),
            alignment: 0.5,
          );
        }
      },
      'authorize': () async {
        final c = await runScenario(tester, app, 'P06');
        await pumpUntil(tester, () => c.quote != null && !c.quoting);
        c.reviewOrder();
        await c.confirm();
        await pumpUntil(tester, () => c.step == FlowStep.authorize);
      },
      'status_unknown': () async {
        final c = await runScenario(tester, app, 'P06');
        await pumpUntil(tester, () => c.quote != null && !c.quoting);
        c.reviewOrder();
        await c.confirm();
        await pumpUntil(tester, () => c.step == FlowStep.authorize);
        await c.authorize();
        await pumpUntil(
          tester,
          () => c.attempt?.submission == SubmissionState.outcomeUnknown,
        );
      },
      'status_pending': () async {
        final c = await runScenario(tester, app, 'P07');
        await pumpUntil(
          tester,
          () => c.attempt?.status == PaymentStatus.pending,
        );
      },
      'status_va_pending': () async {
        final c = await runScenario(tester, app, 'P09');
        await pumpUntil(
          tester,
          () => c.attempt?.status == PaymentStatus.pending,
        );
      },
      'receipt': () async {
        final c = await runScenario(tester, app, 'P15');
        await pumpUntil(
          tester,
          () => c.attempt?.status == PaymentStatus.succeeded,
        );
        await c.paymentAction(PaymentAction.viewReceipt);
        await pumpUntil(tester, () => c.receipt != null);
      },
      'sign_in': () async {
        await runScenario(tester, app, 'H04');
      },
      'kyc_onboarding': () async {
        final c = await runScenario(tester, app, 'K01');
        if (c.step == FlowStep.kycIntro) {
          c.acceptConsent();
          await settle(tester);
        }
      },
      'history': () async {
        final c = await runScenario(tester, app, 'A01');
        await pumpUntil(tester, () => !c.historyLoading);
      },
      'transaction_detail': () async {
        final c = await runScenario(tester, app, 'A02');
        await pumpUntil(tester, () => !c.detailLoading);
      },
      // "Report a problem" is the quiet footer action (D62).
      'report_problem': () async {
        final c = await runScenario(tester, app, 'A02');
        await pumpUntil(tester, () => !c.detailLoading);
        await tapVisible(tester, find.byKey(const Key('report-problem')));
      },
      'statement': () async {
        final c = await runScenario(tester, app, 'A03');
        await pumpUntil(tester, () => c.settlements.isNotEmpty);
      },
      'fees': () async {
        await runScenario(tester, app, 'A04');
      },
      'account_settings': () async {
        await runScenario(tester, app, 'A05');
      },
    };

    // Selective session: --dart-define=CAPTURE_ONLY=history,transaction_detail
    // captures only those screens, in every look of CAPTURE_LOOKS (default
    // light, dark, light_200). The app is Indonesian by default; en and
    // en_200 are the English looks used by the SE and iPad sets.
    const only = String.fromEnvironment('CAPTURE_ONLY');
    const looksDefine = String.fromEnvironment('CAPTURE_LOOKS');
    final selected = {
      ...looks,
      'en': const DemoSettings(locale: Locale('en')),
      'en_200': const DemoSettings(locale: Locale('en'), textScale: 2),
    };
    final names = looksDefine.isEmpty
        ? looks.keys.toList()
        : looksDefine.split(',').map((e) => e.trim()).toList();
    final chosen = only.isEmpty
        ? screens.keys.toList()
        : only.split(',').map((e) => e.trim()).toList();
    for (final look in names) {
      app.updateSettings(selected[look]!);
      await tester.pump();
      for (final screen in chosen) {
        await screens[screen]!();
        await shot(screen, look);
        if (screen == 'report_problem') {
          await tapVisible(tester, find.byKey(const Key('report-cancel')));
          await settle(tester);
        }
      }
    }
  });
}
