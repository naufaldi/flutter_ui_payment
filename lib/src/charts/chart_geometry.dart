import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../foundation/kit_strings.dart';
import '../foundation/money.dart';
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
  PaymentChartUnit unit = PaymentChartUnit.money,
  List<double>? ticks,
}) {
  ticks ??= niceTicks(
    points
        .where((p) => chartReading(p, unit) != null)
        .map((p) => chartReading(p, unit)!.toDouble()),
    zeroBased: zeroBased,
  );
  return List.generate(
    points.length,
    (i) => chartReading(points[i], unit) == null
        ? null
        : Offset(
            points.length == 1
                ? plot.center.dx
                : plot.left + plot.width * i / (points.length - 1),
            plot.bottom -
                (chartReading(points[i], unit)! - ticks!.first) /
                    (ticks.last - ticks.first) *
                    plot.height,
          ),
  );
}

List<Rect?> barRects(
  List<ChartPoint> points,
  Rect plot, {
  PaymentChartUnit unit = PaymentChartUnit.money,
}) {
  assert(
    points.every(
      (p) => chartReading(p, unit) == null || chartReading(p, unit)! >= 0,
    ),
  );
  if (points.isEmpty) return [];
  final maximum = niceTicks(
    points
        .where((p) => chartReading(p, unit) != null)
        .map((p) => chartReading(p, unit)!.toDouble()),
    zeroBased: true,
  ).last;
  final slot = plot.width / points.length;
  final width = math.min(slot * .6, 32.0);
  return List.generate(points.length, (i) {
    final value = chartReading(points[i], unit);
    if (value == null) return null;
    final height = math.min(
      plot.height,
      math.max(2.0, value / maximum * plot.height),
    );
    return Rect.fromLTWH(
      plot.left + slot * (i + .5) - width / 2,
      plot.bottom - height,
      width,
      height,
    );
  });
}

List<Rect> meterRects(
  List<MeterSegment> segments,
  Rect plot, {
  PaymentChartUnit unit = PaymentChartUnit.money,
}) {
  final total = segments.fold<num>(0, (sum, s) => sum + meterReading(s, unit));
  var x = plot.left;
  final available = math.max(
    0.0,
    plot.width - math.max(0, segments.length - 1) * 2,
  );
  return segments.map((s) {
    final width = total == 0 ? 0.0 : available * meterReading(s, unit) / total;
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
  List<ChartPoint> points, [
  PaymentChartUnit unit = PaymentChartUnit.money,
  bool includeRange = true,
]) {
  final settled = points
      .where(
        (p) =>
            chartReading(p, unit) != null &&
            p.status == ChartPointStatus.settled,
      )
      .toList();
  final parts = <String>[kind];
  if (includeRange && points.isNotEmpty) {
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
    final sorted = [
      ...settled,
    ]..sort((a, b) => chartReading(a, unit)!.compareTo(chartReading(b, unit)!));
    String amount(ChartPoint p) => spokenChartValue(
      l10n,
      chartReading(p, unit)!,
      unit,
      currency: p.value?.currency ?? 'IDR',
    );
    String label(ChartPoint p) => p.spokenLabel ?? p.label;
    parts.addAll([
      l10n.chartLowest(amount(sorted.first), label(sorted.first)),
      l10n.chartHighest(amount(sorted.last), label(sorted.last)),
      l10n.chartLatest(amount(settled.last), label(settled.last)),
    ]);
  }
  final pending = points
      .where(
        (p) =>
            chartReading(p, unit) != null &&
            p.status == ChartPointStatus.pending,
      )
      .length;
  final unknown = points
      .where(
        (p) =>
            chartReading(p, unit) != null &&
            p.status == ChartPointStatus.unknown,
      )
      .length;
  final missing = points.where((p) => chartReading(p, unit) == null).length;
  if (pending > 0) parts.add(l10n.chartPendingCount(pending));
  if (unknown > 0) parts.add(l10n.chartUnknownCount(unknown));
  if (missing > 0) parts.add(l10n.chartMissingCount(missing));
  return parts.join(' ');
}

num? chartReading(ChartPoint p, PaymentChartUnit unit) =>
    unit == PaymentChartUnit.money ? p.value?.minorUnits : p.measure;
num meterReading(MeterSegment s, PaymentChartUnit unit) =>
    (unit == PaymentChartUnit.money ? s.value?.minorUnits : s.measure) ?? 0;
String formatChartValue(
  PaymentLocalizations l10n,
  num value,
  PaymentChartUnit unit, {
  String currency = 'IDR',
  bool axis = false,
}) {
  if (unit == PaymentChartUnit.money) {
    final money = Money(value.round(), currency);
    return axis
        ? l10n.moneyFormat.compact(money)
        : l10n.moneyFormat.format(money);
  }
  final parts = value
      .toStringAsFixed(1)
      .replaceFirst(RegExp(r'\.0$'), '')
      .split('.');
  final id = l10n.languageCode == 'id';
  final whole = unit == PaymentChartUnit.number
      ? parts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}${id ? '.' : ','}',
        )
      : parts[0];
  final digits =
      '$whole${parts.length == 2 ? '${id ? ',' : '.'}${parts[1]}' : ''}';
  return unit == PaymentChartUnit.percent ? '$digits%' : digits;
}

String spokenChartValue(
  PaymentLocalizations l10n,
  num value,
  PaymentChartUnit unit, {
  String currency = 'IDR',
}) {
  if (unit == PaymentChartUnit.money) {
    return l10n.moneyFormat.spoken(Money(value.round(), currency));
  }
  final text = formatChartValue(l10n, value, unit);
  return unit == PaymentChartUnit.percent
      ? l10n.chartPercent(text.replaceAll('%', ''))
      : text;
}

List<List<Rect?>> groupedBarRects(
  List<PaymentChartSeries> series,
  Rect plot,
  PaymentChartUnit unit,
) {
  if (series.isEmpty || series.first.points.isEmpty) return [];
  final n = series.length;
  final count = series.first.points.length;
  final slot = plot.width / count;
  final group = math.min(slot * .6, 32.0 * n);
  final width = (group - 2 * (n - 1)) / n;
  final max = niceTicks(
    series
        .expand((s) => s.points)
        .map((p) => chartReading(p, unit))
        .whereType<num>()
        .map((v) => v.toDouble()),
    zeroBased: true,
  ).last;
  return List.generate(
    n,
    (j) => List.generate(count, (i) {
      final value = chartReading(series[j].points[i], unit);
      if (value == null) return null;
      final height = math.min(
        plot.height,
        math.max(2.0, value / max * plot.height),
      );
      return Rect.fromLTWH(
        plot.left + slot * (i + .5) - group / 2 + j * (width + 2),
        plot.bottom - height,
        width,
        height,
      );
    }),
  );
}
