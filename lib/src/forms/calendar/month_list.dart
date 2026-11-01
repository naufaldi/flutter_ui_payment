import 'package:flutter/material.dart';

import '../../foundation/first_line.dart';
import '../../foundation/payment_localizations.dart';
import '../../foundation/payment_theme.dart';
import '../../foundation/payment_tokens.dart';
import '../../foundation/payment_type.dart';
import 'month_grid.dart';

// Internal: a lazy vertical list of months (D51, D52a). Not exported.

/// Every month from [firstDate] to [lastDate], built lazily and opened at
/// [initialMonth]. Each month has a fixed height (heading plus its week
/// rows), so the list can jump straight to a month.
class MonthList extends StatefulWidget {
  const MonthList({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.initialMonth,
    required this.start,
    required this.end,
    required this.range,
    required this.onPick,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialMonth;
  final DateTime? start;
  final DateTime? end;
  final bool range;
  final ValueChanged<DateTime> onPick;

  @override
  State<MonthList> createState() => _MonthListState();
}

class _MonthListState extends State<MonthList> {
  ScrollController? _controller;

  int get _count =>
      (widget.lastDate.year - widget.firstDate.year) * 12 +
      widget.lastDate.month -
      widget.firstDate.month +
      1;

  DateTime _month(int i) =>
      DateTime(widget.firstDate.year, widget.firstDate.month + i);

  double _heading(BuildContext context) {
    final t = PaymentTheme.of(context);
    return lineHeightOf(context, PaymentType.of(context).heading) +
        t.space(PaymentSpace.block) +
        t.space(PaymentSpace.related);
  }

  double _extent(BuildContext context, int i) =>
      _heading(context) +
      weeksIn(_month(i), PaymentLocalizations.of(context).firstDayOfWeek) *
          calendarCellHeight(context) +
      PaymentTheme.of(context).space(PaymentSpace.group);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final target =
        (widget.initialMonth.year - widget.firstDate.year) * 12 +
        widget.initialMonth.month -
        widget.firstDate.month;
    var offset = 0.0;
    for (var i = 0; i < target.clamp(0, _count - 1); i++) {
      offset += _extent(context, i);
    }
    _controller = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final gutter = t.space(PaymentSpace.group);
    return ListView.builder(
      controller: _controller,
      padding: EdgeInsets.symmetric(horizontal: gutter),
      itemCount: _count,
      itemExtentBuilder: (i, _) => i < _count ? _extent(context, i) : null,
      itemBuilder: (context, i) {
        final month = _month(i);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _heading(context),
              child: Padding(
                padding: EdgeInsets.only(
                  top: t.space(PaymentSpace.block),
                  bottom: t.space(PaymentSpace.related),
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    l.formatMonthYear(month),
                    style: type.heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            MonthGrid(
              month: month,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              start: widget.start,
              end: widget.end,
              range: widget.range,
              today: today,
              onPick: widget.onPick,
            ),
          ],
        );
      },
    );
  }
}
