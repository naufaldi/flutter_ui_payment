import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/qris_checkout_block.dart';

void main() => runBlockDemo(const QrisCheckoutDemo());

enum QrisDemoScenario { active, elapsed, unknown, checkOffline }

final qrisDemoStart = DateTime(2026, 11, 24, 10);
final qrisDemoExpiry = qrisDemoStart.add(const Duration(minutes: 15));

/// A standalone example and the gallery's bounded specimen. The QR decodes
/// to plain demo text, never payment data. Every status reply is a fixture.
class QrisCheckoutDemo extends StatefulWidget {
  const QrisCheckoutDemo({
    super.key,
    this.initialDark = false,
    this.embedded = false,
    this.clock,
    this.delay = const Duration(milliseconds: 600),
  });

  final bool initialDark;
  final bool embedded;
  final DateTime Function()? clock;
  final Duration delay;

  @override
  State<QrisCheckoutDemo> createState() => _QrisCheckoutDemoState();
}

class _QrisCheckoutDemoState extends State<QrisCheckoutDemo> {
  static const _initialAttempt = PaymentAttempt(
    attemptId: 'QRIS-DEMO-359',
    quoteId: 'QUOTE-DEMO-359',
    quoteRevision: 1,
    methodId: 'qris',
    submission: SubmissionState.outcomeUnknown,
  );

  late bool _dark = widget.initialDark;
  QrisDemoScenario _scenario = QrisDemoScenario.active;
  late DateTime _launched;
  late PaymentAttempt _attempt;
  int _session = 0;
  int _checks = 0;

  @override
  void initState() {
    super.initState();
    _reset(QrisDemoScenario.active);
  }

  DateTime _now() {
    final start = _scenario == QrisDemoScenario.elapsed
        ? qrisDemoExpiry
        : qrisDemoStart;
    return widget.clock?.call() ??
        start.add(DateTime.now().difference(_launched));
  }

  PaymentStatusSnapshot _reply(String id, PaymentStatus status, int revision) =>
      PaymentStatusSnapshot(
        attemptId: id,
        serverReference: 'TX-DEMO-359',
        status: status,
        revision: revision,
        updatedAt: _now(),
        allowedActions: {
          if (status == PaymentStatus.pending) PaymentAction.checkStatus,
        },
      );

  void _reset(QrisDemoScenario scenario) {
    _scenario = scenario;
    _launched = DateTime.now();
    _session++;
    _checks = 0;
    _attempt = _initialAttempt;
    if (scenario != QrisDemoScenario.unknown) {
      _attempt = _attempt
          .reconcile(_reply(_attempt.attemptId, PaymentStatus.pending, 1))
          .attempt
          .copyWith(lastCheckedAt: _now());
    }
  }

  Future<void> _check(String attemptId) async {
    if (attemptId != _attempt.attemptId ||
        _attempt.observation == Observation.refreshing) {
      return;
    }
    final session = _session;
    final checks = ++_checks;
    setState(() {
      _attempt = _attempt.copyWith(observation: Observation.refreshing);
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || session != _session) return;
    setState(() {
      if (_scenario == QrisDemoScenario.checkOffline && checks == 1) {
        _attempt = _attempt.copyWith(observation: Observation.unavailable);
        return;
      }
      final status = _scenario == QrisDemoScenario.unknown && checks == 1
          ? PaymentStatus.pending
          : PaymentStatus.succeeded;
      _attempt = _attempt
          .reconcile(
            _reply(attemptId, status, status == PaymentStatus.pending ? 1 : 2),
          )
          .attempt
          .copyWith(lastCheckedAt: _now());
    });
  }

  Widget _block(BuildContext context) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(
            PaymentTheme.of(context).space(PaymentSpace.block),
          ),
          child: Text(
            id
                ? 'Kode demo · tidak untuk pembayaran'
                : 'Demo code · not for payment',
            textAlign: TextAlign.center,
            style: PaymentType.of(context).caption,
          ),
        ),
        Expanded(
          child: QrisCheckoutBlock(
            key: ValueKey(_session),
            attempt: _attempt,
            amount: const Money.idr(152500),
            clock: _now,
            code: _attempt.submission == SubmissionState.accepted
                ? (
                    attemptId: _attempt.attemptId,
                    payee: 'Ruang Bayar Akademi',
                    image: const AssetImage('assets/qris/demo-code.webp'),
                    expiresAt: qrisDemoExpiry,
                  )
                : null,
            onCheckStatus: _check,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _block(context)
      : BlockDemoShell(
          title: 'QRIS · Demo',
          dark: _dark,
          onToggleDark: () => setState(() => _dark = !_dark),
          scenarios: [
            for (final (scenario, label) in [
              (QrisDemoScenario.active, 'Kode aktif'),
              (QrisDemoScenario.elapsed, 'Kode kedaluwarsa'),
              (QrisDemoScenario.unknown, 'Respons QRIS hilang'),
              (QrisDemoScenario.checkOffline, 'Cek status gagal'),
            ])
              (
                label: label,
                onSelected: () => setState(() => _reset(scenario)),
              ),
          ],
          body: _block,
        );
}
