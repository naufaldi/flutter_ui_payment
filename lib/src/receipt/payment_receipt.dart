import '../content/property_list.dart';
import '../controls/actions.dart';
import 'package:flutter/material.dart';

import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../payment/payment_models.dart';
import '../payment/payment_status.dart';
import 'receipt_models.dart';

/// Receipt for a payment the host confirmed as succeeded.
///
/// Sharing hands the host only [ReceiptShareData] built from an allowlist.
/// A failed or dismissed share never changes the receipt or the payment.
class PaymentReceipt extends StatefulWidget {
  const PaymentReceipt({
    super.key,
    required this.data,
    this.onShare,
    this.onCopyTransactionId,
  });

  final PaymentReceiptData data;
  final Future<ShareOutcome> Function(ReceiptShareData data)? onShare;
  final Future<bool> Function(String transactionId)? onCopyTransactionId;

  @override
  State<PaymentReceipt> createState() => _PaymentReceiptState();
}

class _PaymentReceiptState extends State<PaymentReceipt> {
  String? _feedback;
  StatusTone _feedbackTone = StatusTone.neutral;

  void _show(String message, StatusTone tone) => setState(() {
    _feedback = message;
    _feedbackTone = tone;
  });

  Future<void> _share() async {
    final l10n = PaymentLocalizations.of(context);
    final data = ReceiptShareData.fromReceipt(
      widget.data,
      title: l10n.receiptShareTitle(widget.data.merchantName),
      labels: {
        'merchant': l10n.merchant,
        'transactionId': l10n.transactionReference,
        'paidAt': l10n.paidAt,
        'total': l10n.totalLabel,
        'method': l10n.paymentMethod,
      },
      moneyFormat: l10n.moneyFormat,
      formatDate: l10n.formatDateTime,
    );
    final outcome = await widget.onShare!(data);
    if (!mounted) return;
    switch (outcome) {
      case ShareOutcome.shared:
        _show(l10n.shareDone, StatusTone.success);
      case ShareOutcome.dismissed:
        _show(l10n.shareDismissed, StatusTone.neutral);
      case ShareOutcome.failed:
        _show(l10n.shareFailed, StatusTone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The same header as the status view: a solid band, then the state
        // in words, so a receipt reads as a settled result at a glance.
        StatusHeader(
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
          title: l10n.statusSucceededTitle,
        ),
        SizedBox(height: theme.spacing * 1.5),
        Text(
          data.merchantName,
          style: type.label.copyWith(color: theme.textSecondary),
        ),
        SizedBox(height: theme.spacing * 0.5),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AmountText(data.total, variant: AmountTextVariant.display),
        ),
        SizedBox(height: theme.spacing * 0.5),
        Text(l10n.formatDateTime(data.paidAt), style: type.caption),
        SizedBox(height: theme.spacing * 2),
        PaymentSection(
          title: l10n.detailsTitle,
          child: Column(
            children: [
              PaymentPropertyList(
                items: [
                  for (final line in data.lines)
                    PaymentPropertyListItem(
                      label: line.label,
                      value: AmountText(line.amount),
                    ),
                ],
              ),
              PaymentDivider(height: theme.spacing * 2),
              PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(
                    label: l10n.totalLabel,
                    emphasis: true,
                    value: AmountText(
                      data.total,
                      variant: AmountTextVariant.total,
                    ),
                  ),
                  PaymentPropertyListItem(
                    label: l10n.paymentMethod,
                    valueText: data.methodLabel,
                  ),
                  // The ID and its label share the top line; the copy button
                  // centers beside them instead of pushing the ID down.
                  PaymentPropertyListItem(
                    label: l10n.transactionReference,
                    value: SelectableText(
                      data.transactionId,
                      textAlign: TextAlign.end,
                      style: type.label.reference(theme),
                    ),
                    trailing: widget.onCopyTransactionId == null
                        ? null
                        : PaymentCopyButton(
                            value: data.transactionId,
                            onCopy: widget.onCopyTransactionId!,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (data.refund.status != RefundStatus.none) ...[
          PaymentDivider(height: theme.spacing * 3),
          RefundSection(refund: data.refund, paidAmount: data.total),
        ],
        if (_feedback != null) ...[
          SizedBox(height: theme.spacing * 1.5),
          PaymentBanner(tone: _feedbackTone, title: _feedback!, announce: true),
        ],
        if (widget.onShare != null) ...[
          SizedBox(height: theme.spacing * 2),
          PaymentButton(
            label: l10n.shareReceipt,
            variant: PaymentButtonVariant.secondary,
            onPressed: _share,
          ),
          SizedBox(height: theme.spacing),
          Text(l10n.shareAllowlistNote, style: type.caption),
        ],
      ],
    );
  }
}
