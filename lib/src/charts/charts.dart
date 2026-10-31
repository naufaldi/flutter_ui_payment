import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../foundation/kit_strings.dart';
import '../foundation/money.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../interaction/interaction.dart';
import 'chart_geometry.dart';
import 'chart_models.dart';
import 'chart_painters.dart';

bool _oneCurrency(Iterable<Money?> values) =>
    values.whereType<Money>().map((v) => v.currency).toSet().length <= 1;

class PaymentLineChart extends StatefulWidget {
  const PaymentLineChart({
    super.key,
    required this.points,
    this.zeroBased = false,
    this.inspectable = true,
    this.semanticLabel,
  });
  final List<ChartPoint> points;
  final bool zeroBased;
  final bool inspectable;
  final String? semanticLabel;
  @override
  State<PaymentLineChart> createState() => _PaymentLineChartState();
}

class _PaymentLineChartState extends State<PaymentLineChart> {
  @override
  Widget build(BuildContext context) => _PointChart(
    points: widget.points,
    zeroBased: widget.zeroBased,
    inspectable: widget.inspectable,
    semanticLabel: widget.semanticLabel,
  );
}

class PaymentBarChart extends StatefulWidget {
  const PaymentBarChart({
    super.key,
    required this.points,
    this.inspectable = true,
    this.semanticLabel,
  });
  final List<ChartPoint> points;
  final bool inspectable;
  final String? semanticLabel;
  @override
  State<PaymentBarChart> createState() => _PaymentBarChartState();
}

class _PaymentBarChartState extends State<PaymentBarChart> {
  @override
  Widget build(BuildContext context) => _PointChart(
    points: widget.points,
    bars: true,
    inspectable: widget.inspectable,
    semanticLabel: widget.semanticLabel,
  );
}

class PaymentSparkline extends StatelessWidget {
  const PaymentSparkline({
    super.key,
    required this.points,
    this.width = 80,
    this.height = 24,
    this.semanticLabel,
  });
  final List<ChartPoint> points;
  final double width;
  final double height;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: _PointChart(
      points: points,
      spark: true,
      inspectable: false,
      semanticLabel: semanticLabel,
    ),
  );
}

class _PointChart extends StatefulWidget {
  const _PointChart({
    required this.points,
    this.bars = false,
    this.spark = false,
    this.zeroBased = false,
    this.inspectable = true,
    this.semanticLabel,
  });
  final List<ChartPoint> points;
  final bool bars;
  final bool spark;
  final bool zeroBased;
  final bool inspectable;
  final String? semanticLabel;
  @override
  State<_PointChart> createState() => _PointChartState();
}

class _PointChartState extends State<_PointChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    assert(
      _oneCurrency(widget.points.map((p) => p.value)),
      'Use one currency per chart.',
    );
    assert(
      !widget.bars ||
          widget.points.every((p) => p.value == null || !p.value!.isNegative),
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
    if (widget.points.any(
      (p) => p.value != null && p.status == ChartPointStatus.pending,
    )) {
      keys.add('○ ${l10n.chartPendingKey}');
    }
    if (widget.points.any(
      (p) => p.value != null && p.status == ChartPointStatus.unknown,
    )) {
      keys.add('▧ ${l10n.chartUnknownKey}');
    }
    if (widget.points.any((p) => p.value == null)) {
      keys.add('┄ ${l10n.chartNoData}');
    }
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? chartSummary(l10n, kind, widget.points),
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
                      final painter = ChartPainter(
                        points: widget.points,
                        theme: theme,
                        format: l10n.moneyFormat,
                        style: type.caption.tabular,
                        scaler: MediaQuery.textScalerOf(
                          context,
                        ).clamp(maxScaleFactor: 1.5),
                        bars: widget.bars,
                        spark: widget.spark,
                        zeroBased: widget.zeroBased,
                        selected: selected,
                      );
                      void inspect(Offset position, bool toggle) {
                        if (!widget.inspectable || widget.points.isEmpty) {
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
                                    ? (fraction * widget.points.length).floor()
                                    : (fraction * (widget.points.length - 1))
                                          .round())
                                .clamp(0, widget.points.length - 1);
                        setState(
                          () => selected = toggle && selected == index
                              ? null
                              : index,
                        );
                      }

                      final point =
                          selected != null && selected! < widget.points.length
                          ? widget.points[selected!]
                          : null;
                      return MouseRegion(
                        onHover: (event) => inspect(event.localPosition, false),
                        onExit: (_) => setState(() => selected = null),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (event) =>
                              inspect(event.localPosition, true),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: painter),
                              ),
                              if (point != null)
                                Positioned(
                                  top: 0,
                                  left: 4,
                                  right: 4,
                                  child: ColoredBox(
                                    color: theme.surface,
                                    child: Text(
                                      '${point.label} · ${point.value == null ? l10n.chartNoData : l10n.moneyFormat.format(point.value!)}${point.status == ChartPointStatus.pending
                                          ? ' · ${l10n.chartPendingKey}'
                                          : point.status == ChartPointStatus.unknown
                                          ? ' · ${l10n.chartUnknownKey}'
                                          : ''}',
                                      style: type.caption,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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

class PaymentMeterChart extends StatelessWidget {
  const PaymentMeterChart({
    super.key,
    required this.segments,
    this.showLegend = true,
    this.semanticLabel,
  });
  final List<MeterSegment> segments;
  final bool showLegend;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    assert(
      _oneCurrency(segments.map((s) => s.value)),
      'Use one currency per chart.',
    );
    assert(segments.every((s) => !s.value.isNegative));
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final colors = meterColors(theme, segments.length);
    final summary = segments.isEmpty
        ? '${l10n.chartMeter}. ${l10n.chartNoData}'
        : '${l10n.chartMeter}. ${segments.map((s) => '${l10n.meterItem(s.label, l10n.moneyFormat.spoken(s.value))}${s.status == ChartPointStatus.pending
              ? ' ${l10n.chartPendingKey}'
              : s.status == ChartPointStatus.unknown
              ? ' ${l10n.chartUnknownKey}'
              : ''}').join('. ')}';
    return Semantics(
      container: true,
      label: semanticLabel ?? summary,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 12,
              width: double.infinity,
              child: CustomPaint(
                painter: MeterPainter(segments, colors, theme.surface),
              ),
            ),
            if (showLegend)
              Padding(
                padding: EdgeInsets.only(top: theme.spacing),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: List.generate(segments.length, (i) {
                    final s = segments[i];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: s.color ?? colors[i],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${s.label} · ${l10n.moneyFormat.format(s.value)}${s.status == ChartPointStatus.pending
                                ? ' · ${l10n.chartPendingKey}'
                                : s.status == ChartPointStatus.unknown
                                ? ' · ${l10n.chartUnknownKey}'
                                : ''}',
                            style: PaymentType.of(context).caption,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChartModule extends StatelessWidget {
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
  static const double compactHeight = 180;
  static const double featuredHeight = 320;
  final String title;
  final ChartState state;
  final Widget? chart;

  /// Host-provided amount. The kit never computes a headline total.
  final Money? headline;
  final String? headlineCaption;
  final bool showHeadline;
  final String? delta;
  final StatusTone deltaTone;
  final double? height;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? errorMessage;
  final FutureOr<void> Function()? onRetry;
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
            rows: math.max(1, ((height ?? compactHeight) / 48).floor()),
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
          if (showHeadline)
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (headline != null)
                    AmountText(headline!, style: type.amountLarge)
                  else if (state == ChartState.loading)
                    const SizedBox(
                      height: 48,
                      child: ClipRect(
                        child: LoadingSkeleton(rows: 1, leading: false),
                      ),
                    )
                  else
                    Text('—', style: type.amountLarge),
                  Wrap(
                    spacing: 8,
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
          SizedBox(
            key: const ValueKey('payment-chart-plot'),
            height: height,
            child: plot,
          ),
        ],
      ),
    );
  }
}
