import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'compositions/merchant_overview.dart';
import 'compositions/merchant_transaction_detail.dart';
import 'themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MerchantDemo());
}

/// Deterministic, synthetic host fixture. No provider or network is involved.
final merchantFixture = MerchantOverviewData(
  merchant: 'Toko Senja',
  balance: const Money.idr(8240000),
  revenue: const Money.idr(12450000),
  period: '29 Okt – 4 Nov 2026',
  points: [
    for (final (label, value) in const [
      ('29 Okt', 1200000),
      ('30 Okt', 1800000),
      ('31 Okt', 1600000),
      ('1 Nov', 2100000),
      ('2 Nov', 1400000),
      ('3 Nov', 2050000),
      ('4 Nov', 2300000),
    ])
      ChartPoint(label: label, value: Money.idr(value)),
  ],
  methods: [
    MeterSegment(label: 'QRIS', measure: 65),
    MeterSegment(label: 'Transfer', measure: 25),
    MeterSegment(label: 'Saldo', measure: 10),
  ],
  recent: merchantTransactions.take(2).toList(),
  unconfirmedCount: 3,
);

final merchantTransactions = [
  for (final (id, amount, method, status, minute) in [
    ('INV-2048', 150000, 'QRIS', PaymentStatus.succeeded, 42),
    ('INV-2047', 320000, 'Transfer', null, 38),
    ('INV-2046', 210000, 'QRIS', null, 30),
    ('INV-2045', 95000, 'Saldo', null, 20),
  ])
    TransactionRecord(
      id: id,
      title: id,
      reference: id,
      amount: Money.idr(amount),
      createdAt: DateTime(2026, 11, 4, 10, minute),
      status: status,
      merchant: method,
      methodLabel: method,
    ),
];

class MerchantDemo extends StatefulWidget {
  const MerchantDemo({super.key});

  @override
  State<MerchantDemo> createState() => _MerchantDemoState();
}

class _MerchantDemoState extends State<MerchantDemo> {
  bool dark = false;

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
    home: _MerchantShell(
      dark: dark,
      onDarkChanged: (v) => setState(() => dark = v),
    ),
  );
}

class _MerchantShell extends StatefulWidget {
  const _MerchantShell({required this.dark, required this.onDarkChanged});
  final bool dark;
  final ValueChanged<bool> onDarkChanged;

  @override
  State<_MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<_MerchantShell> {
  int tab = 0;
  bool unconfirmedOnly = false;

  void transactions({bool unconfirmed = false}) => setState(() {
    tab = 1;
    unconfirmedOnly = unconfirmed;
  });

  void openRecord(TransactionRecord record) => showPaymentSheet<void>(
    context: context,
    builder: (context) => MerchantTransactionDetail(
      record: record,
      onClose: () => Navigator.pop(context),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (widget.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
      child: Scaffold(
        body: SafeArea(
          child: switch (tab) {
            0 => MerchantOverview(
              data: merchantFixture,
              onInspectUnconfirmed: () => transactions(unconfirmed: true),
              onViewTransactions: transactions,
              onOpenTransaction: openRecord,
              onOpenAccount: () => setState(() => tab = 2),
            ),
            1 => ListView(
              padding: EdgeInsets.all(theme.space(PaymentSpace.group)),
              children: [
                Text(
                  unconfirmedOnly
                      ? 'Pembayaran belum diketahui'
                      : 'Semua transaksi',
                  style: type.title,
                ),
                if (unconfirmedOnly)
                  PaymentLink(
                    label: 'Tampilkan semua transaksi',
                    onPressed: () => transactions(),
                  ),
                for (final record in merchantTransactions.where(
                  (r) => !unconfirmedOnly || r.status == null,
                ))
                  TransactionListItem(
                    record: record,
                    onTap: () => openRecord(record),
                  ),
              ],
            ),
            _ => ListView(
              padding: EdgeInsets.all(theme.space(PaymentSpace.group)),
              children: [
                Text('Pengaturan toko', style: type.title),
                Text('Toko Senja · Demo sintetis', style: type.caption),
                SwitchListTile(
                  title: const Text('Mode gelap'),
                  value: widget.dark,
                  onChanged: widget.onDarkChanged,
                ),
              ],
            ),
          },
        ),
        // The native host shell owns navigation and safe-area handling.
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: tab,
          selectedItemColor: theme.textPrimary,
          unselectedItemColor: theme.textSecondary,
          selectedLabelStyle: type.caption,
          unselectedLabelStyle: type.caption,
          backgroundColor: theme.surface,
          elevation: 0,
          onTap: (value) => setState(() {
            tab = value;
            unconfirmedOnly = false;
          }),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Ringkasan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
