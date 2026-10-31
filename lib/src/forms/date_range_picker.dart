import 'package:flutter/material.dart';
import '../controls/controls.dart';
import '../foundation/field_decoration.dart';
import '../foundation/field_trigger.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/primitives.dart';
import '../interaction/interaction.dart';
import '../overlay/sheets.dart';

/// Calendar grouping. Nothing else exists.
enum PaymentDateGranularity {
  /// Daily.
  day,

  /// Weekly.
  week,

  /// Monthly.
  month,

  /// Yearly.
  year,
}

/// A host-named complete calendar range.
@immutable
class PaymentDatePreset {
  const PaymentDatePreset({
    required this.label,
    required this.start,
    required this.end,
  });

  /// Visible name identifying this value or control.
  final String label;

  /// First included calendar day in the host zone.
  final DateTime start;

  /// Last included calendar day in the host zone.
  final DateTime end;
  @override
  bool operator ==(Object other) =>
      other is PaymentDatePreset &&
      other.label == label &&
      other.start == start &&
      other.end == end;
  @override
  int get hashCode => Object.hash(label, start, end);
}

/// A complete range in the host zone, optionally from a preset.
@immutable
class PaymentDateRange {
  const PaymentDateRange({required this.start, required this.end})
    : preset = null;
  PaymentDateRange.fromPreset(PaymentDatePreset this.preset)
    : start = preset.start,
      end = preset.end;

  /// First included calendar day in the host zone.
  final DateTime start;

  /// Last included calendar day in the host zone.
  final DateTime end;

  /// Named host range used for this selection, if any.
  final PaymentDatePreset? preset;
  @override
  bool operator ==(Object other) =>
      other is PaymentDateRange &&
      other.start == start &&
      other.end == end &&
      other.preset == preset;
  @override
  int get hashCode => Object.hash(start, end, preset);
}

/// Preset sheet or Flutter range calendar; performs no zone conversion.
class PaymentDateRangePicker extends StatefulWidget {
  const PaymentDateRangePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.presets = const [],
    this.granularity,
    this.onGranularityChanged,
    this.description,
    this.errorText,
    this.size = PaymentSize.medium,
    this.enabled = true,
  });

  /// Visible name identifying this value or control.
  final String label;

  /// Current host-selected range.
  final PaymentDateRange? value;

  /// Reports the selected range to the host.
  final ValueChanged<PaymentDateRange?> onChanged;

  /// Earliest selectable day in the host zone.
  final DateTime firstDate;

  /// Last selectable day in the host zone.
  final DateTime lastDate;

  /// Named ranges offered before the custom calendar.
  final List<PaymentDatePreset> presets;

  /// Current host-selected grouping of calendar periods.
  final PaymentDateGranularity? granularity;

  /// Reports a grouping choice to the host.
  final ValueChanged<PaymentDateGranularity>? onGranularityChanged;

  /// Persistent explanation below the heading or label.
  final String? description;

  /// Safe error copy displayed with the affected content.
  final String? errorText;

  /// Semantic control size; hit targets remain at least 48 dp.
  final PaymentSize size;

  /// Whether the customer can change this control.
  final bool enabled;
  @override
  State<PaymentDateRangePicker> createState() => _PaymentDateRangePickerState();
}

class _PaymentDateRangePickerState extends State<PaymentDateRangePicker> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _custom() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDateRange: widget.value == null
          ? null
          : DateTimeRange(start: widget.value!.start, end: widget.value!.end),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (mounted && r != null) {
      widget.onChanged(
        PaymentDateRange(
          start: DateUtils.dateOnly(r.start),
          end: DateUtils.dateOnly(r.end),
        ),
      );
    }
  }

  Future<void> _open() async {
    final l = PaymentLocalizations.of(context);
    if (widget.presets.isEmpty) {
      await _custom();
    } else {
      final r = await showPaymentSheet<Object?>(
        context: context,
        builder: (context) => PaymentSheet(
          header: PaymentSheetHeader(
            title: widget.label,
            onClose: () => Navigator.pop(context),
          ),
          body: Column(
            children: [
              for (final p in widget.presets)
                PaymentRadio<PaymentDatePreset>(
                  value: p,
                  groupValue: widget.value?.preset,
                  label: p.label,
                  description: l.formatDateRange(p.start, p.end),
                  onChanged: (v) => Navigator.pop(context, v),
                ),
              PaymentListItem(
                title: l.customRange,
                onPressed: () => Navigator.pop(context, #custom),
              ),
            ],
          ),
          footer: widget.value == null
              ? null
              : PaymentButton(
                  label: l.clearDates,
                  variant: PaymentButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context, #clear),
                ),
        ),
      );
      if (!mounted) return;
      if (r is PaymentDatePreset) {
        widget.onChanged(PaymentDateRange.fromPreset(r));
      }
      if (r == #custom) await _custom();
      if (r == #clear) widget.onChanged(null);
    }
    if (mounted) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    final v = widget.value;
    final range = v == null ? null : l.formatDateRange(v.start, v.end);
    final enabled =
        widget.enabled && !(FieldGroupScope.of(context)?.disabled ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.related),
      children: [
        FieldTrigger(
          label: widget.label,
          value: v?.preset == null ? range : '${v!.preset!.label} · $range',
          hint: l.chooseDates,
          description: widget.description,
          errorText: widget.errorText,
          size: widget.size,
          enabled: enabled,
          focusNode: _focus,
          trailing: const PaymentIcon(
            Icons.date_range_outlined,
            color: PaymentTextColor.secondary,
          ),
          onPressed: _open,
        ),
        if (widget.granularity != null && widget.onGranularityChanged != null)
          PaymentTabs(
            size: PaymentSize.small,
            fitted: true,
            tabs: [
              for (final g in PaymentDateGranularity.values)
                PaymentTab(label: l.dateGranularity(g)),
            ],
            selectedIndex: widget.granularity!.index,
            onSelected: (i) {
              if (enabled) {
                widget.onGranularityChanged!(PaymentDateGranularity.values[i]);
              }
            },
          ),
      ],
    );
  }
}
