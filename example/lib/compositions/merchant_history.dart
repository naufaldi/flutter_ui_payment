import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'paged_block_footer.dart';

/// Copyable paged history. Give it a bounded viewport and the accumulated rows
/// for the active query. The host owns the cursor, loading and safe errors.
class MerchantHistory extends StatelessWidget {
  const MerchantHistory({
    super.key,
    required this.records,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onResetFilters,
    required this.onOpen,
    required this.hasMore,
    required this.onRequestPage,
    this.loading = false,
    this.error,
  });

  final List<TransactionRecord> records;
  final String query;
  final TransactionFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<TransactionRecord> onOpen;
  final bool hasMore;
  final bool loading;

  /// Safe display copy and a distinct attempt number for each failed request.
  final ({String message, int attempt})? error;

  /// Requests the next page or retries the failed page without moving its cursor.
  final VoidCallback onRequestPage;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l10n = PaymentLocalizations.of(context);
    final filters = TransactionFilter.values;
    final folded =
        PaymentType.isLarge(context) &&
        MediaQuery.sizeOf(context).shortestSide < 600;
    final activeStatus = filter != TransactionFilter.all;
    final narrowed = query.trim().isNotEmpty || activeStatus;
    final id = Localizations.localeOf(context).languageCode == 'id';
    final loadMore = id ? 'Muat lagi' : 'Load more';
    final group = theme.space(PaymentSpace.group);
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(group, group, group, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  id ? 'Riwayat transaksi' : 'Transaction history',
                  style: type.title,
                ),
                SizedBox(height: theme.space(PaymentSpace.inline)),
                Text(
                  id
                      ? 'Cari referensi dan telusuri status pembayaran.'
                      : 'Search by reference and explore payment statuses.',
                  style: type.caption,
                ),
                SizedBox(height: group),
                PaymentTextField.search(
                  query: query,
                  onChanged: onQueryChanged,
                  label: l10n.searchTransactions,
                  hiddenElements: folded
                      ? const {PaymentFieldPart.label}
                      : const {},
                  actions: [
                    if (folded)
                      MergeSemantics(
                        child: Semantics(
                          selected: activeStatus,
                          value: l10n.transactionFilterLabel(filter),
                          child: PaymentMenu(
                            entries: [
                              for (final status in filters)
                                PaymentMenuItem(
                                  label: l10n.transactionFilterLabel(status),
                                  icon: status == filter ? Icons.check : null,
                                  semanticLabel: status == filter
                                      ? '${l10n.transactionFilterLabel(status)}, ${l10n.selected}'
                                      : null,
                                  onSelected: () => onFilterChanged(status),
                                ),
                            ],
                            trigger: (toggle, focus) => PaymentIconButton(
                              focusNode: focus,
                              icon: activeStatus
                                  ? Icons.filter_list_alt
                                  : Icons.filter_list,
                              tooltip: l10n.filterByStatus,
                              variant: activeStatus
                                  ? PaymentIconButtonVariant.accent
                                  : PaymentIconButtonVariant.neutral,
                              onPressed: toggle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!folded) ...[
                  SizedBox(height: theme.space(PaymentSpace.related)),
                  PaymentTabs(
                    tabs: [
                      for (final status in filters)
                        PaymentTab(label: l10n.transactionFilterLabel(status)),
                    ],
                    selectedIndex: filters.indexOf(filter),
                    onSelected: (index) => onFilterChanged(filters[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (records.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: group),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                container: true,
                liveRegion: true,
                child: switch ((loading, error, narrowed)) {
                  (true, _, _) => const LoadingSkeleton(
                    rows: 4,
                    leading: false,
                  ),
                  (_, (:final message, :final attempt), _) => StateMessage(
                    key: ValueKey(attempt),
                    icon: Icons.cloud_off_outlined,
                    tone: StatusTone.danger,
                    title: l10n.transactionsFailedTitle,
                    message: message,
                    actionLabel: l10n.retry,
                    onAction: onRequestPage,
                  ),
                  (_, _, true) => StateMessage(
                    icon: Icons.search_off,
                    title: l10n.noMatchesTitle,
                    message: l10n.noMatchesMessage,
                    actionLabel: l10n.resetFilters,
                    onAction: onResetFilters,
                  ),
                  _ => StateMessage(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.noTransactionsTitle,
                    message: l10n.noTransactionsMessage,
                  ),
                },
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: group),
            sliver: SliverList.separated(
              itemCount: records.length,
              separatorBuilder: (_, _) => const PaymentDivider(),
              itemBuilder: (_, index) {
                final record = records[index];
                return TransactionListItem(
                  key: ValueKey(record.id),
                  record: record,
                  onTap: () => onOpen(record),
                );
              },
            ),
          ),
        if (hasMore)
          SliverPadding(
            padding: EdgeInsets.all(group),
            sliver: SliverToBoxAdapter(
              child: PagedBlockFooter(
                label: error == null ? loadMore : l10n.retry,
                loading: loading,
                error: error,
                onPressed: onRequestPage,
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: group)),
      ],
    );
  }
}

/// Inspection works for every kit transaction/refund status. Reporting is an
/// optional host action and does not cancel or resubmit a payment.
class MerchantHistoryDetail extends StatelessWidget {
  const MerchantHistoryDetail({
    super.key,
    required this.record,
    required this.onClose,
    this.onReport,
  });
  final TransactionRecord record;
  final VoidCallback onClose;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    // This detail has no editor. Keep the keyboard for an overlaid report
    // from squeezing the detail behind it.
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: PaymentSheet(
        header: PaymentSheetHeader(
          title: 'Detail transaksi',
          subtitle: record.id,
        ),
        body: TransactionDetail(record: record),
        footer: PaymentButtonGroup(
          direction: Axis.vertical,
          children: [
            if (onReport != null)
              PaymentButton(
                label: id ? 'Laporkan masalah' : 'Report a problem',
                variant: PaymentButtonVariant.quiet,
                onPressed: onReport,
              ),
            PaymentButton(
              label: 'Kembali ke riwayat',
              variant: PaymentButtonVariant.secondary,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
