// Copyable host composition, not kit API. The host restores the attempt,
// reconciles snapshots, loads receipts and implements all platform effects.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// One restored payment, rendered from the host's current state.
///
/// Use in a bounded Scaffold body to keep the priority action pinned. Wrap
/// it in the product's theme (for example ProductLooks from host_checkout.dart).
/// No quote, attempt, status or receipt is created by this composition.
class HostPaymentRecovery extends StatelessWidget {
  const HostPaymentRecovery({
    super.key,
    required this.attempt,
    required this.amount,
    required this.onAction,
    required this.onDone,
    required this.onShare,
    required this.onCopy,
    this.receipt,
    this.busyAction,
    this.header,
  });

  final PaymentAttempt attempt;
  final Money amount;

  /// Reconcile or load a receipt for this ID; never submit a new payment
  /// when handling checkStatus. Return the future to retain busy protection.
  final FutureOr<void> Function(String attemptId, PaymentAction action)
  onAction;
  final VoidCallback onDone;
  final Future<ShareOutcome> Function(ReceiptShareData) onShare;
  final Future<bool> Function(String) onCopy;

  /// Host-loaded data for the current transaction. Unconfirmed or mismatched
  /// data stays hidden, including after an official correction of success.
  final PaymentReceiptData? receipt;
  final PaymentAction? busyAction;

  /// Host notices, such as a safe receipt-loading error. Status refresh
  /// failures use attempt.observation and retain the last trusted snapshot.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final indonesian = Localizations.localeOf(context).languageCode == 'id';
    final data = receipt;
    final confirmed =
        attempt.submission == SubmissionState.accepted &&
        attempt.status == PaymentStatus.succeeded;
    if (confirmed &&
        data != null &&
        data.transactionId == attempt.serverReference) {
      return PaymentFullPageView(
        title: indonesian ? 'Struk pembayaran' : 'Payment receipt',
        primaryAction: PaymentButton(
          label: indonesian ? 'Selesai' : 'Done',
          onPressed: onDone,
        ),
        child: PaymentReceipt(
          data: data,
          onShare: onShare,
          onCopyTransactionId: onCopy,
        ),
      );
    }
    return PaymentStatusView(
      attempt: attempt,
      amount: amount,
      header: header,
      busyAction: busyAction,
      onAction: (action) => onAction(attempt.attemptId, action),
    );
  }
}
