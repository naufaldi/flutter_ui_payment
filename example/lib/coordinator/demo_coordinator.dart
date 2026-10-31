import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../adapters/fake_host.dart';
import '../adapters/status_adapter.dart';
import '../scenarios/scenario_config.dart';

enum FlowStep {
  overview,
  kycIntro,
  kycIdentity,
  kycDocuments,
  kycReview,
  kycStatus,
  checkout,
  confirm,
  authorize,
  payment,
  receipt,
}

/// Identity fields and document slot keys used by the demo host policy.
const idCardSlot = 'idCard';
const selfieSlot = 'selfie';

/// Synthetic identity used to seed scenarios; clearly not a real person.
const demoIdentity = {
  'name': 'Sari Wulandari (Demo)',
  'nik': '3100000000001234',
  'dob': '1995-08-17',
  'occupation': 'employee',
};

/// The one owner of demo state. Widgets render its fields and call its
/// methods; the [DemoHost] stands in for backend, provider and device.
///
/// Every async call captures [_epoch]. An account switch or restart bumps it,
/// so responses for the previous context are discarded instead of rendered.
class DemoCoordinator extends ChangeNotifier {
  DemoCoordinator(this.host, {this.account = 'A'});

  final DemoHost host;
  ScenarioConfig get config => host.config;

  String account;
  int _epoch = 0;
  bool _disposed = false;
  FlowStep step = FlowStep.overview;
  bool starting = true;

  /// Covers sensitive content while the app is in the app switcher.
  bool obscured = false;

  /// Short-lived message for the host UI (support handoff, session expiry).
  String? notice;

  // KYC
  VerificationSnapshot kyc = const VerificationSnapshot(
    status: VerificationStatus.notStarted,
  );
  bool kycOutcomeUnknown = false;
  bool kycSubmitting = false;
  VerificationAction? kycBusyAction;
  String? _kycRequestId;

  /// Held in memory only; never written to storage, cleared on account
  /// switch and lost on restart.
  Map<String, String> identity = {};
  Map<String, DocumentSlotState> documents = {
    idCardSlot: const DocumentSlotState.empty(),
    selfieSlot: const DocumentSlotState.empty(),
  };

  // Checkout
  AmountParseResult amount = const AmountParseResult.issue(AmountIssue.empty);
  PaymentQuote? quote;

  /// The quote the customer saw before a re-quote changed its terms.
  PaymentQuote? previousQuote;
  HostError? quoteError;
  bool quoting = false;
  List<PaymentMethod> methods = const [];
  String? selectedMethodId;
  AuthorizationPhase authPhase = AuthorizationPhase.ready;
  bool confirming = false;
  HostError? submitError;

  // Attempt
  PaymentAttempt? attempt;
  Money? attemptAmount;
  PaymentAction? busyAction;
  bool cancelRequested = false;
  bool showInstructions = true;
  PaymentReceiptData? receipt;
  HostError? receiptError;
  bool loadingReceipt = false;

  /// Count of submit calls this coordinator made, shown in the host log.
  int submitEvents = 0;

  StreamSubscription<Map<String, Object?>>? _lateSub;
  Timer? _poll;
  int _pollsLeft = 0;

  PaymentMethod? get selectedMethod {
    final id = PaymentMethodPicker.validSelection(methods, selectedMethodId);
    return methods.where((m) => m.id == id).firstOrNull;
  }

  Money? get _flexibleAmount => config.flexibleAmount ? amount.money : null;

  bool get hasUnresolvedAttempt => attempt?.isUnresolved ?? false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _poll?.cancel();
    _lateSub?.cancel();
    super.dispose();
  }

  void _log(String message) => host.record('[$account] $message');

  /// Runs [call] and returns null if the account/session changed meanwhile.
  ///
  /// Errors are discarded the same way: a timeout that belonged to account A
  /// must not mark account B's attempt as unknown.
  Future<T?> _guard<T>(Future<T> Function() call) async {
    final epoch = _epoch;
    try {
      final result = await call();
      if (epoch == _epoch) return result;
    } catch (_) {
      if (epoch == _epoch) rethrow;
    }
    host.record('Discarded a response that belonged to a previous session');
    return null;
  }

  /// Busy flags are reset only by the call that set them in this session.
  bool _isCurrent(int epoch) => epoch == _epoch;

  HostError _errorOf(Object e) =>
      e is HostException ? e.error : const HostError(HostErrorCategory.unknown);

  void _go(FlowStep next) {
    step = next;
    notice = null;
    if (next != FlowStep.payment) _stopPolling();
    notifyListeners();
  }

  // ------------------------------------------------------------ Launch

  /// App launch (or relaunch after a restart): ask the host for eligibility
  /// and recover an unresolved attempt from its opaque reference.
  Future<void> start() async {
    starting = true;
    notifyListeners();
    _lateSub = host.lateDeliveries.listen(_onLateDelivery);
    if (config.seedAttempt && host.recovery.load(account) == null) {
      host.seedAttempt(account);
    }
    try {
      final snapshot = await _guard(() => host.kycStatus(account));
      if (snapshot != null) kyc = snapshot;
    } catch (_) {
      // Eligibility stays unknown; checkout re-checks with the backend.
    }
    final stored = host.recovery.load(account);
    starting = false;
    if (stored != null) {
      _log('Recovered attempt reference $stored; checking status');
      attempt = PaymentAttempt(
        attemptId: stored,
        quoteId: '',
        quoteRevision: 0,
        methodId: '',
        submission: SubmissionState.outcomeUnknown,
      );
      _go(FlowStep.payment);
      await refreshStatus();
    } else {
      notifyListeners();
    }
  }

  /// Scenario fixture setup: opens [start] with the synthetic data a user
  /// would have entered so far. A recovered attempt always takes precedence.
  Future<void> setUpScenario(FlowStep start) async {
    if (step != FlowStep.overview || start == FlowStep.overview) return;
    final seedDocuments =
        start == FlowStep.kycReview ||
        kyc.status == VerificationStatus.actionRequired;
    if (config.prefillIdentity || seedDocuments) {
      identity = Map.of(demoIdentity);
    }
    if (seedDocuments) {
      documents = {
        idCardSlot: DocumentSlotState.uploaded(
          demoFixtures[0].file,
          requestId: 'upl-seeded-1',
        ),
        selfieSlot: DocumentSlotState.uploaded(
          demoFixtures[1].file,
          requestId: 'upl-seeded-2',
        ),
      };
    }
    if (start == FlowStep.checkout) {
      await openCheckout();
    } else {
      _go(start);
    }
  }

  /// Leaves the flow screen without touching the attempt.
  void goHome() {
    notice = null;
    _go(FlowStep.overview);
  }

  void resumeAttempt() {
    _go(FlowStep.payment);
    unawaited(refreshStatus());
  }

  /// Switches account: earlier responses are dropped and sensitive context
  /// (identity draft, documents, attempt, receipt) is cleared.
  Future<void> switchAccount(String next) async {
    _epoch++;
    _stopPolling();
    account = next;
    _resetSensitive();
    _log('Switched account; previous context cleared');
    _go(FlowStep.overview);
    try {
      final snapshot = await _guard(() => host.kycStatus(account));
      if (snapshot != null) kyc = snapshot;
    } catch (_) {}
    final stored = host.recovery.load(account);
    if (stored != null) {
      attempt = PaymentAttempt(
        attemptId: stored,
        quoteId: '',
        quoteRevision: 0,
        methodId: '',
        submission: SubmissionState.outcomeUnknown,
      );
    }
    notifyListeners();
  }

  void _resetSensitive() {
    identity = {};
    documents = {
      idCardSlot: const DocumentSlotState.empty(),
      selfieSlot: const DocumentSlotState.empty(),
    };
    kyc = const VerificationSnapshot(status: VerificationStatus.notStarted);
    kycOutcomeUnknown = false;
    _kycRequestId = null;
    quote = null;
    previousQuote = null;
    methods = const [];
    selectedMethodId = null;
    attempt = null;
    attemptAmount = null;
    receipt = null;
    receiptError = null;
    submitError = null;
    cancelRequested = false;
    authPhase = AuthorizationPhase.ready;
    notice = null;
    kycSubmitting = false;
    kycBusyAction = null;
    quoting = false;
    quoteError = null;
    confirming = false;
    busyAction = null;
    loadingReceipt = false;
    amount = const AmountParseResult.issue(AmountIssue.empty);
  }

  void setObscured(bool value) {
    if (obscured == value) return;
    obscured = value;
    notifyListeners();
  }

  /// Called when the app returns to the foreground. Refreshes an unresolved
  /// attempt; never submits anything.
  void onResumed() {
    setObscured(false);
    if (step == FlowStep.payment && hasUnresolvedAttempt) {
      _log('App resumed; refreshing attempt status');
      unawaited(refreshStatus());
    }
  }

  // ----------------------------------------------------------------- KYC

  /// Entry from the overview. KYC gates checkout only when host policy says.
  Future<void> beginPurchase() async {
    notice = null;
    if (hasUnresolvedAttempt) {
      resumeAttempt();
      return;
    }
    if (config.kycRequired && kyc.status != VerificationStatus.verified) {
      _go(
        kyc.status == VerificationStatus.notStarted
            ? FlowStep.kycIntro
            : FlowStep.kycStatus,
      );
      return;
    }
    await openCheckout();
  }

  void acceptConsent() => _go(FlowStep.kycIdentity);

  void submitIdentity(Map<String, String> values) {
    identity = values;
    _go(FlowStep.kycDocuments);
  }

  /// Asks the host for capture access. Returns true when the host picker may
  /// be shown; otherwise the slot shows the host's reason.
  Future<bool> requestCapture(String slot) async {
    final access = await _guard(host.requestCaptureAccess);
    if (access == null) return false;
    switch (access) {
      case CaptureAccess.granted:
        return true;
      case CaptureAccess.denied:
        documents = {
          ...documents,
          slot: const DocumentSlotState.failed(
            DocumentIssue(DocumentIssueKind.permissionDenied),
          ),
        };
      case CaptureAccess.permanentlyDenied:
        documents = {
          ...documents,
          slot: const DocumentSlotState.failed(
            DocumentIssue(
              DocumentIssueKind.permissionPermanentlyDenied,
              canRetry: false,
              canOpenSettings: true,
            ),
          ),
        };
    }
    notifyListeners();
    return false;
  }

  Future<void> openSettings(String slot) async {
    await _guard(host.openSettings);
    documents = {...documents, slot: const DocumentSlotState.empty()};
    notifyListeners();
  }

  /// Starts an upload. Selecting another file while one is uploading
  /// replaces it; the older result is ignored by request identity.
  Future<void> uploadCapture(DocumentRequirement req, CaptureKind kind) =>
      uploadDocument(
        req,
        DocumentFile(
          name: kind == CaptureKind.idCard
              ? 'kamera_ktp_demo.jpg'
              : 'kamera_selfie_ktp_demo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1048576,
        ),
      );

  Future<void> uploadDocument(
    DocumentRequirement requirement,
    DocumentFile file,
  ) async {
    final slot = requirement.key;
    final issue = checkDocumentLimits(requirement, file);
    if (issue != null) {
      documents = {
        ...documents,
        slot: DocumentSlotState.failed(issue, file: file),
      };
      notifyListeners();
      return;
    }
    final requestId = host.nextId('upl');
    documents = {
      ...documents,
      slot: DocumentSlotState.uploading(file, requestId: requestId),
    };
    notifyListeners();
    try {
      final done = await _guard(() async {
        await host.upload(requestId, file);
        return true;
      });
      if (done == null) return;
      if (documents[slot]?.requestId != requestId) {
        _log('Ignored finished upload $requestId (file was replaced)');
        return;
      }
      documents = {
        ...documents,
        slot: DocumentSlotState.uploaded(file, requestId: requestId),
      };
    } catch (e) {
      if (documents[slot]?.requestId != requestId) return;
      documents = {
        ...documents,
        slot: DocumentSlotState.failed(
          e is HostException && e.error.category == HostErrorCategory.validation
              ? DocumentIssue(
                  DocumentIssueKind.rejectedByHost,
                  safeMessage: e.error.safeMessage,
                )
              : const DocumentIssue(DocumentIssueKind.uploadInterrupted),
          file: file,
          requestId: requestId,
        ),
      };
    }
    notifyListeners();
  }

  void goToReview() => _go(FlowStep.kycReview);
  void editIdentity() => _go(FlowStep.kycIdentity);
  void editDocuments() => _go(FlowStep.kycDocuments);

  /// One active submission. The request id is reused until the host gives a
  /// definite answer, so a retry after timeout is deduplicated server-side.
  Future<void> submitKyc() async {
    if (kycSubmitting) return;
    final epoch = _epoch;
    kycSubmitting = true;
    _kycRequestId ??= host.nextId('kyc');
    notifyListeners();
    try {
      final snapshot = await _guard(
        () => host.submitKyc(account, _kycRequestId!, identity),
      );
      if (snapshot == null) return;
      kyc = snapshot;
      kycOutcomeUnknown = false;
      _go(FlowStep.kycStatus);
    } catch (e) {
      final error = _errorOf(e);
      if (error.outcomeUnknown) {
        _log('KYC submit timed out; outcome unknown, resubmit locked');
        kycOutcomeUnknown = true;
        _go(FlowStep.kycStatus);
      } else {
        notice = error.safeMessage;
      }
    } finally {
      if (_isCurrent(epoch)) {
        kycSubmitting = false;
        notifyListeners();
      }
    }
  }

  Future<void> kycAction(VerificationAction action) async {
    switch (action) {
      case VerificationAction.start:
        _kycRequestId = null;
        _go(FlowStep.kycIntro);
      case VerificationAction.fixDetails:
        _kycRequestId = null;
        // Keep valid documents; only the flagged slots must be redone.
        for (final key in kyc.fieldsToFix) {
          if (documents.containsKey(key)) {
            documents = {...documents, key: const DocumentSlotState.empty()};
          }
        }
        _go(identity.isEmpty ? FlowStep.kycIdentity : FlowStep.kycDocuments);
      case VerificationAction.checkStatus:
        if (kycBusyAction != null) return;
        final epoch = _epoch;
        kycBusyAction = action;
        notifyListeners();
        try {
          final snapshot = await _guard(() => host.kycStatus(account));
          if (snapshot != null) {
            kyc = snapshot;
            kycOutcomeUnknown = false;
          }
        } catch (_) {
          // Keep the last known status; the action stays available.
        } finally {
          if (_isCurrent(epoch)) {
            kycBusyAction = null;
            notifyListeners();
          }
        }
      case VerificationAction.contactSupport:
        _log('Support handoff requested (simulated)');
        notice = 'support';
        notifyListeners();
      case VerificationAction.continueToPayment:
        await openCheckout();
    }
  }

  // ------------------------------------------------------------ Checkout

  Future<void> openCheckout() async {
    _go(FlowStep.checkout);
    final loaded = await _guard(host.methods);
    if (loaded == null) return;
    methods = loaded;
    // Drop a selection the host no longer offers.
    selectedMethodId =
        PaymentMethodPicker.validSelection(methods, selectedMethodId) ??
        methods.where((m) => m.isAvailable).firstOrNull?.id;
    notifyListeners();
    if (!config.flexibleAmount) await loadQuote();
  }

  void setAmount(AmountParseResult result) {
    amount = result;
    if (quote != null) quote = null;
    notifyListeners();
  }

  Future<void> selectMethod(PaymentMethod method) async {
    if (selectedMethodId == method.id) return;
    selectedMethodId = method.id;
    notifyListeners();
    if (quote != null || !config.flexibleAmount) await loadQuote();
  }

  Future<void> loadQuote() async {
    final method = selectedMethod;
    if (method == null || quoting) return;
    if (config.flexibleAmount && !amount.isValid) return;
    final epoch = _epoch;
    quoting = true;
    quoteError = null;
    notifyListeners();
    try {
      final next = await _guard(
        () => host.quote(methodId: method.id, amount: _flexibleAmount),
      );
      if (next != null) quote = next;
    } catch (e) {
      quoteError = _errorOf(e);
    } finally {
      if (_isCurrent(epoch)) {
        quoting = false;
        notifyListeners();
      }
    }
  }

  void reviewOrder() {
    if (quote == null || selectedMethod == null) return;
    previousQuote = null;
    submitError = null;
    _go(FlowStep.confirm);
  }

  /// Confirm on the review screen: the host revalidates the quote first. A
  /// change in terms keeps the customer on review until they accept it.
  Future<void> confirm() async {
    final current = quote;
    if (current == null || confirming) return;
    final epoch = _epoch;
    confirming = true;
    submitError = null;
    notifyListeners();
    try {
      final latest = await _guard(
        () => host.revalidate(current, amount: _flexibleAmount),
      );
      if (latest == null) return;
      if (latest.termsDifferFrom(current)) {
        previousQuote = current;
        quote = latest;
        authPhase = AuthorizationPhase.ready;
        return;
      }
      quote = latest;
      previousQuote = null;
      authPhase = AuthorizationPhase.ready;
      _go(FlowStep.authorize);
    } catch (e) {
      submitError = _errorOf(e);
    } finally {
      if (_isCurrent(epoch)) {
        confirming = false;
        notifyListeners();
      }
    }
  }

  void backToReview() {
    authPhase = AuthorizationPhase.ready;
    _go(FlowStep.confirm);
  }

  /// Host challenge. Only an approval leads to a submit.
  Future<void> authorize() async {
    if (authPhase == AuthorizationPhase.inProgress) return;
    authPhase = AuthorizationPhase.inProgress;
    notifyListeners();
    final result = await _guard(host.authorize);
    // Leaving the challenge screen (or switching account) voids its result.
    if (result == null || step != FlowStep.authorize) return;
    authPhase = result;
    _log('Authorization result: ${result.name}');
    notifyListeners();
    if (result == AuthorizationPhase.approved) await _submit();
  }

  Future<void> _submit() async {
    final q = quote;
    final method = selectedMethod;
    if (q == null || method == null) return;
    if (attempt != null && attempt!.isUnresolved) {
      _log('Submit ignored: an attempt is still unresolved');
      return;
    }
    final attemptId = host.nextId('att');
    // Persist the opaque reference before sending so a crash can reconcile.
    host.recovery.save(account, attemptId);
    attempt = PaymentAttempt(
      attemptId: attemptId,
      quoteId: q.id,
      quoteRevision: q.revision,
      methodId: method.id,
      submission: SubmissionState.sending,
    );
    attemptAmount = q.total;
    cancelRequested = false;
    submitEvents++;
    _log('Submit #$submitEvents with idempotency key $attemptId');
    _go(FlowStep.payment);
    try {
      final json = await _guard(
        () => host.submitPayment(
          account: account,
          attemptId: attemptId,
          quote: q,
          methodId: method.id,
        ),
      );
      if (json == null) return;
      _applyStatus(parseStatus(json));
      _startPolling();
    } catch (e) {
      final error = _errorOf(e);
      if (error.category == HostErrorCategory.sessionExpired ||
          error.category == HostErrorCategory.notAllowed ||
          error.category == HostErrorCategory.conflict) {
        // The host states nothing was recorded: drop this attempt and go back.
        host.recovery.clear(account);
        attempt = null;
        submitError = error;
        authPhase = AuthorizationPhase.ready;
        _go(FlowStep.confirm);
      } else {
        // Timeout, offline, garbled answer: the server may have charged.
        _log(
          'Submit outcome unknown (${error.category.name}); pay-again locked',
        );
        attempt = attempt!.copyWith(submission: SubmissionState.outcomeUnknown);
      }
    }
    notifyListeners();
  }

  void _applyStatus(ParsedStatus parsed) {
    final current = attempt;
    if (current == null) return;
    final result = current.reconcile(parsed.snapshot);
    if (!result.applied) {
      _log(
        'Ignored snapshot r${parsed.snapshot.revision} '
        '(${result.rejection!.name})',
      );
      attempt = current.copyWith(observation: Observation.fresh);
      return;
    }
    attempt = result.attempt.copyWith(lastCheckedAt: host.clock());
    attemptAmount = parsed.amount;
    final status = attempt!.status!;
    if (status.isTerminal) {
      // Final result known: polling and the recovery reference can stop.
      _stopPolling();
      host.recovery.clear(account);
    }
  }

  void _onLateDelivery(Map<String, Object?> json) {
    if (attempt == null) return;
    try {
      _applyStatus(parseStatus(json));
      notifyListeners();
    } catch (_) {
      _log('Late delivery rejected by adapter');
    }
  }

  /// Host-owned polling, main flow only: a few checks, stopped when the
  /// result is final or the customer leaves the status screen.
  void _startPolling() {
    if (!config.hostPolls) return;
    _pollsLeft = 4;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _poll?.cancel();
    if (_disposed || _pollsLeft <= 0 || !hasUnresolvedAttempt) return;
    _poll = Timer(
      Duration(milliseconds: (1500 * DemoHost.latencyScale).round()),
      () async {
        _pollsLeft--;
        await refreshStatus();
        _scheduleNextPoll();
      },
    );
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
    _pollsLeft = 0;
  }

  /// Status check with the same attempt reference. Never submits, and never
  /// stacks: a check already in flight absorbs repeated taps.
  Future<void> refreshStatus() async {
    final current = attempt;
    if (current == null ||
        current.observation == Observation.refreshing ||
        current.submission == SubmissionState.sending) {
      return;
    }
    attempt = current.copyWith(observation: Observation.refreshing);
    notifyListeners();
    try {
      final json = await _guard(() => host.paymentStatus(current.attemptId));
      if (json == null) return;
      _applyStatus(parseStatus(json));
    } catch (e) {
      final error = _errorOf(e);
      _log('Status check failed (${error.category.name}); keeping last-known');
      if (attempt != null) {
        attempt = attempt!.copyWith(observation: Observation.unavailable);
      }
    }
    notifyListeners();
  }

  Future<void> paymentAction(PaymentAction action) async {
    switch (action) {
      case PaymentAction.checkStatus:
        await refreshStatus();
      case PaymentAction.viewInstructions:
        showInstructions = true;
        notifyListeners();
      case PaymentAction.requestCancel:
        final current = attempt;
        if (busyAction != null || current == null) return;
        final epoch = _epoch;
        busyAction = action;
        notifyListeners();
        try {
          await _guard(() => host.requestCancel(current.attemptId));
          if (_isCurrent(epoch)) cancelRequested = true;
        } catch (_) {
          // The request may not have arrived; status stays host-owned.
        } finally {
          if (_isCurrent(epoch)) {
            busyAction = null;
            notifyListeners();
          }
        }
        if (_isCurrent(epoch)) await refreshStatus();
      case PaymentAction.startNewAttempt:
        if (!(attempt?.allowsNewAttempt ?? false)) return;
        _log('New attempt allowed by host; previous attempt is final');
        host.recovery.clear(account);
        attempt = null;
        attemptAmount = null;
        await openCheckout();
      case PaymentAction.viewReceipt:
        _go(FlowStep.receipt);
        await loadReceipt();
      case PaymentAction.contactSupport:
        _log('Support handoff requested (simulated)');
        notice = 'support';
        notifyListeners();
    }
  }

  /// Instructions countdown reached zero: ask the host instead of deciding.
  void onInstructionsElapsed() {
    _log('Instructions expired locally; asking host for final status');
    unawaited(refreshStatus());
  }

  // ------------------------------------------------------------- Receipt

  Future<void> loadReceipt() async {
    final current = attempt;
    if (current == null || loadingReceipt) return;
    final epoch = _epoch;
    loadingReceipt = true;
    receiptError = null;
    notifyListeners();
    try {
      final data = await _guard(() => host.receipt(current.attemptId));
      if (data != null) receipt = data;
    } catch (e) {
      receiptError = _errorOf(e);
    } finally {
      if (_isCurrent(epoch)) {
        loadingReceipt = false;
        notifyListeners();
      }
    }
  }

  Future<ShareOutcome> share(ReceiptShareData data) => host.share(data);

  Future<bool> copy(String value) async {
    if (config.clipboardFails) return false;
    try {
      await Clipboard.setData(ClipboardData(text: value));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ends the demo purchase after a final result.
  void finish() {
    if (!hasUnresolvedAttempt) {
      host.recovery.clear(account);
      attempt = null;
      attemptAmount = null;
      receipt = null;
      quote = null;
      previousQuote = null;
    }
    goHome();
  }
}
