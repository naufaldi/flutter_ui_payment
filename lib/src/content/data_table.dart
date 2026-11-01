import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/money.dart';
import '../foundation/table_grid.dart';
import '../foundation/first_line.dart';
import '../foundation/tap_target.dart';
import '../controls/controls.dart';
import '../controls/actions.dart';
import '../controls/button_group.dart';
import '../interaction/interaction.dart';
import 'empty_message.dart';

/// Supported host value presentations.
enum PaymentCellType {
  /// Text value.
  text,

  /// Link value.
  link,

  /// Date value.
  date,

  /// Id value.
  id,

  /// Status value.
  status,

  /// Currency value.
  currency,
}

/// One host-owned data column.
@immutable
class PaymentDataColumn<T> {
  const PaymentDataColumn({
    required this.key,
    required this.label,
    required this.value,
    this.cell = PaymentCellType.text,
    this.statusMap,
    this.onPressed,
    this.hideHeaderLabel = false,
    this.pinned = false,
    this.sortable = false,
    this.compare,
  }) : assert(cell != PaymentCellType.status || statusMap != null),
       assert(cell != PaymentCellType.link || onPressed != null),
       assert(compare == null || sortable);

  /// Stable column identifier.
  final String key;

  /// Visible and spoken label.
  final String label;

  /// Extracts a display value from a host row.
  final Object? Function(T row) value;

  /// Presentation for the extracted value.
  final PaymentCellType cell;

  /// Maps status text to semantic tones.
  final Map<String, StatusTone>? statusMap;

  /// Host action for this row.
  final void Function(T row)? onPressed;

  /// Hides the visual heading while retaining its spoken label.
  final bool hideHeaderLabel;

  /// Keeps this column fixed during horizontal scrolling.
  final bool pinned;

  /// Enables the ascending, descending, host-order cycle.
  final bool sortable;

  /// Optional comparison of host rows for local sorting.
  final int Function(T a, T b)? compare;
}

/// Current column sort; null restores host order.
@immutable
class PaymentDataSort {
  const PaymentDataSort(this.columnKey, {this.ascending = true});

  /// Identifier of the sorted column.
  final String columnKey;

  /// Whether values sort in ascending order.
  final bool ascending;
}

/// Page delivery strategy. Pages start at one.
@immutable
class PaymentPagination {
  const PaymentPagination.local({required this.pageSize, this.onPageChanged})
    : page = null,
      totalItems = null,
      hasMore = null,
      _kind = 0;
  const PaymentPagination.offset({
    required int this.page,
    required this.pageSize,
    required int this.totalItems,
    required ValueChanged<int> this.onPageChanged,
  }) : hasMore = null,
       _kind = 1;
  const PaymentPagination.cursor({
    required int this.page,
    required this.pageSize,
    required bool this.hasMore,
    required ValueChanged<int> this.onPageChanged,
  }) : totalItems = null,
       _kind = 2;

  /// Maximum rows per local page.
  final int pageSize;

  /// Host-controlled page number, starting at one.
  final int? page;

  /// Total host row count for offset paging.
  final int? totalItems;

  /// Whether cursor paging can request a next page.
  final bool? hasMore;

  /// Reports the requested page to the host.
  final ValueChanged<int>? onPageChanged;

  /// Host-provided _kind configuration.
  final int _kind;
}

/// Closed family of row actions.
@immutable
abstract class PaymentRowActionEntry<T> {
  const PaymentRowActionEntry._();
}

/// An action on a host row.
class PaymentRowAction<T> extends PaymentRowActionEntry<T> {
  const PaymentRowAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  }) : super._();

  /// Stable host action identifier.
  final String id;

  /// Visible and spoken label.
  final String label;

  /// Host action for this row.
  final void Function(T row) onPressed;

  /// Places this action in the separate destructive menu group.
  final bool destructive;
}

/// A named action group.
class PaymentRowActionGroup<T> extends PaymentRowActionEntry<T> {
  const PaymentRowActionGroup({
    required this.id,
    required this.label,
    required this.actions,
  }) : super._();

  /// Stable host action identifier.
  final String id;

  /// Visible and spoken label.
  final String label;

  /// Actions in this named group.
  final List<PaymentRowAction<T>> actions;
}

/// Responsive host data with page-scoped selection and local sort/filter.
class PaymentDataTable<T> extends StatefulWidget {
  const PaymentDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowKey,
    this.pagination = const PaymentPagination.local(pageSize: 25),
    this.onRowPressed,
    this.rowActions = const <Never>[],
    this.selection,
    this.onSelectionChanged,
    this.batchActions = const [],
    this.pending = false,
    this.emptyMessage,
    this.errorText,
    this.onRetry,
    this.initialSort,
    this.onSortChanged,
    this.filter,
    this.filterQuery,
    this.enableColumnReorder = false,
    this.enableColumnResize = false,
    this.onColumnOrderChanged,
    this.caption,
  }) : assert((selection == null) == (onSelectionChanged == null));

  /// Column definitions in initial reading order.
  final List<PaymentDataColumn<T>> columns;

  /// Host data; a complete local set or one host-controlled page.
  final List<T> rows;

  /// Returns a stable unique selection key for a row.
  final String Function(T row) rowKey;

  /// Page strategy; null displays all supplied rows.
  final PaymentPagination? pagination;

  /// Optional host action when a data row is pressed.
  final void Function(T row)? onRowPressed;

  /// Per-row actions and named groups.
  final List<PaymentRowActionEntry<T>> rowActions;

  /// Host-controlled selected row keys; null hides selection.
  final Set<String>? selection;

  /// Reports the complete new selection to the host.
  final ValueChanged<Set<String>>? onSelectionChanged;

  /// Host actions displayed while rows are selected.
  final List<PaymentButton> batchActions;

  /// Replaces data with a static table skeleton.
  final bool pending;

  /// Host explanation and optional next action for an empty table.
  final PaymentEmptyMessage? emptyMessage;

  /// Host load error shown with danger tone.
  final String? errorText;

  /// Host retry action.
  final VoidCallback? onRetry;

  /// Initial sort state for this table instance.
  final PaymentDataSort? initialSort;

  /// Reports sort intent, including null for host order.
  final ValueChanged<PaymentDataSort?>? onSortChanged;

  /// Host predicate, permitted only for local data.
  final bool Function(T row, String query)? filter;

  /// Query passed to the host predicate.
  final String? filterQuery;

  /// Not supported (D28); must remain false.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  final bool enableColumnReorder;

  /// Not supported (D28); must remain false.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  final bool enableColumnResize;

  /// Not supported (D28); configure columns through the host.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  final ValueChanged<List<String>>? onColumnOrderChanged;

  /// Spoken description of the data set.
  final String? caption;
  @override
  State<PaymentDataTable<T>> createState() => _PaymentDataTableState<T>();
}

class _PaymentDataTableState<T> extends State<PaymentDataTable<T>> {
  PaymentDataSort? _sort;
  int _page = 1;
  late List<String> _order;
  final _widths = <String, double>{};
  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _order = widget.columns.map((c) => c.key).toList();
  }

  @override
  void didUpdateWidget(covariant PaymentDataTable<T> old) {
    super.didUpdateWidget(old);
    if (old.filterQuery != widget.filterQuery ||
        old.rows.length != widget.rows.length ||
        old.pagination?.pageSize != widget.pagination?.pageSize) {
      _page = 1;
    }
    final keys = widget.columns.map((c) => c.key).toSet();
    if (keys.length != _order.length || !keys.containsAll(_order)) {
      _order = widget.columns.map((c) => c.key).toList();
    }
  }

  void sort(PaymentDataColumn<T> c, {bool? ascending}) {
    setState(() {
      _sort = ascending != null
          ? PaymentDataSort(c.key, ascending: ascending)
          : _sort?.columnKey != c.key
          ? PaymentDataSort(c.key)
          : _sort!.ascending
          ? PaymentDataSort(c.key, ascending: false)
          : null;
      _page = 1;
    });
    widget.onSortChanged?.call(_sort);
  }

  int natural(Object? a, Object? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    if (a is Money && b is Money) {
      final currency = a.currency.compareTo(b.currency);
      return currency == 0 ? a.compareTo(b) : currency;
    }
    if (a is Comparable && a.runtimeType == b.runtimeType) {
      return a.compareTo(b);
    }
    return a.toString().compareTo(b.toString());
  }

  List<PaymentMenuEntry> actions(T row) {
    final result = <PaymentMenuEntry>[];
    final danger = <PaymentMenuItem>[];
    PaymentMenuItem item(PaymentRowAction<T> a) => PaymentMenuItem(
      id: a.id,
      label: a.label,
      destructive: a.destructive,
      onSelected: () => a.onPressed(row),
    );
    for (final entry in widget.rowActions) {
      if (entry is PaymentRowAction<T>) {
        if (entry.destructive) {
          danger.add(item(entry));
        } else {
          result.add(item(entry));
        }
      } else if (entry is PaymentRowActionGroup<T>) {
        final safe = entry.actions
            .where((a) => !a.destructive)
            .map(item)
            .toList();
        danger.addAll(entry.actions.where((a) => a.destructive).map(item));
        if (safe.isNotEmpty) {
          result.add(PaymentMenuGroup(title: entry.label, items: safe));
        }
      }
    }
    if (danger.isNotEmpty) result.add(PaymentMenuGroup(items: danger));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final p = w.pagination;
    final local = p == null || p._kind == 0;
    final l = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final theme = PaymentTheme.of(context);
    assert(w.columns.isNotEmpty);
    assert(
      // ignore: deprecated_member_use_from_same_package
      !w.enableColumnReorder && !w.enableColumnResize,
      "Column editing is not supported (D28)",
    );
    assert(w.batchActions.isEmpty || w.selection != null);
    assert(local || w.filter == null);
    assert(p == null || p.pageSize > 0);
    assert(w.columns.map((c) => c.key).toSet().length == w.columns.length);
    if (w.pending) {
      return LoadingSkeleton.table(
        rows: math.min(p?.pageSize ?? 5, 5),
        columns: math.max(2, math.min(w.columns.length, 4)),
      );
    }
    if (w.errorText != null) {
      return StateMessage(
        icon: Icons.cloud_off_outlined,
        title: w.errorText!,
        tone: StatusTone.danger,
        actionLabel: w.onRetry == null ? null : l.retry,
        onAction: w.onRetry,
      );
    }
    if (w.rows.isEmpty) {
      return StateMessage(
        icon: w.emptyMessage?.icon ?? Icons.inbox_outlined,
        title: w.emptyMessage?.title ?? l.emptyTitle,
        message: w.emptyMessage?.message,
        actionLabel: w.emptyMessage?.actionLabel,
        onAction: w.emptyMessage?.onAction,
      );
    }
    var rows = w.rows.toList();
    final query = (w.filterQuery ?? '').trim();
    if (local && w.filter != null && query.isNotEmpty) {
      rows = rows.where((r) => w.filter!(r, query)).toList();
    }
    if (rows.isEmpty) {
      return StateMessage(
        icon: Icons.search_off,
        title: l.noMatchesTitle,
        message: l.noMatchesMessage,
      );
    }
    final cols = [
      for (final key in _order) w.columns.firstWhere((c) => c.key == key),
    ];
    if (local && _sort != null) {
      final c = cols.where((c) => c.key == _sort!.columnKey).firstOrNull;
      if (c != null) {
        final indexed = rows.indexed.toList();
        indexed.sort((a, b) {
          final av = c.value(a.$2), bv = c.value(b.$2);
          if (c.compare == null && (av == null || bv == null)) {
            return av == null && bv == null
                ? a.$1.compareTo(b.$1)
                : av == null
                ? 1
                : -1;
          }
          final result = c.compare?.call(a.$2, b.$2) ?? natural(av, bv);
          return result == 0
              ? a.$1.compareTo(b.$1)
              : _sort!.ascending
              ? result
              : -result;
        });
        rows = indexed.map((e) => e.$2).toList();
      }
    }
    final total = local ? rows.length : p.totalItems;
    final int page = local
        ? _page
              .clamp(
                1,
                p == null ? 1 : math.max(1, (rows.length / p.pageSize).ceil()),
              )
              .toInt()
        : p.page!;
    if (local && p != null) {
      rows = rows.skip((page - 1) * p.pageSize).take(p.pageSize).toList();
    }
    final keys = rows.map(w.rowKey).toSet();
    final selected = w.selection ?? <String>{};
    final selectedOnPage = keys.intersection(selected).length;
    Widget checkbox(
      String label,
      bool value,
      ValueChanged<bool> changed, {
      bool mixed = false,
    }) => SizedBox(
      width: 48,
      child: PaymentCheckbox(
        label: label,
        value: value,
        indeterminate: mixed,
        onChanged: changed,
        hiddenElements: const {PaymentFieldPart.label},
      ),
    );
    Widget selectAll() => checkbox(
      l.selectAllOnPage,
      selectedOnPage == keys.length,
      (v) => w.onSelectionChanged!(
        {...selected}
          ..removeAll(v ? <String>{} : keys)
          ..addAll(v ? keys : <String>{}),
      ),
      mixed: selectedOnPage > 0 && selectedOnPage < keys.length,
    );
    final titleColumn = cols.firstWhere(
      (c) => c.pinned,
      orElse: () => cols.first,
    );
    String title(T row) => (titleColumn.value(row) ?? '').toString();
    Widget cell(PaymentDataColumn<T> c, T row) {
      final value = c.value(row);
      return switch (c.cell) {
        PaymentCellType.text => Text(value?.toString() ?? ''),
        PaymentCellType.link => PaymentLink(
          label: value?.toString() ?? '',
          onPressed: () => c.onPressed!(row),
        ),
        PaymentCellType.date => Text(l.formatDate(value as DateTime)),
        PaymentCellType.id => SizedBox(
          width: _widths[c.key] ?? 160,
          // Starts on the column edge, as its header does (#57-2).
          child: MiddleEllipsisText(
            value.toString(),
            style: type.label.reference(theme),
            textAlign: TextAlign.start,
          ),
        ),
        PaymentCellType.status => PaymentBadge(
          label: value.toString(),
          tone: c.statusMap![value] ?? StatusTone.neutral,
        ),
        PaymentCellType.currency => AmountText(value as Money),
      };
    }

    Widget rowMenu(T row) =>
        PaymentMenu(tooltip: l.rowActions(title(row)), entries: actions(row));
    void go(int next) {
      if (local) setState(() => _page = next);
      p?.onPageChanged?.call(next);
    }

    return LayoutBuilder(
      builder: (context, k) {
        final narrow = tableIsNarrow(context, k);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The label starts on the same inset as row titles: after the
            // 48 dp checkbox box (#62).
            if (narrow && w.selection != null)
              Row(
                children: [
                  selectAll(),
                  Expanded(
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => w.onSelectionChanged!(
                          selectedOnPage == keys.length && keys.isNotEmpty
                              ? ({...selected}..removeAll(keys))
                              : ({...selected}..addAll(keys)),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(l.selectAllOnPage, style: type.label),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (w.selection != null && selected.isNotEmpty)
              Row(
                children: [
                  if (selected.isNotEmpty) ...[
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l.rowsSelected(selected.length),
                          style: type.label.tabular,
                        ),
                      ),
                    ),
                    if (w.batchActions.isNotEmpty)
                      Flexible(
                        child: PaymentButtonGroup(children: w.batchActions),
                      ),
                  ],
                ],
              ),
            if (narrow && cols.any((c) => c.sortable))
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PaymentMenu(
                  trigger: (toggle, focus) => PaymentButton(
                    label: _sort == null
                        ? l.sort
                        : l.sortBy(
                            '${cols.firstWhere((c) => c.key == _sort!.columnKey).label}, ${l.sortDirection(cols.firstWhere((c) => c.key == _sort!.columnKey).cell, _sort!.ascending)}',
                          ),
                    onPressed: toggle,
                    focusNode: focus,
                    variant: PaymentButtonVariant.secondary,
                    icon: Icons.swap_vert,
                    width: PaymentWidth.hug,
                    size: PaymentSize.small,
                  ),
                  entries: [
                    for (final c in cols.where((c) => c.sortable)) ...[
                      PaymentMenuItem(
                        label: '${c.label}, ${l.sortDirection(c.cell, true)}',
                        onSelected: () => sort(c, ascending: true),
                      ),
                      PaymentMenuItem(
                        label: '${c.label}, ${l.sortDirection(c.cell, false)}',
                        onSelected: () => sort(c, ascending: false),
                      ),
                    ],
                    if (_sort != null)
                      PaymentMenuItem(
                        label: l.sortDefault,
                        onSelected: () {
                          setState(() {
                            _sort = null;
                            _page = 1;
                          });
                          w.onSortChanged?.call(null);
                        },
                      ),
                  ],
                ),
              ),
            if (narrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final row in rows) ...[
                    // D60: the title and its ⋮ share the first line (D56);
                    // every other column, the amount included, is a label on
                    // the start edge and its value on the one value edge.
                    InkWell(
                      onTap: w.onRowPressed == null
                          ? null
                          : () => w.onRowPressed!(row),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: theme.space(PaymentSpace.related),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FirstLineRow(
                              gap: 0,
                              leading: w.selection == null
                                  ? null
                                  : checkbox(
                                      l.selectRow(title(row)),
                                      selected.contains(w.rowKey(row)),
                                      (v) {
                                        final next = {...selected};
                                        if (v) {
                                          next.add(w.rowKey(row));
                                        } else {
                                          next.remove(w.rowKey(row));
                                        }
                                        w.onSelectionChanged!(next);
                                      },
                                    ),
                              text: titleColumn.cell == PaymentCellType.id
                                  // An ID title stays on one line with
                                  // non-breaking hyphens (U+2011) and scales
                                  // down only when it does not fit, as
                                  // AmountText does; speech keeps the
                                  // original text.
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        title(row).replaceAll('-', '\u2011'),
                                        semanticsLabel: title(row),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: type.reference(type.heading),
                                      ),
                                    )
                                  : Text(title(row), style: type.heading),
                              trailing: w.rowActions.isEmpty
                                  ? null
                                  : rowMenu(row),
                              trailingGap: theme.space(PaymentSpace.related),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: w.selection == null ? 0 : 48,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final c in cols)
                                    if (c != titleColumn)
                                      InfoRow(
                                        label: c.label,
                                        value: DefaultTextStyle(
                                          style:
                                              c.cell == PaymentCellType.currency
                                              ? type.label.tabular
                                              : type.label,
                                          child: TextActionEdge.end(
                                            child: cell(c, row),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PaymentDivider(),
                  ],
                ],
              )
            else
              TableGrid(
                caption: w.caption,
                onRowPressed: w.onRowPressed == null
                    ? null
                    : (i) => w.onRowPressed!(rows[i]),
                columns: [
                  if (w.selection != null)
                    const TableGridColumn(
                      label: '',
                      width: 48,
                      pin: TablePin.start,
                    ),
                  for (final c in cols)
                    TableGridColumn(
                      label: c.label,
                      numeric: c.cell == PaymentCellType.currency,
                      pin: c.pinned ? TablePin.start : TablePin.none,
                      width: _widths[c.key],
                      hideLabel: c.hideHeaderLabel,
                    ),
                  if (w.rowActions.isNotEmpty)
                    const TableGridColumn(
                      label: '',
                      width: 48,
                      pin: TablePin.end,
                    ),
                ],
                header: [
                  if (w.selection != null) selectAll(),
                  for (final c in cols)
                    Semantics(
                      button: c.sortable,
                      label: _sort?.columnKey == c.key
                          ? (_sort!.ascending
                                ? l.sortedAscending(c.label)
                                : l.sortedDescending(c.label))
                          : c.label,
                      child: InkWell(
                        onTap: c.sortable ? () => sort(c) : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!c.hideHeaderLabel) Text(c.label),
                            if (_sort?.columnKey == c.key)
                              Icon(
                                _sort!.ascending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (w.rowActions.isNotEmpty) const SizedBox.shrink(),
                ],
                rows: [
                  for (final row in rows)
                    [
                      if (w.selection != null)
                        checkbox(
                          l.selectRow(title(row)),
                          selected.contains(w.rowKey(row)),
                          (v) {
                            final next = {...selected};
                            if (v) {
                              next.add(w.rowKey(row));
                            } else {
                              next.remove(w.rowKey(row));
                            }
                            w.onSelectionChanged!(next);
                          },
                        ),
                      for (final c in cols) cell(c, row),
                      if (w.rowActions.isNotEmpty) rowMenu(row),
                    ],
                ],
              ),
            if (p != null && (!local || total! > p.pageSize))
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p._kind == 2
                          ? l.pageNumber(page)
                          : l.pageRange(
                              (page - 1) * p.pageSize + 1,
                              math.min(page * p.pageSize, total!),
                              total,
                            ),
                      style: type.caption.tabular,
                    ),
                  ),
                  PaymentIconButton(
                    icon: Icons.chevron_left,
                    tooltip: l.previousPage,
                    onPressed: page > 1 ? () => go(page - 1) : null,
                  ),
                  PaymentIconButton(
                    icon: Icons.chevron_right,
                    tooltip: l.nextPage,
                    onPressed:
                        (p._kind == 2 ? p.hasMore! : page * p.pageSize < total!)
                        ? () => go(page + 1)
                        : null,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
