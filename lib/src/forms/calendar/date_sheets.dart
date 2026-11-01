import 'package:flutter/material.dart';

import '../../foundation/kit_strings.dart';
import '../../foundation/payment_localizations.dart';
import '../../foundation/payment_theme.dart';
import '../../foundation/payment_tokens.dart';
import '../../foundation/payment_type.dart';
import '../../foundation/primitives.dart';
import '../../overlay/modal_presenters.dart';
import '../../overlay/sheets.dart';
import '../date_field.dart';
import '../date_range_picker.dart';
import 'date_wheel.dart';
import 'month_grid.dart';
import 'month_list.dart';

// Internal: the kit's date sheets (D51, D52, D52a). Not exported.

/// Whether a single date uses the wheel: the allowed span is more than five
/// years, such as a date of birth (Q2 default). Otherwise the calendar.
bool usesDateWheel(DateTime firstDate, DateTime lastDate) => DateTime(
  firstDate.year + 5,
  firstDate.month,
  firstDate.day,
).isBefore(lastDate);

DateTime _clamp(DateTime d, DateTime first, DateTime last) =>
    d.isBefore(first) ? first : (d.isAfter(last) ? last : d);

/// Opens the single-date sheet with a full-width "Choose date" footer. The
/// wheel sheet hugs its content and opens at [initial], or at [lastDate]
/// when empty; the calendar sheet is full height and opens at [initial]'s
/// month, or today's. Resolves null when closed without a choice.
Future<DateTime?> showKitDateSheet({
  required BuildContext context,
  required String title,
  required DateTime? initial,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final first = DateUtils.dateOnly(firstDate);
  final last = DateUtils.dateOnly(lastDate);
  final value = initial == null
      ? null
      : _clamp(DateUtils.dateOnly(initial), first, last);
  if (usesDateWheel(first, last)) {
    return showKitBottomSheet<DateTime>(
      context: context,
      showDragHandle: false,
      builder: (_) => _WheelSheet(
        title: title,
        initial: value ?? last,
        firstDate: first,
        lastDate: last,
      ),
    );
  }
  return showKitBottomSheet<DateTime>(
    context: context,
    fullHeight: true,
    showDragHandle: false,
    builder: (_) => _CalendarSheet(
      title: title,
      initial: value,
      firstDate: first,
      lastDate: last,
    ),
  );
}

class _WheelSheet extends StatefulWidget {
  const _WheelSheet({
    required this.title,
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final String title;
  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_WheelSheet> createState() => _WheelSheetState();
}

class _WheelSheetState extends State<_WheelSheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    return PaymentSheet(
      header: PaymentSheetHeader(
        title: widget.title,
        onClose: () => Navigator.pop(context),
      ),
      body: DateWheel(
        initial: widget.initial,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        onChanged: (v) => _value = v,
      ),
      footer: PaymentButton(
        label: l.chooseDate,
        onPressed: () => Navigator.pop(context, _value),
      ),
    );
  }
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.title,
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final String title;
  final DateTime? initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    return KitFullSheet(
      header: PaymentSheetHeader(
        title: widget.title,
        onClose: () => Navigator.pop(context),
      ),
      top: const WeekdayHeader(),
      body: MonthList(
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        initialMonth:
            widget.initial ?? _clamp(today, widget.firstDate, widget.lastDate),
        start: _value,
        end: null,
        range: false,
        onPick: (d) => setState(() => _value = d),
      ),
      footer: PaymentButton(
        label: l.chooseDate,
        onPressed: _value == null ? null : () => Navigator.pop(context, _value),
      ),
    );
  }
}

/// What the range sheet resolves to; null means it was closed unchanged.
class KitRangeResult {
  const KitRangeResult(this.range);

  /// The applied range, or null when the customer cleared it.
  final PaymentDateRange? range;
}

/// Opens the full-height range sheet (D51): a scrolling month calendar with
/// two-tap selection, typed entry from the header, and a pinned footer with
/// the summary, a full-width Apply and a quiet Clear.
Future<KitRangeResult?> showKitRangeSheet({
  required BuildContext context,
  required String title,
  required PaymentDateRange? initial,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showKitBottomSheet<KitRangeResult>(
  context: context,
  fullHeight: true,
  showDragHandle: false,
  builder: (_) => _RangeSheet(
    title: title,
    initial: initial,
    firstDate: DateUtils.dateOnly(firstDate),
    lastDate: DateUtils.dateOnly(lastDate),
  ),
);

class _RangeSheet extends StatefulWidget {
  const _RangeSheet({
    required this.title,
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final String title;
  final PaymentDateRange? initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late DateTime? _start = widget.initial?.start;
  late DateTime? _end = widget.initial?.end;
  bool _typed = false;

  bool _inRange(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  /// First tap sets the start, the second the end; a tap before the start,
  /// or after a complete range, starts again.
  void _pick(DateTime d) => setState(() {
    if (_start == null || _end != null || d.isBefore(_start!)) {
      _start = d;
      _end = null;
    } else {
      _end = d;
    }
  });

  String? _typedError(DateTime? d) {
    final l = PaymentLocalizations.of(context);
    if (d == null || _inRange(d)) return null;
    return l.dateOutOfRange(
      l.formatDate(widget.firstDate),
      l.formatDate(widget.lastDate),
    );
  }

  bool get _valid =>
      _start != null &&
      _inRange(_start!) &&
      (_end == null || (_inRange(_end!) && !_end!.isBefore(_start!)));

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final gutter = t.space(PaymentSpace.group);
    final summary = switch ((_start, _end)) {
      (null, _) => Text(
        l.chooseDates,
        style: type.label.copyWith(color: t.textSecondary),
      ),
      (final s?, null) => Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${l.formatDate(s)} – '),
            TextSpan(
              text: l.chooseEndDate,
              style: TextStyle(color: t.textSecondary),
            ),
          ],
        ),
        style: type.label,
      ),
      (final s?, final e?) => Text(l.formatDateRange(s, e), style: type.label),
    };
    final endError = _start != null && _end != null && _end!.isBefore(_start!)
        ? l.startAfterEnd
        : _typedError(_end);
    return KitFullSheet(
      header: PaymentSheetHeader(
        title: widget.title,
        onClose: () => Navigator.pop(context),
      ),
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaymentButton(
            label: _typed ? l.useCalendar : l.typeDates,
            icon: _typed
                ? Icons.calendar_month_outlined
                : Icons.keyboard_outlined,
            variant: PaymentButtonVariant.secondary,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
            onPressed: () => setState(() => _typed = !_typed),
          ),
          if (!_typed) const WeekdayHeader(),
        ],
      ),
      body: _typed
          ? SingleChildScrollView(
              padding: EdgeInsets.all(gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gutter,
                children: [
                  PaymentDateField(
                    label: l.startDate,
                    value: _start,
                    onChanged: (d) => setState(() => _start = d),
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    errorText: _typedError(_start),
                    textInputAction: TextInputAction.next,
                  ),
                  PaymentDateField(
                    label: l.endDate,
                    value: _end,
                    onChanged: (d) => setState(() => _end = d),
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    errorText: endError,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            )
          : MonthList(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              initialMonth: _clamp(
                _start ?? today,
                widget.firstDate,
                widget.lastDate,
              ),
              start: _start,
              end: _end,
              range: true,
              onPick: _pick,
            ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.space(PaymentSpace.related),
        children: [
          Semantics(liveRegion: true, child: summary),
          PaymentButton(
            label: l.applyDates,
            onPressed: _valid
                ? () => Navigator.pop(
                    context,
                    KitRangeResult(
                      PaymentDateRange(start: _start!, end: _end ?? _start!),
                    ),
                  )
                : null,
          ),
          PaymentButton(
            label: l.clear,
            variant: PaymentButtonVariant.quiet,
            onPressed: _start == null && widget.initial == null
                ? null
                : () => Navigator.pop(context, const KitRangeResult(null)),
          ),
        ],
      ),
    );
  }
}
