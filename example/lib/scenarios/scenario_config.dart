import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// Bilingual text: host-provided copy and scenario picker descriptions.
class Bi {
  const Bi(this.en, this.id);
  final String en;
  final String id;
  String of(String languageCode) => languageCode == 'id' ? id : en;
}

/// Deterministic knobs for the simulated host. Every scenario in the picker is
/// one of these plus a starting point; nothing here depends on randomness.
enum KycSubmitOutcome { inReview, timeoutThenInReview }

enum KycReviewOutcome { verified, actionRequired, rejected }

enum CaptureAccess { granted, denied, permanentlyDenied }

enum QuoteBehavior { stable, failOnce, expiredAtConfirm, totalChangesAtConfirm }

enum MethodSet { standard, empty, someUnavailable, insufficientBalance }

enum AuthOutcome { approve, cancel, fail, expire }

enum SubmitBehavior { accepted, slow, responseLost, sessionExpired }

enum ServerFault { none, offline, invalidData }

enum ShareBehavior { shared, dismissed, failed }

/// One server-side step returned by a status check.
class ServerStep {
  const ServerStep(
    this.status, {
    this.actions,
    this.reason,
    this.refund = const RefundInfo(status: RefundStatus.none),
    this.replayStale = false,
  }) : fault = ServerFault.none;

  /// A check that fails or misbehaves without changing server state.
  const ServerStep.fault(this.fault)
    : status = null,
      actions = null,
      reason = null,
      replayStale = false,
      refund = const RefundInfo(status: RefundStatus.none);

  final PaymentStatus? status;
  final Set<PaymentAction>? actions;
  final Bi? reason;
  final RefundInfo refund;
  final ServerFault fault;

  /// After answering, the provider also delivers a duplicate and an older
  /// snapshot late, as webhooks sometimes do.
  final bool replayStale;
}

class ScenarioConfig {
  const ScenarioConfig({
    this.kycRequired = true,
    this.signedOut = false,
    this.signInCancelsOnce = false,
    this.historyEmpty = false,
    this.historyFailsOnce = false,
    this.initialKyc = VerificationStatus.notStarted,
    this.kycReason,
    this.kycFieldsToFix = const {},
    this.kycSubmit = KycSubmitOutcome.inReview,
    this.kycReview = KycReviewOutcome.verified,
    this.captureAccess = const [CaptureAccess.granted],
    this.interruptFirstUpload = false,
    this.rejectFirstCapture = false,
    this.uploadDuration = const Duration(milliseconds: 900),
    this.prefillIdentity = false,
    this.flexibleAmount = false,
    this.quote = QuoteBehavior.stable,
    this.methods = MethodSet.standard,
    this.auth = AuthOutcome.approve,
    this.submit = SubmitBehavior.accepted,
    this.script = const [
      ServerStep(PaymentStatus.processing),
      ServerStep(PaymentStatus.succeeded),
    ],
    this.vaScript = const [
      ServerStep(PaymentStatus.pending),
      ServerStep(PaymentStatus.succeeded),
    ],
    this.vaExpiry = const Duration(hours: 23, minutes: 59),
    this.hostPolls = false,
    this.seedAttempt = false,
    this.seedMethodId = 'balance',
    this.receiptFailsOnce = false,
    this.share = ShareBehavior.shared,
    this.clipboardFails = false,
    this.slowStatusCheck = false,
    this.sessionExpiredOnce = false,
    this.longLabels = false,
  });

  final bool kycRequired;
  final bool signedOut, signInCancelsOnce, historyEmpty, historyFailsOnce;
  final VerificationStatus initialKyc;
  final Bi? kycReason;
  final Set<String> kycFieldsToFix;
  final KycSubmitOutcome kycSubmit;
  final KycReviewOutcome kycReview;

  /// Answers to successive capture-permission requests; the last repeats.
  final List<CaptureAccess> captureAccess;
  final bool interruptFirstUpload;
  final bool rejectFirstCapture;
  final Duration uploadDuration;

  /// Starts KYC with synthetic data the host still holds (actionRequired).
  final bool prefillIdentity;

  final bool flexibleAmount;
  final QuoteBehavior quote;
  final MethodSet methods;
  final AuthOutcome auth;
  final SubmitBehavior submit;

  /// Server statuses for the balance method: submit returns the first step,
  /// each status check advances one step and stays on the last.
  final List<ServerStep> script;
  final List<ServerStep> vaScript;
  final Duration vaExpiry;

  /// The host coordinator polls a few times after submit (main flow only).
  final bool hostPolls;

  /// Starts with an attempt already stored by the host, as after a restart.
  final bool seedAttempt;
  final String seedMethodId;
  final bool receiptFailsOnce;
  final ShareBehavior share;
  final bool clipboardFails;

  /// Status checks take 3 s so an account switch can overtake them.
  final bool slowStatusCheck;

  /// The first payment submit is rejected because the session expired.
  final bool sessionExpiredOnce;
  final bool longLabels;
}
