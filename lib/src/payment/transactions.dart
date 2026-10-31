import 'dart:async';

import 'package:flutter/material.dart';

import '../controls/controls.dart';
import '../foundation/row_shell.dart';
import '../foundation/focus_ring.dart';
import '../foundation/kit_strings.dart';
import '../foundation/money.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../interaction/interaction.dart';
import 'payment_models.dart';
import 'payment_status.dart';

/// One past or ongoing payment as the host's history API reports it.
///
/// A presentation record, not a ledger entry: the host maps its own data
/// into it. [status] null means the host does not know the outcome yet
/// (for example a submit whose response was lost), which is shown as
/// "not confirmed", never as failed.
@immutable
class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
    required this.status,
    this.merchant,
    this.methodLabel,
    this.reference,
    this.refund = const RefundInfo(status: RefundStatus.none),
  });

  final String id;
  final String title;
  final Money amount;
  final DateTime createdAt;
  final PaymentStatus? status;
  final String? merchant;
  final String? methodLabel;
  final String? reference;
  final RefundInfo refund;

  /// Whether this record belongs in [filter]'s group.
  bool matches(TransactionFilter filter) => switch (filter) {
    TransactionFilter.all => true,
    TransactionFilter.inProgress => status == null || !status!.isTerminal,
    TransactionFilter.succeeded => status == PaymentStatus.succeeded,
    TransactionFilter.unsuccessful =>
      status == PaymentStatus.failed ||
          status == PaymentStatus.canceled ||
          status == PaymentStatus.expired,
    TransactionFilter.refunds => refund.status != RefundStatus.none,
  };

  /// Local search and filter for hosts that already hold the records.
  /// Hosts that search on the server pass their results straight to
  /// [TransactionHistory] instead.
  static List<TransactionRecord> where(
    Iterable<TransactionRecord> records, {
    String query = '',
    TransactionFilter filter = TransactionFilter.all,
  }) {
    final q = query.trim().toLowerCase();
    return [
      for (final r in records)
        if (r.matches(filter) &&
            (q.isEmpty ||
                r.title.toLowerCase().contains(q) ||
                (r.merchant?.toLowerCase().contains(q) ?? false) ||
                (r.reference?.toLowerCase().contains(q) ?? false)))
          r,
    ];
  }
}

(StatusTone, IconData) _statusLook(PaymentStatus? status) => switch (status) {
  null => (StatusTone.warning, Icons.help_outline),
  PaymentStatus.requiresAction => (StatusTone.info, Icons.touch_app_outlined),
  PaymentStatus.processing => (StatusTone.info, Icons.sync),
  PaymentStatus.pending => (StatusTone.warning, Icons.schedule),
  PaymentStatus.succeeded => (StatusTone.success, Icons.check_circle_outline),
  PaymentStatus.failed => (StatusTone.danger, Icons.error_outline),
  PaymentStatus.canceled => (StatusTone.neutral, Icons.block),
  PaymentStatus.expired => (StatusTone.neutral, Icons.timer_off_outlined),
};

(StatusTone, IconData) _refundLook(RefundStatus status) => switch (status) {
  RefundStatus.none => (StatusTone.neutral, Icons.remove),
  RefundStatus.pending => (StatusTone.warning, Icons.schedule),
  RefundStatus.partial => (StatusTone.info, Icons.call_split),
  RefundStatus.refunded => (StatusTone.success, Icons.undo),
  RefundStatus.failed => (StatusTone.danger, Icons.error_outline),
};

/// A row in a transaction list: what, when, how much and its status.
///
/// Success is the quiet default and carries no tag; every other state gets
/// one. A refund gets its own tag and never strikes the original amount.
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({super.key, required this.record, this.onTap});

  final TransactionRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final status = record.status;
    final (tone, icon) = _statusLook(status);
    final refunded = record.refund.status != RefundStatus.none;
    final settled = status == PaymentStatus.succeeded;
    // Strike-through means "no money moved" and is reserved for failed and
    // canceled payments; a refund keeps the original amount readable.
    final struck =
        status == PaymentStatus.failed || status == PaymentStatus.canceled;
    final stacked = PaymentType.isLarge(context);
    // People scan the list for the name; the amount aligns by its tabular
    // figures, not by weight.
    final title = Text(
      record.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: type.heading,
    );
    // Only settled payments read as money that moved; everything else stays
    // in the secondary color so it is not mistaken for a completed debit.
    final amount = AmountText(
      record.amount,
      style: TextStyle(
        color: settled ? theme.textPrimary : theme.textSecondary,
        decoration: struck ? TextDecoration.lineThrough : null,
      ),
    );
    final (refundTone, refundIcon) = _refundLook(record.refund.status);
    final tags = [
      if (!settled)
        StatusBadge(
          tone: tone,
          icon: icon,
          label: l10n.paymentStatusShort(status),
        ),
      if (refunded)
        StatusBadge(
          tone: refundTone,
          icon: refundIcon,
          label: l10n.refundStatusLabel(record.refund.status),
        ),
    ];
    return MergeSemantics(
      child: RowShell(
        onTap: onTap,
        centerShortRows: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large text stacks the amount under the title so neither
            // squeezes the other into breaking mid-word.
            if (stacked) ...[
              title,
              Align(alignment: AlignmentDirectional.centerStart, child: amount),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  SizedBox(width: theme.spacing * 2),
                  amount,
                ],
              ),
            SizedBox(height: theme.spacing * 0.5),
            // Two lines so the date is never elided at large text.
            Text(
              [
                ?record.merchant,
                l10n.formatDateTime(record.createdAt),
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: type.caption,
            ),
            // A success row shows no tag, but screen readers still hear
            // the status, as they do for every other row.
            if (settled)
              Semantics(
                label: l10n.paymentStatusShort(status),
                child: const SizedBox.shrink(),
              ),
            if (tags.isNotEmpty) ...[
              SizedBox(height: theme.spacing),
              Wrap(
                spacing: theme.spacing,
                runSpacing: theme.spacing * 0.5,
                children: tags,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search, filters and a list of transactions with loading, empty, "no
/// matches" and error states.
///
/// Fully controlled: the host owns [query], [filter] and [records] (local or
/// from its API) and gets [onQueryChanged] and [onFilterChanged]. Records are
/// laid out in a column for pages of up to a few dozen; for longer lists,
/// build [TransactionListItem]s in a `ListView.builder`.
class TransactionHistory extends StatefulWidget {
  const TransactionHistory({
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
    this.filters = TransactionFilter.values,
  });

  /// Already filtered for [query] and [filter].
  final List<TransactionRecord> records;
  final String query;
  final TransactionFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final ValueChanged<TransactionRecord> onOpen;
  final bool loading;

  /// Safe message when the host could not load the list.
  final String? error;
  final FutureOr<void> Function()? onRetry;
  final List<TransactionFilter> filters;

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  late final _search = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(TransactionHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _search.text) _search.text = widget.query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final narrowed =
        widget.query.trim().isNotEmpty ||
        widget.filter != TransactionFilter.all;

    Widget content;
    if (widget.loading) {
      content = const LoadingSkeleton(rows: 4, leading: false);
    } else if (widget.error != null) {
      content = StateMessage(
        icon: Icons.cloud_off_outlined,
        tone: StatusTone.danger,
        title: l10n.transactionsFailedTitle,
        message: widget.error,
        actionLabel: widget.onRetry == null ? null : l10n.retry,
        onAction: widget.onRetry,
      );
    } else if (widget.records.isEmpty) {
      content = narrowed
          ? StateMessage(
              icon: Icons.search_off,
              title: l10n.noMatchesTitle,
              message: l10n.noMatchesMessage,
              actionLabel: l10n.resetFilters,
              onAction: () {
                widget.onQueryChanged('');
                widget.onFilterChanged(TransactionFilter.all);
              },
            )
          : StateMessage(
              icon: Icons.receipt_long_outlined,
              title: l10n.noTransactionsTitle,
              message: l10n.noTransactionsMessage,
            );
    } else {
      content = Column(
        children: [
          for (final (i, r) in widget.records.indexed) ...[
            if (i > 0) const PaymentDivider(),
            TransactionListItem(record: r, onTap: () => widget.onOpen(r)),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentFocusRing(
          radius: theme.controlBorderRadius,
          child: TextField(
            controller: _search,
            onChanged: widget.onQueryChanged,
            textInputAction: TextInputAction.search,
            style: type.input,
            decoration: InputDecoration(
              labelText: l10n.searchTransactions,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () => widget.onQueryChanged(''),
                    ),
              border: OutlineInputBorder(
                borderRadius: theme.controlBorderRadius,
              ),
              // A control edge, not a rule, so it meets 3:1.
              enabledBorder: OutlineInputBorder(
                borderRadius: theme.controlBorderRadius,
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: theme.controlBorderRadius,
                borderSide: BorderSide(color: theme.accent, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: theme.spacing),
        PaymentTabs(
          labels: [
            for (final f in widget.filters) l10n.transactionFilterLabel(f),
          ],
          selectedIndex: widget.filters.indexOf(widget.filter),
          onSelected: (i) => widget.onFilterChanged(widget.filters[i]),
        ),
        Semantics(liveRegion: true, container: true, child: content),
      ],
    );
  }
}

/// Clips horizontally to the box but leaves 4 px above and below, the room a
/// focus ring needs.
/// Details of one transaction. The original payment and any refund are
/// shown as separate sections; host actions go in [actions].
class TransactionDetail extends StatelessWidget {
  const TransactionDetail({
    super.key,
    required this.record,
    this.actions = const [],
  });

  final TransactionRecord record;

  /// Host-chosen actions such as "View receipt" or "Check status". For an
  /// unconfirmed payment, offer a status check, never paying again.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final (tone, icon) = _statusLook(record.status);
    final unknown = record.status == null;
    final body = type.bodyFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Band shape, tone, icon and words, as in the status view, so an
        // unconfirmed payment never reads as a plain "pending".
        StatusHeader(
          tone: tone,
          icon: icon,
          title: l10n.paymentStatusShort(record.status),
          hatched: unknown,
        ),
        SizedBox(height: theme.spacing * 1.5),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AmountText(record.amount, variant: AmountTextVariant.display),
        ),
        SizedBox(height: theme.spacing * 0.5),
        Text(
          record.title,
          style: type.label.copyWith(color: theme.textSecondary),
        ),
        if (unknown) ...[
          SizedBox(height: theme.spacing * 1.5),
          Text(
            l10n.statusUnknownLead,
            style: body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing * 0.5),
          Text(l10n.statusUnknownDetail, style: body),
        ],
        // Actions come before the details, as in the status view.
        if (actions.isNotEmpty) SizedBox(height: theme.spacing * 3),
        for (final (i, action) in actions.indexed) ...[
          if (i > 0) SizedBox(height: theme.spacing),
          action,
        ],
        SizedBox(height: theme.spacing * 2),
        PaymentSection(
          title: l10n.detailsTitle,
          child: Column(
            children: [
              if (record.merchant != null)
                InfoRow(label: l10n.merchantLabel, valueText: record.merchant),
              InfoRow(
                label: l10n.dateLabel,
                valueText: l10n.formatDateTime(record.createdAt),
              ),
              if (record.methodLabel != null)
                InfoRow(label: l10n.methodLabel, valueText: record.methodLabel),
              if (record.reference != null)
                InfoRow(
                  label: l10n.transactionReference,
                  value: MiddleEllipsisText(
                    record.reference!,
                    style: type.label.reference(theme),
                  ),
                ),
            ],
          ),
        ),
        // The refund is its own ruled section with its own state; the
        // original payment above keeps its success.
        if (record.refund.status != RefundStatus.none) ...[
          PaymentDivider(height: theme.spacing * 3),
          RefundSection(refund: record.refund, paidAmount: record.amount),
        ],
      ],
    );
  }
}
