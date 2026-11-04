import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// Copyable host composition for paying into a virtual account.
///
/// Every value is host data: the attempt and its snapshot, the account
/// number, exact amount and deadline. The deadline only tells the payer when
/// to transfer by. Reaching it is never a payment verdict: the status stays
/// whatever the host last reported and Check status remains available for
/// the same attempt. While the issuing response is unknown the kit hides the
/// account, so nobody is invited to transfer to an unconfirmed number.
class ManualTransferBlock extends StatelessWidget {
  const ManualTransferBlock({
    super.key,
    required this.attempt,
    required this.amount,
    required this.invoice,
    required this.payerLabel,
    required this.clock,
    required this.onCheckStatus,
    required this.onCopy,
    this.checking = false,
    this.onDone,
  });

  final PaymentAttempt attempt;
  final Money amount;

  /// Invoice and merchant, shown as supporting context above the status.
  final String invoice;

  /// Already masked by the host, e.g. "Akun •••• 2190".
  final String payerLabel;
  final DateTime Function() clock;
  final Future<void> Function() onCheckStatus;

  /// Host clipboard: return false when copying failed.
  final Future<bool> Function(String value) onCopy;
  final bool checking;

  /// Shown as the quiet footer action once the host reports a final status.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final va = attempt.snapshot?.instructions;
    final done =
        attempt.snapshot?.status == PaymentStatus.succeeded && onDone != null;
    return PaymentStatusView(
      attempt: attempt,
      amount: amount,
      busyAction: checking ? PaymentAction.checkStatus : null,
      onAction: (action) => switch (action) {
        PaymentAction.checkStatus => onCheckStatus(),
        // Only actions the host allowed reach here; this block offers none
        // that starts a new attempt or pays again.
        _ => null,
      },
      header: Padding(
        padding: EdgeInsets.only(bottom: theme.space(PaymentSpace.block)),
        child: Text('$invoice · $payerLabel', style: type.caption),
      ),
      instructions: va == null
          ? null
          : PaymentInstructions(
              instructions: va,
              clock: clock,
              onCopyNumber: onCopy,
            ),
      secondaryAction: done
          ? PaymentButton(
              label: 'Selesai',
              variant: PaymentButtonVariant.quiet,
              onPressed: onDone,
            )
          : null,
    );
  }
}
