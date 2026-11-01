import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/scenarios/catalog.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

const l10n = _En();

/// Thin alias so the tests read like the UI copy they look for.
class _En {
  const _En();
  PaymentLocalizations get _l => PaymentLocalizations('en');
  String kyc(VerificationAction a) => _l.verificationActionLabel(a);
  String pay(PaymentAction a) => _l.paymentActionLabel(a);
}

Finder confirmButton() => find.descendant(
  of: find.byType(PaymentButton),
  matching: find.text('Confirm payment'),
);

int logCount(DemoCoordinator c, String fragment) =>
    c.host.log.value.where((e) => e.message.contains(fragment)).length;

Future<void> checkoutToAuthorize(WidgetTester tester, DemoCoordinator c) async {
  await pumpUntil(tester, () => c.quote != null && !c.quoting, reason: 'quote');
  await tapVisible(tester, find.byKey(const Key('review-order')));
  await pumpUntil(tester, () => c.step == FlowStep.confirm);
  await tapVisible(tester, payButtons());
  await pumpUntil(tester, () => c.step == FlowStep.authorize, reason: 'auth');
}

Future<void> authorizeAndSubmit(WidgetTester tester, DemoCoordinator c) async {
  await tapVisible(tester, confirmButton());
  await pumpUntil(tester, () => c.step == FlowStep.payment, reason: 'submit');
}

Future<void> checkStatusUntil(
  WidgetTester tester,
  DemoCoordinator c,
  PaymentStatus status,
) async {
  for (var i = 0; i < 8 && c.attempt?.status != status; i++) {
    await pumpUntil(
      tester,
      () => c.attempt!.observation != Observation.refreshing,
    );
    if (c.attempt?.status == status) break;
    await tapVisible(tester, find.text(l10n.pay(PaymentAction.checkStatus)));
    await pumpUntil(
      tester,
      () => c.attempt!.observation != Observation.refreshing,
    );
  }
  expect(c.attempt?.status, status);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('K04 camera photo rejected by host, retaken, uploaded', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K04', variant: 1);
    await tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('slot-idCard')),
        matching: find.text('Choose document'),
      ),
    );
    await tapVisible(tester, find.text('Take a photo'));
    await tapVisible(tester, find.text('Take photo'));
    await tapVisible(tester, find.text('Use photo'));
    await pumpUntil(
      tester,
      () => c.documents[idCardSlot]?.phase == DocumentSlotPhase.failed,
    );
    expect(
      find.text('The ID photo is blurry. Retake it in good light.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Retake'));
    await tapVisible(tester, find.text('Take photo'));
    await tapVisible(tester, find.text('Use photo'));
    await pumpUntil(
      tester,
      () => c.documents[idCardSlot]?.phase == DocumentSlotPhase.uploaded,
    );
    await settle(tester);
    expect(find.text('Choose document'), findsWidgets);
  });
  testWidgets('K03 camera denied via source sheet keeps the slot recoverable', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K03', variant: 1);
    final slot = find.byKey(const Key('slot-idCard'));
    await tapVisible(
      tester,
      find.descendant(of: slot, matching: find.text('Choose document')),
    );
    await tapVisible(tester, find.text('Take a photo'));
    await tapVisible(
      tester,
      find.descendant(of: slot, matching: find.text('Open settings')),
    );
    await pumpUntil(
      tester,
      () => c.documents[idCardSlot]?.phase == DocumentSlotPhase.empty,
    );
  });
  testWidgets('P12 VA number copies with inline confirmation', (tester) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P12');
    await pumpUntil(tester, () => c.attempt?.status == PaymentStatus.pending);
    await tapVisible(tester, find.byTooltip('Copy'));
    await pumpUntilFound(tester, find.byIcon(PaymentIcons.copied));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(PaymentIcons.copy), findsOneWidget);
  });
  testWidgets('P15 receipt copy failure stays inline', (tester) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P15', variant: 2);
    await checkStatusUntil(tester, c, PaymentStatus.succeeded);
    await tapVisible(tester, find.text(l10n.pay(PaymentAction.viewReceipt)));
    await pumpUntilFound(tester, find.text('Share receipt'));
    final total = c.receipt!.total;
    await tapVisible(tester, find.byTooltip('Copy'));
    await pumpUntilFound(tester, find.text('Copy failed'));
    expect(c.receipt!.total, total);
    expect(find.byType(PaymentBanner), findsNothing);
  });
  testWidgets('H01 happy flow: KYC → checkout → one payment → receipt', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'H01');

    await tapVisible(tester, find.byKey(const Key('buy')));
    expect(c.step, FlowStep.kycIntro);
    await tapVisible(tester, find.byType(PaymentCheckbox));
    await tapVisible(tester, find.text('Continue'));
    expect(c.step, FlowStep.kycIdentity);

    await fillIdentity(tester);
    await tapVisible(tester, find.text('Continue'));
    await pumpUntil(tester, () => c.step == FlowStep.kycDocuments);
    expect(c.step, FlowStep.kycDocuments);
    expect(c.identity['dob'], '1995-08-17');
    expect(c.identity['occupation'], 'employee');
    expect(c.identity['province'], 'jawa-barat');

    for (final (slot, fixture) in [
      ('idCard', 'ktp_demo_sari.jpg'),
      ('selfie', 'ktp_demo_retake.png'),
    ]) {
      await tapVisible(
        tester,
        find.descendant(
          of: find.byKey(Key('slot-$slot')),
          matching: find.text('Choose document'),
        ),
      );
      await tapVisible(tester, find.text('Choose a file'));
      await tapVisible(tester, find.byKey(Key('fixture-$fixture')));
      await pumpUntil(
        tester,
        () => c.documents[slot]!.phase == DocumentSlotPhase.uploaded,
        reason: 'upload $slot',
      );
    }
    await tapVisible(tester, find.byKey(const Key('to-review')));
    expect(c.step, FlowStep.kycReview);
    // The NIK is masked on review.
    expect(find.text('••••••••••••1234'), findsOneWidget);

    await tapVisible(tester, find.text('Submit for verification'));
    await pumpUntil(tester, () => c.step == FlowStep.kycStatus);
    expect(c.kyc.status, VerificationStatus.inReview);
    await tapVisible(
      tester,
      find.text(l10n.kyc(VerificationAction.checkStatus)),
    );
    await pumpUntil(tester, () => c.kyc.status == VerificationStatus.verified);
    await tapVisible(
      tester,
      find.text(l10n.kyc(VerificationAction.continueToPayment)),
    );
    await pumpUntil(tester, () => c.step == FlowStep.checkout);

    await checkoutToAuthorize(tester, c);
    expect(find.text('Rp102,500'), findsWidgets);
    await authorizeAndSubmit(tester, c);
    // The host coordinator polls; the UI never infers success.
    await pumpUntil(
      tester,
      () => c.attempt?.status == PaymentStatus.succeeded,
      reason: 'host polling to success',
    );
    await tapVisible(tester, find.text(l10n.pay(PaymentAction.viewReceipt)));
    await pumpUntilFound(tester, find.text('Share receipt'));
    expect(find.text('TRX-004071'), findsWidgets);
    await tapVisible(tester, find.byTooltip('Copy'));
    await pumpUntilFound(tester, find.byIcon(PaymentIcons.copied));
    expect(find.byType(PaymentBanner), findsNothing);

    expect(c.submitEvents, 1);
    expect(c.host.attemptCount, 1);
    expect(c.host.chargeCount, 1);
  });

  testWidgets(
    'H04 signed out: sign in → KYC onboarding → checkout → detail page → report a problem',
    (tester) async {
      final app = await launch(tester);
      final c = await runScenario(tester, app, 'H04');

      expect(c.step, FlowStep.signIn);
      expect(
        find.descendant(
          of: find.byType(PaymentSignInView),
          matching: find.byType(EditableText),
        ),
        findsNothing,
      );
      await tapVisible(tester, find.byKey(const Key('sign-in')));
      await pumpUntil(tester, () => c.step == FlowStep.overview);
      await tapVisible(tester, find.byKey(const Key('buy')));
      expect(c.step, FlowStep.kycIntro);
      await tapVisible(tester, find.byType(PaymentCheckbox));
      await tapVisible(tester, find.text('Continue'));
      expect(c.step, FlowStep.kycIdentity);

      await fillIdentity(tester);
      await tapVisible(tester, find.text('Continue'));
      await pumpUntil(tester, () => c.step == FlowStep.kycDocuments);
      expect(c.step, FlowStep.kycDocuments);
      expect(c.identity['dob'], '1995-08-17');
      expect(c.identity['occupation'], 'employee');
      expect(c.identity['province'], 'jawa-barat');

      for (final (slot, fixture) in [
        ('idCard', 'ktp_demo_sari.jpg'),
        ('selfie', 'ktp_demo_retake.png'),
      ]) {
        await tapVisible(
          tester,
          find.descendant(
            of: find.byKey(Key('slot-$slot')),
            matching: find.text('Choose document'),
          ),
        );
        await tapVisible(tester, find.text('Choose a file'));
        await tapVisible(tester, find.byKey(Key('fixture-$fixture')));
        await pumpUntil(
          tester,
          () => c.documents[slot]!.phase == DocumentSlotPhase.uploaded,
          reason: 'upload $slot',
        );
      }
      await tapVisible(tester, find.byKey(const Key('to-review')));
      expect(c.step, FlowStep.kycReview);
      // The NIK is masked on review.
      expect(find.text('••••••••••••1234'), findsOneWidget);

      await tapVisible(tester, find.text('Submit for verification'));
      await pumpUntil(tester, () => c.step == FlowStep.kycStatus);
      expect(c.kyc.status, VerificationStatus.inReview);
      await tapVisible(
        tester,
        find.text(l10n.kyc(VerificationAction.checkStatus)),
      );
      await pumpUntil(
        tester,
        () => c.kyc.status == VerificationStatus.verified,
      );
      await tapVisible(
        tester,
        find.text(l10n.kyc(VerificationAction.continueToPayment)),
      );
      await pumpUntil(tester, () => c.step == FlowStep.checkout);

      await checkoutToAuthorize(tester, c);
      expect(find.text('Rp102,500'), findsWidgets);
      await authorizeAndSubmit(tester, c);
      // The host coordinator polls; the UI never infers success.
      await pumpUntil(
        tester,
        () => c.attempt?.status == PaymentStatus.succeeded,
        reason: 'host polling to success',
      );
      await tapVisible(tester, find.text(l10n.pay(PaymentAction.viewReceipt)));
      await pumpUntilFound(tester, find.text('Share receipt'));
      expect(find.text('TRX-004071'), findsWidgets);
      await tapVisible(tester, find.byTooltip('Copy'));
      await pumpUntilFound(tester, find.byIcon(PaymentIcons.copied));
      expect(find.byType(PaymentBanner), findsNothing);

      expect(c.submitEvents, 1);
      expect(c.host.attemptCount, 1);
      expect(c.host.chargeCount, 1);

      await tapVisible(tester, find.byKey(const Key('receipt-details')));
      await pumpUntil(
        tester,
        () => c.step == FlowStep.transactionDetail && !c.detailLoading,
      );
      expect(find.byType(PaymentDetailPage), findsOneWidget);
      // The phone attempts table titles the ID with non-breaking hyphens;
      // its semantics label keeps the original.
      expect(
        find.text(c.attempt!.attemptId.replaceAll('-', '\u2011')),
        findsWidgets,
      );
      await openReport(tester);
      await tapVisible(
        tester,
        find
            .descendant(
              of: find.byType(PaymentSelect<String>),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tapVisible(tester, find.text('Charged twice'));
      await tester.enterText(
        find.descendant(
          of: find.byType(PaymentTextArea),
          matching: find.byType(EditableText),
        ),
        'test note',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      await tapVisible(tester, find.byKey(const Key('send-report')));
      await pumpUntilFound(tester, find.textContaining('Report sent'));
      await settle(tester);
      expect(find.byType(PaymentFocusView), findsNothing);
      expect(logCount(c, 'Problem reported'), 1);
      expect(
        c.host.log.value.any((e) => e.message.contains('test note')),
        isFalse,
      );
    },
  );

  testWidgets('P05 double tap and slow submit send one payment', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P05');
    await pumpUntil(tester, () => c.quote != null && !c.quoting);
    await tapVisible(tester, find.byKey(const Key('review-order')));

    final pay = payButtons();
    await tester.ensureVisible(pay);
    await tester.tap(pay);
    await tester.tap(pay, warnIfMissed: false);
    await pumpUntil(tester, () => c.step == FlowStep.authorize);

    final confirm = confirmButton();
    await settle(tester);
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump();
    // A programmatic retry while the challenge runs is absorbed too.
    await c.authorize();
    await pumpUntil(tester, () => c.step == FlowStep.payment);
    expect(c.attempt!.submission, SubmissionState.sending);
    expect(find.text('Sending'), findsOneWidget);

    await pumpUntil(tester, () => c.attempt!.status != null);
    await checkStatusUntil(tester, c, PaymentStatus.succeeded);
    expect(c.submitEvents, 1);
    expect(c.host.attemptCount, 1);
    expect(c.host.chargeCount, 1);
  });

  testWidgets('P06 accepted but response lost: same attempt, no pay again', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P06');
    await checkoutToAuthorize(tester, c);
    await authorizeAndSubmit(tester, c);
    final attemptId = c.attempt!.attemptId;

    await pumpUntil(
      tester,
      () => c.attempt!.submission == SubmissionState.outcomeUnknown,
      reason: 'timeout',
    );
    await pumpUntilFound(tester, find.text('Result not confirmed yet'));
    expect(payButtons(), findsNothing);
    expect(find.text(l10n.pay(PaymentAction.startNewAttempt)), findsNothing);
    expect(c.attempt!.availableActions, {PaymentAction.checkStatus});
    // The server did record the attempt before the answer was lost.
    expect(c.host.attemptCount, 1);

    await checkStatusUntil(tester, c, PaymentStatus.succeeded);
    expect(c.attempt!.attemptId, attemptId);
    expect(c.submitEvents, 1);
    expect(c.host.attemptCount, 1);
    expect(c.host.chargeCount, 1);
  });

  testWidgets('P07 pending → offline keeps last-known → success', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P07');
    expect(c.step, FlowStep.payment);
    await pumpUntil(tester, () => c.attempt?.status == PaymentStatus.pending);
    await pumpUntilFound(tester, find.text('Pending'));

    await tapVisible(tester, find.text(l10n.pay(PaymentAction.checkStatus)));
    await pumpUntil(
      tester,
      () => c.attempt!.observation == Observation.unavailable,
      reason: 'offline refresh',
    );
    expect(c.attempt!.status, PaymentStatus.pending);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    await checkStatusUntil(tester, c, PaymentStatus.succeeded);
    await pumpUntilFound(tester, find.text('Payment successful'));
    expect(c.submitEvents, 0);
    expect(c.host.attemptCount, 1);
  });

  testWidgets('P02 total change requires review and a new authorization', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P02', variant: 2);
    await pumpUntil(tester, () => c.quote != null && !c.quoting);
    await tapVisible(tester, find.byKey(const Key('review-order')));
    await tapVisible(tester, find.text('Pay Rp102,500'));
    await pumpUntilFound(tester, find.text('The total has changed'));
    expect(c.step, FlowStep.confirm);
    expect(c.quote!.revision, 2);

    // Pay is disabled until the new total is acknowledged.
    await tester.ensureVisible(find.text('Pay Rp103,500'));
    await settle(tester);
    await tester.tap(find.text('Pay Rp103,500'), warnIfMissed: false);
    await settle(tester);
    expect(c.step, FlowStep.confirm);

    await tapVisible(tester, find.byType(PaymentCheckbox));
    await tapVisible(tester, find.text('Pay Rp103,500'));
    await pumpUntil(tester, () => c.step == FlowStep.authorize);
    expect(c.authPhase, AuthorizationPhase.ready);
    await authorizeAndSubmit(tester, c);
    await pumpUntil(tester, () => c.attempt!.status != null);
    expect(c.attempt!.quoteRevision, 2);
    expect(c.attemptAmount, const Money.idr(103500));
    expect(c.submitEvents, 1);
  });

  testWidgets('K07 KYC actionRequired keeps valid data and has no bypass', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K07', variant: 2);
    expect(c.step, FlowStep.kycReview);
    await tapVisible(tester, find.text('Submit for verification'));
    await pumpUntil(tester, () => c.kyc.status == VerificationStatus.inReview);
    await tapVisible(
      tester,
      find.text(l10n.kyc(VerificationAction.checkStatus)),
    );
    await pumpUntil(
      tester,
      () => c.kyc.status == VerificationStatus.actionRequired,
    );
    await pumpUntilFound(tester, find.text('Update needed'));
    expect(find.textContaining('blurry'), findsOneWidget);
    expect(
      find.text(l10n.kyc(VerificationAction.continueToPayment)),
      findsNothing,
    );

    await tapVisible(
      tester,
      find.text(l10n.kyc(VerificationAction.fixDetails)),
    );
    expect(c.step, FlowStep.kycDocuments);
    expect(c.documents['idCard']!.phase, DocumentSlotPhase.empty);
    expect(c.documents['selfie']!.phase, DocumentSlotPhase.uploaded);
    expect(c.identity['nik'], '3100000000001234');
  });

  testWidgets('K06 KYC double tap + timeout: one request, never rejected', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K06');
    final submit = find.text('Submit for verification');
    await tester.ensureVisible(submit);
    await settle(tester);
    await tester.tap(submit);
    await tester.tap(submit, warnIfMissed: false);
    await pumpUntil(tester, () => c.kycOutcomeUnknown, reason: 'kyc timeout');
    await pumpUntilFound(tester, find.text('Submission not confirmed'));
    expect(find.text('Not approved'), findsNothing);
    expect(logCount(c, 'KYC request'), 1);

    await tapVisible(
      tester,
      find.text(l10n.kyc(VerificationAction.checkStatus)),
    );
    await pumpUntil(tester, () => !c.kycOutcomeUnknown);
    expect(c.kyc.status, isNot(VerificationStatus.rejected));
    expect(logCount(c, 'KYC request'), 1);
  });

  testWidgets('P08 background and restart recover the same attempt', (
    tester,
  ) async {
    final app = await launch(tester);
    var c = await runScenario(tester, app, 'P08');
    await checkoutToAuthorize(tester, c);
    await authorizeAndSubmit(tester, c);
    await pumpUntil(tester, () => c.attempt!.status != null);
    final attemptId = c.attempt!.attemptId;
    final checksBefore = logCount(c, 'Status check');

    // Real lifecycle events: the screen is masked while inactive and the
    // status is refreshed on resume, without submitting anything.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(c.obscured, isTrue);
    expect(find.bySemanticsLabel('Content hidden'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(c.obscured, isFalse);
    await pumpUntil(
      tester,
      () => c.attempt!.observation != Observation.refreshing,
    );
    expect(logCount(c, 'App resumed; refreshing'), 1);
    expect(checksBefore, 0);

    app.simulateRestart();
    await tester.pump();
    c = app.coordinator;
    await pumpUntil(tester, () => !c.starting);
    expect(c.step, FlowStep.payment);
    expect(c.attempt!.attemptId, attemptId);
    expect(c.submitEvents, 0);
    await checkStatusUntil(tester, c, PaymentStatus.succeeded);
    expect(c.host.attemptCount, 1);
    expect(c.host.chargeCount, 1);
  });

  testWidgets('K08 restart mid-KYC does not restore identity input', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K08', variant: 2);
    expect(c.identity, isNotEmpty);
    app.simulateRestart();
    await tester.pump();
    await pumpUntil(tester, () => !app.coordinator.starting);
    expect(app.coordinator.identity, isEmpty);
    expect(app.coordinator.step, FlowStep.overview);
  });

  testWidgets('X04 account switch discards the old account response', (
    tester,
  ) async {
    // Real latency so the slow check is still running when we switch.
    final app = await launch(tester, latencyScale: 0.5);
    final c = await runScenario(tester, app, 'X04');
    expect(c.step, FlowStep.payment);
    // The slow status check for account A is still in flight.
    expect(c.attempt!.observation, Observation.refreshing);
    await tester.tap(find.byKey(const Key('account-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('account-B')));
    await tester.pump();

    await pumpUntil(
      tester,
      () => logCount(c, 'Discarded a response') > 0,
      reason: 'stale response discarded',
    );
    await settle(tester);
    expect(c.account, 'B');
    expect(c.attempt, isNull);
    expect(c.step, FlowStep.overview);
    expect(find.textContaining('TRX-004070'), findsNothing);
    expect(find.text('Processing'), findsNothing);
  });

  testWidgets('account switch during a lost submit does not leak the error', (
    tester,
  ) async {
    final app = await launch(tester, latencyScale: 0.5);
    final c = await runScenario(tester, app, 'P06');
    await checkoutToAuthorize(tester, c);
    await tapVisible(tester, confirmButton());
    await pumpUntil(tester, () => c.step == FlowStep.payment);
    await c.switchAccount('B');
    await pumpUntil(
      tester,
      () => logCount(c, 'Discarded a response') > 0,
      reason: 'timeout discarded',
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(c.account, 'B');
    expect(c.attempt, isNull);
    expect(c.submitError, isNull);
  });

  test('scenario picker lists all 27 PRD edge IDs', () {
    const prdIds = {
      'K01', 'K02', 'K03', 'K04', 'K05', 'K06', 'K07', 'K08', //
      'P01', 'P02', 'P03', 'P04', 'P05', 'P06', 'P07', 'P08', 'P09', 'P10',
      'P11', 'P12', 'P13', 'P14', 'P15', 'X01', 'X02', 'X03', 'X04',
    };
    final ids = scenarios.map((s) => s.id).toSet();
    expect(prdIds.difference(ids), isEmpty);
  });
}

Future<void> openReport(WidgetTester tester) async {
  final button = find.byKey(const Key('report-problem'));
  if (button.evaluate().isNotEmpty) {
    await tapVisible(tester, button);
  } else {
    await tapVisible(tester, find.byTooltip('More actions'));
    await tapVisible(tester, find.text('Report a problem'));
  }
}
