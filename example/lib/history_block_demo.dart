import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'compositions/merchant_history.dart';
import 'themes.dart';

void main() => runApp(const HistoryBlockDemo());

enum HistoryDemoState { ready, loading, empty, error }

final historyFixture = [
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
];

/// Synthetic list/search adapter. There is no server query, polling or payment.
class HistoryBlockDemo extends StatefulWidget {
  const HistoryBlockDemo({
    super.key,
    this.initialState = HistoryDemoState.ready,
    this.initialDark = false,
  });
  final HistoryDemoState initialState;
  final bool initialDark;
  @override
  State<HistoryBlockDemo> createState() => _HistoryBlockDemoState();
}

class _HistoryBlockDemoState extends State<HistoryBlockDemo> {
  late HistoryDemoState mode = widget.initialState;
  late bool dark = widget.initialDark;
  String query = '';
  TransactionFilter filter = TransactionFilter.all;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(DemoBrand.ruangBayar, Brightness.light),
    darkTheme: buildTheme(DemoBrand.ruangBayar, Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: const [
      PaymentLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat · Demo'),
          actions: [
            PaymentIconButton(
              icon: Icons.brightness_6_outlined,
              tooltip: 'Ganti tema',
              onPressed: () => setState(() => dark = !dark),
            ),
            PopupMenuButton<HistoryDemoState>(
              tooltip: 'Skenario demo',
              onSelected: (value) => setState(() {
                mode = value;
                query = '';
                filter = TransactionFilter.all;
              }),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: HistoryDemoState.ready,
                  child: Text('Data tersedia'),
                ),
                PopupMenuItem(
                  value: HistoryDemoState.loading,
                  child: Text('Memuat'),
                ),
                PopupMenuItem(
                  value: HistoryDemoState.empty,
                  child: Text('Belum ada transaksi'),
                ),
                PopupMenuItem(
                  value: HistoryDemoState.error,
                  child: Text('Gagal memuat'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: MerchantHistory(
            records: mode == HistoryDemoState.empty
                ? []
                : TransactionRecord.where(
                    historyFixture,
                    query: query,
                    filter: filter,
                  ),
            query: query,
            filter: filter,
            onQueryChanged: (value) => setState(() => query = value),
            onFilterChanged: (value) => setState(() => filter = value),
            loading: mode == HistoryDemoState.loading,
            error: mode == HistoryDemoState.error
                ? 'Riwayat belum dapat dimuat. Coba lagi.'
                : null,
            onRetry: () async => setState(() => mode = HistoryDemoState.ready),
            onOpen: (record) => showPaymentSheet<void>(
              context: context,
              builder: (context) => MerchantHistoryDetail(
                record: record,
                onClose: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
