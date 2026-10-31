import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../scenarios/scenario_config.dart';

/// Thrown by the fake host services. Adapters convert everything the
/// "network" produces into [HostError]; widgets never see exceptions.
class HostException implements Exception {
  const HostException(this.error);
  final HostError error;
  @override
  String toString() => 'HostException(${error.category})';
}

/// A synthetic document fixture offered instead of a camera capture.
class DocumentFixture {
  const DocumentFixture(this.file, this.description);
  final DocumentFile file;
  final String description;
}

const demoFixtures = [
  DocumentFixture(
    DocumentFile(
      name: 'ktp_demo_sari.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1258291,
    ),
    'valid',
  ),
  DocumentFixture(
    DocumentFile(
      name: 'ktp_demo_retake.png',
      mimeType: 'image/png',
      sizeBytes: 838861,
    ),
    'valid',
  ),
  DocumentFixture(
    DocumentFile(
      name: 'ktp_scan_besar.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 12582912,
    ),
    'tooLarge',
  ),
  DocumentFixture(
    DocumentFile(
      name: 'ktp_dokumen.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 524288,
    ),
    'wrongType',
  ),
];

class HostLogEntry {
  HostLogEntry(this.at, this.message);
  final DateTime at;
  final String message;
}

/// Server-side record of one payment attempt in the fake backend.
class _AttemptRecord {
  _AttemptRecord({
    required this.account,
    required this.attemptId,
    required this.reference,
    required this.quote,
    required this.methodId,
    required this.script,
    required this.createdAt,
  });

  final String account;
  final String attemptId;
  final String reference;
  final PaymentQuote quote;
  final String methodId;
  final List<ServerStep> script;
  final DateTime createdAt;
  int index = 0;
  int revision = 1;
  bool cancelRequested = false;
  PaymentStatus? forcedStatus;

  ServerStep get currentStep {
    for (var i = index; i >= 0; i--) {
      if (script[i].fault == ServerFault.none) return script[i];
    }
    return script.firstWhere((s) => s.fault == ServerFault.none);
  }

  PaymentStatus get status => forcedStatus ?? currentStep.status!;
}

/// The simulated backend, provider and device capabilities behind the demo.
///
/// It outlives a simulated app restart: the server keeps attempts and the
/// [RecoveryStore] keeps one opaque attempt reference per account.
class DemoHost {
  DemoHost(this.config, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final ScenarioConfig config;
  final DateTime Function() clock;
  String languageCode = 'id';

  /// Scales every simulated latency; tests shorten it.
  static double latencyScale = 1;

  final ValueNotifier<List<HostLogEntry>> log = ValueNotifier(const []);
  final recovery = RecoveryStore();

  final Map<String, _KycRecord> _kyc = {};
  final Map<String, _AttemptRecord> _attempts = {};
  final _late = StreamController<Map<String, Object?>>.broadcast();
  int _captureRequests = 0;
  bool _settingsGranted = false;
  bool _uploadInterrupted = false;
  bool _quoteFailed = false;
  bool _receiptFailed = false;
  bool _sessionExpiredUsed = false;
  bool _quoteChangedServed = false;
  int _ids = 0;

  /// Number of charges the fake provider made — one per attempt at most.
  int get chargeCount =>
      _attempts.values.where((r) => r.status == PaymentStatus.succeeded).length;
  int get attemptCount => _attempts.length;

  /// Stale snapshots delivered late, as a webhook might.
  Stream<Map<String, Object?>> get lateDeliveries => _late.stream;

  bool get _id => languageCode == 'id';
  String _t(String en, String id) => _id ? id : en;

  /// Amounts inside fixture copy go through the same formatter as the kit,
  /// so an English screen never shows an Indonesian-format number.
  String _money(int rupiah) =>
      MoneyFormat(languageCode).format(Money.idr(rupiah));

  void record(String message) {
    log.value = [...log.value, HostLogEntry(clock(), message)];
  }

  String nextId(String prefix) {
    _ids++;
    final stamp = clock().millisecondsSinceEpoch.toRadixString(36);
    return '$prefix-$stamp-$_ids';
  }

  Future<void> _latency([int ms = 600]) =>
      Future.delayed(Duration(milliseconds: (ms * latencyScale).round()));

  bool _signInCanceled = false, _historyFailed = false;
  Future<bool> signIn() async {
    await _latency();
    if (config.signInCancelsOnce && !_signInCanceled) {
      _signInCanceled = true;
      record('Sign-in canceled');
      return false;
    }
    record('Signed in');
    return true;
  }

  Future<List<TransactionRecord>> history(String account) async {
    await _latency();
    if (config.historyFailsOnce && !_historyFailed) {
      _historyFailed = true;
      throw const HostException(HostError(HostErrorCategory.unavailable));
    }
    final now = clock();
    final rows = <TransactionRecord>[
      if (!config.historyEmpty) ...[
        for (final r in _attempts.values.where(
          (r) => r.account == account && r.status == PaymentStatus.succeeded,
        ))
          TransactionRecord(
            id: r.attemptId,
            title: 'Paket Belajar',
            amount: r.quote.total,
            createdAt: r.createdAt,
            status: r.status,
            merchant: 'Ruang Bayar Akademi',
            methodLabel: r.methodId,
            reference: r.reference,
          ),
        for (var i = 0; i < 14; i++)
          TransactionRecord(
            id: 'TRX-DEMO-${(i + 42).toString().padLeft(4, '0')}',
            title: [
              'Toko Contoh',
              'Ruang Bayar Akademi',
              'Kopi Demo',
              'Pasar Demo',
            ][i % 4],
            merchant: [
              'Toko Contoh',
              'Ruang Bayar Akademi',
              'Kopi Demo',
              'Pasar Demo',
            ][i % 4],
            amount: Money.idr((i + 1) * 12500),
            createdAt: now.subtract(Duration(days: i * 3)),
            status: [
              PaymentStatus.succeeded,
              PaymentStatus.pending,
              PaymentStatus.failed,
              null,
            ][i % 4],
            methodLabel: [
              'BCA virtual account',
              'QRIS',
              'Ruang Bayar balance',
            ][i % 3],
            reference: 'TRX-DEMO-${(i + 42).toString().padLeft(4, '0')}',
            refund: i == 0
                ? const RefundInfo(
                    status: RefundStatus.refunded,
                    amount: Money.idr(25000),
                  )
                : const RefundInfo(status: RefundStatus.none),
          ),
      ],
    ];
    record('[$account] History loaded (${rows.length})');
    return rows;
  }

  void dispose() {
    _late.close();
    log.dispose();
  }

  // ---------------------------------------------------------------- KYC

  _KycRecord _kycFor(String account) => _kyc.putIfAbsent(account, () {
    if (account != 'A') {
      return _KycRecord(VerificationStatus.verified, updatedAt: clock());
    }
    return _KycRecord(
      config.initialKyc,
      requestId: config.initialKyc == VerificationStatus.notStarted
          ? null
          : 'kyc-seeded-001',
      reason: config.kycReason?.of(languageCode),
      fieldsToFix: config.kycFieldsToFix,
      updatedAt: config.initialKyc == VerificationStatus.inReview
          ? clock().subtract(const Duration(days: 3))
          : clock(),
    );
  });

  VerificationSnapshot _kycSnapshot(_KycRecord r) {
    final actions = switch (r.status) {
      VerificationStatus.notStarted => {VerificationAction.start},
      VerificationStatus.inReview => {VerificationAction.checkStatus},
      VerificationStatus.actionRequired => {
        VerificationAction.fixDetails,
        VerificationAction.contactSupport,
      },
      VerificationStatus.verified => {VerificationAction.continueToPayment},
      // Rejection is final unless the host's policy says otherwise.
      VerificationStatus.rejected => {VerificationAction.contactSupport},
      VerificationStatus.expired => {VerificationAction.start},
    };
    return VerificationSnapshot(
      status: r.status,
      requestId: r.requestId,
      safeReason: r.reason,
      fieldsToFix: r.fieldsToFix,
      allowedActions: actions,
      updatedAt: r.updatedAt,
    );
  }

  Future<VerificationSnapshot> kycStatus(String account) async {
    await _latency(400);
    final r = _kycFor(account);
    if (r.status == VerificationStatus.inReview && r.pendingOutcome != null) {
      if (r.checksUntilDecision > 0) {
        r.checksUntilDecision--;
      } else {
        _decide(r);
      }
    }
    return _kycSnapshot(r);
  }

  void _decide(_KycRecord r) {
    switch (r.pendingOutcome!) {
      case KycReviewOutcome.verified:
        r.status = VerificationStatus.verified;
        r.reason = null;
        r.fieldsToFix = const {};
      case KycReviewOutcome.actionRequired:
        r.status = VerificationStatus.actionRequired;
        r.reason = _t(
          'The ID photo is blurry. Upload a clearer photo; your other details are kept.',
          'Foto KTP buram. Unggah foto yang lebih jelas; data lain tetap tersimpan.',
        );
        r.fieldsToFix = const {'idCard'};
      case KycReviewOutcome.rejected:
        r.status = VerificationStatus.rejected;
        r.reason = _t(
          'We couldn’t approve this verification. Contact support for next steps.',
          'Verifikasi ini tidak dapat disetujui. Hubungi bantuan untuk langkah berikutnya.',
        );
    }
    r.pendingOutcome = null;
    r.updatedAt = clock();
  }

  /// Idempotent on [requestId]: a repeated submit returns the same record.
  Future<VerificationSnapshot> submitKyc(
    String account,
    String requestId,
    Map<String, String> identity,
  ) async {
    await _latency(900);
    final r = _kycFor(account);
    if (r.requestId == requestId && r.status == VerificationStatus.inReview) {
      record('KYC submit $requestId deduplicated by host');
      return _kycSnapshot(r);
    }
    r
      ..status = VerificationStatus.inReview
      ..requestId = requestId
      ..reason = null
      ..fieldsToFix = const {}
      ..updatedAt = clock()
      ..pendingOutcome = config.kycReview
      ..checksUntilDecision = 0;
    record(
      'KYC request $requestId received (fields: ${identity.keys.join(', ')})',
    );
    if (config.kycSubmit == KycSubmitOutcome.timeoutThenInReview &&
        !r.timeoutServed) {
      r.timeoutServed = true;
      // The server stored the request, but the answer never arrives.
      await _latency(1200);
      throw const HostException(HostError(HostErrorCategory.timeout));
    }
    return _kycSnapshot(r);
  }

  Future<CaptureAccess> requestCaptureAccess() async {
    await _latency(300);
    if (_settingsGranted) return CaptureAccess.granted;
    final answers = config.captureAccess;
    final answer = answers[_captureRequests.clamp(0, answers.length - 1)];
    _captureRequests++;
    return answer;
  }

  /// Simulates the user enabling access in system settings.
  Future<void> openSettings() async {
    await _latency(300);
    _settingsGranted = true;
    record('Capture access enabled in (simulated) Settings');
  }

  bool _captureRejected = false;

  Future<void> upload(String requestId, DocumentFile file) async {
    await Future.delayed(config.uploadDuration * latencyScale);
    if (config.rejectFirstCapture &&
        file.name.startsWith('kamera_') &&
        !_captureRejected) {
      _captureRejected = true;
      record('Host rejected synthetic camera photo');
      throw HostException(
        HostError(
          HostErrorCategory.validation,
          safeMessage: _t(
            'The ID photo is blurry. Retake it in good light.',
            'Foto KTP buram. Ambil ulang di tempat yang terang.',
          ),
        ),
      );
    }
    if (config.interruptFirstUpload && !_uploadInterrupted) {
      _uploadInterrupted = true;
      throw const HostException(HostError(HostErrorCategory.network));
    }
    record('Upload $requestId stored (${file.name})');
  }

  // ------------------------------------------------------------- Quotes

  String get merchantName => config.longLabels
      ? 'Ruang Bayar Akademi — Cabang Pendidikan Profesional Jakarta Selatan'
      : 'Ruang Bayar Akademi';

  PaymentQuote _price({
    required String methodId,
    Money? amount,
    int revision = 1,
    bool changedFee = false,
    Duration validity = const Duration(minutes: 10),
  }) {
    final item = amount ?? const Money.idr(100000);
    final itemLabel = amount != null
        ? _t('Learning credit top-up', 'Isi Saldo Belajar')
        : config.longLabels
        ? _t(
            'Paket Belajar Intensive — exam preparation and professional certification (12 months, full access)',
            'Paket Belajar Intensif — persiapan ujian dan sertifikasi profesional (12 bulan, akses penuh)',
          )
        : 'Paket Belajar';
    final serviceFee = Money.idr(changedFee ? 3500 : 2500);
    final lines = [
      QuoteLine(
        label: itemLabel,
        amount: item,
        detail: amount == null ? _t('1 × 1 month', '1 × 1 bulan') : null,
      ),
      QuoteLine(
        label: _t('Service fee', 'Biaya layanan'),
        amount: serviceFee,
        kind: QuoteLineKind.fee,
      ),
      if (methodId == 'va')
        QuoteLine(
          label: _t('Transfer fee', 'Biaya transfer'),
          amount: const Money.idr(1500),
          kind: QuoteLineKind.fee,
        ),
    ];
    final total = lines.fold(const Money.idr(0), (sum, l) => sum + l.amount);
    return PaymentQuote(
      id: amount == null ? 'Q-PAKET' : 'Q-TOPUP-${amount.minorUnits}',
      revision: revision,
      lines: lines,
      total: total,
      expiresAt: clock().add(validity),
      methodId: methodId,
    );
  }

  Future<PaymentQuote> quote({required String methodId, Money? amount}) async {
    await _latency(700);
    if (config.quote == QuoteBehavior.failOnce && !_quoteFailed) {
      _quoteFailed = true;
      throw HostException(
        HostError(
          HostErrorCategory.network,
          safeMessage: _t(
            'Prices couldn’t be loaded. Try again.',
            'Harga belum bisa dimuat. Coba lagi.',
          ),
        ),
      );
    }
    final quote = _price(
      methodId: methodId,
      amount: amount,
      validity: config.quote == QuoteBehavior.expiredAtConfirm
          ? const Duration(seconds: 2)
          : const Duration(minutes: 10),
    );
    record('Quote ${quote.id} r${quote.revision}: ${quote.total.minorUnits}');
    return quote;
  }

  /// Confirms the quote is still valid; returns the latest snapshot.
  Future<PaymentQuote> revalidate(PaymentQuote current, {Money? amount}) async {
    await _latency(500);
    final now = clock();
    if (config.quote == QuoteBehavior.totalChangesAtConfirm &&
        !_quoteChangedServed) {
      _quoteChangedServed = true;
      final next = _price(
        methodId: current.methodId!,
        amount: amount,
        revision: current.revision + 1,
        changedFee: true,
      );
      record(
        'Quote changed: ${current.total.minorUnits} → ${next.total.minorUnits}',
      );
      return next;
    }
    if (current.isExpiredAt(now)) {
      final next = _price(
        methodId: current.methodId!,
        amount: amount,
        revision: current.revision + 1,
        changedFee: _quoteChangedServed,
      );
      record('Quote r${current.revision} expired; issued r${next.revision}');
      return next;
    }
    return current;
  }

  Future<List<PaymentMethod>> methods() async {
    await _latency(300);
    final balance = config.methods == MethodSet.insufficientBalance
        ? PaymentMethod(
            id: 'balance',
            label: _t('Ruang Bayar balance', 'Saldo Ruang Bayar'),
            kind: PaymentMethodKind.balance,
            detail: _t('Balance ${_money(50000)}', 'Saldo ${_money(50000)}'),
            unavailableReason: _t(
              'Balance is not enough for this payment',
              'Saldo tidak cukup untuk pembayaran ini',
            ),
          )
        : PaymentMethod(
            id: 'balance',
            label: _t('Ruang Bayar balance', 'Saldo Ruang Bayar'),
            kind: PaymentMethodKind.balance,
            detail: _t('Balance ${_money(350000)}', 'Saldo ${_money(350000)}'),
            unavailableReason: config.methods == MethodSet.someUnavailable
                ? _t(
                    'Under maintenance until 22:00',
                    'Sedang pemeliharaan hingga 22.00',
                  )
                : null,
          );
    return switch (config.methods) {
      MethodSet.empty => const [],
      _ => [
        balance,
        PaymentMethod(
          id: 'va',
          label: _t(
            'Virtual account (Bank Contoh)',
            'Virtual account (Bank Contoh)',
          ),
          kind: PaymentMethodKind.virtualAccount,
          detail: _t('Pay by bank transfer', 'Bayar lewat transfer bank'),
          feeNote: _t(
            '+ ${_money(1500)} transfer fee',
            '+ biaya transfer ${_money(1500)}',
          ),
        ),
        if (config.methods == MethodSet.someUnavailable)
          PaymentMethod(
            id: 'card',
            label: _t('Card •••• 4242', 'Kartu •••• 4242'),
            kind: PaymentMethodKind.card,
            unavailableReason: _t(
              'Not accepted for this purchase',
              'Tidak diterima untuk pembelian ini',
            ),
          ),
      ],
    };
  }

  // -------------------------------------------------------------- Auth

  /// The host's own challenge (PIN/biometric). Only the outcome is returned.
  Future<AuthorizationPhase> authorize() async {
    await _latency(900);
    return switch (config.auth) {
      AuthOutcome.approve => AuthorizationPhase.approved,
      AuthOutcome.cancel => AuthorizationPhase.canceled,
      AuthOutcome.fail => AuthorizationPhase.failed,
      AuthOutcome.expire => AuthorizationPhase.expired,
    };
  }

  // ----------------------------------------------------------- Payments

  /// Idempotent on [attemptId]: repeats return the existing record.
  Future<Map<String, Object?>> submitPayment({
    required String account,
    required String attemptId,
    required PaymentQuote quote,
    required String methodId,
  }) async {
    if (config.sessionExpiredOnce && !_sessionExpiredUsed) {
      _sessionExpiredUsed = true;
      await _latency(500);
      throw HostException(
        HostError(
          HostErrorCategory.sessionExpired,
          safeMessage: _t(
            'Your session ended. Sign in again, then confirm the payment again. Nothing was charged.',
            'Sesi Anda berakhir. Masuk lagi, lalu konfirmasi ulang pembayaran. Tidak ada dana yang ditarik.',
          ),
        ),
      );
    }
    await _latency(config.submit == SubmitBehavior.slow ? 2500 : 800);
    final existing = _attempts[attemptId];
    if (existing != null) {
      record('Submit $attemptId deduplicated (idempotency key reused)');
      return _statusJson(existing);
    }
    final record_ = _AttemptRecord(
      account: account,
      attemptId: attemptId,
      reference: 'TRX-${(_attempts.length + 4071).toString().padLeft(6, '0')}',
      quote: quote,
      methodId: methodId,
      script: methodId == 'va' ? config.vaScript : config.script,
      createdAt: clock(),
    );
    _attempts[attemptId] = record_;
    record(
      'Submit $attemptId accepted as ${record_.reference} '
      '(quote ${quote.id} r${quote.revision})',
    );
    if (config.submit == SubmitBehavior.responseLost) {
      await _latency(1500);
      throw const HostException(HostError(HostErrorCategory.timeout));
    }
    return _statusJson(record_);
  }

  Map<String, Object?> _statusJson(_AttemptRecord r, {int? revision}) {
    final step = r.currentStep;
    final status = r.status;
    final actions =
        (r.forcedStatus == null ? step.actions : null) ??
        _defaultActions(status, r.methodId);
    return {
      'attemptId': r.attemptId,
      'reference': r.reference,
      'status': status.name,
      'revision': revision ?? r.revision,
      'updatedAt': clock().toUtc().toIso8601String(),
      'amount': {
        'minor': r.quote.total.minorUnits,
        'currency': r.quote.total.currency,
      },
      'actions': [for (final a in actions) a.name],
      'reason': r.forcedStatus == null ? step.reason?.of(languageCode) : null,
      'refund': {
        'status': step.refund.status.name,
        if (step.refund.amount != null)
          'amount': step.refund.amount!.minorUnits,
      },
      if (r.methodId == 'va' && !status.isTerminal)
        'instructions': {
          'provider': 'Bank Contoh — Virtual Account',
          'number': '8808 0012 3456 7890',
          'expiresAt': r.createdAt
              .add(config.vaExpiry)
              .toUtc()
              .toIso8601String(),
          'steps': [
            _t(
              'Open your bank app and choose Transfer → Virtual Account.',
              'Buka aplikasi bank, pilih Transfer → Virtual Account.',
            ),
            _t(
              'Enter the number above and check the amount.',
              'Masukkan nomor di atas dan periksa nominal.',
            ),
            _t(
              'Confirm the transfer, then return here and check the status.',
              'Konfirmasi transfer, lalu kembali ke sini dan cek status.',
            ),
          ],
        },
    };
  }

  Set<PaymentAction> _defaultActions(PaymentStatus status, String methodId) =>
      switch (status) {
        PaymentStatus.requiresAction => {
          PaymentAction.checkStatus,
          PaymentAction.viewInstructions,
        },
        PaymentStatus.processing => {PaymentAction.checkStatus},
        PaymentStatus.pending => {
          PaymentAction.checkStatus,
          if (methodId == 'va') PaymentAction.requestCancel,
        },
        PaymentStatus.succeeded => {PaymentAction.viewReceipt},
        PaymentStatus.failed => {
          PaymentAction.startNewAttempt,
          PaymentAction.contactSupport,
        },
        PaymentStatus.canceled ||
        PaymentStatus.expired => {PaymentAction.startNewAttempt},
      };

  Future<Map<String, Object?>> paymentStatus(String attemptId) async {
    await _latency(config.slowStatusCheck ? 3000 : 600);
    final r = _attempts[attemptId];
    if (r == null) {
      throw const HostException(
        HostError(HostErrorCategory.notAllowed, retryable: false),
      );
    }
    if (r.cancelRequested && !r.status.isTerminal) {
      r.forcedStatus = PaymentStatus.canceled;
      r.revision++;
      record('Provider confirmed cancellation of ${r.reference}');
      return _statusJson(r);
    }
    if (r.forcedStatus == null && r.index < r.script.length - 1) {
      r.index++;
    }
    final fault = r.forcedStatus == null
        ? r.script[r.index].fault
        : ServerFault.none;
    switch (fault) {
      case ServerFault.offline:
        record('Status check for ${r.reference} failed: offline');
        throw const HostException(HostError(HostErrorCategory.network));
      case ServerFault.invalidData:
        record('Provider returned unknown status "SETTLED_V2"');
        return {..._statusJson(r), 'status': 'SETTLED_V2'};
      case ServerFault.none:
        break;
    }
    if (r.methodId == 'va' &&
        r.status == PaymentStatus.pending &&
        !clock().isBefore(r.createdAt.add(config.vaExpiry))) {
      r.forcedStatus = PaymentStatus.expired;
      record('Provider expired ${r.reference}: no transfer received');
    }
    r.revision++;
    final fresh = _statusJson(r);
    if (r.forcedStatus == null && r.currentStep.replayStale) {
      final duplicate = Map<String, Object?>.of(fresh);
      final stale = {
        ...fresh,
        'revision': r.revision - 1,
        'status': PaymentStatus.processing.name,
        'actions': [PaymentAction.checkStatus.name],
      };
      Future.delayed(Duration(milliseconds: (700 * latencyScale).round()), () {
        if (_late.isClosed) return;
        record(
          'Late duplicate (r${duplicate['revision']}) and stale '
          '(r${stale['revision']}, processing) snapshots delivered',
        );
        _late
          ..add(duplicate)
          ..add(stale);
      });
    }
    return fresh;
  }

  Future<void> requestCancel(String attemptId) async {
    await _latency(700);
    final r = _attempts[attemptId]!;
    r.cancelRequested = true;
    record('Cancellation requested for ${r.reference}; awaiting provider');
  }

  Future<PaymentReceiptData> receipt(String attemptId) async {
    await _latency(600);
    if (config.receiptFailsOnce && !_receiptFailed) {
      _receiptFailed = true;
      throw const HostException(HostError(HostErrorCategory.network));
    }
    final r = _attempts[attemptId]!;
    if (r.status != PaymentStatus.succeeded) {
      throw const HostException(HostError(HostErrorCategory.notAllowed));
    }
    return PaymentReceiptData(
      transactionId: r.reference,
      merchantName: merchantName,
      paidAt: r.createdAt,
      lines: r.quote.lines,
      total: r.quote.total,
      methodLabel: r.methodId == 'va'
          ? 'Virtual account •••• 7890'
          : _t('Ruang Bayar balance •••• 2190', 'Saldo Ruang Bayar •••• 2190'),
      refund: r.currentStep.refund,
    );
  }

  /// Seeds a previously submitted attempt, as if the app had been killed after
  /// submitting. Only the opaque reference goes into the recovery store.
  void seedAttempt(String account) {
    final quote = _price(methodId: config.seedMethodId);
    final attemptId = 'att-seeded-0001';
    _attempts[attemptId] = _AttemptRecord(
      account: account,
      attemptId: attemptId,
      reference: 'TRX-004070',
      quote: quote,
      methodId: config.seedMethodId,
      script: config.seedMethodId == 'va' ? config.vaScript : config.script,
      createdAt: clock(),
    );
    recovery.save(account, attemptId);
    record('Seeded attempt $attemptId for account $account');
  }

  // -------------------------------------------------------- Device APIs

  Future<ShareOutcome> share(ReceiptShareData data) async {
    await _latency(300);
    record('Share requested with fields: ${data.fields.keys.join(', ')}');
    return switch (config.share) {
      ShareBehavior.shared => ShareOutcome.shared,
      ShareBehavior.dismissed => ShareOutcome.dismissed,
      ShareBehavior.failed => ShareOutcome.failed,
    };
  }
}

class _KycRecord {
  _KycRecord(
    this.status, {
    this.requestId,
    this.reason,
    this.fieldsToFix = const {},
    required this.updatedAt,
  });

  VerificationStatus status;
  String? requestId;
  String? reason;
  Set<String> fieldsToFix;
  DateTime updatedAt;
  KycReviewOutcome? pendingOutcome;
  int checksUntilDecision = 0;
  bool timeoutServed = false;
}

/// What the host persists for recovery: an opaque attempt reference per
/// account. No KYC data, PIN or credentials are stored.
class RecoveryStore {
  final Map<String, String> _attemptByAccount = {};

  void save(String account, String attemptId) =>
      _attemptByAccount[account] = attemptId;
  String? load(String account) => _attemptByAccount[account];
  void clear(String account) => _attemptByAccount.remove(account);
}
