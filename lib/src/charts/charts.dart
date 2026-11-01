import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
                      final painter = ChartPainter(
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
                        style: type.caption.tabular,
                        scaler: MediaQuery.textScalerOf(
                          context,
                        ).clamp(maxScaleFactor: 1.5),
                        bars: widget.bars,
                        spark: widget.spark,
                        zeroBased: widget.zeroBased,
                        selected: shown,
                      );
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
                      String readout(int i) => series
                          .map((s) {
                            final p = s.points[i];
                            final reading = chartReading(p, widget.unit);
                            return '${p.label} · ${series.length > 1 ? '${s.label} ' : ''}${reading == null ? l10n.chartNoData : formatChartValue(l10n, reading, widget.unit, currency: p.value?.currency ?? 'IDR')}${p.status == ChartPointStatus.settled ? '' : ' · ${p.status == ChartPointStatus.pending ? l10n.chartPendingKey : l10n.chartUnknownKey}'}';
                          })
                          .join('\n');
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
                              child: Text(
                                shown == null
                                    ? l10n.chartNoData
                                    : readout(shown),
                                key: const ValueKey('payment-chart-value'),
                                style: type.caption.tabular.copyWith(
                                  color: shown == null
                                      ? theme.textSecondary
                                      : theme.textPrimary,
                                ),
                                textScaler: MediaQuery.textScalerOf(
                                  context,
                                ).clamp(maxScaleFactor: 1.5),
                                maxLines: series.length,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
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
          // the rows under a chart stay on the first screen (#58-3).
          SizedBox(
            key: const ValueKey('payment-chart-plot'),
            height: height == null || !large
                ? height
                : math.min(height!, compactHeight),
            child: plot,
          ),
        ],
      ),
    );
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
