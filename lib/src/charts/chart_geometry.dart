import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import 'chart_models.dart';

List<double> niceTicks(Iterable<double> values, {bool zeroBased = false}) {
  final data = values.toList();
  var low = data.isEmpty ? 0.0 : data.reduce(math.min);
  var high = data.isEmpty ? 1.0 : data.reduce(math.max);
  if (zeroBased) low = math.min(0, low);
  if (high == low) high = low + math.max(1, low.abs() * .1);
  final raw = (high - low) / 2;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final step = [
    1,
    2,
    2.5,
    5,
    10,
  ].map((n) => n * magnitude).firstWhere((n) => n >= raw);
  final start = (low / step).floor() * step;
  final end = (high / step).ceil() * step;
  return [start, (start + end) / 2, end];
}

List<Offset?> linePoints(
  List<ChartPoint> points,
  Rect plot, {
  bool zeroBased = false,
}) {
  final ticks = niceTicks(
    points
        .where((p) => p.value != null)
        .map((p) => p.value!.minorUnits.toDouble()),
    zeroBased: zeroBased,
  );
  return List.generate(
    points.length,
    (i) => points[i].value == null
        ? null
        : Offset(
            points.length == 1
                ? plot.center.dx
                : plot.left + plot.width * i / (points.length - 1),
            plot.bottom -
                (points[i].value!.minorUnits - ticks.first) /
                    (ticks.last - ticks.first) *
                    plot.height,
          ),
  );
}

List<Rect?> barRects(List<ChartPoint> points, Rect plot) {
  assert(points.every((p) => p.value == null || !p.value!.isNegative));
  if (points.isEmpty) return [];
  final maximum = niceTicks(
    points
        .where((p) => p.value != null)
        .map((p) => p.value!.minorUnits.toDouble()),
    zeroBased: true,
  ).last;
  final slot = plot.width / points.length;
  final width = math.min(slot * .6, 32.0);
  return List.generate(points.length, (i) {
    final value = points[i].value;
    if (value == null) return null;
    final height = math.min(
      plot.height,
      math.max(2.0, value.minorUnits / maximum * plot.height),
    );
    return Rect.fromLTWH(
      plot.left + slot * (i + .5) - width / 2,
      plot.bottom - height,
      width,
      height,
    );
  });
}

List<Rect> meterRects(List<MeterSegment> segments, Rect plot) {
  final total = segments.fold<int>(0, (sum, s) => sum + s.value.minorUnits);
  var x = plot.left;
  final available = math.max(
    0.0,
    plot.width - math.max(0, segments.length - 1) * 2,
  );
  return segments.map((s) {
    final width = total == 0 ? 0.0 : available * s.value.minorUnits / total;
    final rect = Rect.fromLTWH(x, plot.top, width, plot.height);
    x += width + 2;
    return rect;
  }).toList();
}

List<Color> meterColors(PaymentTheme theme, int n) {
  assert(n <= 5);
  return List.generate(n, (i) {
    var t = [0.0, .25, .45, .6, .7][i];
    var color = Color.lerp(theme.accent, theme.surface, t)!;
    double contrast(Color c) {
      final a = c.computeLuminance();
      final b = theme.surface.computeLuminance();
      return (math.max(a, b) + .05) / (math.min(a, b) + .05);
    }

    while (t > 0 && contrast(color) < 3) {
      t = math.max(0, t - .025);
      color = Color.lerp(theme.accent, theme.surface, t)!;
    }
    return color;
  });
}

String chartSummary(
  PaymentLocalizations l10n,
  String kind,
  List<ChartPoint> points,
) {
  final settled = points
      .where((p) => p.value != null && p.status == ChartPointStatus.settled)
      .toList();
  final parts = <String>[kind];
  if (points.isNotEmpty) {
    parts.add(
      l10n.chartRange(
        points.first.spokenLabel ?? points.first.label,
        points.last.spokenLabel ?? points.last.label,
        points.length,
      ),
    );
  }
  if (settled.isEmpty) {
    parts.add(l10n.chartNoData);
  } else {
    final sorted = [...settled]..sort((a, b) => a.value!.compareTo(b.value!));
    String amount(ChartPoint p) => l10n.moneyFormat.spoken(p.value!);
    String label(ChartPoint p) => p.spokenLabel ?? p.label;
    parts.addAll([
      l10n.chartLowest(amount(sorted.first), label(sorted.first)),
      l10n.chartHighest(amount(sorted.last), label(sorted.last)),
      l10n.chartLatest(amount(settled.last), label(settled.last)),
    ]);
  }
  final pending = points
      .where((p) => p.value != null && p.status == ChartPointStatus.pending)
      .length;
  final unknown = points
      .where((p) => p.value != null && p.status == ChartPointStatus.unknown)
      .length;
  final missing = points.where((p) => p.value == null).length;
  if (pending > 0) parts.add(l10n.chartPendingCount(pending));
  if (unknown > 0) parts.add(l10n.chartUnknownCount(unknown));
  if (missing > 0) parts.add(l10n.chartMissingCount(missing));
  return parts.join(' ');
}
