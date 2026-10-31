import 'package:flutter/foundation.dart';

import '../foundation/money.dart';

enum QuoteLineKind { item, fee, discount, tax }

@immutable
class QuoteLine {
  const QuoteLine({
    required this.label,
    required this.amount,
    this.kind = QuoteLineKind.item,
    this.detail,
  });

  final String label;
  final Money amount;
  final QuoteLineKind kind;
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is QuoteLine &&
      other.label == label &&
      other.amount == amount &&
      other.kind == kind &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(label, amount, kind, detail);
}

/// A priced snapshot from the host. The UI renders [total] as given and never
/// recomputes it; consistency is the host's responsibility.
@immutable
class PaymentQuote {
  const PaymentQuote({
    required this.id,
    required this.revision,
    required this.lines,
    required this.total,
    required this.expiresAt,
    this.methodId,
  });

  final String id;
  final int revision;

  /// Items, fees, discounts and taxes in display order. Fees are always shown.
  final List<QuoteLine> lines;
  final Money total;
  final DateTime expiresAt;

  /// The payment method this quote was priced for, if method-specific.
  final String? methodId;

  Iterable<QuoteLine> get items =>
      lines.where((l) => l.kind == QuoteLineKind.item);
  Iterable<QuoteLine> get adjustments =>
      lines.where((l) => l.kind != QuoteLineKind.item);

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// True when the customer-visible terms differ, so prior consent no longer
  /// covers this quote.
  bool termsDifferFrom(PaymentQuote other) =>
      total != other.total ||
      methodId != other.methodId ||
      !listEquals(lines, other.lines);
}

enum PaymentMethodKind { balance, virtualAccount, card, eWallet, other }

@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.label,
    required this.kind,
    this.detail,
    this.unavailableReason,
    this.feeNote,
  });

  final String id;
  final String label;
  final PaymentMethodKind kind;

  /// Masked secondary text such as "Balance Rp250.000" or "•••• 4242".
  final String? detail;

  /// When non-null the method is shown disabled with this host-provided reason.
  final String? unavailableReason;
  final String? feeNote;

  bool get isAvailable => unavailableReason == null;
}

/// Business status reported by the host after the server knows the payment.
enum PaymentStatus {
  requiresAction,
  processing,
  pending,
  succeeded,
  failed,
  canceled,
  expired;

  bool get isTerminal =>
      this == succeeded ||
      this == failed ||
      this == canceled ||
      this == expired;

  /// Parses a wire value; returns null for unknown values so adapters can
  /// reject the snapshot instead of inventing an outcome.
  static PaymentStatus? tryParse(String? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

/// Refund lifecycle, tracked separately so a refund never rewrites the
/// original payment result.
enum RefundStatus { none, pending, partial, refunded, failed }

@immutable
class RefundInfo {
  const RefundInfo({
    required this.status,
    this.amount,
    this.updatedAt,
    this.safeReason,
  });

  final RefundStatus status;
  final Money? amount;
  final DateTime? updatedAt;
  final String? safeReason;
}

/// Actions the host currently allows for an attempt.
enum PaymentAction {
  checkStatus,
  viewInstructions,
  requestCancel,
  startNewAttempt,
  viewReceipt,
  contactSupport,
}

@immutable
class VirtualAccountInstructions {
  const VirtualAccountInstructions({
    required this.providerLabel,
    required this.accountNumber,
    required this.amount,
    required this.expiresAt,
    this.steps = const [],
  });

  final String providerLabel;
  final String accountNumber;
  final Money amount;
  final DateTime expiresAt;
  final List<String> steps;
}

/// An authoritative status snapshot produced by the host adapter.
@immutable
class PaymentStatusSnapshot {
  const PaymentStatusSnapshot({
    required this.attemptId,
    required this.serverReference,
    required this.status,
    required this.revision,
    required this.updatedAt,
    this.allowedActions = const {},
    this.safeReason,
    this.refund = const RefundInfo(status: RefundStatus.none),
    this.instructions,
    this.isCorrection = false,
  });

  final String attemptId;
  final String serverReference;
  final PaymentStatus status;

  /// Monotonic server revision used to order snapshots.
  final int revision;
  final DateTime updatedAt;
  final Set<PaymentAction> allowedActions;
  final String? safeReason;
  final RefundInfo refund;
  final VirtualAccountInstructions? instructions;

  /// An official provider correction, the only way a succeeded payment may
  /// change to another business status.
  final bool isCorrection;
}

/// What the client knows about its own submission, independent of the
/// business status.
enum SubmissionState {
  /// Prepared but not sent; may still be abandoned.
  notSent,

  /// One submit call is in flight.
  sending,

  /// The server acknowledged the attempt with a reference.
  accepted,

  /// Sent, but no answer arrived. The server may have charged; only a host
  /// status check with the same attempt reference can resolve this.
  outcomeUnknown,
}

/// Freshness of the last observed status.
enum Observation { fresh, refreshing, unavailable }

/// Local record of one payment attempt.
///
/// [attemptId] is the client-side identity the host uses as idempotency
/// reference; it stays the same for every retry or reconciliation of this
/// attempt.
@immutable
class PaymentAttempt {
  const PaymentAttempt({
    required this.attemptId,
    required this.quoteId,
    required this.quoteRevision,
    required this.methodId,
    this.submission = SubmissionState.notSent,
    this.snapshot,
    this.observation = Observation.fresh,
    this.lastCheckedAt,
  });

  final String attemptId;
  final String quoteId;
  final int quoteRevision;
  final String methodId;
  final SubmissionState submission;

  /// Last trusted snapshot; kept when a refresh fails so the UI can show the
  /// last-known state.
  final PaymentStatusSnapshot? snapshot;
  final Observation observation;
  final DateTime? lastCheckedAt;

  PaymentStatus? get status => snapshot?.status;
  String? get serverReference => snapshot?.serverReference;

  bool get isUnresolved =>
      submission == SubmissionState.sending ||
      submission == SubmissionState.outcomeUnknown ||
      (snapshot != null && !snapshot!.status.isTerminal);

  /// A new attempt is allowed only when the host says so and this attempt's
  /// result is final and not a success.
  bool get allowsNewAttempt {
    final s = snapshot;
    return submission == SubmissionState.accepted &&
        s != null &&
        s.status.isTerminal &&
        s.status != PaymentStatus.succeeded &&
        s.allowedActions.contains(PaymentAction.startNewAttempt);
  }

  /// Actions to offer. Never includes [PaymentAction.startNewAttempt] while
  /// the outcome is unresolved.
  Set<PaymentAction> get availableActions {
    if (submission == SubmissionState.outcomeUnknown || snapshot == null) {
      return submission == SubmissionState.notSent
          ? const {}
          : const {PaymentAction.checkStatus};
    }
    final actions = {...snapshot!.allowedActions};
    if (!allowsNewAttempt) actions.remove(PaymentAction.startNewAttempt);
    return actions;
  }

  PaymentAttempt copyWith({
    SubmissionState? submission,
    PaymentStatusSnapshot? snapshot,
    Observation? observation,
    DateTime? lastCheckedAt,
  }) {
    return PaymentAttempt(
      attemptId: attemptId,
      quoteId: quoteId,
      quoteRevision: quoteRevision,
      methodId: methodId,
      submission: submission ?? this.submission,
      snapshot: snapshot ?? this.snapshot,
      observation: observation ?? this.observation,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  /// Applies an incoming snapshot using the ordering rules the host adapter
  /// must uphold. Returns the updated attempt, or the unchanged attempt plus
  /// a reason when the snapshot is ignored.
  ReconcileResult reconcile(PaymentStatusSnapshot incoming) {
    if (incoming.attemptId != attemptId) {
      return ReconcileResult.rejected(this, ReconcileRejection.wrongAttempt);
    }
    final current = snapshot;
    if (current != null) {
      if (current.serverReference != incoming.serverReference) {
        return ReconcileResult.rejected(
          this,
          ReconcileRejection.referenceMismatch,
        );
      }
      if (incoming.revision <= current.revision) {
        return ReconcileResult.rejected(this, ReconcileRejection.stale);
      }
      if (current.status == PaymentStatus.succeeded &&
          incoming.status != PaymentStatus.succeeded &&
          !incoming.isCorrection) {
        return ReconcileResult.rejected(
          this,
          ReconcileRejection.successDowngrade,
        );
      }
    }
    return ReconcileResult.applied(
      copyWith(
        submission: SubmissionState.accepted,
        snapshot: incoming,
        observation: Observation.fresh,
      ),
    );
  }
}

enum ReconcileRejection {
  wrongAttempt,
  referenceMismatch,
  stale,
  successDowngrade,
}

@immutable
class ReconcileResult {
  const ReconcileResult.applied(this.attempt) : rejection = null;
  const ReconcileResult.rejected(
    this.attempt,
    ReconcileRejection this.rejection,
  );

  final PaymentAttempt attempt;
  final ReconcileRejection? rejection;

  bool get applied => rejection == null;
}

/// Progress of the host-owned authorization challenge (PIN, OTP, biometrics).
/// The library never receives the secret itself.
enum AuthorizationPhase {
  ready,
  inProgress,
  approved,
  canceled,
  failed,
  expired,
}
