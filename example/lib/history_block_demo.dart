import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/merchant_history.dart';

void main() => runBlockDemo(const HistoryBlockDemo());

enum HistoryDemoState { ready, loading, empty, error, nextPageError }

enum _PageRequest { idle, loading, failed }

typedef HistoryPage = ({List<TransactionRecord> records, String? nextCursor});
typedef HistoryPageSource =
    Future<HistoryPage> Function(
      String query,
      TransactionFilter filter,
      String? cursor,
    );

final _historyFixture = [
  for (final (id, amount, method, status, minute) in [
    ('INV-2048', 150000, 'QRIS', PaymentStatus.succeeded, 42),
    ('INV-2047', 320000, 'Transfer', null, 38),
    ('INV-2046', 210000, 'QRIS', PaymentStatus.pending, 30),
    ('INV-2045', 95000, 'Saldo', PaymentStatus.failed, 20),
  ])
    TransactionRecord(
      id: id,
      title: id,
      reference: id,
      amount: Money.idr(amount),
      createdAt: DateTime(2026, 11, 4, 10, minute),
      methodLabel: method,
      status: status,
    ),
  TransactionRecord(
    id: 'INV-2044',
    title: 'INV-2044',
    reference: 'INV-2044',
    amount: const Money.idr(240000),
    createdAt: DateTime(2026, 11, 3, 15, 10),
    methodLabel: 'Transfer',
    status: PaymentStatus.succeeded,
    refund: const RefundInfo(
      status: RefundStatus.partial,
      amount: Money.idr(50000),
    ),
  ),
  for (var i = 0; i < 24; i++)
    TransactionRecord(
      id: 'INV-${2043 - i}',
      title: 'INV-${2043 - i}',
      reference: 'INV-${2043 - i}',
      amount: Money.idr(75000 + 5000 * i),
      createdAt: DateTime(2026, 11, 3).subtract(Duration(days: i)),
      methodLabel: i.isEven ? 'QRIS' : 'Transfer',
      status: i % 3 == 0 ? PaymentStatus.failed : PaymentStatus.succeeded,
    ),
];

/// A runnable host with a synthetic cursor source. No network or payment occurs.
class HistoryBlockDemo extends StatefulWidget {
  const HistoryBlockDemo({
    super.key,
    this.initialState = HistoryDemoState.ready,
    this.initialDark = false,
    this.embedded = false,
    this.fetchPage,
    this.fixtureDelay = const Duration(milliseconds: 280),
  });
  final HistoryDemoState initialState;
  final bool initialDark;
  final bool embedded;
  final HistoryPageSource? fetchPage;
  final Duration fixtureDelay;
  @override
  State<HistoryBlockDemo> createState() => _HistoryBlockDemoState();
}

class _HistoryBlockDemoState extends State<HistoryBlockDemo> {
  late HistoryDemoState _mode = widget.initialState;
  late bool _dark = widget.initialDark;
  String _query = '';
  TransactionFilter _filter = TransactionFilter.all;
  List<TransactionRecord> _records = [];
  String? _nextCursor;
  int _generation = 0;
  int _failedAttempt = 0;
  _PageRequest _request = _PageRequest.idle;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPage());
  }

  void _restart(String query, TransactionFilter filter) {
    setState(() {
      _generation++;
      _query = query;
      _filter = filter;
      _records = [];
      _nextCursor = null;
      _request = _PageRequest.idle;
    });
    unawaited(_loadPage());
  }

  Future<void> _loadPage() async {
    if (_request == _PageRequest.loading ||
        (_nextCursor == null && _records.isNotEmpty)) {
      return;
    }
    final generation = _generation;
    final cursor = _nextCursor;
    setState(() => _request = _PageRequest.loading);
    if (_mode == HistoryDemoState.loading) return;

    try {
      final page = await (widget.fetchPage ?? _fixturePage)(
        _query,
        _filter,
        cursor,
      );
      // A completed request (including an error) may belong to an old query.
      if (!mounted || generation != _generation) return;
      setState(() {
        _records = [..._records, ...page.records];
        _nextCursor = page.nextCursor;
        _request = _PageRequest.idle;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _request = _PageRequest.failed;
        _failedAttempt++;
      });
    }
  }

  Future<HistoryPage> _fixturePage(
    String query,
    TransactionFilter filter,
    String? cursor,
  ) async {
    final mode = _mode;
    final fail =
        mode == HistoryDemoState.error ||
        (mode == HistoryDemoState.nextPageError && cursor != null);
    if (fail) _mode = HistoryDemoState.ready;
    if (widget.fixtureDelay > Duration.zero) {
      await Future<void>.delayed(widget.fixtureDelay);
    }
    if (fail) throw StateError('Synthetic page failure');
    final matching = TransactionRecord.where(
      mode == HistoryDemoState.empty ? const [] : _historyFixture,
      query: query,
      filter: filter,
    );
    // Only the synthetic server interprets the cursor.
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = start + 3;
    return (
      records: matching.skip(start).take(3).toList(),
      nextCursor: end < matching.length ? '$end' : null,
    );
  }

  Widget _block(BuildContext context) => MerchantHistory(
    records: _records,
    query: _query,
    filter: _filter,
    onQueryChanged: (value) => _restart(value, _filter),
    onFilterChanged: (value) {
      if (value != _filter) _restart(_query, value);
    },
    onResetFilters: () => _restart('', TransactionFilter.all),
    hasMore: _nextCursor != null,
    loading: _request == _PageRequest.loading,
    error: _request != _PageRequest.failed
        ? null
        : (
            attempt: _failedAttempt,
            message: switch ((
              Localizations.localeOf(context).languageCode,
              _nextCursor,
            )) {
              ('id', null) => 'Riwayat belum dapat dimuat. Coba lagi.',
              ('id', _) =>
                'Halaman berikutnya gagal dimuat. Transaksi sebelumnya tetap tersedia.',
              (_, null) => 'History couldn’t load. Try again.',
              _ =>
                'Couldn’t load the next page. Previous transactions are still available.',
            },
          ),
    onRequestPage: () => unawaited(_loadPage()),
    onOpen: (record) => showPaymentSheet<void>(
      context: context,
      builder: (context) => MerchantHistoryDetail(
        record: record,
        onClose: () => Navigator.pop(context),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _block(context)
      : BlockDemoShell(
          title: 'Riwayat · Demo',
          dark: _dark,
          onToggleDark: () => setState(() => _dark = !_dark),
          scenarios: [
            for (final (state, label) in [
              (HistoryDemoState.ready, 'Data tersedia'),
              (HistoryDemoState.loading, 'Memuat'),
              (HistoryDemoState.empty, 'Belum ada transaksi'),
              (HistoryDemoState.error, 'Gagal memuat riwayat'),
              (
                HistoryDemoState.nextPageError,
                'Gagal memuat halaman berikutnya',
              ),
            ])
              (
                label: label,
                onSelected: () {
                  _mode = state;
                  _restart('', TransactionFilter.all);
                },
              ),
          ],
          body: _block,
        );
}
