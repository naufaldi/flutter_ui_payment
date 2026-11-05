import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'helpers/reduced_motion.dart';

// Status swaps (D69, #96): full-width status content fades, never scales,
// and its height eases, so nothing below jumps when the title's line count
// changes.

/// Keeps the view's MediaQuery and only changes the text scale, so a
/// reduced-motion setup applied around it still reaches the kit.
Widget host(Widget child, {double textScale = 1}) => MaterialApp(
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

PaymentAttempt attempt(PaymentStatus status) => PaymentAttempt(
  attemptId: 'att-1',
  quoteId: 'Q-1',
  quoteRevision: 1,
  methodId: 'balance',
  submission: SubmissionState.accepted,
  snapshot: PaymentStatusSnapshot(
    attemptId: 'att-1',
    serverReference: 'TRX-004071',
    status: status,
    revision: 2,
    updatedAt: DateTime.utc(2026, 11, 2, 9),
  ),
);

Widget payment(PaymentStatus status) => PaymentStatusView(
  attempt: attempt(status),
  amount: const Money.idr(102500),
  onAction: (_) {},
);

Widget verification(VerificationStatus status) => VerificationStatusView(
  snapshot: VerificationSnapshot(status: status),
  onAction: (_) {},
);

/// Phone width: 390 dp less the 16 dp padding on each side.
const _column = 358.0;

void main() {
  for (final (name, from, to) in [
    (
      'payment',
      payment(PaymentStatus.pending),
      payment(PaymentStatus.succeeded),
    ),
    (
      'verification',
      verification(VerificationStatus.inReview),
      verification(VerificationStatus.verified),
    ),
  ]) {
    group('$name status view', () {
      testWidgets('the band keeps the column width mid-swap', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(from));
        final rest = tester.getRect(find.byType(StatusBand));
        expect(rest.width, _column);

        await tester.pumpWidget(host(to));
        await tester.pump(const Duration(milliseconds: 50));
        final bands = find.byType(StatusBand);
        // Both the leaving and the entering band are on screen, unscaled.
        expect(bands, findsNWidgets(2));
        for (final band in bands.evaluate()) {
          final rect = tester.getRect(find.byWidget(band.widget));
          expect(rect.left, rest.left);
          expect(rect.width, rest.width);
        }
        // The leaving status takes no taps: only the entering band is hit.
        expect(bands.hitTestable(), findsOneWidget);

        await tester.pumpAndSettle();
        expect(bands, findsOneWidget);
        expect(tester.getRect(bands), rest);
      });

      for (final setup in ReducedMotion.values) {
        testWidgets('swaps still under reduced motion (${setup.name})', (
          tester,
        ) async {
          await tester.pumpWidget(setup.apply(tester, host(from)));
          await expectStill(
            tester,
            () => tester.pumpWidget(setup.apply(tester, host(to))),
          );
          expect(find.byType(StatusBand), findsOneWidget);
        });
      }
    });
  }

  group('a title that changes line count at 200% text', () {
    // At 2× on a 400 dp column, "Pending" takes one line and "Payment
    // successful" two.
    Future<List<double>> track(
      WidgetTester tester,
      PaymentStatus from,
      PaymentStatus to,
    ) async {
      tester.view.physicalSize = const Size(432, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(payment(from), textScale: 2));
      final amount = find.byType(AmountText);
      final tops = [tester.getTopLeft(amount).dy];
      await tester.pumpWidget(host(payment(to), textScale: 2));
      // 1 ms steps: the eased height is steepest at about 5× its mean
      // speed, so a 16 ms frame would move a correct glide by several dp.
      for (var ms = 0; ms < 400; ms++) {
        tops.add(tester.getTopLeft(amount).dy);
        await tester.pump(const Duration(milliseconds: 1));
      }
      tops.add(tester.getTopLeft(amount).dy);
      expect(tester.hasRunningAnimations, isFalse);
      return tops;
    }

    double lineHeight(WidgetTester tester) =>
        tester.getSize(find.text('Pending')).height;

    testWidgets('growing, the amount glides down', (tester) async {
      final tops = await track(
        tester,
        PaymentStatus.pending,
        PaymentStatus.succeeded,
      );
      final title = tester.getSize(find.text('Payment successful')).height;
      // The title really went from one line to two.
      expect(title, closeTo(2 * 40, 1));
      expect(tops.last - tops.first, closeTo(title / 2, 1));
      for (var i = 1; i < tops.length; i++) {
        final step = tops[i] - tops[i - 1];
        expect(step, inInclusiveRange(0, 1), reason: 'step $i');
      }
    });

    testWidgets('shrinking, the amount never jumps up', (tester) async {
      final tops = await track(
        tester,
        PaymentStatus.succeeded,
        PaymentStatus.pending,
      );
      expect(tops.first - tops.last, closeTo(lineHeight(tester), 1));
      for (var i = 1; i < tops.length; i++) {
        final step = tops[i] - tops[i - 1];
        expect(step, inInclusiveRange(-1, 0), reason: 'step $i');
      }
    });
  });
}
