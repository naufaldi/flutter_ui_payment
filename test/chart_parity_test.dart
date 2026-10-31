import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/charts/chart_geometry.dart';
import 'charts_test.dart' show host;

void main() {
  const points = [
    ChartPoint(label: 'A', measure: 45),
    ChartPoint(label: 'B', measure: 60),
  ];
  testWidgets('series legend and percentage summaries describe each series', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const SizedBox(
          height: 180,
          child: PaymentLineChart(
            unit: PaymentChartUnit.percent,
            series: [
              PaymentChartSeries(label: 'This month', points: points),
              PaymentChartSeries(label: 'Last month', points: points),
            ],
          ),
        ),
      ),
    );
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Last month'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('.*This month:.*45 percent.*Last month:.*')),
      findsOneWidget,
    );
    semantics.dispose();
  });
  testWidgets('meter rows activate the supplied segment', (tester) async {
    MeterSegment? selected;
    final segment = MeterSegment(label: 'QRIS', measure: 45);
    await tester.pumpWidget(
      host(
        PaymentMeterChart(
          unit: PaymentChartUnit.percent,
          segments: [segment],
          onSegmentPressed: (s) => selected = s,
        ),
      ),
    );
    await tester.tap(find.text('QRIS'));
    expect(selected, same(segment));
  });
  testWidgets('inspectable sparkline reserves a touch target', (tester) async {
    await tester.pumpWidget(
      host(
        const Center(
          child: PaymentSparkline(
            points: points,
            unit: PaymentChartUnit.percent,
            inspectable: true,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PaymentSparkline)).height, 48);
  });
  test('grouped bars share a scale and preserve gaps', () {
    final rects = groupedBarRects(
      const [
        PaymentChartSeries(label: 'A', points: points),
        PaymentChartSeries(label: 'B', points: points),
      ],
      const Rect.fromLTWH(0, 0, 320, 180),
      PaymentChartUnit.percent,
    );
    expect(rects.length, 2);
    expect(rects[0][0]!.right, lessThan(rects[1][0]!.left));
    expect(rects[0][0]!.height, rects[1][0]!.height);
  });
}
