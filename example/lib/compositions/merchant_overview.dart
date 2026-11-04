import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// Copyable host data, not a new kit model or a ledger.
/// The host supplies authoritative totals and the unresolved count separately
/// from the short recent-transactions preview.
class MerchantOverviewData {
  const MerchantOverviewData({
    required this.merchant,
    required this.balance,
    required this.revenue,
    required this.period,
    required this.points,
    required this.methods,
    required this.recent,
    required this.unconfirmedCount,
  });

  final String merchant;
  final Money? balance;
  final Money revenue;
  final String period;
  final List<ChartPoint> points;
  final List<MeterSegment> methods;
  final List<TransactionRecord> recent;
  final int unconfirmedCount;
}

/// Scaffold-free block: the host owns navigation, fetching and status checks.
/// Uses only public library APIs; safe to copy into a different host app.
class MerchantOverview extends StatelessWidget {
  const MerchantOverview({
    super.key,
    required this.data,
    required this.onInspectUnconfirmed,
    required this.onViewTransactions,
    required this.onOpenTransaction,
    required this.onOpenAccount,
  });

  final MerchantOverviewData data;
  final VoidCallback onInspectUnconfirmed;
  final VoidCallback onViewTransactions;
  final ValueChanged<TransactionRecord> onOpenTransaction;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final gap = theme.space(PaymentSpace.group);
    return ListView(
      key: const PageStorageKey('merchant-overview'),
      padding: EdgeInsets.all(gap),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.merchant, style: type.title),
                  Text('Ruang Bayar · Demo', style: type.caption),
                ],
              ),
            ),
            PaymentIconButton(
              icon: Icons.person_outline,
              tooltip: 'Akun toko',
              onPressed: onOpenAccount,
            ),
          ],
        ),
        const PaymentDivider(),
        SizedBox(height: gap),
        Text('Saldo tersedia', style: type.caption),
        SizedBox(height: theme.space(PaymentSpace.related)),
        if (data.balance case final balance?)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(balance, variant: AmountTextVariant.display),
          )
        else
          Text('Saldo belum tersedia', style: type.body),
        SizedBox(height: gap),
        if (data.unconfirmedCount > 0) ...[
          PaymentBanner(
            tone: StatusTone.warning,
            icon: Icons.help_outline,
            title: '${data.unconfirmedCount} pembayaran perlu dicek',
            message: 'Belum terkonfirmasi. Jangan minta bayar ulang.',
            actions: [
              PaymentLink(
                label: 'Periksa transaksi',
                onPressed: onInspectUnconfirmed,
              ),
            ],
          ),
          SizedBox(height: gap),
        ],
        ChartModule(
          title: 'Pemasukan',
          state: data.points.isEmpty ? ChartState.empty : ChartState.ready,
          headline: data.revenue,
          emptyTitle: 'Belum ada pemasukan',
          emptyMessage: 'Pembayaran terkonfirmasi akan muncul di sini.',
          chart: PaymentBarChart(points: data.points, showLegend: false),
        ),
        Text(data.period, style: type.caption),
        const PaymentDivider(),
        PaymentSection(
          title: 'Metode pembayaran',
          child: data.methods.isEmpty
              ? Text('Belum ada metode tercatat.', style: type.caption)
              : PaymentMeterChart(
                  segments: data.methods,
                  unit: PaymentChartUnit.percent,
                ),
        ),
        const PaymentDivider(),
        PaymentSection(
          title: 'Transaksi terbaru',
          trailing: PaymentLink(
            label: 'Lihat semua',
            onPressed: onViewTransactions,
            variant: PaymentLinkVariant.secondary,
          ),
          child: data.recent.isEmpty
              ? Text(
                  'Belum ada transaksi. Pembayaran pertama akan tampil di sini.',
                  style: type.body,
                )
              : Column(
                  children: [
                    for (final record in data.recent) ...[
                      TransactionListItem(
                        record: record,
                        onTap: () => onOpenTransaction(record),
                      ),
                      const PaymentDivider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
