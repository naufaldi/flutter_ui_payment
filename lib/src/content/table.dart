import 'package:flutter/material.dart';
import '../foundation/table_grid.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';

/// A static table that becomes labeled list rows on phones and at large text.
class PaymentTable extends StatelessWidget {
  /// Creates a table of host-computed values.
  const PaymentTable({
    super.key,
    required this.head,
    required this.rows,
    this.footer,
    this.caption,
  });

  /// Column headings in display order.
  final List<PaymentTableHeaderCell> head;

  /// Data rows matching the column headings.
  final List<PaymentTableRow> rows;

  /// Optional host-computed summary.
  final PaymentTableRow? footer;

  /// Spoken table description.
  final String? caption;
  @override
  Widget build(BuildContext context) {
    assert(head.isNotEmpty);
    assert([...rows, ?footer].every((r) => r.cells.length == head.length));
    final index = head.indexWhere((h) => h.rowHeader);
    final title = index < 0 ? 0 : index;
    bool isNumeric(int i) =>
        head[i].numeric ||
        rows.any((row) => row.cells[i].numeric) ||
        (footer?.cells[i].numeric ?? false);
    final numeric = List.generate(head.length, (i) => i).indexWhere(isNumeric);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return LayoutBuilder(
      builder: (context, k) {
        if (!tableIsNarrow(context, k)) {
          return TableGrid(
            caption: caption,
            columns: [
              for (var i = 0; i < head.length; i++)
                TableGridColumn(
                  label: head[i].label,
                  numeric: isNumeric(i),
                  pin: i == title ? TablePin.start : TablePin.none,
                ),
            ],
            header: [for (final h in head) Text(h.label)],
            rows: [
              for (final r in rows) [for (final c in r.cells) c.child],
            ],
            footer: footer == null
                ? null
                : [for (final c in footer!.cells) c.child],
          );
        }
        Widget value(PaymentTableCell c, TextStyle style) =>
            DefaultTextStyle(style: style, child: c.child);
        return Semantics(
          label: caption,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const PaymentDivider(),
                MergeSemantics(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: theme.space(PaymentSpace.block),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(PaymentSpace.inline),
                      children: [
                        if (PaymentType.isLarge(context)) ...[
                          value(rows[i].cells[title], type.heading),
                          if (numeric >= 0 && numeric != title)
                            value(rows[i].cells[numeric], type.label.tabular),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: value(
                                  rows[i].cells[title],
                                  type.heading,
                                ),
                              ),
                              if (numeric >= 0 && numeric != title)
                                Flexible(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: value(
                                      rows[i].cells[numeric],
                                      type.label.tabular,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        for (var j = 0; j < head.length; j++)
                          if (j != title && j != numeric)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${head[j].label}: ', style: type.caption),
                                Flexible(
                                  child: value(rows[i].cells[j], type.caption),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
              ],
              if (footer != null)
                InfoRow(
                  label: footer!.cells[title].child is Text
                      ? (footer!.cells[title].child as Text).data ??
                            head[title].label
                      : head[title].label,
                  value: footer!.cells[numeric < 0 ? title : numeric].child,
                  emphasis: true,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A row with one cell per heading.
@immutable
class PaymentTableRow {
  /// Creates a row in column order.
  const PaymentTableRow(this.cells);

  /// Values in column order.
  final List<PaymentTableCell> cells;
}

/// A labeled column.
@immutable
class PaymentTableHeaderCell {
  /// Creates a column heading.
  const PaymentTableHeaderCell(
    this.label, {
    this.numeric = false,
    this.rowHeader = false,
  });

  /// Visible and spoken label.
  final String label;

  /// End-aligns tabular numbers.
  final bool numeric;

  /// Pins this column and uses it as each narrow row's title.
  final bool rowHeader;
}

/// A table value.
@immutable
class PaymentTableCell {
  /// Creates a value cell.
  const PaymentTableCell(this.child, {this.numeric = false});

  /// Display value supplied by the host.
  final Widget child;

  /// Marks a numeric value.
  final bool numeric;
}
