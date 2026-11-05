import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Copyable host block. Supply already-filtered records; the host owns query,
/// loading, safe error messages and retrieval. No network or ledger logic.
class MerchantHistory extends StatelessWidget {
  const MerchantHistory({
    super.key,
    required this.records,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onOpen,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<TransactionRecord> records;
  final String query;
  final TransactionFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final ValueChanged<TransactionRecord> onOpen;
  final bool loading;
  final String? error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return ListView(
      padding: EdgeInsets.all(theme.space(PaymentSpace.group)),
      children: [
        Text('Riwayat transaksi', style: type.title),
        SizedBox(height: theme.space(PaymentSpace.inline)),
        Text(
          'Cari referensi dan telusuri status pembayaran.',
          style: type.caption,
        ),
        SizedBox(height: theme.space(PaymentSpace.group)),
        TransactionHistory(
          records: records,
          query: query,
          filter: filter,
          onQueryChanged: onQueryChanged,
          onFilterChanged: onFilterChanged,
          onOpen: onOpen,
          loading: loading,
          error: error,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

/// Read-only inspection works for every kit transaction/refund status.
/// Closing never cancels or resubmits a payment. Add authoritative host status
/// check/receipt callbacks only when your integration actually supplies them.
class MerchantHistoryDetail extends StatelessWidget {
  const MerchantHistoryDetail({
    super.key,
    required this.record,
    required this.onClose,
  });
  final TransactionRecord record;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => PaymentSheet(
    header: PaymentSheetHeader(title: 'Detail transaksi', subtitle: record.id),
    body: TransactionDetail(record: record),
    footer: PaymentButton(
      label: 'Kembali ke riwayat',
      variant: PaymentButtonVariant.secondary,
      onPressed: onClose,
    ),
  );
}
