part of 'gallery_screen.dart';

/// A synthetic host that restores one attempt and returns authoritative
/// fixtures. No submission, networking or persistence is performed here.
class _HostRecoveryDemo extends StatefulWidget {
  const _HostRecoveryDemo();

  @override
  State<_HostRecoveryDemo> createState() => _HostRecoveryDemoState();
}

class _HostRecoveryDemoState extends State<_HostRecoveryDemo> {
  static const _unknown = PaymentAttempt(
    attemptId: 'DEMO-RESTORED-1103',
    quoteId: 'Q-HOST',
    quoteRevision: 1,
    methodId: 'balance',
    submission: SubmissionState.outcomeUnknown,
  );
  static const _states = ['Unknown', 'Offline pending', 'Receipt'];
  String _state = 'Unknown';
  PaymentAttempt _attempt = _unknown;
  int _request = 0;

  PaymentStatusSnapshot _snapshot(PaymentStatus status) =>
      PaymentStatusSnapshot(
        attemptId: _unknown.attemptId,
        serverReference: 'DEMO-TX-1103',
        status: status,
        revision: 1,
        updatedAt: _now,
        allowedActions: status == PaymentStatus.succeeded
            ? {PaymentAction.viewReceipt}
            : {PaymentAction.checkStatus},
      );

  void _select(String state) => setState(() {
    _request++;
    _state = state;
    _attempt = switch (state) {
      'Offline pending' =>
        _unknown
            .reconcile(_snapshot(PaymentStatus.pending))
            .attempt
            .copyWith(
              observation: Observation.unavailable,
              lastCheckedAt: _now,
            ),
      'Receipt' =>
        _unknown.reconcile(_snapshot(PaymentStatus.succeeded)).attempt,
      _ => _unknown,
    };
  });

  Future<void> _action(String id, PaymentAction action) async {
    if (action != PaymentAction.checkStatus) return;
    final request = ++_request;
    setState(() {
      _attempt = _attempt.copyWith(observation: Observation.refreshing);
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted ||
        request != _request ||
        _attempt.attemptId != id ||
        _attempt.observation != Observation.refreshing) {
      return;
    }
    // A deliberate fixture, not a conclusion drawn from elapsed time.
    _select('Receipt');
  }

  @override
  Widget build(BuildContext context) => _Entry(
    name: 'Host payment recovery · variants',
    states: _StatePicker(
      values: _states,
      selected: _state,
      label: (v) => v,
      onSelected: _select,
    ),
    child: ProductLooks(
      child: SizedBox(
        height: 640,
        child: HostPaymentRecovery(
          attempt: _attempt,
          amount: const Money.idr(102500),
          receipt: _state == 'Receipt'
              ? PaymentReceiptData(
                  transactionId: 'DEMO-TX-1103',
                  merchantName: 'Ruang Bayar Akademi (Demo)',
                  paidAt: _now,
                  lines: _quote().lines,
                  total: const Money.idr(102500),
                  methodLabel: 'Saldo •••• 2190',
                )
              : null,
          onAction: _action,
          onDone: () => _select('Unknown'),
          onShare: (_) async => ShareOutcome.dismissed,
          onCopy: (_) async => false,
        ),
      ),
    ),
  );
}
