import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

PaymentStatusSnapshot snap(
  PaymentStatus status, {
  int revision = 1,
  String attemptId = 'att-1',
  String reference = 'TRX-1',
  Set<PaymentAction> actions = const {},
  bool correction = false,
}) => PaymentStatusSnapshot(
  attemptId: attemptId,
  serverReference: reference,
  status: status,
  revision: revision,
  updatedAt: DateTime.utc(2026, 10, 30, 9),
  allowedActions: actions,
  isCorrection: correction,
);

PaymentQuote quote({
  int revision = 1,
  int fee = 2500,
  String? methodId = 'balance',
}) => PaymentQuote(
  id: 'Q-1',
  revision: revision,
  lines: [
    const QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
    QuoteLine(
      label: 'Service fee',
      amount: Money.idr(fee),
      kind: QuoteLineKind.fee,
    ),
  ],
  total: Money.idr(100000 + fee),
  expiresAt: DateTime.utc(2026, 10, 30, 10),
  methodId: methodId,
);

void main() {
  const sent = PaymentAttempt(
    attemptId: 'att-1',
    quoteId: 'Q-1',
    quoteRevision: 1,
    methodId: 'balance',
    submission: SubmissionState.sending,
  );

  group('PaymentAttempt.reconcile', () {
    test('applies a newer snapshot and marks the submission accepted', () {
      final result = sent.reconcile(snap(PaymentStatus.processing));
      expect(result.applied, isTrue);
      expect(result.attempt.submission, SubmissionState.accepted);
      expect(result.attempt.status, PaymentStatus.processing);
    });

    test('ignores stale and duplicate revisions', () {
      final current = sent
          .reconcile(snap(PaymentStatus.pending, revision: 3))
          .attempt;
      final stale = current.reconcile(
        snap(PaymentStatus.processing, revision: 2),
      );
      final duplicate = current.reconcile(
        snap(PaymentStatus.pending, revision: 3),
      );
      expect(stale.rejection, ReconcileRejection.stale);
      expect(duplicate.rejection, ReconcileRejection.stale);
      expect(stale.attempt.status, PaymentStatus.pending);
    });

    test('a later non-correction cannot downgrade a success', () {
      final paid = sent
          .reconcile(snap(PaymentStatus.succeeded, revision: 4))
          .attempt;
      final late = paid.reconcile(snap(PaymentStatus.failed, revision: 5));
      expect(late.rejection, ReconcileRejection.successDowngrade);
      expect(late.attempt.status, PaymentStatus.succeeded);

      final correction = paid.reconcile(
        snap(PaymentStatus.failed, revision: 5, correction: true),
      );
      expect(correction.applied, isTrue);
      expect(correction.attempt.status, PaymentStatus.failed);
    });

    test('rejects snapshots for another attempt or server reference', () {
      expect(
        sent
            .reconcile(snap(PaymentStatus.succeeded, attemptId: 'att-2'))
            .rejection,
        ReconcileRejection.wrongAttempt,
      );
      final known = sent.reconcile(snap(PaymentStatus.processing)).attempt;
      expect(
        known
            .reconcile(
              snap(PaymentStatus.succeeded, revision: 2, reference: 'TRX-9'),
            )
            .rejection,
        ReconcileRejection.referenceMismatch,
      );
    });
  });

  group('PaymentAttempt actions', () {
    test('an unknown outcome only offers a status check', () {
      final unknown = sent.copyWith(submission: SubmissionState.outcomeUnknown);
      expect(unknown.isUnresolved, isTrue);
      expect(unknown.availableActions, {PaymentAction.checkStatus});
      expect(unknown.allowsNewAttempt, isFalse);
    });

    test('pending never allows a new attempt even if the host lists it', () {
      final pending = sent
          .reconcile(
            snap(
              PaymentStatus.pending,
              actions: {
                PaymentAction.checkStatus,
                PaymentAction.startNewAttempt,
              },
            ),
          )
          .attempt;
      expect(pending.isUnresolved, isTrue);
      expect(
        pending.availableActions,
        isNot(contains(PaymentAction.startNewAttempt)),
      );
    });

    test('a final failure allows a new attempt only when the host does', () {
      final allowed = sent
          .reconcile(
            snap(
              PaymentStatus.failed,
              actions: {PaymentAction.startNewAttempt},
            ),
          )
          .attempt;
      final denied = sent
          .reconcile(
            snap(PaymentStatus.failed, actions: {PaymentAction.contactSupport}),
          )
          .attempt;
      expect(allowed.allowsNewAttempt, isTrue);
      expect(denied.allowsNewAttempt, isFalse);
      expect(denied.availableActions, {PaymentAction.contactSupport});
    });

    test('a success never offers a new attempt', () {
      final paid = sent
          .reconcile(
            snap(
              PaymentStatus.succeeded,
              actions: {
                PaymentAction.viewReceipt,
                PaymentAction.startNewAttempt,
              },
            ),
          )
          .attempt;
      expect(paid.availableActions, {PaymentAction.viewReceipt});
    });
  });

  group('PaymentQuote', () {
    test('terms differ when total, fee lines or method change', () {
      expect(quote().termsDifferFrom(quote(revision: 2)), isFalse);
      expect(quote().termsDifferFrom(quote(fee: 3500)), isTrue);
      expect(quote().termsDifferFrom(quote(methodId: 'va')), isTrue);
    });

    test('expiry is inclusive of the expiry instant', () {
      final q = quote();
      expect(q.isExpiredAt(DateTime.utc(2026, 10, 30, 9, 59)), isFalse);
      expect(q.isExpiredAt(DateTime.utc(2026, 10, 30, 10)), isTrue);
    });
  });

  group('Status parsing', () {
    test('unknown wire values are rejected, not guessed', () {
      expect(PaymentStatus.tryParse('succeeded'), PaymentStatus.succeeded);
      expect(PaymentStatus.tryParse('SETTLED_V2'), isNull);
      expect(PaymentStatus.tryParse(null), isNull);
      expect(VerificationStatus.tryParse('verified'), isNotNull);
      expect(VerificationStatus.tryParse('approved'), isNull);
    });

    test('HostError treats only a timeout as an unknown outcome', () {
      expect(const HostError(HostErrorCategory.timeout).outcomeUnknown, true);
      expect(const HostError(HostErrorCategory.network).outcomeUnknown, false);
    });
  });

  group('Documents', () {
    const requirement = DocumentRequirement(
      key: 'idCard',
      label: 'ID card',
      acceptedTypes: {'image/jpeg', 'image/png'},
      maxBytes: 5 * 1024 * 1024,
    );

    test('host limits reject wrong type and oversize files', () {
      expect(
        checkDocumentLimits(
          requirement,
          const DocumentFile(
            name: 'a.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 10,
          ),
        )?.kind,
        DocumentIssueKind.unsupportedType,
      );
      expect(
        checkDocumentLimits(
          requirement,
          const DocumentFile(
            name: 'a.jpg',
            mimeType: 'image/jpeg',
            sizeBytes: 6 * 1024 * 1024,
          ),
        )?.kind,
        DocumentIssueKind.tooLarge,
      );
      expect(
        checkDocumentLimits(
          requirement,
          const DocumentFile(
            name: 'a.jpg',
            mimeType: 'image/jpeg',
            sizeBytes: 1024,
          ),
        ),
        isNull,
      );
    });

    test('review masks all but the last four characters', () {
      expect(VerificationReview.mask('3100000000001234'), '••••••••••••1234');
      expect(VerificationReview.mask('123'), '123');
    });
  });

  group('ReceiptShareData', () {
    test('contains only allowlisted fields', () {
      final receipt = PaymentReceiptData(
        transactionId: 'TRX-004071',
        merchantName: 'Ruang Bayar Akademi',
        paidAt: DateTime.utc(2026, 10, 30, 9),
        lines: const [
          QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
        ],
        total: const Money.idr(102500),
        methodLabel: 'Saldo •••• 2190',
      );
      final share = ReceiptShareData.fromReceipt(
        receipt,
        title: 'Receipt',
        labels: const {
          'merchant': 'Merchant',
          'transactionId': 'Reference',
          'paidAt': 'Paid at',
          'total': 'Total',
          'method': 'Method',
        },
        moneyFormat: const MoneyFormat('id'),
        formatDate: (_) => '30 Okt 2026',
      );
      expect(share.fields.keys, [
        'Merchant',
        'Reference',
        'Paid at',
        'Total',
        'Method',
      ]);
      expect(share.text, contains('Rp102.500'));
      expect(share.text, isNot(contains('Paket Belajar')));
    });
  });

  group('CountdownText', () {
    test('never reports a negative remaining time', () {
      final expires = DateTime.utc(2026, 10, 30, 10);
      expect(
        CountdownText.remaining(expires, DateTime.utc(2026, 10, 30, 11)),
        Duration.zero,
      );
      expect(CountdownText.formatDuration(Duration.zero), '00:00');
      expect(
        CountdownText.formatDuration(const Duration(hours: 23, minutes: 5)),
        '23:05:00',
      );
    });
  });
}
