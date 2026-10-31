import 'package:flutter/material.dart';
import '../foundation/money.dart';

/// Settlement state of a reading.
enum ChartPointStatus {
  /// Confirmed reading.
  settled,

  /// Awaiting confirmation.
  pending,

  /// Not yet confirmed.
  unknown,
}

/// One period reading, with missing values distinct from zero.
@immutable
class ChartPoint {
  /// Creates a period reading.
  const ChartPoint({
    required this.label,
    this.value,
    this.status = ChartPointStatus.settled,
    this.spokenLabel,
    this.measure,
  });

  /// Visible period or category label.
  final String label;

  /// Null is missing data, never zero.
  final Money? value;

  /// Host-computed quantity; null is missing data.
  final num? measure;

  /// Settlement state; never encoded by a series color.
  final ChartPointStatus status;

  /// Optional expanded period name for spoken summaries.
  final String? spokenLabel;
}

/// One non-negative category in a meter.
@immutable
class MeterSegment {
  /// Creates a category reading.
  MeterSegment({
    required this.label,
    this.value,
    this.status = ChartPointStatus.settled,
    this.measure,
  }) : assert(value != null || measure != null),
       assert(value == null || !value.isNegative),
       assert(measure == null || measure >= 0);

  /// Visible period or category label.
  final String label;

  /// Money reading when using currency units.
  final Money? value;

  /// Settlement state; never encoded by a series color.
  final ChartPointStatus status;

  /// Host-computed non-negative quantity.
  final num? measure;
}

/// Host-owned chart loading state.
enum ChartState {
  /// Fetch in progress.
  loading,

  /// Data available.
  ready,

  /// No data available.
  empty,

  /// Fetch failed.
  error,
}

/// Axes to label or grid.
enum PaymentChartAxis {
  /// Horizontal axis.
  x,

  /// Vertical axis.
  y,

  /// Both axes.
  both,

  /// Neither axis.
  none,
}

/// How a chart reads its values.
enum PaymentChartUnit {
  /// Currency amounts.
  money,

  /// Host-computed percentages, where 45 means 45 percent.
  percent,

  /// Plain counts or quantities.
  number,
}

/// Named points sharing the same periods with the other series.
@immutable
class PaymentChartSeries {
  /// Creates a series.
  const PaymentChartSeries({required this.label, required this.points});

  /// Legend and spoken name.
  final String label;

  /// One point per period.
  final List<ChartPoint> points;
}
