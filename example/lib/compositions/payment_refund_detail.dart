import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Copyable host composition: a confirmed payment with its refund lifecycle.
///
/// The original payment keeps its success and amount in every refund state;
/// the refund is a separate section whose status, amount and reference come
/// from the host. The person can ask the host for a newer refund status and
/// open a read-only receipt. This block never starts, edits or cancels a
/// refund.
class PaymentRefundDetail extends StatelessWidget {
  const PaymentRefundDetail({
    super.key,
    required this.record,
    required this.refundReference,
    required this.onViewReceipt,
    required this.onCopyReference,
    this.onRefreshRefund,
    this.refreshing = false,
    this.refreshError,
  });

  /// The original payment as the host confirmed it, with its refund.
  final TransactionRecord record;

  /// Already masked by the host, e.g. "RF-•••-4821".
  final String refundReference;
  final VoidCallback onViewReceipt;

  /// Host clipboard for the payment reference: false when copying failed.
  final Future<bool> Function(String reference) onCopyReference;

  /// Asks the host for a newer refund status; null once the refund is final.
  final Future<void> Function()? onRefreshRefund;
  final bool refreshing;

  /// Shown above the detail; the last known refund status stays in place.
  final String? refreshError;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final receipt = PaymentButton(
      label: 'Lihat struk',
      variant: onRefreshRefund == null
          ? PaymentButtonVariant.primary
          : PaymentButtonVariant.quiet,
      // The sheet stays open while its Future runs; keep the button idle.
      onPressed: () {
        onViewReceipt();
      },
    );
    return PaymentFullPageView(
      title: 'Detail pembayaran',
      primaryAction: onRefreshRefund == null
          ? receipt
          : PaymentButton(
              label: 'Perbarui status refund',
              busy: refreshing,
              busyLabel: 'Memeriksa refund…',
              onPressed: onRefreshRefund,
            ),
      secondaryAction: onRefreshRefund == null ? null : receipt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (refreshError != null) ...[
            PaymentBanner(
              tone: StatusTone.neutral,
              icon: Icons.cloud_off_outlined,
              title: 'Status refund belum diperbarui',
              message: refreshError,
            ),
            SizedBox(height: theme.space(PaymentSpace.group)),
          ],
          TransactionDetail(record: record, onCopyReference: onCopyReference),
          SizedBox(height: theme.space(PaymentSpace.related)),
          PaymentPropertyList(
            items: [
              PaymentPropertyListItem(
                label: 'Referensi refund',
                valueText: refundReference,
                reference: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Read-only receipt for the original payment, opened in a sheet.
class PaymentRefundReceiptSheet extends StatelessWidget {
  const PaymentRefundReceiptSheet({
    super.key,
    required this.data,
    required this.onClose,
  });
  final PaymentReceiptData data;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => PaymentSheet(
    header: PaymentSheetHeader(title: 'Struk pembayaran', onClose: onClose),
    // No share or copy here: the host offers only effects it implements.
    body: PaymentReceipt(data: data),
    footer: PaymentButton(
      label: 'Tutup',
      variant: PaymentButtonVariant.secondary,
      onPressed: onClose,
    ),
  );
}
