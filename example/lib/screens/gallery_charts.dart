part of 'gallery_screen.dart';

List<ChartPoint> _chartFixture(String state) {
  if (state == 'single') {
    return const [ChartPoint(label: '1 Oct', value: Money.idr(450000))];
  }
  return List.generate(
    5,
    (i) => ChartPoint(
      label: '${1 + i * 7} Oct',
      value: state == 'missing' && i == 2
          ? null
          : Money.idr(
              state == 'zeros'
                  ? 0
                  : state == 'large'
                  ? (i + 1) * 250000000000
                  : state == 'outlier' && i == 4
                  ? 4500000
                  : [350000, 450000, 280000, 510000, 420000][i],
            ),
      status: state == 'pending' && i == 3
          ? ChartPointStatus.pending
          : state == 'pending' && i == 4
          ? ChartPointStatus.unknown
          : ChartPointStatus.settled,
    ),
  );
}

class _ChartDemo extends StatefulWidget {
  const _ChartDemo({required this.kind});
  final String kind;
  @override
  State<_ChartDemo> createState() => _ChartDemoState();
}

class _ChartDemoState extends State<_ChartDemo> {
  String state = 'typical';
  @override
  Widget build(BuildContext context) {
    final points = _chartFixture(state);
    final chart = switch (widget.kind) {
      'bar' => PaymentBarChart(points: points),
      'meter' => PaymentMeterChart(
        segments: [
          for (final p in points)
            if (p.value != null)
              MeterSegment(label: p.label, value: p.value!, status: p.status),
        ],
      ),
      'sparkline' => Row(
        children: [
          const Expanded(child: AmountText(Money.idr(2010000))),
          PaymentSparkline(points: points),
        ],
      ),
      _ => PaymentLineChart(points: points),
    };
    return _Entry(
      name: switch (widget.kind) {
        'bar' => 'PaymentBarChart',
        'meter' => 'PaymentMeterChart',
        'sparkline' => 'PaymentSparkline · beside a KPI',
        _ => 'PaymentLineChart',
      },
      states: _StatePicker(
        values: const [
          'typical',
          'pending',
          'outlier',
          'single',
          'zeros',
          'missing',
          'large',
        ],
        selected: state,
        onSelected: (value) => setState(() => state = value),
        label: (value) => value,
      ),
      child: ChartModule(
        title: _t(context, 'Spending, October', 'Pengeluaran, Oktober'),
        state: ChartState.ready,
        headline: const Money.idr(2010000),
        headlineCaption: _t(context, 'Settled', 'Selesai'),
        height: widget.kind == 'meter'
            ? null
            : widget.kind == 'sparkline'
            ? 48
            : 180,
        chart: chart,
      ),
    );
  }
}

class _ChartStatesDemo extends StatefulWidget {
  const _ChartStatesDemo();
  @override
  State<_ChartStatesDemo> createState() => _ChartStatesDemoState();
}

class _ChartStatesDemoState extends State<_ChartStatesDemo> {
  ChartState state = ChartState.loading;
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'ChartModule · states',
    states: _StatePicker(
      values: const [
        ChartState.loading,
        ChartState.error,
        ChartState.empty,
        ChartState.ready,
      ],
      selected: state,
      onSelected: (value) => setState(() => state = value),
      label: (value) => value.name,
    ),
    child: ChartModule(
      title: 'Spending',
      state: state,
      chart: PaymentBarChart(points: _chartFixture('typical')),
      onRetry: () => _galleryFeedback(
        context,
        'Host: reload requested',
        'Host: muat ulang diminta',
      ),
    ),
  );
}

class _SpendingInContextDemo extends StatelessWidget {
  const _SpendingInContextDemo();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'In context: spending above history',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChartModule(
          title: _t(context, 'Spending, October', 'Pengeluaran, Oktober'),
          state: ChartState.ready,
          headline: const Money.idr(1080000),
          headlineCaption: _t(context, 'Settled', 'Selesai'),
          chart: PaymentBarChart(points: _chartFixture('pending')),
        ),
        PaymentMeterChart(
          segments: [
            MeterSegment(label: 'Transfer', value: const Money.idr(650000)),
            MeterSegment(label: 'QRIS', value: const Money.idr(430000)),
          ],
        ),
        const SizedBox(height: 16),
        const _HistoryDemo(),
      ],
    ),
  );
}
