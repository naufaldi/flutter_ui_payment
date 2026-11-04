import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// Host presentation for the two states in the synthetic merchant demo.
/// This does not fetch status, retry payment, or create a receipt.
class MerchantTransactionDetail extends StatelessWidget {
  const MerchantTransactionDetail({
    super.key,
    required this.record,
    required this.onClose,
  });

  final TransactionRecord record;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final confirmed = record.status == PaymentStatus.succeeded;
    final group = theme.space(PaymentSpace.group);
    return PaymentSheet(
      header: PaymentSheetHeader(
        title: 'Detail transaksi',
        subtitle: record.reference ?? record.id,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountText(record.amount, variant: AmountTextVariant.display),
          SizedBox(height: theme.space(PaymentSpace.inline)),
          Text(
            record.methodLabel ?? 'Metode tidak tersedia',
            style: type.caption,
          ),
          SizedBox(height: theme.space(PaymentSpace.major)),
          StatusHeader(
            tone: confirmed ? StatusTone.success : StatusTone.warning,
            icon: confirmed ? Icons.check_circle_outline : Icons.help_outline,
            title: confirmed ? 'Pembayaran berhasil' : 'Belum terkonfirmasi',
            hatched: !confirmed,
          ),
          SizedBox(height: theme.space(PaymentSpace.related)),
          Text(
            confirmed
                ? 'Pembayaran ini telah dikonfirmasi.'
                : 'Status pembayaran ini belum dapat dipastikan. Periksa statusnya sebelum meminta pelanggan membayar ulang.',
            style: type.bodyFor(context),
          ),
          SizedBox(height: group),
          Text(
            'Demo · Data sintetis. Tidak ada pembayaran dikirim.',
            style: type.caption,
          ),
        ],
      ),
      footer: PaymentButton(
        label: 'Kembali ke transaksi',
        variant: PaymentButtonVariant.secondary,
        onPressed: onClose,
      ),
    );
  }
}
