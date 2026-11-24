import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/wallet_handoff_block.dart';

void main() => runBlockDemo(const WalletHandoffDemo());

enum _Scenario { appAvailable, appUnavailable, noReturn }

/// Simulates a wallet app and provider independently. No app or URL is opened.
class WalletHandoffDemo extends StatefulWidget {
  const WalletHandoffDemo({
    super.key,
    this.embedded = false,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 450),
  });

  final bool embedded;
  final bool initialDark;
  final Duration delay;

  @override
  State<WalletHandoffDemo> createState() => _WalletHandoffDemoState();
}

class _WalletHandoffDemoState extends State<WalletHandoffDemo> {
  late bool _dark = widget.initialDark;
  late _Scenario _scenario;
  late PaymentAttempt _attempt;
  WalletHandoff? _handoff;
  int _serial = 0;

  @override
  void initState() {
    super.initState();
    _reset(_Scenario.appAvailable);
  }

  PaymentStatusSnapshot _reply(PaymentStatus status, int revision) =>
      PaymentStatusSnapshot(
        attemptId: _attempt.attemptId,
        serverReference: 'TX-DEMO-$_serial',
        status: status,
        revision: revision,
        updatedAt: DateTime.utc(2026, 11, 24, 10, revision - 1),
        allowedActions: {
          if (status == PaymentStatus.pending) PaymentAction.checkStatus,
        },
      );

  void _reset(_Scenario scenario) {
    _scenario = scenario;
    final id = 'WALLET-DEMO-${++_serial}';
    _attempt = PaymentAttempt(
      attemptId: id,
      quoteId: 'QUOTE-DEMO-372',
      quoteRevision: 1,
      methodId: 'wallet-demo',
    );
    _attempt = _attempt.reconcile(_reply(PaymentStatus.pending, 1)).attempt;
    _handoff = (attemptId: id, phase: WalletHandoffPhase.ready);
  }

  Future<void> _open(String attemptId) => openWalletHandoff(
    attemptId: attemptId,
    readHandoff: () => mounted ? _handoff : null,
    writeHandoff: (next) => setState(() {
      _handoff =
          _scenario == _Scenario.noReturn &&
              next?.phase == WalletHandoffPhase.awaitingReturn
          ? (attemptId: attemptId, phase: WalletHandoffPhase.noReturn)
          : next;
    }),
    isAuthorized: () =>
        _attempt.attemptId == attemptId &&
        _attempt.observation == Observation.fresh &&
        _attempt.status == PaymentStatus.pending,
    persistAttempt: () async {}, // Demo only: there is no persistent storage.
    launchWallet: () async {
      final opens = _scenario != _Scenario.appUnavailable;
      await Future<void>.delayed(widget.delay);
      return opens;
    },
  );

  void _finishHandoff(String attemptId, WalletHandoffPhase result) {
    if (_handoff !=
        (attemptId: attemptId, phase: WalletHandoffPhase.awaitingReturn)) {
      return;
    }
    setState(() => _handoff = (attemptId: attemptId, phase: result));
  }

  Future<void> _check(String attemptId) async {
    if (_attempt.attemptId != attemptId ||
        _attempt.observation == Observation.refreshing ||
        !_attempt.availableActions.contains(PaymentAction.checkStatus)) {
      return;
    }
    final revision = _attempt.snapshot!.revision + 1;
    // Provider fixtures advance on checks, never on a wallet return signal.
    final status = switch (_scenario) {
      _Scenario.appAvailable when revision > 2 => PaymentStatus.succeeded,
      _Scenario.noReturn => PaymentStatus.expired,
      _ => PaymentStatus.pending,
    };
    final offline =
        _scenario == _Scenario.noReturn &&
        _attempt.observation == Observation.fresh;
    setState(() {
      _attempt = _attempt.copyWith(observation: Observation.refreshing);
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || _attempt.attemptId != attemptId) return;
    setState(() {
      if (offline) {
        _attempt = _attempt.copyWith(observation: Observation.unavailable);
        return;
      }
      final reply = _reply(status, revision);
      _attempt = _attempt
          .reconcile(reply)
          .attempt
          .copyWith(lastCheckedAt: reply.updatedAt);
    });
  }

  Widget _body(BuildContext context) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    final theme = PaymentTheme.of(context);
    final attemptId = _attempt.attemptId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(theme.space(PaymentSpace.block)),
          child: Text(
            id
                ? 'Simulasi · tanpa aplikasi dompet'
                : 'Demo · no wallet app opens',
            textAlign: TextAlign.center,
            style: PaymentType.of(context).caption,
          ),
        ),
        if (_handoff?.phase == WalletHandoffPhase.awaitingReturn)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.space(PaymentSpace.block),
            ),
            child: PaymentButtonGroup(
              direction: Axis.vertical,
              children: [
                PaymentButton(
                  label: id ? 'Simulasi kembali' : 'Simulate return',
                  variant: PaymentButtonVariant.secondary,
                  onPressed: () =>
                      _finishHandoff(attemptId, WalletHandoffPhase.returned),
                ),
                PaymentButton(
                  label: id ? 'Simulasi batal' : 'Simulate cancel',
                  variant: PaymentButtonVariant.quiet,
                  onPressed: () =>
                      _finishHandoff(attemptId, WalletHandoffPhase.canceled),
                ),
              ],
            ),
          ),
        Expanded(
          child: WalletHandoffBlock(
            attempt: _attempt,
            amount: const Money.idr(152500),
            handoff: _handoff,
            onOpenWallet: _open,
            onCheckStatus: _check,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _body(context)
      : BlockDemoShell(
          title: 'Dompet digital',
          dark: _dark,
          onToggleDark: () => setState(() => _dark = !_dark),
          scenarios: [
            for (final (scenario, label) in [
              (_Scenario.appAvailable, 'Aplikasi tersedia'),
              (_Scenario.appUnavailable, 'Aplikasi tidak tersedia'),
              (_Scenario.noReturn, 'Tidak kembali dari dompet'),
            ])
              (
                label: label,
                onSelected: () => setState(() => _reset(scenario)),
              ),
          ],
          body: _body,
        );
}
