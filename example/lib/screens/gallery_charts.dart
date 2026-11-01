part of 'gallery_screen.dart';

List<ChartPoint> _chartFixture(String state, [String month = 'Oct']) {
  if (state == 'single') {
    return [ChartPoint(label: '1 $month', value: const Money.idr(450000))];
  }
  return List.generate(
    5,
    (i) => ChartPoint(
      label: '${1 + i * 7} $month',
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
    final points = _chartFixture(state, _t(context, 'Oct', 'Okt'));
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
      title: _t(context, 'Spending', 'Pengeluaran'),
      state: state,
      chart: PaymentBarChart(
        points: _chartFixture('typical', _t(context, 'Oct', 'Okt')),
      ),
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
          chart: PaymentBarChart(
            points: _chartFixture('pending', _t(context, 'Oct', 'Okt')),
          ),
        ),
        PaymentMeterChart(
          segments: [
            MeterSegment(label: 'Transfer', value: const Money.idr(650000)),
            MeterSegment(label: 'QRIS', value: const Money.idr(430000)),
          ],
        ),
        const SizedBox(height: 16),
        const _ContextHistory(),
      ],
    ),
  );
}

class _ContextHistory extends StatefulWidget {
  const _ContextHistory();
  @override
  State<_ContextHistory> createState() => _ContextHistoryState();
}

class _ContextHistoryState extends State<_ContextHistory> {
  String query = '';
  TransactionFilter filter = TransactionFilter.all;
  @override
  Widget build(BuildContext context) => TransactionHistory(
    records: TransactionRecord.where(
      _records.take(3),
      query: query,
      filter: filter,
    ),
    query: query,
    filter: filter,
    onQueryChanged: (value) => setState(() => query = value),
    onFilterChanged: (value) => setState(() => filter = value),
    onOpen: (record) => _galleryFeedback(
      context,
      'Host: open transaction',
      'Host: buka transaksi',
    ),
  );
}

class _ChartVariants extends StatelessWidget {
  const _ChartVariants(this.kind);
  final String kind;
  @override
  Widget build(BuildContext context) {
    final series = [
      PaymentChartSeries(
        label: _t(context, 'This month', 'Bulan ini'),
        points: _chartFixture('pending', _t(context, 'Oct', 'Okt')),
      ),
      PaymentChartSeries(
        label: _t(context, 'Last month', 'Bulan lalu'),
        points: _chartFixture('typical', _t(context, 'Oct', 'Okt')),
      ),
    ];
    final measures = List.generate(
      5,
      (i) => ChartPoint(
        label: _t(context, 'W${i + 1}', 'M${i + 1}'),
        measure: [92, 95, 88, 97, 99][i],
      ),
    );
    final chart = switch (kind) {
      'bar' => PaymentBarChart(series: series),
      'meter' => PaymentMeterChart(
        segments: [
          for (final label in [
            'Transfer',
            'QRIS',
            _t(context, 'Card', 'Kartu'),
          ])
            MeterSegment(label: label, value: const Money.idr(250000)),
        ],
        onSegmentPressed: (s) => _galleryFeedback(
          context,
          'Host: open ${s.label}',
          'Host: buka ${s.label}',
        ),
      ),
      'sparkline' => Row(
        children: [
          Expanded(
            child: Text(_t(context, 'Spending trend', 'Tren pengeluaran')),
          ),
          PaymentSparkline(
            key: const Key('sparkline-inspect'),
            series: series,
            inspectable: true,
          ),
        ],
      ),
      _ => PaymentLineChart(series: series),
    };
    final name = switch (kind) {
      'bar' => 'PaymentBarChart',
      'meter' => 'PaymentMeterChart',
      'sparkline' => 'PaymentSparkline',
      _ => 'PaymentLineChart',
    };
    return _Entry(
      name: '$name · variants',
      child: Column(
        children: [
          ChartModule(
            title: _t(
              context,
              'Spending, this month vs last month',
              'Pengeluaran, bulan ini vs bulan lalu',
            ),
            state: ChartState.ready,
            showHeadline: false,
            height: kind == 'meter' ? null : 180,
            chart: chart,
          ),
          if (kind == 'line' || kind == 'bar')
            SizedBox(
              height: 120,
              child: kind == 'line'
                  ? PaymentLineChart(
                      points: measures,
                      unit: PaymentChartUnit.percent,
                      axis: PaymentChartAxis.y,
                    )
                  : PaymentBarChart(
                      points: measures,
                      unit: PaymentChartUnit.number,
                      grid: PaymentChartAxis.none,
                    ),
            ),
          if (kind == 'line')
            SizedBox(
              height: 120,
              child: PaymentLineChart(
                points: _chartFixture('typical', _t(context, 'Oct', 'Okt')),
                axis: PaymentChartAxis.none,
                grid: PaymentChartAxis.none,
              ),
            ),
          if (kind == 'meter') ...[
            SizedBox(
              height: PaymentTheme.of(context).space(PaymentSpace.group),
            ),
            PaymentInline(
              _t(context, 'Budget used', 'Anggaran terpakai'),
              role: PaymentTextRole.heading,
            ),
            PaymentMeterChart(
              unit: PaymentChartUnit.percent,
              segments: [
                MeterSegment(label: 'Transfer', measure: 40),
                MeterSegment(label: 'QRIS', measure: 25),
                MeterSegment(label: _t(context, 'Card', 'Kartu'), measure: 10),
              ],
            ),
            if (kind == 'sparkline')
              PaymentSparkline(
                points: _chartFixture('typical', _t(context, 'Oct', 'Okt')),
              ),
          ],
        ],
      ),
    );
  }
}
