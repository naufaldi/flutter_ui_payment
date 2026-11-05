import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/kyc_review_demo.dart';
import 'package:rakit_ui_example/compositions/kyc_review_block.dart';

Future<void> correctDocument(WidgetTester tester) async {
  await tester.tap(find.text('Perbarui data'));
  await tester.pumpAndSettle();
  final replace = find.text(PaymentLocalizations('id').tryAgain);
  await tester.scrollUntilVisible(
    replace,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(replace);
  await tester.pumpAndSettle();
  expect(
    tester.widget<KycReviewBlock>(find.byType(KycReviewBlock)).snapshot.status,
    VerificationStatus.actionRequired,
  );
  await tester.tap(find.text('Lanjutkan tinjauan'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('corrected upload stays unverified until a host review verdict', (
    tester,
  ) async {
    await tester.pumpWidget(const KycReviewDemo(delay: Duration.zero));
    await tester.pumpAndSettle();
    await correctDocument(tester);
    expect(find.text('DEMO-00002190'), findsNothing);
    expect(find.textContaining('2190'), findsOneWidget);
    await tester.tap(find.text(PaymentLocalizations('id').submitVerification));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<VerificationStatusView>(find.byType(VerificationStatusView))
          .snapshot
          .status,
      VerificationStatus.inReview,
    );
    await tester.tap(find.text('Cek status'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<VerificationStatusView>(find.byType(VerificationStatusView))
          .snapshot
          .status,
      VerificationStatus.verified,
    );
  });

  testWidgets(
    'failed correction keeps review data and allows retry without verification',
    (tester) async {
      await tester.pumpWidget(
        const KycReviewDemo(failFirstSubmit: true, delay: Duration.zero),
      );
      await tester.pumpAndSettle();
      await correctDocument(tester);
      await tester.tap(
        find.text(PaymentLocalizations('id').submitVerification),
      );
      await tester.pumpAndSettle();
      expect(find.text('Perbaikan belum terkirim'), findsOneWidget);
      expect(
        tester
            .widget<KycReviewBlock>(find.byType(KycReviewBlock))
            .snapshot
            .status,
        VerificationStatus.actionRequired,
      );
      await tester.tap(
        find.text(PaymentLocalizations('id').submitVerification),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VerificationStatusView), findsOneWidget);
    },
  );

  testWidgets(
    '320dp/200% correction has a reachable primary action in reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        const KycReviewDemo(initialDark: true, delay: Duration.zero),
      );
      await tester.pumpAndSettle();
      await correctDocument(tester);
      expect(
        find.text(PaymentLocalizations('id').submitVerification).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
