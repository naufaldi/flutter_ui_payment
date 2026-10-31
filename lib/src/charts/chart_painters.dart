import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../foundation/hatch.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import 'chart_geometry.dart';
import 'chart_models.dart';

class ChartPainter extends CustomPainter {
  ChartPainter({
    required this.series,
    required this.unit,
    required this.colors,
    required this.showX,
    required this.showY,
    required this.gridX,
    required this.gridY,
    required this.theme,
    required this.l10n,
    required this.style,
    required this.scaler,
    this.bars = false,
    this.spark = false,
    this.zeroBased = false,
    this.selected,
  });
  final List<PaymentChartSeries> series;
  final PaymentChartUnit unit;
  final List<Color> colors;
  final bool showX, showY, gridX, gridY;
  List<ChartPoint> get points => series.first.points;
  final PaymentTheme theme;
  final PaymentLocalizations l10n;
  final TextStyle style;
  final TextScaler scaler;
  final bool bars;
  final bool spark;
  final bool zeroBased;
  final int? selected;

  Rect plot(Size size) => Rect.fromLTRB(
    spark ? 4 : (showY && size.width >= 200 ? 76 : 8),
    spark ? 5 : 22,
    size.width - 8,
    math.max(spark ? 5 : 22, size.height - (spark ? 5 : (showX ? 28 : 8))),
  );

  TextPainter text(String value) => TextPainter(
    text: TextSpan(
      text: value,
      style: style.copyWith(color: theme.textSecondary),
    ),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final area = plot(size);
    if (series.isEmpty || points.isEmpty || area.height <= 0) return;
    final values = series
        .expand((s) => s.points)
        .map((p) => chartReading(p, unit))
        .whereType<num>()
        .map((v) => v.toDouble());
    final ticks = niceTicks(values, zeroBased: bars || zeroBased);
    if (!spark) {
      final currency =
          points.where((p) => p.value != null).firstOrNull?.value?.currency ??
          'IDR';
      for (var i = 0; i < ticks.length; i++) {
        final y = area.bottom - area.height * i / 2;
        if (gridY) {
          canvas.drawLine(
            Offset(area.left, y),
            Offset(area.right, y),
            Paint()
              ..color = theme.outline
              ..strokeWidth = 1,
          );
        }
        if (showY && size.width >= 200) {
          final label = text(
            formatChartValue(
              l10n,
              ticks[i],
              unit,
              currency: currency,
              axis: true,
            ),
          );
          if (i != 1 || label.height < area.height / 2) {
            label.paint(canvas, Offset(0, y - label.height / 2));
          }
        }
      }
      final labels = points.map((p) => text(p.label)).toList();
      final widest = labels.map((p) => p.width).reduce(math.max);
      final stride = math.max(
        1,
        ((widest + 12) / (area.width / points.length)).ceil(),
      );
      double previousEnd = -double.infinity;
      for (var i = 0; i < points.length; i++) {
        if (i != 0 &&
            i != points.length - 1 &&
            (size.width < 200 || i % stride != 0)) {
          continue;
        }
        final x = bars
            ? area.left + area.width * (i + .5) / points.length
            : points.length == 1
            ? area.center.dx
            : area.left + area.width * i / (points.length - 1);
        final label = labels[i];
        final left = (x - label.width / 2).clamp(
          0.0,
          math.max(0.0, size.width - label.width),
        );
        final lastWidth = labels.last.width;
        if (i != points.length - 1 &&
            i != 0 &&
            (left < previousEnd + 6 ||
                left + label.width > size.width - lastWidth - 6)) {
          continue;
        }
        if (gridX) {
          canvas.drawLine(
            Offset(x, area.top),
            Offset(x, area.bottom),
            Paint()..color = theme.outline,
          );
        }
        if (showX) {
          label.paint(canvas, Offset(left.toDouble(), area.bottom + 6));
        }
        previousEnd = left + label.width;
      }
    }
    canvas.save();
    canvas.clipRect(area.inflate(5));
    final grouped = bars
        ? groupedBarRects(series, area, unit)
        : <List<Rect?>>[];
    for (var j = 0; j < series.length; j++) {
      final points = series[j].points;
      final color = colors[j];
      if (bars) {
        final rects = grouped[j];
        for (var i = 0; i < points.length; i++) {
          final rect = rects[i];
          if (rect == null) {
            final x = area.left + area.width * (i + .5) / points.length;
            dash(
              canvas,
              Offset(x - 4, area.bottom),
              Offset(x + 4, area.bottom),
              theme.border,
              2,
              2,
            );
          } else {
            paintChartRect(
              canvas,
              rect,
              points[i].status,
              color,
              theme.surface,
            );
          }
        }
      } else {
        final offsets = linePoints(
          points,
          area,
          zeroBased: zeroBased,
          ticks: ticks,
          unit: unit,
        );
        for (var i = 0; i < offsets.length; i++) {
          final point = offsets[i];
          if (point == null) continue;
          if (i > 0 && offsets[i - 1] != null) {
            final status = points[i].status == ChartPointStatus.settled
                ? points[i - 1].status
                : points[i].status;
            if (status == ChartPointStatus.settled && seriesDash[j] == null) {
              canvas.drawLine(
                offsets[i - 1]!,
                point,
                Paint()
                  ..color = color
                  ..strokeWidth = spark ? 1.5 : 2,
              );
            } else {
              dashPattern(
                canvas,
                offsets[i - 1]!,
                point,
                color,
                status == ChartPointStatus.pending
                    ? [4, 3]
                    : status == ChartPointStatus.unknown
                    ? [1.5, 3]
                    : seriesDash[j]!,
                spark ? 1.5 : 2,
              );
            }
          }
          final paint = Paint()
            ..color = color
            ..strokeWidth = 1.5;
          switch (points[i].status) {
            case ChartPointStatus.pending:
              canvas.drawCircle(point, 4, Paint()..color = theme.surface);
              canvas.drawCircle(point, 4, paint..style = PaintingStyle.stroke);
            case ChartPointStatus.unknown:
              final square = Rect.fromCenter(
                center: point,
                width: 7,
                height: 7,
              );
              canvas.drawRect(square, Paint()..color = theme.surface);
              canvas.drawRect(square, paint..style = PaintingStyle.stroke);
            case ChartPointStatus.settled:
              if (i == offsets.length - 1 ||
                  (i == 0 || offsets[i - 1] == null) &&
                      (i == offsets.length - 1 || offsets[i + 1] == null)) {
                canvas.drawCircle(point, spark ? 2 : 3.5, paint);
              }
          }
        }
      }
    }
    if (selected != null && selected! < points.length) {
      final x = bars
          ? area.left + area.width * (selected! + .5) / points.length
          : points.length == 1
          ? area.center.dx
          : area.left + area.width * selected! / (points.length - 1);
      canvas.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        Paint()
          ..color = theme.outline
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) => true;
}

void dash(
  Canvas canvas,
  Offset from,
  Offset to,
  Color color,
  double length,
  double gap,
) {
  final distance = (to - from).distance;
  if (distance == 0) return;
  final direction = (to - from) / distance;
  for (var x = 0.0; x < distance; x += length + gap) {
    canvas.drawLine(
      from + direction * x,
      from + direction * math.min(distance, x + length),
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );
  }
}

void paintChartRect(
  Canvas canvas,
  Rect rect,
  ChartPointStatus status,
  Color color,
  Color surface,
) {
  switch (status) {
    case ChartPointStatus.settled:
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    case ChartPointStatus.pending:
      canvas.drawRect(rect, Paint()..color = surface);
      canvas.drawRect(
        rect.deflate(.75),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    case ChartPointStatus.unknown:
      paintHatch(canvas, rect, color: color, background: surface);
  }
}

class MeterPainter extends CustomPainter {
  MeterPainter(this.segments, this.colors, this.surface, this.unit);
  final PaymentChartUnit unit;
  final List<MeterSegment> segments;
  final List<Color> colors;
  final Color surface;
  @override
  void paint(Canvas canvas, Size size) {
    final rects = meterRects(segments, Offset.zero & size, unit: unit);
    for (var i = 0; i < rects.length; i++) {
      paintChartRect(canvas, rects[i], segments[i].status, colors[i], surface);
    }
  }

  @override
  bool shouldRepaint(MeterPainter oldDelegate) => true;
}

const seriesDash = <List<double>?>[
  null,
  [8, 4],
  [8, 3, 2, 3],
];
void dashPattern(
  Canvas canvas,
  Offset from,
  Offset to,
  Color color,
  List<double> pattern,
  double width,
) {
  final distance = (to - from).distance;
  if (distance == 0) return;
  final direction = (to - from) / distance;
  var x = 0.0;
  var i = 0;
  while (x < distance) {
    final end = math.min(distance, x + pattern[i % pattern.length]);
    if (i.isEven) {
      canvas.drawLine(
        from + direction * x,
        from + direction * end,
        Paint()
          ..color = color
          ..strokeWidth = width,
      );
    }
    x = end;
    i++;
  }
}
