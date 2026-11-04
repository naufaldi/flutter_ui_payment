import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'compositions/host_checkout.dart';
import 'compositions/host_checkout_journey.dart';
import 'themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const CheckoutBlockDemo());
}

enum CheckoutDemoScenario { lostResponse, pendingOffline, receiptRetry }

/// Synthetic adapter for this runnable example only. Replace it with host
/// persistence and authoritative APIs. Delay never determines a verdict.
class CheckoutDemoHost {
  CheckoutDemoHost({
    this.scenario = CheckoutDemoScenario.lostResponse,
    this.delay = const Duration(milliseconds: 500),
  });

  final CheckoutDemoScenario scenario;
  final Duration delay;
  final submittedIds = <String>[];
  final checkedIds = <String>[];
  int receiptLoads = 0;
  CheckoutOrder? sentOrder;
  final now = DateTime(2026, 11, 4, 10, 42);

  PaymentStatusSnapshot snapshot(
    PaymentAttempt attempt,
    PaymentStatus status,
  ) => PaymentStatusSnapshot(
    attemptId: attempt.attemptId,
    serverReference: 'TX-${attempt.attemptId}',
    status: status,
    revision: status == PaymentStatus.succeeded ? 2 : 1,
    updatedAt: now,
    allowedActions: {
      status == PaymentStatus.succeeded
          ? PaymentAction.viewReceipt
          : PaymentAction.checkStatus,
    },
  );

  Future<PaymentStatusSnapshot?> submit(
    PaymentAttempt attempt,
    CheckoutOrder order,
  ) async {
    // The fixture records identity before simulating transport. A real host
    // must persist this durably before sending and deduplicate server-side.
    submittedIds.add(attempt.attemptId);
    sentOrder = order;
    await Future<void>.delayed(delay);
    return switch (scenario) {
      CheckoutDemoScenario.lostResponse => null,
      CheckoutDemoScenario.pendingOffline => snapshot(
        attempt,
        PaymentStatus.pending,
      ),
      CheckoutDemoScenario.receiptRetry => snapshot(
        attempt,
        PaymentStatus.succeeded,
      ),
    };
  }

  Future<PaymentStatusSnapshot> check(PaymentAttempt attempt) async {
    checkedIds.add(attempt.attemptId);
    await Future<void>.delayed(delay);
    if (scenario == CheckoutDemoScenario.pendingOffline &&
        checkedIds.length == 1) {
      throw StateError('Synthetic offline response');
    }
    return snapshot(attempt, PaymentStatus.succeeded);
  }

  Future<PaymentReceiptData> receipt(PaymentAttempt attempt) async {
    receiptLoads++;
    await Future<void>.delayed(delay);
    if (scenario == CheckoutDemoScenario.receiptRetry && receiptLoads == 1) {
      throw StateError('Synthetic receipt service failure');
    }
    return PaymentReceiptData(
      transactionId: attempt.serverReference!,
      merchantName: sentOrder!.merchant,
      paidAt: now,
      lines: sentOrder!.quote.lines,
      total: sentOrder!.quote.total,
      methodLabel: 'Saldo •••• 2190',
    );
  }
}

/// Full native phone host shell around the existing copyable D104 block.
class CheckoutBlockDemo extends StatefulWidget {
  const CheckoutBlockDemo({super.key, this.host, this.initialDark = false});
  final CheckoutDemoHost? host;
  final bool initialDark;

  @override
  State<CheckoutBlockDemo> createState() => _CheckoutBlockDemoState();
}

class _CheckoutBlockDemoState extends State<CheckoutBlockDemo> {
  late CheckoutDemoHost host = widget.host ?? CheckoutDemoHost();
  late bool dark = widget.initialDark;
  int session = 1;
  int attemptSequence = 0;
  String email = '';

  void restart([CheckoutDemoScenario? scenario]) => setState(() {
    host = CheckoutDemoHost(scenario: scenario ?? host.scenario);
    session++;
    email = '';
  });

  CheckoutOrder get order => CheckoutOrder(
    merchant: 'Ruang Bayar Akademi · Demo',
    merchantVerified: true, // Explicitly verified synthetic fixture only.
    reference: 'INV-DEMO-$session',
    quote: PaymentQuote(
      id: 'QUOTE-DEMO-$session',
      revision: 1,
      methodId: 'balance',
      lines: const [
        QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
        QuoteLine(
          label: 'Biaya layanan',
          amount: Money.idr(2500),
          kind: QuoteLineKind.fee,
        ),
      ],
      total: const Money.idr(102500),
      expiresAt: host.now.add(const Duration(minutes: 5)),
    ),
    methods: const [
      PaymentMethod(
        id: 'balance',
        label: 'Saldo Ruang Bayar',
        kind: PaymentMethodKind.balance,
      ),
    ],
    selectedMethodId: 'balance',
    balance: const Money.idr(350000),
    balanceState: BalanceState.sufficient,
    receiptEmail: email,
  );

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
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Checkout · Demo'),
            actions: [
              PaymentIconButton(
                icon: dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                tooltip: dark ? 'Mode terang' : 'Mode gelap',
                onPressed: () => setState(() => dark = !dark),
              ),
              PopupMenuButton<CheckoutDemoScenario>(
                tooltip: 'Skenario demo',
                onSelected: restart,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: CheckoutDemoScenario.lostResponse,
                    child: Text('Respons hilang'),
                  ),
                  PopupMenuItem(
                    value: CheckoutDemoScenario.pendingOffline,
                    child: Text('Pending lalu offline'),
                  ),
                  PopupMenuItem(
                    value: CheckoutDemoScenario.receiptRetry,
                    child: Text('Struk gagal dimuat'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: HostCheckoutJourney(
              key: ValueKey(session),
              order: order,
              clock: () => host.now,
              newAttemptId: () => 'DEMO-${++attemptSequence}',
              onSelectMethod: (_) {}, // The sole wallet is already priced.
              onReceiptEmailChanged: (value) => setState(() => email = value),
              onSubmit: host.submit,
              onCheckStatus: host.check,
              onLoadReceipt: host.receipt,
              onOtherAction: (_, _) =>
                  throw UnsupportedError('No such fixture action'),
              onDone: restart,
              // No platform effect is performed or falsely reported as success.
              onShare: (_) async => ShareOutcome.dismissed,
              onCopy: (_) async => false,
            ),
          ),
        ),
      ),
    ),
  );
}
