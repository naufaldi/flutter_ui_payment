import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';
import '../../adapters/account_models.dart';
import 'report_problem.dart';

class TransactionDetailStep extends StatelessWidget {
  const TransactionDetailStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final l = PaymentLocalizations.of(context);
    final r = c.detail;
    if (r == null) return const LoadingSkeleton();
    final statuses = {
      l.paymentStatusShort(PaymentStatus.succeeded): StatusTone.success,
      l.paymentStatusShort(PaymentStatus.failed): StatusTone.danger,
      l.paymentStatusShort(PaymentStatus.pending): StatusTone.warning,
      l.paymentStatusShort(null): StatusTone.neutral,
    };
    return PaymentDetailPage(
      title: s.detailTitle(l.moneyFormat.format(r.amount), r.merchant),
      description: '${r.methodLabel} · ${l.formatDate(r.createdAt)}',
      breadcrumbs: [
        PaymentBreadcrumb(label: s.transactions, onPressed: c.openHistory),
      ],
      actions: [
        PaymentButton(
          key: const Key('view-receipt'),
          label: s.viewReceipt,
          variant: PaymentButtonVariant.secondary,
          onPressed: r.id == c.attempt?.attemptId
              ? c.closeDetail
              : () => showPaymentToast(context, message: s.viewReceipt),
        ),
        PaymentButton(
          key: const Key('report-problem'),
          label: s.reportProblem,
          variant: PaymentButtonVariant.secondary,
          onPressed: () => showReportProblem(context, c, r),
        ),
      ],
      pending: c.detailLoading,
      primary: [
        PaymentPageModule(
          title: s.paymentModule,
          child: TransactionDetail(record: r, onCopyReference: c.copy),
        ),
        PaymentDetailPageTable<AttemptRow>(
          title: s.attempts,
          pending: c.detailLoading,
          columns: [
            PaymentDataColumn(
              key: 'id',
              label: s.columnId,
              value: (r) => r.id,
              cell: PaymentCellType.id,
              pinned: true,
            ),
            PaymentDataColumn(
              key: 'date',
              label: s.columnDate,
              value: (r) => r.at,
              cell: PaymentCellType.date,
            ),
            PaymentDataColumn(
              key: 'method',
              label: s.columnMethod,
              value: (r) => r.method,
            ),
            PaymentDataColumn(
              key: 'status',
              label: s.columnStatus,
              value: (r) => l.paymentStatusShort(r.status),
              cell: PaymentCellType.status,
              statusMap: statuses,
            ),
            PaymentDataColumn(
              key: 'amount',
              label: s.columnAmount,
              value: (r) => r.amount,
              cell: PaymentCellType.currency,
            ),
          ],
          rows: c.detailAttempts,
          rowKey: (r) => r.id,
        ),
      ],
      secondary: [
        PaymentDetailPagePropertyList(
          title: s.merchant,
          pending: false,
          items: [
            PaymentDetailProperty(
              label: s.propertyName,
              values: [PaymentDetailValue(r.merchant ?? 'Toko Contoh')],
            ),
            PaymentDetailProperty(
              label: s.propertyOrder,
              values: [
                PaymentDetailValue('DEMO-42', reference: true, onCopy: c.copy),
              ],
            ),
            PaymentDetailProperty(
              label: s.propertySupport,
              values: [
                PaymentDetailValue.link(
                  PaymentLink(
                    label: s.helpCentre,
                    external: true,
                    onPressed: () =>
                        showPaymentToast(context, message: s.supportOpened),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
