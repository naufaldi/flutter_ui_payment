import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../foundation/first_line.dart';
import '../../foundation/kit_strings.dart';
import '../../foundation/payment_localizations.dart';
import '../../foundation/payment_motion.dart';
import '../../foundation/payment_theme.dart';
import '../../foundation/payment_tokens.dart';
import '../../foundation/payment_type.dart';

// Internal: the far-date wheel (D52a). Not exported.

enum _Part { day, month, year }

/// Day, month and year wheels in the typed pattern's order. The day clamps
/// to the month's length, values outside [firstDate]–[lastDate] are drawn
/// disabled and the wheels settle back inside the range. Each column is
/// adjustable for screen readers. Items grow with the text scale.
class DateWheel extends StatefulWidget {
  const DateWheel({
    super.key,
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  State<DateWheel> createState() => _DateWheelState();
}

class _DateWheelState extends State<DateWheel> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;
  late final _controllers = {
    _Part.day: FixedExtentScrollController(initialItem: _day - 1),
    _Part.month: FixedExtentScrollController(initialItem: _month - 1),
    _Part.year: FixedExtentScrollController(
      initialItem: _year - widget.firstDate.year,
    ),
  };

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  DateTime get _value {
    final d = DateTime(_year, _month, math.min(_day, _daysInMonth));
    if (d.isBefore(widget.firstDate)) return widget.firstDate;
    if (d.isAfter(widget.lastDate)) return widget.lastDate;
    return d;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _count(_Part part) => switch (part) {
    _Part.day => _daysInMonth,
    _Part.month => 12,
    _Part.year => widget.lastDate.year - widget.firstDate.year + 1,
  };

  int _current(_Part part) => switch (part) {
    _Part.day => _day - 1,
    _Part.month => _month - 1,
    _Part.year => _year - widget.firstDate.year,
  };

  void _set(_Part part, int index) {
    setState(() {
      switch (part) {
        case _Part.day:
          _day = index + 1;
        case _Part.month:
          _month = index + 1;
        case _Part.year:
          _year = widget.firstDate.year + index;
      }
      // 31 March → February: the day wheel shrinks, so clamp the day.
      _day = math.min(_day, _daysInMonth);
    });
    if (part != _Part.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _controllers[_Part.day]!;
        if (mounted && c.hasClients && c.selectedItem != _day - 1) {
          c.jumpToItem(_day - 1);
        }
      });
    }
    widget.onChanged(_value);
  }

  /// After a fling ends, move every column onto the clamped date.
  void _settle() {
    final v = _value;
    if (v.day == _day && v.month == _month && v.year == _year) return;
    setState(() {
      _day = v.day;
      _month = v.month;
      _year = v.year;
    });
    for (final part in _Part.values) {
      _move(part, _current(part));
    }
  }

  void _move(_Part part, int index) {
    final c = _controllers[part]!;
    if (!c.hasClients || c.selectedItem == index) return;
    if (PaymentMotion.of(context).reduced) {
      c.jumpToItem(index);
    } else {
      c.animateToItem(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  bool _enabled(_Part part, int index) {
    final first = widget.firstDate, last = widget.lastDate;
    final (y, m) = switch (part) {
      _Part.year => (first.year + index, null),
      _Part.month => (_year, index + 1),
      _Part.day => (_year, _month),
    };
    if (m == null) return true;
    final start = DateTime(y, m, part == _Part.day ? index + 1 : 1);
    final end = part == _Part.day
        ? start
        : DateTime(y, m, DateUtils.getDaysInMonth(y, m));
    return !end.isBefore(first) && !start.isAfter(last);
  }

  String _text(_Part part, int index) {
    final l = PaymentLocalizations.of(context);
    return switch (part) {
      _Part.day => '${index + 1}',
      _Part.month => l.monthName(index + 1),
      _Part.year => '${widget.firstDate.year + index}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    final extent =
        lineHeightOf(context, type.body) + t.space(PaymentSpace.group);
    // Column order follows the typed pattern, DD/MM/YYYY by default (Q12).
    final pattern = l.dateInputPattern;
    final order = [_Part.day, _Part.month, _Part.year]
      ..sort(
        (a, b) => pattern
            .indexOf(switch (a) {
              _Part.day => 'DD',
              _Part.month => 'MM',
              _Part.year => 'YYYY',
            })
            .compareTo(
              pattern.indexOf(switch (b) {
                _Part.day => 'DD',
                _Part.month => 'MM',
                _Part.year => 'YYYY',
              }),
            ),
      );
    Widget column(_Part part) {
      final count = _count(part);
      final i = _current(part).clamp(0, count - 1);
      final name = switch (part) {
        _Part.day => l.day,
        _Part.month => l.month,
        _Part.year => l.year,
      };
      return Semantics(
        container: true,
        label: name,
        value: _text(part, i),
        increasedValue: i + 1 < count ? _text(part, i + 1) : null,
        decreasedValue: i > 0 ? _text(part, i - 1) : null,
        onIncrease: i + 1 < count ? () => _move(part, i + 1) : null,
        onDecrease: i > 0 ? () => _move(part, i - 1) : null,
        child: ExcludeSemantics(
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _settle();
              });
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              controller: _controllers[part],
              itemExtent: extent,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 1.6,
              overAndUnderCenterOpacity: 0.6,
              onSelectedItemChanged: (index) => _set(part, index),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: count,
                builder: (context, index) => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space(PaymentSpace.related),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _text(part, index),
                        maxLines: 1,
                        style: type
                            .tabular(type.body)
                            .copyWith(
                              color: _enabled(part, index)
                                  ? t.textPrimary
                                  : t.disabled,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: extent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The selection band behind the centre row.
          Container(
            height: extent,
            decoration: BoxDecoration(
              color: t.surfaceMuted,
              borderRadius: t.controlBorderRadius,
            ),
          ),
          Row(
            children: [
              for (final part in order)
                Expanded(
                  flex: part == _Part.month ? 3 : 2,
                  child: column(part),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
