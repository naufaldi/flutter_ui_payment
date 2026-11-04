part of 'gallery_screen.dart';

class _HostJourneyDemo extends StatefulWidget {
  const _HostJourneyDemo();
  @override
  State<_HostJourneyDemo> createState() => _HostJourneyDemoState();
}

class _HostJourneyDemoState extends State<_HostJourneyDemo> {
  static const _scenarios = ['Lost response', 'Pending then offline'];
  String _scenario = _scenarios.first;
  int _session = 0;
  int _attemptSequence = 0;
  int _checks = 0;
  String _email = 'rina@contoh.id';
  String _selected = 'balance';
  CheckoutOrder? _sentOrder;

  PaymentStatusSnapshot _snapshot(
    PaymentAttempt attempt,
    PaymentStatus status,
  ) => PaymentStatusSnapshot(
    attemptId: attempt.attemptId,
    serverReference: 'TX-${attempt.attemptId}',
    status: status,
    revision: status == PaymentStatus.succeeded ? 2 : 1,
    updatedAt: _now,
    allowedActions: status == PaymentStatus.succeeded
        ? {PaymentAction.viewReceipt}
        : {PaymentAction.checkStatus},
  );

  void _restart(String scenario) => setState(() {
    _scenario = scenario;
    _session++;
    _checks = 0;
    _sentOrder = null;
  });

  @override
  Widget build(BuildContext context) => _Entry(
    name: 'Host checkout journey · variants',
    states: _StatePicker(
      values: _scenarios,
      selected: _scenario,
      label: (v) => v,
      onSelected: _restart,
    ),
    child: SizedBox(
      height: 640,
      child: HostCheckoutJourney(
        key: ValueKey(_session),
        order: CheckoutOrder(
          merchant: 'Ruang Bayar Akademi (Demo)',
          reference: 'INV-HOST-$_session',
          quote: _quote(methodId: 'balance'),
          methods: const [
            PaymentMethod(
              id: 'balance',
              label: 'Saldo Ruang Bayar',
              kind: PaymentMethodKind.balance,
            ),
          ],
          selectedMethodId: _selected,
          balance: const Money.idr(350000),
          balanceState: BalanceState.sufficient,
          receiptEmail: _email,
        ),
        clock: () => _now,
        newAttemptId: () => 'ATT-${++_attemptSequence}',
        onSelectMethod: (method) => setState(() => _selected = method.id),
        onReceiptEmailChanged: (value) => setState(() => _email = value),
        onSubmit: (attempt, order) async {
          final scenario = _scenario;
          _sentOrder = order;
          await Future<void>.delayed(const Duration(milliseconds: 600));
          // Explicit synthetic responses, never a verdict inferred from time.
          return scenario == 'Lost response'
              ? null
              : _snapshot(attempt, PaymentStatus.pending);
        },
        onCheckStatus: (attempt) async {
          final offline = _scenario == 'Pending then offline' && _checks++ == 0;
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (offline) throw StateError('Synthetic offline response');
          return _snapshot(attempt, PaymentStatus.succeeded);
        },
        onLoadReceipt: (attempt) async => PaymentReceiptData(
          transactionId: attempt.serverReference!,
          merchantName: _sentOrder!.merchant,
          paidAt: _now,
          lines: _sentOrder!.quote.lines,
          total: _sentOrder!.quote.total,
          methodLabel: 'Saldo •••• 2190',
        ),
        onOtherAction: (_, _) => throw UnsupportedError('Fixture action'),
        onDone: () => _restart(_scenario),
        onShare: (_) async => ShareOutcome.dismissed,
        onCopy: (_) async => false,
      ),
    ),
  );
}
