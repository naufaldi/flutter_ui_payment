import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'compositions/host_checkout.dart';
import 'compositions/host_checkout_journey.dart';
import 'themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const CheckoutBlockDemo());
}

enum CheckoutDemoScenario { lostResponse, pendingOffline, receiptRetry }

/// The two host-owned designs one checkout model can wear: the stacked
/// invoice on Hairline, or the wallet review on the Soft preset.
enum CheckoutDemoLook { invoice, wallet }

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

  String methodLabel(CheckoutOrder order) {
    final id = order.selectedMethodId;
    final method = order.methods.firstWhere(
      (m) => m.id == id,
      orElse: () => order.methods.first,
    );
    final tail = method.kind == PaymentMethodKind.virtualAccount
        ? '8800'
        : '2190';
    return '${method.label} •••• $tail';
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
      methodLabel: methodLabel(sentOrder!),
    );
  }
}

/// Full native phone host shell around the existing copyable D104 block.
class CheckoutBlockDemo extends StatefulWidget {
  const CheckoutBlockDemo({
    super.key,
    this.host,
    this.initialDark = false,
    this.quoteFor,
  });
  final CheckoutDemoHost? host;
  final bool initialDark;

  /// Replaces the fixture pricing, e.g. to control answer order in tests.
  final Future<PaymentQuote> Function(String methodId)? quoteFor;

  @override
  State<CheckoutBlockDemo> createState() => _CheckoutBlockDemoState();
}

class _CheckoutBlockDemoState extends State<CheckoutBlockDemo> {
  late CheckoutDemoHost host = widget.host ?? CheckoutDemoHost();
  late bool dark = widget.initialDark;
  CheckoutDemoLook look = CheckoutDemoLook.invoice;
  bool reducedMotion = false;
  int session = 1;
  int attemptSequence = 0;
  String email = '';
  String selectedMethodId = 'balance';
  late PaymentQuote quote = _quoteFor('balance');
  bool quoting = false;
  int quoteRequest = 0;

  static const _methods = [
    PaymentMethod(
      id: 'balance',
      label: 'Saldo Ruang Bayar',
      kind: PaymentMethodKind.balance,
      detail: 'Saldo Rp350.000',
      feeNote: 'Biaya layanan Rp2.500',
    ),
    PaymentMethod(
      id: 'va',
      label: 'Virtual account',
      kind: PaymentMethodKind.virtualAccount,
      detail: 'Bank Demo',
      feeNote: 'Biaya bank Rp4.000',
    ),
  ];

  /// Synthetic pricing for the selected method. A real host asks its server;
  /// the bank transfer carries a higher fee, so the total changes with it.
  PaymentQuote _quoteFor(String methodId) => PaymentQuote(
    id: 'QUOTE-DEMO-$session-$methodId',
    revision: 1,
    methodId: methodId,
    lines: [
      const QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
      QuoteLine(
        label: methodId == 'va' ? 'Biaya bank' : 'Biaya layanan',
        amount: Money.idr(methodId == 'va' ? 4000 : 2500),
        kind: QuoteLineKind.fee,
      ),
    ],
    total: Money.idr(methodId == 'va' ? 104000 : 102500),
    expiresAt: host.now.add(const Duration(minutes: 5)),
  );

  Future<PaymentQuote> _fixtureQuote(String methodId) async {
    await Future<void>.delayed(host.delay);
    return _quoteFor(methodId);
  }

  /// Re-quotes for the chosen method. Every request gets a number and a
  /// session stamp; only the newest answer from the live session may update
  /// the screen, so a replay or a second tap can never apply a stale price.
  Future<void> select(PaymentMethod method) async {
    final request = ++quoteRequest;
    final current = session;
    setState(() {
      selectedMethodId = method.id;
      quoting = true;
    });
    try {
      final answer = await (widget.quoteFor ?? _fixtureQuote)(method.id);
      if (!mounted || current != session || request != quoteRequest) return;
      setState(() {
        quoting = false;
        quote = answer;
      });
    } catch (_) {
      if (!mounted || current != session || request != quoteRequest) return;
      // The previous quote stays but belongs to another method, so Pay
      // remains blocked until a current quote arrives.
      setState(() => quoting = false);
    }
  }

  /// Scenario and replay start a fresh session on purpose: the journey
  /// remounts, quoting state resets and any quote still in flight is stale.
  void restart([CheckoutDemoScenario? scenario]) => setState(() {
    host = CheckoutDemoHost(
      scenario: scenario ?? host.scenario,
      delay: host.delay,
    );
    session++;
    email = '';
    selectedMethodId = 'balance';
    quote = _quoteFor('balance');
    quoting = false;
    quoteRequest++;
  });

  CheckoutOrder get order => CheckoutOrder(
    merchant: 'Ruang Bayar Akademi · Demo',
    merchantVerified: true, // Explicitly verified synthetic fixture only.
    reference: 'INV-DEMO-$session',
    quote: quote,
    methods: _methods,
    selectedMethodId: selectedMethodId,
    balance: const Money.idr(350000),
    balanceState: BalanceState.sufficient,
    receiptEmail: email,
    quoting: quoting,
  );

  void _onDemoMenu(int value) => switch (value) {
    0 => setState(() => look = CheckoutDemoLook.invoice),
    1 => setState(() => look = CheckoutDemoLook.wallet),
    2 => restart(CheckoutDemoScenario.lostResponse),
    3 => restart(CheckoutDemoScenario.pendingOffline),
    4 => restart(CheckoutDemoScenario.receiptRetry),
    5 => restart(),
    _ => setState(() => reducedMotion = !reducedMotion),
  };

  static PopupMenuEntry<int> _menuHeader(BuildContext context, String label) =>
      PopupMenuItem<int>(
        enabled: false,
        height: 32,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  static PopupMenuEntry<int> _menuItem(
    int value,
    String label, {
    bool selected = false,
  }) => PopupMenuItem<int>(
    value: value,
    child: Row(
      children: [
        Expanded(child: Text(label)),
        if (selected) const Icon(Icons.check, size: 18),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final brand = look == CheckoutDemoLook.wallet
        ? DemoBrand.soft
        : DemoBrand.ruangBayar;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brand, Brightness.light),
      darkTheme: buildTheme(brand, Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        PaymentLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // The demo's own switch joins the OS flags; it never clears them.
        return MediaQuery(
          data: media.copyWith(
            disableAnimations:
                media.disableAnimations ||
                reducedMotion ||
                View.of(
                  context,
                ).platformDispatcher.accessibilityFeatures.reduceMotion,
          ),
          child: child!,
        );
      },
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
                PopupMenuButton<int>(
                  tooltip: 'Menu demo',
                  onSelected: _onDemoMenu,
                  itemBuilder: (context) => [
                    _menuHeader(context, 'Tampilan'),
                    _menuItem(
                      0,
                      'Invoice',
                      selected: look == CheckoutDemoLook.invoice,
                    ),
                    _menuItem(
                      1,
                      'Dompet',
                      selected: look == CheckoutDemoLook.wallet,
                    ),
                    _menuHeader(context, 'Skenario'),
                    _menuItem(
                      2,
                      'Respons hilang',
                      selected:
                          host.scenario == CheckoutDemoScenario.lostResponse,
                    ),
                    _menuItem(
                      3,
                      'Pending lalu offline',
                      selected:
                          host.scenario == CheckoutDemoScenario.pendingOffline,
                    ),
                    _menuItem(
                      4,
                      'Struk gagal dimuat',
                      selected:
                          host.scenario == CheckoutDemoScenario.receiptRetry,
                    ),
                    _menuHeader(context, 'Demo'),
                    _menuItem(5, 'Putar ulang'),
                    _menuItem(6, 'Kurangi gerakan', selected: reducedMotion),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: HostCheckoutJourney(
                key: ValueKey(session),
                layout: look == CheckoutDemoLook.wallet
                    ? CheckoutLayout.wallet
                    : CheckoutLayout.invoice,
                order: order,
                clock: () => host.now,
                newAttemptId: () => 'DEMO-${++attemptSequence}',
                onSelectMethod: select,
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
}
