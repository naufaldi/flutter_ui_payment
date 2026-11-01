import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/charts/chart_geometry.dart';
import 'package:flutter_ui_payment/src/charts/chart_painters.dart';

Widget host(
  Widget child, {
  String locale = 'en',
  double scale = 1,
  bool dark = false,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 320, child: child)),
    ),
  ),
);
const points = [
  ChartPoint(label: '1 Oct', value: Money.idr(100)),
  ChartPoint(
    label: '8 Oct',
    value: Money.idr(1000),
    status: ChartPointStatus.pending,
  ),
  ChartPoint(
    label: '15 Oct',
    value: Money.idr(200),
    status: ChartPointStatus.unknown,
  ),
  ChartPoint(label: '22 Oct', value: null),
];
const weeks = [
  ChartPoint(label: 'W1', value: Money.idr(100000)),
  ChartPoint(label: 'W2', value: Money.idr(350000)),
  ChartPoint(label: 'W3', value: Money.idr(200000)),
  ChartPoint(label: 'W4', value: Money.idr(420000)),
];
String valueText(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('payment-chart-value')))
    .data!;
void main() {
  test('geometry handles zero, missing, outliers and frame bounds', () {
    final rects = barRects(const [
      ChartPoint(label: 'zero', value: Money.idr(0)),
      ChartPoint(label: 'missing', value: null),
      ChartPoint(label: 'small', value: Money.idr(1)),
      ChartPoint(label: 'outlier', value: Money.idr(100000)),
    ], const Rect.fromLTWH(0, 0, 320, 180));
    expect(rects[0]!.height, 2);
    expect(rects[1], null);
    expect(rects[2]!.height, greaterThanOrEqualTo(2));
    expect(
      rects.whereType<Rect>().every(
        (r) => r.top >= 0 && r.bottom <= 180 && r.width.isFinite,
      ),
      true,
    );
    expect(niceTicks([0, 0], zeroBased: true).first, 0);
    expect(
      linePoints(const [
        ChartPoint(label: 'one', value: Money.idr(1)),
      ], const Rect.fromLTWH(0, 0, 80, 24)).single!.dx,
      40,
    );
  });
  test('category ramp retains 3:1 contrast', () {
    for (final brightness in Brightness.values) {
      final theme = PaymentTheme.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
      );
      for (final color in meterColors(theme, 5)) {
        final a = color.computeLuminance(),
            b = theme.surface.computeLuminance();
        expect(
          ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
          greaterThanOrEqualTo(3),
        );
      }
    }
  });
  testWidgets('summary excludes unsettled extrema and exposes one chart node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const SizedBox(height: 180, child: PaymentBarChart(points: points))),
    );
    final node = find.bySemanticsLabel(RegExp('^Bar chart'));
    expect(node, findsOneWidget);
    final label = tester.getSemantics(node).label;
    expect(label, contains('Highest 100 IDR'));
    expect(label, contains('1 period is pending and not counted.'));
    expect(label, contains('1 period is not confirmed yet and not counted.'));
    expect(label, contains('1 period has no data.'));
    semantics.dispose();
  });
  testWidgets('all chart states keep plot and module heights at large text', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      double? height;
      for (final state in ChartState.values) {
        await tester.pumpWidget(
          host(
            ChartModule(
              title: 'Spending',
              state: state,
              chart: const PaymentBarChart(points: points),
              onRetry: () {},
            ),
            scale: scale,
          ),
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('payment-chart-plot')))
              .height,
          180,
        );
        final measured = tester.getSize(find.byType(ChartModule)).height;
        height ??= measured;
        expect(measured, height);
        expect(tester.takeException(), null);
      }
    }
  });
  testWidgets('retry remains reachable at 200 percent', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(
        ChartModule(
          title: 'Spending',
          state: ChartState.error,
          onRetry: () {
            retries++;
          },
        ),
        scale: 2,
      ),
    );
    final retry = find.text('Retry');
    await tester.ensureVisible(retry);
    expect(retry.hitTestable(), findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    expect(retries, 1);
  });
  testWidgets('empty, zero, single and large fixtures render in both locales', (
    tester,
  ) async {
    for (final locale in ['en', 'id']) {
      for (final fixture in <List<ChartPoint>>[
        [],
        const [ChartPoint(label: 'A', value: Money.idr(0))],
        const [ChartPoint(label: 'A', value: Money.idr(1250000000000))],
        points,
      ]) {
        final charts = <Widget>[
          PaymentLineChart(points: fixture),
          PaymentBarChart(points: fixture),
          PaymentSparkline(points: fixture),
          PaymentMeterChart(
            segments: fixture
                .where((p) => p.value != null)
                .map(
                  (p) => MeterSegment(
                    label: p.label,
                    value: p.value!,
                    status: p.status,
                  ),
                )
                .toList(),
          ),
        ];
        for (final chart in charts) {
          await tester.pumpWidget(
            host(
              ChartModule(
                title: 'Spending',
                height: chart is PaymentMeterChart ? null : 180,
                state: ChartState.ready,
                chart: chart,
              ),
              locale: locale,
              scale: 2,
              dark: true,
            ),
          );
          expect(tester.takeException(), null);
        }
      }
    }
  });
  testWidgets('hover readout and sparkline sizing', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(height: 180, child: PaymentBarChart(points: weeks))),
    );
    expect(valueText(tester), startsWith('W4 ·'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    final box = tester.getRect(find.byType(PaymentBarChart));
    await mouse.moveTo(box.topRight + const Offset(-200, 90));
    await tester.pump();
    expect(valueText(tester), isNot(startsWith('W4 ·')));
    // Leaving returns to rest.
    await mouse.moveTo(box.bottomRight + const Offset(10, 10));
    await tester.pump();
    expect(valueText(tester), startsWith('W4 ·'));
    await mouse.removePointer();
    await tester.pumpWidget(
      host(const Center(child: PaymentSparkline(points: points))),
    );
    expect(tester.getSize(find.byType(PaymentSparkline)), const Size(80, 24));
    expect(
      find.descendant(
        of: find.byType(PaymentSparkline),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });
  for (final bars in [false, true]) {
    final kind = bars ? 'bar' : 'line';
    Widget chart({bool inspectable = true}) => SizedBox(
      height: 180,
      child: bars
          ? PaymentBarChart(points: weeks, inspectable: inspectable)
          : PaymentLineChart(points: weeks, inspectable: inspectable),
    );
    testWidgets('$kind chart shows the latest exact value at rest (D58)', (
      tester,
    ) async {
      await tester.pumpWidget(host(chart(), locale: 'id'));
      expect(valueText(tester), 'W4 · Rp420.000');
      final rest = tester.getSize(find.byType(CustomPaint).last);
      final label = tester.getRect(
        find.byKey(const ValueKey('payment-chart-value')),
      );
      final height = tester.getSize(find.byType(SizedBox).first).height;
      // A tap on another period selects it, with no toggle-off.
      final plot = tester.getRect(find.byType(GestureDetector).last);
      await tester.tapAt(Offset(plot.left + 90, plot.center.dy));
      await tester.pump();
      final tapped = valueText(tester);
      expect(tapped, isNot('W4 · Rp420.000'));
      expect(tapped, contains('Rp'));
      await tester.tapAt(Offset(plot.left + 90, plot.center.dy));
      await tester.pump();
      expect(valueText(tester), tapped);
      // A drag moves it to the end.
      await tester.dragFrom(
        Offset(plot.left + 90, plot.center.dy),
        Offset(plot.width - 90, 0),
      );
      await tester.pump();
      expect(valueText(tester), 'W4 · Rp420.000');
      // The label band and the chart keep their geometry.
      expect(tester.getSize(find.byType(CustomPaint).last), rest);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('payment-chart-value')))
            .bottom,
        label.bottom,
      );
      expect(tester.getSize(find.byType(SizedBox).first).height, height);
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<ChartPainter>()
          .single;
      expect(painter.markEvery, isTrue);
      expect(painter.selected, 3);
    });
    testWidgets('$kind chart without inspection still labels its rest value', (
      tester,
    ) async {
      await tester.pumpWidget(host(chart(inspectable: false)));
      expect(valueText(tester), 'W4 · Rp420,000');
      await tester.tap(find.byType(bars ? PaymentBarChart : PaymentLineChart));
      await tester.pump();
      expect(valueText(tester), 'W4 · Rp420,000');
    });
  }
  test('series longer than 12 points mark only the last and selected', () {
    final long = [
      for (var i = 0; i < 13; i++)
        ChartPoint(label: '$i', value: Money.idr(i * 1000)),
    ];
    final theme = PaymentTheme.fromColorScheme(
      ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    ChartPainter painter(List<ChartPoint> points) => ChartPainter(
      series: [PaymentChartSeries(label: '', points: points)],
      unit: PaymentChartUnit.money,
      colors: const [Colors.blue],
      showX: true,
      showY: true,
      gridX: false,
      gridY: true,
      theme: theme,
      l10n: PaymentLocalizations('en'),
      style: const TextStyle(fontSize: 13, height: 18 / 13),
      scaler: TextScaler.noScaling,
    );
    expect(painter(long).markEvery, isFalse);
    expect(painter(long.take(12).toList()).markEvery, isTrue);
  });
  testWidgets('the y gutter fits its scaled labels', (tester) async {
    final gutters = <double>[];
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        host(
          const SizedBox(height: 180, child: PaymentBarChart(points: weeks)),
          scale: scale,
        ),
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<ChartPainter>()
          .single;
      final area = painter.plot(const Size(320, 180));
      final widest = [
        'Rp0',
        'Rp250K',
        'Rp500K',
      ].map((l) => painter.text(l).width).reduce((a, b) => a > b ? a : b);
      expect(area.left, greaterThanOrEqualTo(widest + 8));
      gutters.add(area.left);
    }
    // The gutter follows the labels instead of a fixed 76.
    expect(gutters.last, greaterThan(gutters.first));
  });
}
