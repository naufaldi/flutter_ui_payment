import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rakit_ui/rakit_ui.dart';

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
  final String? error;

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
                  (_, final String message, _) => StateMessage(
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
              child: _PageFooter(
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

class _PageFooter extends StatefulWidget {
  const _PageFooter({
    required this.label,
    required this.loading,
    required this.error,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final String? error;
  final VoidCallback onPressed;

  @override
  State<_PageFooter> createState() => _PageFooterState();
}

class _PageFooterState extends State<_PageFooter> {
  @override
  void didUpdateWidget(_PageFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != null || widget.error == null) return;

    final footer = context.findRenderObject()! as RenderBox;
    final viewport = RenderAbstractViewport.of(footer);
    final position = Scrollable.of(context).position;
    final top = viewport.getOffsetToReveal(footer, 0).offset;
    // Don't pull the reader back to the footer if they scrolled away.
    if (top + footer.size.height <= position.pixels ||
        top >= position.pixels + position.viewportDimension) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.error == null) return;
      position.ensureVisible(
        footer,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(PaymentSpace.related),
      children: [
        PaymentButton(
          label: widget.label,
          variant: PaymentButtonVariant.secondary,
          busy: widget.loading,
          onPressed: widget.onPressed,
        ),
        if (widget.error case final String message)
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              message,
              style: PaymentType.of(
                context,
              ).bodyFor(context).copyWith(color: theme.textSecondary),
            ),
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
