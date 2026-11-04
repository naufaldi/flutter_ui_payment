import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'block_demo_shell.dart';
import 'compositions/manual_transfer_block.dart';

void main() => runBlockDemo(const ManualTransferDemo());

enum ManualTransferScenario { open, elapsed, checkOffline, issueUnknown }

final manualTransferIssuedAt = DateTime(2026, 11, 4, 10, 0);
final manualTransferDeadline = DateTime(2026, 11, 4, 11, 0);
const manualTransferAmount = Money.idr(152500);

/// Synthetic VA host. Status answers are declared fixture responses: time
/// passing never produces one. There is no bank SDK, network or polling.
class ManualTransferDemo extends StatefulWidget {
  const ManualTransferDemo({
    super.key,
    this.initialScenario = ManualTransferScenario.open,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 600),
    this.clock,
  });
  final ManualTransferScenario initialScenario;
  final bool initialDark;
  final Duration delay;

  /// Fixed clock for tests and captures; the demo otherwise starts 18 minutes
  /// after issue and runs in real time from there.
  final DateTime Function()? clock;

  @override
  State<ManualTransferDemo> createState() => _ManualTransferDemoState();
}

class _ManualTransferDemoState extends State<ManualTransferDemo> {
  late bool dark = widget.initialDark;
  late ManualTransferScenario scenario;
  late DateTime started;
  late PaymentAttempt attempt;
  final launched = DateTime.now();
  bool checking = false;
  int checks = 0;
  int generation = 0;

  /// Every check names this one attempt; the demo never creates another.
  static const attemptId = 'VA-DEMO-217';

  @override
  void initState() {
    super.initState();
    reset(widget.initialScenario);
  }

  DateTime now() =>
      widget.clock?.call() ?? started.add(DateTime.now().difference(launched));

  PaymentStatusSnapshot snapshot(
    PaymentStatus status, {
    int revision = 1,
    String? reason,
  }) => PaymentStatusSnapshot(
    attemptId: attemptId,
    serverReference: 'TX-DEMO-88104217',
    status: status,
    revision: revision,
    updatedAt: now(),
    safeReason: reason,
    allowedActions: status == PaymentStatus.pending
        ? const {PaymentAction.checkStatus}
        : const {},
    instructions: status == PaymentStatus.pending
        ? VirtualAccountInstructions(
            providerLabel: 'Virtual Account Bank Demo',
            accountNumber: '8808 1234 5678 9012',
            amount: manualTransferAmount,
            expiresAt: manualTransferDeadline,
            steps: const [
              'Buka aplikasi atau ATM bank Anda.',
              'Pilih transfer ke virtual account.',
              'Masukkan nomor di atas dan pastikan jumlahnya sama persis.',
              'Simpan bukti transfer, lalu ketuk Cek status.',
            ],
          )
        : null,
  );

  void reset(ManualTransferScenario value) {
    generation++;
    scenario = value;
    checking = false;
    checks = 0;
    // Elapsed starts past the deadline: the host still reports pending.
    started = manualTransferIssuedAt.add(
      Duration(minutes: value == ManualTransferScenario.elapsed ? 75 : 18),
    );
    attempt = value == ManualTransferScenario.issueUnknown
        ? const PaymentAttempt(
            attemptId: attemptId,
            quoteId: 'QUOTE-DEMO-217',
            quoteRevision: 1,
            methodId: 'va',
            submission: SubmissionState.outcomeUnknown,
          )
        : PaymentAttempt(
            attemptId: attemptId,
            quoteId: 'QUOTE-DEMO-217',
            quoteRevision: 1,
            methodId: 'va',
            submission: SubmissionState.accepted,
            snapshot: snapshot(PaymentStatus.pending),
            lastCheckedAt: now(),
          );
  }

  Future<void> check() async {
    if (checking) return;
    final current = generation;
    final count = ++checks;
    setState(() {
      checking = true;
      attempt = attempt.copyWith(observation: Observation.refreshing);
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      checking = false;
      if (scenario == ManualTransferScenario.checkOffline && count == 1) {
        // Failed refresh: keep the last known pending snapshot and attempt.
        attempt = attempt.copyWith(observation: Observation.unavailable);
        return;
      }
      final next = switch (scenario) {
        // The issuing call was received after all: the account is now known.
        ManualTransferScenario.issueUnknown when count == 1 => snapshot(
          PaymentStatus.pending,
        ),
        ManualTransferScenario.elapsed => snapshot(
          PaymentStatus.succeeded,
          revision: 2,
          reason:
              'Bank mengonfirmasi transfer yang diterima sebelum batas '
              'waktu.',
        ),
        _ => snapshot(PaymentStatus.succeeded, revision: 2),
      };
      // The kit's ordering rules drop wrong-attempt, stale or downgrading
      // snapshots; a rejected one leaves the last known status in place.
      attempt = attempt
          .reconcile(next)
          .attempt
          .copyWith(observation: Observation.fresh, lastCheckedAt: now());
    });
  }

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Transfer VA · Demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    scenarios: [
      for (final (value, label) in [
        (ManualTransferScenario.open, 'Menunggu transfer'),
        (ManualTransferScenario.elapsed, 'Batas waktu lewat'),
        (ManualTransferScenario.checkOffline, 'Cek status gagal'),
        (ManualTransferScenario.issueUnknown, 'Respons VA hilang'),
      ])
        (label: label, onSelected: () => setState(() => reset(value))),
    ],
    body: (context) => ManualTransferBlock(
      key: ValueKey(generation),
      attempt: attempt,
      amount: manualTransferAmount,
      invoice: 'INV-DEMO-217 · Ruang Bayar Akademi',
      payerLabel: 'Akun •••• 2190',
      clock: now,
      checking: checking,
      onCheckStatus: check,
      onDone: () => setState(() => reset(ManualTransferScenario.open)),
      onCopy: copyToClipboard,
    ),
  );
}
