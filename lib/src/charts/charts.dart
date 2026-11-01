import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../foundation/kit_strings.dart';
import '../foundation/money.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../foundation/row_shell.dart';
import '../foundation/payment_tokens.dart';
import '../interaction/interaction.dart';
import '../controls/controls.dart';
import 'chart_geometry.dart';
import 'chart_models.dart';
import 'chart_painters.dart';

bool _oneCurrency(Iterable<Money?> values) =>
    values.whereType<Money>().map((v) => v.currency).toSet().length <= 1;

/// Trends across periods, with gaps for missing readings.
class PaymentLineChart extends StatefulWidget {
  /// Creates a chart.
  const PaymentLineChart({
    super.key,
    this.points = const [],
    this.series = const [],
    this.unit = PaymentChartUnit.money,
    this.axis = PaymentChartAxis.both,
    this.grid = PaymentChartAxis.y,
    this.showLegend = true,
    this.zeroBased = false,
    this.inspectable = true,
    this.semanticLabel,
  });

  /// Single-series points; leave empty when providing series.
  final List<ChartPoint> points;

  /// Named series with matching period labels; at most three.
  final List<PaymentChartSeries> series;

  /// Which reading to display and announce.
  final PaymentChartUnit unit;

  /// Axes whose labels are visible.
  final PaymentChartAxis axis;

  /// Axes whose grid rules are visible.
  final PaymentChartAxis grid;

  /// Whether to show the series legend.
  final bool showLegend;

  /// Whether the scale includes zero.
  final bool zeroBased;

  /// Whether pointer gestures select a reading.
  final bool inspectable;

  /// Host-authored replacement for the generated summary.
  final String? semanticLabel;
  @override
  State<PaymentLineChart> createState() => _PaymentLineChartState();
}

class _PaymentLineChartState extends State<PaymentLineChart> {
  @override
  Widget build(BuildContext context) => _PointChart(
    points: widget.points,
    series: widget.series,
    unit: widget.unit,
    axis: widget.axis,
    grid: widget.grid,
    showLegend: widget.showLegend,
    zeroBased: widget.zeroBased,
    inspectable: widget.inspectable,
    semanticLabel: widget.semanticLabel,
  );
}

/// Non-negative grouped readings across periods.
class PaymentBarChart extends StatefulWidget {
  /// Creates a chart.
  const PaymentBarChart({
    super.key,
    this.points = const [],
    this.series = const [],
    this.unit = PaymentChartUnit.money,
    this.axis = PaymentChartAxis.both,
    this.grid = PaymentChartAxis.y,
    this.showLegend = true,
    this.inspectable = true,
    this.semanticLabel,
  });

  /// Single-series points; leave empty when providing series.
  final List<ChartPoint> points;

  /// Named series with matching period labels; at most three.
  final List<PaymentChartSeries> series;

  /// Which reading to display and announce.
  final PaymentChartUnit unit;

  /// Axes whose labels are visible.
  final PaymentChartAxis axis;

  /// Axes whose grid rules are visible.
  final PaymentChartAxis grid;

  /// Whether to show the series legend.
  final bool showLegend;

  /// Whether pointer gestures select a reading.
  final bool inspectable;

  /// Host-authored replacement for the generated summary.
  final String? semanticLabel;
  @override
  State<PaymentBarChart> createState() => _PaymentBarChartState();
}

class _PaymentBarChartState extends State<PaymentBarChart> {
  @override
  Widget build(BuildContext context) => _PointChart(
    points: widget.points,
    series: widget.series,
    unit: widget.unit,
    axis: widget.axis,
    grid: widget.grid,
    showLegend: widget.showLegend,
    bars: true,
    inspectable: widget.inspectable,
    semanticLabel: widget.semanticLabel,
  );
}

/// Compact trend with optional pointer inspection.
class PaymentSparkline extends StatelessWidget {
  /// Creates a chart.
  const PaymentSparkline({
    super.key,
    this.points = const [],
    this.series = const [],
    this.unit = PaymentChartUnit.money,
    this.inspectable = false,
    this.width = 80,
    this.height = 24,
    this.semanticLabel,
  });

  /// Single-series points; leave empty when providing series.
  final List<ChartPoint> points;

  /// Named series with matching period labels; at most three.
  final List<PaymentChartSeries> series;

  /// Which reading to display and announce.
  final PaymentChartUnit unit;

  /// Whether pointer gestures select a reading.
  final bool inspectable;

  /// Width.
  final double width;

  /// Height.
  final double height;

  /// Host-authored replacement for the generated summary.
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: inspectable ? math.max(height, 48) : height,
    child: _PointChart(
      points: points,
      series: series,
      unit: unit,
      axis: PaymentChartAxis.none,
      grid: PaymentChartAxis.none,
      showLegend: false,
      spark: true,
      inspectable: inspectable,
      semanticLabel: semanticLabel,
    ),
  );
}

class _PointChart extends StatefulWidget {
  const _PointChart({
    this.points = const [],
    this.series = const [],
    this.unit = PaymentChartUnit.money,
    this.axis = PaymentChartAxis.both,
    this.grid = PaymentChartAxis.y,
    this.showLegend = true,
    this.bars = false,
    this.spark = false,
    this.zeroBased = false,
    this.inspectable = true,
    this.semanticLabel,
  });

  /// Single-series points; leave empty when providing series.
  final List<ChartPoint> points;

  /// Named series with matching period labels; at most three.
  final List<PaymentChartSeries> series;

  /// Which reading to display and announce.
  final PaymentChartUnit unit;

  /// Axes whose labels are visible.
  final PaymentChartAxis axis;

  /// Axes whose grid rules are visible.
  final PaymentChartAxis grid;

  /// Whether to show the series legend.
  final bool showLegend;

  /// Bars.
  final bool bars;

  /// Spark.
  final bool spark;

  /// Whether the scale includes zero.
  final bool zeroBased;

  /// Whether pointer gestures select a reading.
  final bool inspectable;

  /// Host-authored replacement for the generated summary.
  final String? semanticLabel;
  @override
  State<_PointChart> createState() => _PointChartState();
}

class _PointChartState extends State<_PointChart> {
  /// The period a tap, drag or hover picked; null is the rest state.
  int? selected;

  // Readout layouts by width, measured for [_readoutKey]. A tap, drag or
  // hover only changes the selection, so it reuses them (#78).
  Object? _readoutKey;
  final _readoutLayouts = <double, ({bool stacked, int lines})>{};

  static List<String> _periods(_PointChart chart) => [
    for (final p
        in chart.series.isEmpty ? chart.points : chart.series.first.points)
      p.label,
  ];

  // Different periods return the chart to rest, so a stale index never
  // outlives the periods it pointed at. A rebuild with the same periods
  // keeps the person's selection.
  @override
  void didUpdateWidget(_PointChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_periods(oldWidget), _periods(widget))) selected = null;
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.points.isEmpty || widget.series.isEmpty);
    assert(widget.series.length <= (widget.spark ? 2 : 3));
    final series = widget.series.isEmpty
        ? [PaymentChartSeries(label: '', points: widget.points)]
        : widget.series;
    final points = series.first.points;
    assert(
      series.every(
        (s) =>
            s.points.length == points.length &&
            List.generate(
              points.length,
              (i) => s.points[i].label == points[i].label,
            ).every((v) => v),
      ),
    );
    final all = series.expand((s) => s.points);
    assert(
      widget.unit != PaymentChartUnit.money ||
          _oneCurrency(all.map((p) => p.value)),
      'Use one currency per chart.',
    );
    assert(
      !widget.bars ||
          all.every(
            (p) =>
                chartReading(p, widget.unit) == null ||
                chartReading(p, widget.unit)! >= 0,
          ),
    );
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final kind = widget.spark
        ? l10n.chartSparkline
        : widget.bars
        ? l10n.chartBar
        : l10n.chartLine;
    final keys = <String>[];
    if (all.any(
      (p) =>
          chartReading(p, widget.unit) != null &&
          p.status == ChartPointStatus.pending,
    )) {
      keys.add('○ ${l10n.chartPendingKey}');
    }
    if (all.any(
      (p) =>
          chartReading(p, widget.unit) != null &&
          p.status == ChartPointStatus.unknown,
    )) {
      keys.add('▧ ${l10n.chartUnknownKey}');
    }
    if (all.any((p) => chartReading(p, widget.unit) == null)) {
      keys.add('┄ ${l10n.chartNoData}');
    }
    final style = type.caption.tabular;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    final direction = Directionality.of(context);
    ChartPainter painterFor(int? shown, [int? bandLines]) => ChartPainter(
      series: series,
      unit: widget.unit,
      colors: meterColors(theme, series.length),
      showX:
          widget.axis == PaymentChartAxis.x ||
          widget.axis == PaymentChartAxis.both,
      showY:
          widget.axis == PaymentChartAxis.y ||
          widget.axis == PaymentChartAxis.both,
      gridX:
          widget.grid == PaymentChartAxis.x ||
          widget.grid == PaymentChartAxis.both,
      gridY:
          widget.grid == PaymentChartAxis.y ||
          widget.grid == PaymentChartAxis.both,
      theme: theme,
      l10n: l10n,
      style: style,
      scaler: scaler,
      bars: widget.bars,
      spark: widget.spark,
      zeroBased: widget.zeroBased,
      selected: shown,
      bandLines: bandLines,
    );
    // One line per series: the period and series name, then the value. Only
    // the first line repeats the period.
    List<(String, String)> readout(int i) => [
      for (final (j, s) in series.indexed)
        (
          [
            if (j == 0) s.points[i].label,
            if (series.length > 1) s.label,
          ].join(' · '),
          '${switch (chartReading(s.points[i], widget.unit)) {
            null => l10n.chartNoData,
            final reading => formatChartValue(l10n, reading, widget.unit, currency: s.points[i].value?.currency ?? 'IDR'),
          }}${s.points[i].status == ChartPointStatus.settled ? '' : ' · ${s.points[i].status == ChartPointStatus.pending ? l10n.chartPendingKey : l10n.chartUnknownKey}'}',
        ),
    ];
    // #78: when any period's series name and value don't fit on one line at
    // the clamped scale, every line stacks the name over the value, and a
    // name wraps to two lines rather than losing its end. The band takes the
    // worst case over all periods, so selection never moves it. A
    // single-series readout keeps its one line.
    ({bool stacked, int lines}) measureReadout(double width) {
      final oneLine = (stacked: false, lines: series.length);
      if (widget.spark || series.length < 2 || points.isEmpty) return oneLine;
      debugReadoutMeasures++;
      final room = math.max(0.0, painterFor(null).plot(Size(width, 0)).width);
      double measure(String text, {bool lines = false}) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 2,
        )..layout(maxWidth: lines ? room : double.infinity);
        final result = lines
            ? painter.computeLineMetrics().length.toDouble()
            : painter.width;
        painter.dispose();
        return result;
      }

      final rows = [for (var i = 0; i < points.length; i++) readout(i)];
      if (rows.every(
        (row) => row.every(
          (line) =>
              line.$1.isEmpty ||
              measure('${line.$1} · ') + measure(line.$2) <= room,
        ),
      )) {
        return oneLine;
      }
      return (
        stacked: true,
        lines: rows
            .map(
              (row) => row.fold(
                0,
                (sum, line) =>
                    sum +
                    1 +
                    (line.$1.isEmpty
                        ? 0
                        : measure(line.$1, lines: true).toInt()),
              ),
            )
            .reduce(math.max),
      );
    }

    // Everything the readout's text and the plot width depend on. Lists
    // compare by identity, so new series data measures again.
    final readoutKey = (
      widget.series,
      widget.points,
      widget.unit,
      widget.spark,
      widget.axis,
      Localizations.maybeLocaleOf(context),
      direction,
      style,
      scaler,
    );
    if (readoutKey != _readoutKey) {
      _readoutKey = readoutKey;
      _readoutLayouts.clear();
    }
    ({bool stacked, int lines}) readoutLayout(double width) {
      // Hosts that keep resizing don't grow the cache without bound.
      if (_readoutLayouts.length > 4) _readoutLayouts.clear();
      return _readoutLayouts.putIfAbsent(width, () => measureReadout(width));
    }

    // In a ChartModule the plot slot grows by the lines a stacked readout
    // adds, so the plot keeps its height.
    _ReadoutScope.maybeOf(context)?.extra = (width) => math.max(
      0,
      (readoutLayout(width).lines - series.length) * painterFor(null).line,
    );
    return Semantics(
      container: true,
      label:
          widget.semanticLabel ??
          (series.length == 1
              ? chartSummary(l10n, kind, points, widget.unit)
              : '$kind ${points.isEmpty ? '' : l10n.chartRange(points.first.label, points.last.label, points.length)} ${series.map((s) => '${s.label}: ${chartSummary(l10n, '', s.points, widget.unit, false)}').join(' ')}'),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            assert(
              constraints.hasBoundedHeight,
              'Wrap in ChartModule or a SizedBox with a fixed height.',
            );
            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      if ((selected ?? 0) >= points.length) selected = null;
                      final latest = points.lastIndexWhere(
                        (p) =>
                            p.status == ChartPointStatus.settled &&
                            chartReading(p, widget.unit) != null,
                      );
                      // D58: the latest settled period is selected at rest; a
                      // tap, drag or hover moves the selection and leaving
                      // returns to rest. Sparklines keep no rest selection.
                      final shown = widget.spark || points.isEmpty
                          ? selected
                          : (selected ?? (latest < 0 ? null : latest));
                      final layout = readoutLayout(box.maxWidth);
                      final painter = painterFor(shown, layout.lines);
                      void inspect(Offset position, bool toggle) {
                        if (!widget.inspectable || points.isEmpty) {
                          return;
                        }
                        final area = painter.plot(box.biggest);
                        final fraction =
                            ((position.dx - area.left) / area.width).clamp(
                              0.0,
                              1.0,
                            );
                        final index =
                            (widget.bars
                                    ? (fraction * points.length).floor()
                                    : (fraction * (points.length - 1)).round())
                                .clamp(0, points.length - 1);
                        setState(
                          () => selected = toggle && selected == index
                              ? null
                              : index,
                        );
                      }

                      final index = selected ?? latest;
                      final message = index < 0
                          ? l10n.chartNoData
                          : '${points[index].label} · ${formatChartValue(l10n, chartReading(points[index], widget.unit) ?? 0, widget.unit, currency: points[index].value?.currency ?? 'IDR')}';
                      if (widget.spark) {
                        final plot = MouseRegion(
                          onHover: (event) =>
                              inspect(event.localPosition, false),
                          onExit: (_) => setState(() => selected = null),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (event) =>
                                inspect(event.localPosition, true),
                            child: CustomPaint(
                              painter: painter,
                              size: Size.infinite,
                            ),
                          ),
                        );
                        return widget.inspectable
                            ? PaymentTooltip(
                                message: message,
                                type: PaymentTooltipType.description,
                                placement: PaymentTooltipPlacement.top,
                                delay: Duration.zero,
                                child: plot,
                              )
                            : plot;
                      }
                      // One exact-value label sits in a fixed band above the
                      // plot, so rest and selection never shift the layout.
                      final area = painter.plot(box.biggest);
                      final chart = Stack(
                        children: [
                          Positioned.fill(child: CustomPaint(painter: painter)),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: painter.band,
                            child: CustomSingleChildLayout(
                              delegate: _BandLabelLayout(
                                x: shown == null
                                    ? area.left
                                    : painter.columnX(shown, area),
                                left: area.left,
                                right: area.right,
                                centred: shown != null,
                              ),
                              child: DefaultTextStyle.merge(
                                style: type.caption.tabular.copyWith(
                                  color: shown == null
                                      ? theme.textSecondary
                                      : theme.textPrimary,
                                ),
                                maxLines: 1,
                                child: MediaQuery.withClampedTextScaling(
                                  maxScaleFactor: 1.5,
                                  child: Column(
                                    key: const ValueKey('payment-chart-value'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (shown == null)
                                        Text(l10n.chartNoData)
                                      else if (layout.stacked)
                                        for (final (name, value) in readout(
                                          shown,
                                        )) ...[
                                          if (name.isNotEmpty)
                                            // Only a name longer than
                                            // two lines at the plot width
                                            // ends in an ellipsis.
                                            Text(
                                              name,
                                              maxLines: 2,
                                              softWrap: true,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          Text(
                                            value,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ]
                                      else
                                        // The name gives way before the
                                        // amount does.
                                        for (final (name, value) in readout(
                                          shown,
                                        ))
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (name.isNotEmpty)
                                                Flexible(
                                                  child: Text(
                                                    '$name · ',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: false,
                                                  ),
                                                ),
                                              // Truncates only when the
                                              // amount alone is wider than
                                              // the plot.
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: math.max(
                                                    0,
                                                    area.width,
                                                  ),
                                                ),
                                                child: Text(
                                                  value,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                              ),
                                            ],
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                      if (!widget.inspectable) return chart;
                      return MouseRegion(
                        onHover: (event) => inspect(event.localPosition, false),
                        onExit: (_) => setState(() => selected = null),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (event) =>
                              inspect(event.localPosition, false),
                          onHorizontalDragStart: (event) =>
                              inspect(event.localPosition, false),
                          onHorizontalDragUpdate: (event) =>
                              inspect(event.localPosition, false),
                          child: chart,
                        ),
                      );
                    },
                  ),
                ),
                if (!widget.spark && widget.showLegend && series.length > 1)
                  Wrap(
                    spacing: theme.space(PaymentSpace.group),
                    runSpacing: theme.space(PaymentSpace.inline),
                    children: List.generate(
                      series.length,
                      (i) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: theme.space(PaymentSpace.group),
                            height: theme.space(PaymentSpace.block),
                            child: CustomPaint(
                              painter: _SeriesKey(
                                meterColors(theme, series.length)[i],
                                seriesDash[i],
                                widget.bars,
                              ),
                            ),
                          ),
                          SizedBox(width: theme.space(PaymentSpace.inline)),
                          Text(
                            series[i].label,
                            style: type.caption,
                            textScaler: MediaQuery.textScalerOf(
                              context,
                            ).clamp(maxScaleFactor: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!widget.spark && keys.isNotEmpty)
                  Text(
                    keys.join('   '),
                    style: type.caption,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.5),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A categorical breakdown with optional host actions on legend rows.
class PaymentMeterChart extends StatelessWidget {
  /// Creates a meter chart.
  const PaymentMeterChart({
    super.key,
    required this.segments,
    this.showLegend = true,
    this.unit = PaymentChartUnit.money,
    this.onSegmentPressed,
    this.semanticLabel,
  });

  /// Segments.
  final List<MeterSegment> segments;

  /// Whether to show the series legend.
  final bool showLegend;

  /// Which reading to display and announce.
  final PaymentChartUnit unit;

  /// On Segment Pressed.
  final ValueChanged<MeterSegment>? onSegmentPressed;

  /// Host-authored replacement for the generated summary.
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    assert(
      unit != PaymentChartUnit.money ||
          _oneCurrency(segments.map((s) => s.value)),
    );
    assert(onSegmentPressed == null || showLegend);
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final colors = meterColors(theme, segments.length);
    String spoken(MeterSegment s) =>
        '${s.label}, ${spokenChartValue(l10n, meterReading(s, unit), unit, currency: s.value?.currency ?? 'IDR')}${s.status == ChartPointStatus.settled ? '' : ', ${s.status == ChartPointStatus.pending ? l10n.chartPendingKey : l10n.chartUnknownKey}'}';
    Widget entry(int i) {
      final s = segments[i];
      final child = onSegmentPressed != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: PaymentType.firstLineHeight(context),
                  child: Center(
                    child: Container(
                      width: theme.space(PaymentSpace.block),
                      height: theme.space(PaymentSpace.block),
                      color: colors[i],
                    ),
                  ),
                ),
                SizedBox(width: theme.space(PaymentSpace.block)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.label, style: type.label),
                      if (s.status != ChartPointStatus.settled)
                        Text(
                          s.status == ChartPointStatus.pending
                              ? l10n.chartPendingKey
                              : l10n.chartUnknownKey,
                          style: type.caption,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: theme.space(PaymentSpace.group)),
                Text(
                  formatChartValue(
                    l10n,
                    meterReading(s, unit),
                    unit,
                    currency: s.value?.currency ?? 'IDR',
                  ),
                  style: type.label.tabular,
                ),
              ],
            )
          : Row(
              mainAxisSize: onSegmentPressed == null
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              children: [
                Container(
                  width: theme.space(PaymentSpace.block),
                  height: theme.space(PaymentSpace.block),
                  color: colors[i],
                ),
                SizedBox(width: theme.space(PaymentSpace.inline)),
                Flexible(
                  child: Wrap(
                    spacing: theme.space(PaymentSpace.inline),
                    children: [
                      Text(s.label, style: type.caption),
                      Text(
                        formatChartValue(
                          l10n,
                          meterReading(s, unit),
                          unit,
                          currency: s.value?.currency ?? 'IDR',
                        ),
                        style: type.caption.tabular,
                      ),
                      if (s.status != ChartPointStatus.settled)
                        Text(
                          s.status == ChartPointStatus.pending
                              ? l10n.chartPendingKey
                              : l10n.chartUnknownKey,
                          style: type.caption,
                        ),
                    ],
                  ),
                ),
              ],
            );
      return onSegmentPressed == null
          ? child
          : Semantics(
              button: true,
              label: spoken(s),
              excludeSemantics: true,
              child: RowShell(onTap: () => onSegmentPressed!(s), child: child),
            );
    }

    final legend = onSegmentPressed == null
        ? Wrap(
            spacing: theme.space(PaymentSpace.group),
            runSpacing: theme.space(PaymentSpace.related),
            children: List.generate(segments.length, entry),
          )
        : Column(children: List.generate(segments.length, entry));
    return Semantics(
      container: true,
      label:
          semanticLabel ??
          (onSegmentPressed != null
              ? l10n.chartMeter
              : '${l10n.chartMeter}. ${segments.isEmpty ? l10n.chartNoData : segments.map(spoken).join('. ')}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: theme.space(PaymentSpace.block),
              width: double.infinity,
              child: CustomPaint(
                painter: MeterPainter(segments, colors, theme.surface, unit),
              ),
            ),
          ),
          if (showLegend)
            Padding(
              padding: EdgeInsets.only(top: theme.space(PaymentSpace.related)),
              child: onSegmentPressed == null
                  ? ExcludeSemantics(child: legend)
                  : legend,
            ),
        ],
      ),
    );
  }
}

/// A chart section with stable loading, empty and error states.
class ChartModule extends StatelessWidget {
  /// Creates a chart.
  const ChartModule({
    super.key,
    required this.title,
    required this.state,
    this.chart,
    this.headline,
    this.headlineCaption,
    this.showHeadline = true,
    this.delta,
    this.deltaTone = StatusTone.neutral,
    this.height = compactHeight,
    this.emptyTitle,
    this.emptyMessage,
    this.errorMessage,
    this.onRetry,
    this.trailing,
  }) : assert(state != ChartState.ready || chart != null);

  /// Compact Height.
  static const double compactHeight = 180;

  /// Featured Height.
  static const double featuredHeight = 320;

  /// Title.
  final String title;

  /// State.
  final ChartState state;

  /// Chart.
  final Widget? chart;

  /// Host-provided amount. The kit never computes a headline total.
  final Money? headline;

  /// Headline Caption.
  final String? headlineCaption;

  /// Show Headline.
  final bool showHeadline;

  /// Delta.
  final String? delta;

  /// Delta Tone.
  final StatusTone deltaTone;

  /// Height.
  final double? height;

  /// Empty Title.
  final String? emptyTitle;

  /// Empty Message.
  final String? emptyMessage;

  /// Error Message.
  final String? errorMessage;

  /// On Retry.
  final FutureOr<void> Function()? onRetry;

  /// Trailing.
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final theme = PaymentTheme.of(context);
    final large = PaymentType.isLarge(context);
    final room = _ReadoutRoom();
    final plot = switch (state) {
      ChartState.ready => chart!,
      ChartState.loading => ClipRect(
        child: SingleChildScrollView(
          child: LoadingSkeleton(
            rows: math.max(1, ((height ?? compactHeight) / 62).floor()),
            leading: false,
          ),
        ),
      ),
      ChartState.error => SingleChildScrollView(
        child: StateMessage(
          icon: Icons.cloud_off_outlined,
          tone: StatusTone.warning,
          title: l10n.chartLoadFailed,
          message: large ? null : errorMessage,
          actionLabel: l10n.retry,
          onAction: onRetry,
        ),
      ),
      ChartState.empty => SingleChildScrollView(
        child: StateMessage(
          icon: Icons.insert_chart_outlined,
          title: emptyTitle ?? l10n.chartEmptyTitle,
          message: large ? null : emptyMessage,
        ),
      ),
    };
    return PaymentSection(
      title: title,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The headline block reserves its caption line only when there is
          // a caption or delta, so a bare amount leaves no hole above the
          // plot, whose value band already separates the two (#62).
          if (showHeadline)
            SizedBox(
              height:
                  MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.6)
                      .scale(
                        type.amountLarge.fontSize! * type.amountLarge.height!,
                      ) +
                  (headlineCaption == null && delta == null
                      ? 0
                      : MediaQuery.textScalerOf(context).scale(
                          type.caption.fontSize! * type.caption.height!,
                        )) +
                  theme.space(PaymentSpace.group),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (headline != null)
                    AmountText(headline!, variant: AmountTextVariant.large)
                  else if (state == ChartState.loading)
                    // A skeleton row is a two-line list row (62 dp); the
                    // amount-line slot shows its top and clips the rest.
                    SizedBox(
                      height: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.6)
                          .scale(
                            type.amountLarge.fontSize! *
                                type.amountLarge.height!,
                          ),
                      child: const ClipRect(
                        child: OverflowBox(
                          alignment: AlignmentDirectional.topStart,
                          maxHeight: double.infinity,
                          child: LoadingSkeleton(rows: 1, leading: false),
                        ),
                      ),
                    )
                  else
                    Text('—', style: type.amountLarge),
                  Wrap(
                    spacing: theme.space(PaymentSpace.related),
                    children: [
                      if (headlineCaption != null)
                        Text(headlineCaption!, style: type.caption),
                      if (delta != null)
                        Text(
                          delta!,
                          style: type.caption.copyWith(
                            color: theme.tone(deltaTone).foreground,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          // At large text the plot never grows past the compact height, so
          // the rows under a chart stay on the first screen (#58-3). The one
          // exception is a readout that stacks: the slot grows by the lines
          // it adds, so the plot keeps its height (#78).
          _ChartSlot(
            key: const ValueKey('payment-chart-plot'),
            height: height == null || !large
                ? height
                : math.min(height!, compactHeight),
            room: room,
            child: _ReadoutScope(room: room, child: plot),
          ),
        ],
      ),
    );
  }
}

/// The height a chart in a [ChartModule] adds to the plot slot: the lines
/// its stacked readout needs beyond one per series (#78).
class _ReadoutRoom {
  /// Set by the chart as it builds, read by the slot as it lays out.
  double Function(double width)? extra;
}

class _ReadoutScope extends InheritedWidget {
  const _ReadoutScope({required this.room, required super.child});
  final _ReadoutRoom room;

  static _ReadoutRoom? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ReadoutScope>()?.room;

  @override
  bool updateShouldNotify(_ReadoutScope oldWidget) => room != oldWidget.room;
}

/// A fixed-height plot slot, like a `SizedBox`, plus the room its chart asks
/// for at the slot's width.
class _ChartSlot extends SingleChildRenderObjectWidget {
  const _ChartSlot({
    super.key,
    required this.height,
    required this.room,
    super.child,
  });
  final double? height;
  final _ReadoutRoom room;

  @override
  _RenderChartSlot createRenderObject(BuildContext context) =>
      _RenderChartSlot(height, room);

  @override
  void updateRenderObject(BuildContext context, _RenderChartSlot slot) => slot
    ..height = height
    ..room = room;
}

class _RenderChartSlot extends RenderProxyBox {
  _RenderChartSlot(this._height, this._room);
  double? _height;
  set height(double? value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  _ReadoutRoom _room;
  set room(_ReadoutRoom value) {
    if (identical(value, _room)) return;
    _room = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints constraints) => _height == null
      ? constraints
      : BoxConstraints.tightFor(
          height: _height! + (_room.extra?.call(constraints.maxWidth) ?? 0),
        ).enforce(constraints);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height ?? super.computeMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height ?? super.computeMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(_inner(constraints)) ??
      _inner(constraints).constrain(Size.zero);

  @override
  void performLayout() {
    final inner = _inner(constraints);
    if (child == null) {
      size = inner.constrain(Size.zero);
      return;
    }
    child!.layout(inner, parentUsesSize: true);
    size = child!.size;
  }
}

/// Places the value label over its column, kept inside the plot.
class _BandLabelLayout extends SingleChildLayoutDelegate {
  const _BandLabelLayout({
    required this.x,
    required this.left,
    required this.right,
    required this.centred,
  });
  final double x, left, right;
  final bool centred;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: math.max(0, right - left));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final start = centred ? x - childSize.width / 2 : left;
    return Offset(
      start.clamp(left, math.max(left, right - childSize.width)),
      size.height - childSize.height,
    );
  }

  @override
  bool shouldRelayout(_BandLabelLayout old) =>
      old.x != x ||
      old.left != left ||
      old.right != right ||
      old.centred != centred;
}

class _SeriesKey extends CustomPainter {
  _SeriesKey(this.color, this.pattern, this.bars);
  final Color color;
  final List<double>? pattern;
  final bool bars;
  @override
  void paint(Canvas canvas, Size size) {
    if (bars) {
      canvas.drawRect(Offset.zero & size, Paint()..color = color);
    } else if (pattern == null) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
    } else {
      dashPattern(
        canvas,
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        color,
        pattern!,
        2,
      );
    }
  }

  @override
  bool shouldRepaint(_SeriesKey oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.pattern != pattern ||
      oldDelegate.bars != bars;
}
