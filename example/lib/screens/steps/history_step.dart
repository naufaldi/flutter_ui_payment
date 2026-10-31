import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';

class HistoryStep extends StatelessWidget {
  const HistoryStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final l = PaymentLocalizations.of(context);
    final t = PaymentTheme.of(context);
    final now = c.host.clock();
    final month = DateTime(now.year, now.month);
    final previous = DateTime(now.year, now.month - 1);
    final paid = c.history
        .where(
          (r) =>
              r.status == PaymentStatus.succeeded &&
              !r.createdAt.isBefore(month),
        )
        .toList();
    final total = paid.fold<Money>(const Money.idr(0), (a, r) => a + r.amount);
    final refunded = c.history
        .where((r) => r.refund.amount != null && !r.createdAt.isBefore(month))
        .fold<Money>(const Money.idr(0), (a, r) => a + r.refund.amount!);
    List<ChartPoint> weekly(DateTime start) => [
      for (var w = 0; w < 4; w++)
        ChartPoint(
          label: 'W${w + 1}',
          value: c.history
              .where(
                (r) =>
                    r.status == PaymentStatus.succeeded &&
                    r.createdAt.year == start.year &&
                    r.createdAt.month == start.month &&
                    ((r.createdAt.day - 1) ~/ 7).clamp(0, 3) == w,
              )
              .fold<Money>(const Money.idr(0), (a, r) => a + r.amount),
        ),
    ];
    final methods = <String, int>{};
    for (final r in paid) {
      if (r.methodLabel != null) {
        methods.update(r.methodLabel!, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final ranked = methods.keys.toList()
      ..sort((a, b) => methods[b]!.compareTo(methods[a]!));
    final active =
        c.historyRange != null ||
        c.historyFilter != TransactionFilter.all ||
        c.historyQuery.isNotEmpty;
    return PaymentFullPageView(
      title: s.transactions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.space(PaymentSpace.group),
        children: [
          PaymentOverviewPage(
            primary: [
              ChartModule(
                title: s.spendingTitle,
                state: c.historyLoading ? ChartState.loading : ChartState.ready,
                headline: total,
                headlineCaption: s.thisMonth,
                chart: SizedBox(
                  height: 200,
                  child: PaymentBarChart(
                    series: [
                      PaymentChartSeries(
                        label: s.thisMonth,
                        points: weekly(month),
                      ),
                      PaymentChartSeries(
                        label: s.lastMonth,
                        points: weekly(previous),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            secondary: [
              PaymentDetailPagePropertyList(
                title: s.thisMonth,
                pending: c.historyLoading,
                items: [
                  PaymentDetailProperty(
                    label: 'Payments',
                    values: [PaymentDetailValue('${paid.length}')],
                  ),
                  PaymentDetailProperty(
                    label: 'Refunds',
                    values: [
                      PaymentDetailValue(
                        MoneyFormat(s.languageCode).format(refunded),
                      ),
                    ],
                  ),
                  PaymentDetailProperty(
                    label: 'Most used',
                    values: [PaymentDetailValue(ranked.firstOrNull ?? '—')],
                  ),
                ],
              ),
            ],
          ),
          PaymentDateRangePicker(
            label: s.dateRange,
            value: c.historyRange,
            onChanged: c.setHistoryRange,
            firstDate: DateTime(2026),
            lastDate: now,
            presets: [
              PaymentDatePreset(
                label: s.last7Days,
                start: DateUtils.dateOnly(
                  now,
                ).subtract(const Duration(days: 6)),
                end: now,
              ),
              PaymentDatePreset(
                label: s.presetThisMonth,
                start: month,
                end: now,
              ),
              PaymentDatePreset(
                label: s.presetLastMonth,
                start: previous,
                end: month.subtract(const Duration(days: 1)),
              ),
            ],
          ),
          if (active) ...[
            PaymentChipList(
              children: [
                if (c.historyRange != null)
                  PaymentChip(
                    label: s.filterDate,
                    value: l.formatDateRange(
                      c.historyRange!.start,
                      c.historyRange!.end,
                    ),
                    onClose: () => c.setHistoryRange(null),
                  ),
                if (c.historyFilter != TransactionFilter.all)
                  PaymentChip(
                    label: s.filterStatus,
                    value: l.transactionFilterLabel(c.historyFilter),
                    onClose: () => c.setHistoryFilter(TransactionFilter.all),
                  ),
                if (c.historyQuery.isNotEmpty)
                  PaymentChip(
                    label: s.filterSearch,
                    value: c.historyQuery,
                    onClose: () => c.setHistoryQuery(''),
                  ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PaymentLink(
                label: s.clearAll,
                onPressed: c.clearHistoryFilters,
              ),
            ),
          ],
          if (c.historyRange != null &&
              c.visibleHistory.isEmpty &&
              c.historyQuery.isEmpty &&
              c.historyFilter == TransactionFilter.all)
            PaymentBanner(
              tone: StatusTone.info,
              title: s.noTransactionsTitle,
              message: s.noTransactionsMessage,
              actions: [
                PaymentLink(
                  label: s.clearAll,
                  onPressed: c.clearHistoryFilters,
                ),
              ],
            ),
          TransactionHistory(
            records: c.visibleHistory,
            query: c.historyQuery,
            filter: c.historyFilter,
            onQueryChanged: c.setHistoryQuery,
            onFilterChanged: c.setHistoryFilter,
            onOpen: (_) => showPaymentToast(context, message: s.transactions),
            loading: c.historyLoading,
            error: c.historyError == null
                ? null
                : c.historyError!.safeMessage ?? s.historyFailed,
            onRetry: c.retryHistory,
          ),
        ],
      ),
    );
  }
}
