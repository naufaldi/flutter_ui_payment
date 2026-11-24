import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/compositions/report_problem_block.dart';
import 'package:rakit_ui_example/history_block_demo.dart';

void main() {
  testWidgets('selected transaction and draft survive retry until confirmed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final failure = Completer<ConfirmedProblemReport>();
    final confirmation = Completer<ConfirmedProblemReport>();
    final drafts = <ReportProblemDraft>[];
    final row = TransactionRecord(
      id: 'payment-71',
      title: 'Toko Kopi',
      reference: 'ORD-482',
      amount: const Money.idr(41000),
      createdAt: DateTime(2026, 11, 24),
      status: PaymentStatus.succeeded,
    );
    await tester.pumpWidget(
      HistoryBlockDemo(
        initialDark: true,
        fetchPage: (_, _, _) async => (records: [row], nextCursor: null),
        submitReport: (draft) {
          drafts.add(draft);
          return switch (drafts.length) {
            1 => failure.future,
            2 => Future.value((draft: draft, caseId: '   ')),
            3 => Future.value((draft: drafts.first, caseId: 'CASE-EARLIER')),
            _ => confirmation.future,
          };
        },
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      expect(finder.hitTestable(), findsOneWidget);
      await tester.tap(finder.hitTestable());
      await tester.pumpAndSettle();
    }

    await tap(find.widgetWithText(TransactionListItem, row.title));
    await tap(find.text('Laporkan masalah'));
    final sheet = find.byKey(const Key('report-problem-sheet'));
    final reference = find.descendant(
      of: sheet,
      matching: find.text('ORD-482'),
    );
    expect(reference.hitTestable(), findsOneWidget);
    final send = find.descendant(
      of: find.byKey(const Key('send-report')),
      matching: find.byType(FilledButton),
    );
    expect(
      tester.getSemantics(send).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    final reason = find.byType(PaymentSelect<ReportProblemReason>);
    final reasonTrigger = find
        .descendant(of: reason, matching: find.byType(InkWell))
        .first;
    await tester.ensureVisible(reasonTrigger);
    await tester.pumpAndSettle();
    await tap(reasonTrigger);
    await tap(find.text('Nominal salah'));

    final area = find.byType(PaymentTextArea);
    final note = find.descendant(of: area, matching: find.byType(EditableText));
    await tester.ensureVisible(note);
    await tester.pumpAndSettle();
    expect(note.hitTestable(), findsOneWidget);
    await tester.enterText(note, 'Tagihan seharusnya Rp37.000');
    expect(send.hitTestable(), findsOneWidget);
    expect(tester.getSize(send).height, greaterThanOrEqualTo(48));
    await tester.tap(send);
    await tester.tap(send);
    // Back can arrive before any pending-state widgets have rebuilt.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(drafts, [
      (
        transactionId: 'payment-71',
        reference: 'ORD-482',
        reason: ReportProblemReason.wrongAmount,
        note: 'Tagihan seharusnya Rp37.000',
      ),
    ]);
    expect(
      tester.getSemantics(send).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    expect(find.text('Laporan terkirim'), findsNothing);
    expect(sheet, findsOneWidget);
    expect(find.text('Buang laporan ini?'), findsNothing);
    expect(
      find.descendant(of: sheet, matching: find.byType(PaymentIconButton)),
      findsNothing,
    );
    failure.completeError(StateError('private transport details'));
    await tester.pumpAndSettle();

    final error = find.text('Belum ada ID kasus. Coba lagi.');
    expect(error.hitTestable(), findsOneWidget);
    final firstError = tester.getSemantics(error);
    final errorFlags = firstError.flagsCollection;
    expect(errorFlags.isLiveRegion, isTrue);
    expect(errorFlags.isHidden, isFalse);
    expect(find.textContaining('private transport details'), findsNothing);
    expect(find.text('Nominal salah'), findsOneWidget);
    expect(find.text('Tagihan seharusnya Rp37.000'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    await tester.ensureVisible(note);
    await tester.pumpAndSettle();
    expect(note.hitTestable(), findsOneWidget);
    expect(send.hitTestable(), findsOneWidget);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();

    final errorBeforeRetry = tester.getSemantics(error).id;
    await tap(send);
    expect(error.hitTestable(), findsOneWidget);
    expect(tester.getSemantics(error).id, isNot(errorBeforeRetry));
    expect(find.text('Laporan terkirim'), findsNothing);
    const editedNote = 'Koreksi: tagihan seharusnya Rp36.000';
    await tester.ensureVisible(note);
    await tester.enterText(note, editedNote);
    await tap(send);
    expect(drafts[2].note, editedNote);
    expect(find.text('CASE-EARLIER'), findsNothing);
    expect(find.text('Laporan terkirim'), findsNothing);
    expect(find.text(editedNote), findsOneWidget);
    expect(error.hitTestable(), findsOneWidget);
    await tester.tap(send);
    await tester.pump();
    expect(drafts, [drafts.first, drafts.first, drafts[2], drafts[2]]);
    confirmation.complete((draft: drafts[2], caseId: 'CASE-739'));
    await tester.pumpAndSettle();

    expect(find.text('CASE-739').hitTestable(), findsOneWidget);
    expect(
      find.bySemanticsLabel('Laporan terkirim. ID kasus: CASE-739'),
      findsOneWidget,
    );
    expect(send, findsNothing);
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('CASE-739').hitTestable(), findsOneWidget);
    await tap(find.text('Selesai'));
    expect(find.text('Detail transaksi').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
