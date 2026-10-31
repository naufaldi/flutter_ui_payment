import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'payment_theme.dart';
import 'payment_type.dart';
import 'payment_tokens.dart';
import 'edge_fade.dart';

bool tableIsNarrow(BuildContext c, BoxConstraints k) =>
    k.maxWidth < 600 || PaymentType.isLarge(c);

enum TablePin { start, none, end }

class TableGridColumn {
  const TableGridColumn({
    required this.label,
    this.numeric = false,
    this.pin = TablePin.none,
    this.width,
    this.hideLabel = false,
  });
  final String label;
  final bool numeric;
  final TablePin pin;
  final double? width;
  final bool hideLabel;
}

class TableGrid extends StatelessWidget {
  const TableGrid({
    super.key,
    required this.columns,
    required this.header,
    required this.rows,
    this.footer,
    this.onRowPressed,
    this.caption,
  });
  final List<TableGridColumn> columns;
  final List<Widget> header;
  final List<List<Widget>> rows;
  final List<Widget>? footer;
  final void Function(int row)? onRowPressed;
  final String? caption;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final h = math.max(
      48.0,
      PaymentType.firstLineHeight(context) +
          2 * theme.space(PaymentSpace.block),
    );
    final first = columns.indexWhere((c) => c.pin == TablePin.start);
    Widget grid(List<int> indexes) => Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        for (var j = 0; j < indexes.length; j++)
          j: columns[indexes[j]].width != null
              ? FixedColumnWidth(columns[indexes[j]].width!)
              : IntrinsicColumnWidth(
                  flex: columns[indexes[j]].numeric ? null : 1,
                ),
      },
      children: [
        for (var row = -1; row < rows.length + (footer == null ? 0 : 1); row++)
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.outline)),
            ),
            children: [
              for (final i in indexes)
                Builder(
                  builder: (context) {
                    final col = columns[i];
                    final heading = row < 0;
                    Widget child = SizedBox(
                      height: h,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: col.width == 48
                              ? 0
                              : theme.space(PaymentSpace.block),
                        ),
                        child: Align(
                          alignment: col.numeric
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: DefaultTextStyle(
                            style: heading
                                ? type.caption
                                : row == rows.length
                                ? (col.numeric
                                      ? type.heading.tabular
                                      : type.heading)
                                : col.numeric
                                ? type.label.tabular
                                : type.label,
                            maxLines: 1,
                            softWrap: false,
                            child: heading
                                ? (col.hideLabel
                                      ? const SizedBox.shrink()
                                      : header[i])
                                : row == rows.length
                                ? footer![i]
                                : rows[row][i],
                          ),
                        ),
                      ),
                    );
                    child = Semantics(
                      container: true,
                      header: heading,
                      label: heading ? null : '${col.label}: ',
                      child: child,
                    );
                    if (!heading && row < rows.length && onRowPressed != null) {
                      child = i == (first < 0 ? 0 : first)
                          ? InkWell(
                              onTap: () => onRowPressed!(row),
                              child: child,
                            )
                          : GestureDetector(
                              onTap: () => onRowPressed!(row),
                              excludeFromSemantics: true,
                              behavior: HitTestBehavior.opaque,
                              child: child,
                            );
                    }
                    return child;
                  },
                ),
            ],
          ),
      ],
    );
    final start = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].pin == TablePin.start) i,
    ];
    final middle = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].pin == TablePin.none) i,
    ];
    final end = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].pin == TablePin.end) i,
    ];
    return Semantics(
      label: caption,
      container: true,
      explicitChildNodes: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (start.isNotEmpty) grid(start),
          if (middle.isNotEmpty)
            Expanded(
              child: LayoutBuilder(
                builder: (context, k) => EdgeFadeScroll(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: k.maxWidth),
                    child: grid(middle),
                  ),
                ),
              ),
            ),
          if (end.isNotEmpty) grid(end),
        ],
      ),
    );
  }
}
