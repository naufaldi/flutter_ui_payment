import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/block_demo_shell.dart';
import 'package:rakit_ui_example/compositions/wallet_handoff_block.dart';
import 'package:rakit_ui_example/wallet_handoff_demo.dart';

import 'support/small_screen.dart';

void main() {
  const ready = (attemptId: 'attempt-1', phase: WalletHandoffPhase.ready);
  const opening = (attemptId: 'attempt-1', phase: WalletHandoffPhase.opening);

  test(
    'failed persistence never launches and leaves a safe recovery path',
    () async {
      for (final authorizationStillValid in [true, false]) {
        WalletHandoff? handoff = ready;
        var authorized = true;
        var launches = 0;
        final stored = Completer<void>();
        final error = StateError('could not persist attempt');
        final openingResult = openWalletHandoff(
          attemptId: ready.attemptId,
          readHandoff: () => handoff,
          writeHandoff: (next) => handoff = next,
          isAuthorized: () => authorized,
          persistAttempt: () => stored.future,
          launchWallet: () async {
            launches++;
            return true;
          },
        );
        expect(handoff, opening);
        authorized = authorizationStillValid;
        final reported = expectLater(openingResult, throwsA(same(error)));
        stored.completeError(error);
        await reported;
        expect(launches, 0);
        expect(handoff, authorizationStillValid ? ready : null);
      }
    },
  );

  test(
    'a phase change on the same attempt during persistence stops launch',
    () async {
      WalletHandoff? handoff = ready;
      var launches = 0;
      final stored = Completer<void>();
      final openingResult = openWalletHandoff(
        attemptId: ready.attemptId,
        readHandoff: () => handoff,
        writeHandoff: (next) => handoff = next,
        isAuthorized: () => true,
        persistAttempt: () => stored.future,
        launchWallet: () async {
          launches++;
          return true;
        },
      );
      expect(handoff, opening);
      const canceled = (
        attemptId: 'attempt-1',
        phase: WalletHandoffPhase.canceled,
      );
      handoff = canceled;
      stored.complete();
      await openingResult;
      expect(launches, 0);
      expect(handoff, canceled);
    },
  );

  testWidgets('checkout recovers no app, cancel and no return on one attempt', (
    tester,
  ) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const WalletHandoffDemo(initialDark: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();

    final check = find.text('Cek status');
    PaymentAttempt shownAttempt() => tester
        .widget<PaymentStatusView>(find.byType(PaymentStatusView))
        .attempt;

    Future<void> tap(String label) async {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> choose(String scenario) async {
      await tester.tap(find.byTooltip('Skenario demo'));
      await tester.pumpAndSettle();
      await tap(scenario);
    }

    Future<void> recover(String hint, String attemptId) async {
      expect(find.text(hint), findsOneWidget);
      expect(find.text('Buka dompet'), findsNothing);
      expect(check.hitTestable(), findsOneWidget);
      expect(
        tester.getSize(buttonLabeled('Cek status')).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.bySemanticsLabel('Cek status'), findsOneWidget);
      expect(shownAttempt().attemptId, attemptId);
      await tap('Cek status');
      expect(shownAttempt().attemptId, attemptId);
      expect(shownAttempt().status, PaymentStatus.pending);
    }

    final canceledId = shownAttempt().attemptId;
    expect(
      tester.getTopLeft(find.byType(AmountText)).dy,
      lessThan(tester.getTopLeft(buttonLabeled('Buka dompet')).dy),
    );
    await tap('Buka dompet');
    await tap('Simulasi batal');
    expect(find.text('Pembayaran dibatalkan'), findsNothing);
    await recover('Batal di aplikasi dompet', canceledId);

    await choose('Aplikasi tidak tersedia');
    final missingId = shownAttempt().attemptId;
    expect(missingId, isNot(canceledId));
    await tap('Buka dompet');
    await recover('Aplikasi dompet tidak tersedia', missingId);

    await choose('Tidak kembali dari dompet');
    final noReturnId = shownAttempt().attemptId;
    await tap('Buka dompet');
    await recover('Belum ada respons dari dompet', noReturnId);
    expect(shownAttempt().observation, Observation.unavailable);
    expect(find.text('Pembayaran kedaluwarsa'), findsNothing);
    await tap('Cek status');
    expect(shownAttempt().attemptId, noReturnId);
    expect(find.text('Pembayaran kedaluwarsa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'return preserves the in-flight check and a replacement ignores old replies',
    (tester) async {
      const delay = Duration(seconds: 5);
      await tester.pumpWidget(const WalletHandoffDemo(delay: delay));
      await tester.pumpAndSettle();

      Future<void> tap(String label) async {
        await tester.tap(find.text(label));
        await tester.pump();
      }

      PaymentAttempt current() => tester
          .widget<PaymentStatusView>(find.byType(PaymentStatusView))
          .attempt;

      Future<void> reset() async {
        final previous = current().attemptId;
        await tester.tap(find.byTooltip('Skenario demo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tap('Aplikasi tersedia');
        await tester.pump(const Duration(milliseconds: 350));
        expect(current().attemptId, isNot(previous));
      }

      final open = find.text('Buka dompet');
      await tap('Buka dompet');
      expect(
        tester.getSemantics(buttonLabeled('Buka dompet')).value,
        'Membuka dompet',
      );
      await reset();
      expect(open.hitTestable(), findsOneWidget);
      await tester.pump(delay);
      expect(open.hitTestable(), findsOneWidget);
      expect(find.text('Simulasi kembali'), findsNothing);

      await tap('Buka dompet');
      await tester.pump(delay);
      final returningAttempt = current().attemptId;
      await tap('Cek status');
      expect(current().observation, Observation.refreshing);
      await tap('Simulasi kembali');
      expect(find.text('Kembali dari dompet'), findsOneWidget);
      expect(current().attemptId, returningAttempt);
      expect(current().observation, Observation.refreshing);
      expect(current().snapshot?.revision, 1);
      await tester.pump(delay);
      expect(current().observation, Observation.fresh);
      expect(current().snapshot?.revision, 2);
      await tap('Cek status'); // This reply would confirm the previous attempt.
      expect(
        tester.getSemantics(buttonLabeled('Cek status')).value,
        'Mengecek status…',
      );
      await reset();
      await tester.pump(delay);
      await tester.pumpAndSettle();

      expect(find.text('WALLET-DEMO-3'), findsOneWidget);
      expect(open.hitTestable(), findsOneWidget);
      expect(find.text('Pembayaran berhasil'), findsNothing);
    },
  );

  testWidgets('unmatched or unconfirmed handoff leaves only status recovery', (
    tester,
  ) async {
    const attempt = PaymentAttempt(
      attemptId: 'current-attempt',
      quoteId: 'approved-quote',
      quoteRevision: 3,
      methodId: 'wallet',
      submission: SubmissionState.outcomeUnknown,
    );
    final checks = <String>[];
    Future<void> show(PaymentAttempt current, String handoffId) async {
      await tester.pumpWidget(
        BlockDemoShell(
          title: 'Dompet digital',
          dark: false,
          onToggleDark: () {},
          body: (_) => WalletHandoffBlock(
            attempt: current,
            amount: const Money.idr(152500),
            handoff: (attemptId: handoffId, phase: WalletHandoffPhase.ready),
            onOpenWallet: (_) async => fail('Must not open this authorization'),
            onCheckStatus: (id) async => checks.add(id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buka dompet'), findsNothing);
    }

    final pending = attempt.reconcile(
      PaymentStatusSnapshot(
        attemptId: attempt.attemptId,
        serverReference: 'wallet-reference',
        status: PaymentStatus.pending,
        revision: 1,
        updatedAt: DateTime.utc(2026, 11, 24),
        allowedActions: {PaymentAction.checkStatus},
      ),
    );
    await show(pending.attempt, 'older-attempt');
    expect(find.text('Menunggu'), findsOneWidget);
    await show(attempt, attempt.attemptId);
    expect(find.text('Hasil belum terkonfirmasi'), findsOneWidget);
    await tester.tap(find.text('Cek status'));
    await tester.pumpAndSettle();
    expect(checks, [attempt.attemptId]);
  });
}
