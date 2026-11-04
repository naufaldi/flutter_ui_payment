import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'block_demo_shell.dart';
import 'compositions/payment_refund_detail.dart';

void main() => runBlockDemo(const RefundDetailDemo());

enum RefundDemoScenario { partial, full, refreshFails }

final refundPaidAt = DateTime(2026, 11, 3, 15, 10);
const refundOriginalAmount = Money.idr(240000);

/// Synthetic refund host. Refund states are declared fixture answers; the
/// demo never initiates a refund and calls no network.
class RefundDetailDemo extends StatefulWidget {
  const RefundDetailDemo({
    super.key,
    this.initialScenario = RefundDemoScenario.partial,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 500),
  });
  final RefundDemoScenario initialScenario;
  final bool initialDark;
  final Duration delay;

  @override
  State<RefundDetailDemo> createState() => _RefundDetailDemoState();
}

class _RefundDetailDemoState extends State<RefundDetailDemo> {
  late bool dark = widget.initialDark;
  late RefundDemoScenario scenario = widget.initialScenario;
  late RefundInfo refund = requested;
  bool refreshing = false;
  String? refreshError;
  int refreshes = 0;
  int generation = 0;

  Money get requestedAmount => scenario == RefundDemoScenario.full
      ? refundOriginalAmount
      : const Money.idr(50000);

  RefundInfo get requested => RefundInfo(
    status: RefundStatus.pending,
    amount: requestedAmount,
    updatedAt: DateTime(2026, 11, 4, 9, 15),
    safeReason:
        'Merchant menyetujui refund. Bank biasanya memproses dalam '
        '3–7 hari kerja.',
  );

  bool get settled =>
      refund.status == RefundStatus.partial ||
      refund.status == RefundStatus.refunded;

  void reset(RefundDemoScenario value) => setState(() {
    generation++;
    scenario = value;
    refund = requested;
    refreshing = false;
    refreshError = null;
    refreshes = 0;
  });

  Future<void> refresh() async {
    if (refreshing) return;
    final current = generation;
    final count = ++refreshes;
    setState(() {
      refreshing = true;
      refreshError = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      refreshing = false;
      if (scenario == RefundDemoScenario.refreshFails && count == 1) {
        refreshError =
            'Menampilkan status terakhir yang diketahui. Coba lagi nanti.';
        return;
      }
      refund = RefundInfo(
        status: scenario == RefundDemoScenario.full
            ? RefundStatus.refunded
            : RefundStatus.partial,
        amount: requestedAmount,
        updatedAt: DateTime(2026, 11, 4, 10, 42),
        safeReason: 'Dana dikembalikan ke rekening asal pembayaran.',
      );
    });
  }

  TransactionRecord get record => TransactionRecord(
    id: 'INV-2044',
    title: 'Paket Belajar Pro',
    merchant: 'Ruang Bayar Akademi',
    reference: 'TX-DEMO-55302044',
    amount: refundOriginalAmount,
    createdAt: refundPaidAt,
    methodLabel: 'Transfer •••• 2190',
    // The original payment stays succeeded in every refund state.
    status: PaymentStatus.succeeded,
    refund: refund,
  );

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Refund · Demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    scenarios: [
      for (final (value, label) in [
        (RefundDemoScenario.partial, 'Refund sebagian'),
        (RefundDemoScenario.full, 'Refund penuh'),
        (RefundDemoScenario.refreshFails, 'Cek refund gagal'),
      ])
        (label: label, onSelected: () => reset(value)),
    ],
    body: (context) => PaymentRefundDetail(
      key: ValueKey(generation),
      record: record,
      refundReference: 'RF-•••-4821',
      refreshing: refreshing,
      refreshError: refreshError,
      onRefreshRefund: settled ? null : refresh,
      onCopyReference: copyToClipboard,
      onViewReceipt: () => showPaymentSheet<void>(
        context: context,
        builder: (sheet) => PaymentRefundReceiptSheet(
          data: PaymentReceiptData(
            transactionId: record.reference!,
            merchantName: record.merchant!,
            paidAt: refundPaidAt,
            lines: const [
              QuoteLine(label: 'Paket Belajar Pro', amount: Money.idr(236000)),
              QuoteLine(
                label: 'Biaya bank',
                amount: Money.idr(4000),
                kind: QuoteLineKind.fee,
              ),
            ],
            total: refundOriginalAmount,
            methodLabel: record.methodLabel!,
            refund: refund,
          ),
          onClose: () => Navigator.pop(sheet),
        ),
      ),
    ),
  );
}
