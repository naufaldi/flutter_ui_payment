import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../foundation/first_line.dart';
import '../../foundation/kit_strings.dart';
import '../../foundation/payment_localizations.dart';
import '../../foundation/payment_theme.dart';
import '../../foundation/payment_tokens.dart';
import '../../foundation/payment_type.dart';

// Internal: the kit's month calendar (D51, D52a). Not exported.

/// Height of one week row: 48 dp, or taller when large text needs it.
double calendarCellHeight(BuildContext context) => math.max(
  48,
  lineHeightOf(context, PaymentType.of(context).label) +
      PaymentTheme.of(context).space(PaymentSpace.block),
);

/// Leading blank cells before day 1 when weeks start on [firstDayOfWeek].
int leadingBlanks(DateTime month, int firstDayOfWeek) =>
    (DateTime(month.year, month.month).weekday - firstDayOfWeek) % 7;

/// Week rows [month] needs.
int weeksIn(DateTime month, int firstDayOfWeek) =>
    ((leadingBlanks(month, firstDayOfWeek) +
                DateUtils.getDaysInMonth(month.year, month.month)) /
            7)
        .ceil();

/// The weekday headings, one row pinned above the month list. Hidden from
/// screen readers: each day already says its weekday.
class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final t = PaymentTheme.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.space(PaymentSpace.related)),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                // Shrinks a heading that would touch its neighbours at
                // large text, keeping a gap between columns.
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space(PaymentSpace.inline) / 2,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l.weekdayShort((l.firstDayOfWeek - 1 + i) % 7 + 1),
                        style: type.caption,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One month of 48 dp day cells. A single date marks [start] only; a range
/// marks [start] to [end] with the accent band between them. Days outside
/// [firstDate]–[lastDate] are disabled. Each day is a focusable button, so
/// the arrow keys move by a day or a week and Enter or Space picks it.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.start,
    required this.end,
    required this.range,
    required this.today,
    required this.onPick,
  });

  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? start;
  final DateTime? end;
  final bool range;
  final DateTime today;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    final height = calendarCellHeight(context);
    final lead = leadingBlanks(month, l.firstDayOfWeek);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final weeks = weeksIn(month, l.firstDayOfWeek);
    return Column(
      children: [
        for (var w = 0; w < weeks; w++)
          SizedBox(
            height: height,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: switch (w * 7 + c - lead + 1) {
                      final d when d >= 1 && d <= days => _Day(
                        date: DateTime(month.year, month.month, d),
                        grid: this,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.grid});

  final DateTime date;
  final MonthGrid grid;

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    final g = grid;
    final enabled = !date.isBefore(g.firstDate) && !date.isAfter(g.lastDate);
    final isStart = g.start != null && DateUtils.isSameDay(date, g.start);
    final isEnd = g.end != null && DateUtils.isSameDay(date, g.end);
    final hasRange = g.range && g.start != null && g.end != null;
    final within =
        hasRange && date.isAfter(g.start!) && date.isBefore(g.end!) ||
        isStart && hasRange && !isEnd ||
        isEnd && hasRange && !isStart;
    final selected = isStart || isEnd;
    final isToday = DateUtils.isSameDay(date, g.today);
    final band = t.accent.withValues(alpha: 0.14);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The band runs through the range; on its ends it covers only the half
    // facing the range, so the ends read as caps.
    final bandAlign = isStart
        ? (rtl ? Alignment.centerLeft : Alignment.centerRight)
        : isEnd
        ? (rtl ? Alignment.centerRight : Alignment.centerLeft)
        : Alignment.center;
    final label = [
      l.formatDateLong(date),
      if (isToday) l.today,
      if (g.range && isStart) l.rangeStart,
      if (g.range && isEnd) l.rangeEnd,
    ].join(', ');
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? () => g.onPick(date) : null,
      child: LayoutBuilder(
        builder: (context, box) {
          final circle = math.min(box.maxWidth, box.maxHeight) - 4;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (within)
                Align(
                  alignment: bandAlign,
                  child: FractionallySizedBox(
                    widthFactor: selected ? 0.5 : 1,
                    child: Container(height: circle, color: band),
                  ),
                ),
              InkWell(
                onTap: enabled ? () => g.onPick(date) : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: circle,
                  height: circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? t.accent : null,
                    border: isToday && !selected
                        ? Border.all(color: t.accent, width: 1.5)
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${date.day}',
                      style: type
                          .tabular(type.label)
                          .copyWith(
                            color: selected
                                ? t.onAccent
                                : enabled
                                ? t.textPrimary
                                : t.disabled,
                            fontWeight: selected || isToday
                                ? FontWeight.w600
                                : null,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
