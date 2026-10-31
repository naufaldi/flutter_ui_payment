import 'package:flutter/material.dart';
import '../foundation/money.dart';

enum ChartPointStatus { settled, pending, unknown }

@immutable
class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.value,
    this.status = ChartPointStatus.settled,
    this.spokenLabel,
  });
  final String label;

  /// Null is missing data, never zero.
  final Money? value;
  final ChartPointStatus status;
  final String? spokenLabel;
}

@immutable
class MeterSegment {
  MeterSegment({
    required this.label,
    required this.value,
    this.status = ChartPointStatus.settled,
    this.color,
  }) : assert(!value.isNegative);
  final String label;
  final Money value;
  final ChartPointStatus status;
  final Color? color;
}

enum ChartState { loading, ready, empty, error }
