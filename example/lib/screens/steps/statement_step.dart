import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';
import '../../adapters/account_models.dart';

class StatementStep extends StatelessWidget {
  const StatementStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    Future<void> download(Set<String> ids) async {
      await c.downloadSettlements(ids);
      if (context.mounted) {
        showPaymentToast(context, message: s.prepared(ids.length));
      }
    }

    return PaymentFullPageView(
      title: s.statementTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).space(PaymentSpace.group),
        children: [
          PaymentTextField.search(
            query: c.settlementQuery,
            onChanged: c.setSettlementQuery,
            label: s.searchSettlements,
          ),
          PaymentDataTable<Settlement>(
            caption: s.statementTitle,
            columns: [
              PaymentDataColumn(
                key: 'id',
                label: 'ID',
                value: (r) => r.id,
                cell: PaymentCellType.id,
                pinned: true,
              ),
              PaymentDataColumn(
                key: 'date',
                label: 'Date',
                value: (r) => r.date,
                cell: PaymentCellType.date,
                sortable: true,
              ),
              PaymentDataColumn(
                key: 'description',
                label: 'Description',
                value: (r) => r.description,
              ),
              PaymentDataColumn(
                key: 'status',
                label: 'Status',
                value: (r) => r.status,
                cell: PaymentCellType.status,
                statusMap: const {
                  'Paid': StatusTone.success,
                  'Pending': StatusTone.warning,
                  'Failed': StatusTone.danger,
                },
              ),
              PaymentDataColumn(
                key: 'amount',
                label: 'Amount',
                value: (r) => r.amount,
                cell: PaymentCellType.currency,
                sortable: true,
              ),
            ],
            rows: c.settlements,
            rowKey: (r) => r.id,
            pagination: const PaymentPagination.local(pageSize: 10),
            initialSort: const PaymentDataSort('date', ascending: false),
            filter: (r, q) =>
                r.id.toLowerCase().contains(q.toLowerCase()) ||
                r.description.toLowerCase().contains(q.toLowerCase()),
            filterQuery: c.settlementQuery,
            selection: c.selectedSettlements,
            onSelectionChanged: c.setSelectedSettlements,
            batchActions: [
              PaymentButton(
                label: s.downloadSelected(c.selectedSettlements.length),
                variant: PaymentButtonVariant.secondary,
                size: PaymentSize.small,
                onPressed: () => download(c.selectedSettlements),
              ),
            ],
            rowActions: [
              PaymentRowAction(
                id: 'download',
                label: s.download,
                onPressed: (r) => download({r.id}),
              ),
            ],
            emptyMessage: PaymentEmptyMessage(
              s.noSettlementsTitle,
              message: s.noSettlementsMessage,
              actionLabel: s.clearSearch,
              onAction: () => c.setSettlementQuery(''),
            ),
          ),
        ],
      ),
    );
  }
}
