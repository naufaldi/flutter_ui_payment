import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Host-reported handoff progress, separate from the payment's business status.
enum WalletHandoffPhase {
  ready,
  opening,
  awaitingReturn,
  returned,
  appUnavailable,
  canceled,
  noReturn,
}

typedef WalletHandoff = ({String attemptId, WalletHandoffPhase phase});

/// Host-side recipe for [WalletHandoffBlock.onOpenWallet]. The caller captures
/// the attempt and wallet authorization in its callbacks. [isAuthorized] must
/// only read state and must reject a replaced attempt or authorization.
/// Don't re-arm the same attempt while its earlier handoff is still in flight.
/// If [persistAttempt] throws, no launch occurs. Catch the error in the host
/// to explain that the attempt could not be saved. [launchWallet] reports
/// expected launch failures as `false`, independent of payment status.
Future<void> openWalletHandoff({
  required String attemptId,
  required WalletHandoff? Function() readHandoff,
  required void Function(WalletHandoff?) writeHandoff,
  required bool Function() isAuthorized,
  required Future<void> Function() persistAttempt,
  required Future<bool> Function() launchWallet,
}) async {
  final ready = (attemptId: attemptId, phase: WalletHandoffPhase.ready);
  if (readHandoff() != ready || !isAuthorized()) return;
  final opening = (attemptId: attemptId, phase: WalletHandoffPhase.opening);
  writeHandoff(opening);
  try {
    await persistAttempt();
  } catch (_) {
    if (readHandoff() == opening) {
      writeHandoff(isAuthorized() ? ready : null);
    }
    rethrow;
  }
  if (readHandoff() != opening) return;
  if (!isAuthorized()) {
    writeHandoff(null);
    return;
  }
  final opened = await launchWallet();
  if (readHandoff() == opening) {
    writeHandoff((
      attemptId: attemptId,
      phase: opened
          ? WalletHandoffPhase.awaitingReturn
          : WalletHandoffPhase.appUnavailable,
    ));
  }
}

/// Copyable host block for one wallet and one existing payment attempt.
/// Wallet callbacks and lifecycle events cannot update the payment status here.
class WalletHandoffBlock extends StatelessWidget {
  const WalletHandoffBlock({
    super.key,
    required this.attempt,
    required this.amount,
    required this.onOpenWallet,
    required this.onCheckStatus,
    this.handoff,
  });

  final PaymentAttempt attempt;
  final Money amount;
  final WalletHandoff? handoff;
  final Future<void> Function(String attemptId) onOpenWallet;
  final Future<void> Function(String attemptId) onCheckStatus;

  @override
  Widget build(BuildContext context) {
    final id = attempt.attemptId;
    final snapshot = attempt.snapshot;
    final handoff = this.handoff;
    final phase =
        handoff != null &&
            handoff.attemptId == id &&
            (handoff.phase != WalletHandoffPhase.ready ||
                (attempt.observation == Observation.fresh &&
                    attempt.availableActions.contains(
                      PaymentAction.checkStatus,
                    ))) &&
            attempt.submission == SubmissionState.accepted &&
            (attempt.status == PaymentStatus.pending ||
                attempt.status == PaymentStatus.requiresAction)
        ? handoff.phase
        : null;
    final showAmountBeforeLaunch =
        phase == WalletHandoffPhase.ready ||
        phase == WalletHandoffPhase.opening;

    // This block can only open the existing authorization or check its status.
    // Other host actions belong outside it, even after a terminal result.
    final statusAttempt =
        snapshot != null &&
            snapshot.allowedActions.any((a) => a != PaymentAction.checkStatus)
        ? attempt.copyWith(
            snapshot: PaymentStatusSnapshot(
              attemptId: snapshot.attemptId,
              serverReference: snapshot.serverReference,
              status: snapshot.status,
              revision: snapshot.revision,
              updatedAt: snapshot.updatedAt,
              safeReason: snapshot.safeReason,
              refund: snapshot.refund,
              instructions: snapshot.instructions,
              isCorrection: snapshot.isCorrection,
              allowedActions: {
                if (snapshot.allowedActions.contains(PaymentAction.checkStatus))
                  PaymentAction.checkStatus,
              },
            ),
          )
        : attempt;

    return PaymentStatusView(
      key: ValueKey(id),
      attempt: statusAttempt,
      amount: showAmountBeforeLaunch ? null : amount,
      header: phase == null
          ? null
          : _instructions(context, phase, () => onOpenWallet(id)),
      onAction: (action) async {
        if (action == PaymentAction.checkStatus) await onCheckStatus(id);
      },
    );
  }

  Widget _instructions(
    BuildContext context,
    WalletHandoffPhase phase,
    Future<void> Function() open,
  ) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    final canOpen = phase == WalletHandoffPhase.ready;
    final opening = phase == WalletHandoffPhase.opening;
    final (title, message, tone) = switch (phase) {
      WalletHandoffPhase.ready || WalletHandoffPhase.opening => (
        id ? 'Bayar di dompet digital' : 'Pay in your wallet',
        id
            ? 'Buka aplikasi dompet di perangkat ini, lalu kembali untuk cek status.'
            : 'Open the wallet app on this device, then come back to check status.',
        StatusTone.info,
      ),
      WalletHandoffPhase.awaitingReturn => (
        id ? 'Menunggu kembali dari dompet' : 'Waiting for wallet return',
        id
            ? 'Jika sudah selesai di aplikasi dompet, cek status di sini.'
            : 'If you finished in the wallet app, check status here.',
        StatusTone.info,
      ),
      WalletHandoffPhase.returned => (
        id ? 'Kembali dari dompet' : 'Back from wallet',
        id
            ? 'Cek status untuk memastikan pembayaran ini.'
            : 'Check status to confirm this payment.',
        StatusTone.info,
      ),
      WalletHandoffPhase.appUnavailable => (
        id ? 'Aplikasi dompet tidak tersedia' : 'Wallet app unavailable',
        id
            ? 'Aplikasi tidak dapat dibuka. Cek status sebelum membayar lagi.'
            : 'The app could not open. Check status before paying again.',
        StatusTone.warning,
      ),
      WalletHandoffPhase.canceled => (
        id ? 'Batal di aplikasi dompet' : 'Wallet step canceled',
        id
            ? 'Cek status untuk mengetahui apakah pembayaran tercatat.'
            : 'Check status to see whether this payment went through.',
        StatusTone.warning,
      ),
      WalletHandoffPhase.noReturn => (
        id ? 'Belum ada respons dari dompet' : 'No return from wallet',
        id
            ? 'Cek status pembayaran ini sebelum mencoba lagi.'
            : 'Check this payment’s status before trying again.',
        StatusTone.warning,
      ),
    };
    final theme = PaymentTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.space(PaymentSpace.group)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canOpen || opening) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(amount, variant: AmountTextVariant.display),
            ),
            SizedBox(height: theme.space(PaymentSpace.related)),
          ],
          PaymentBanner(
            tone: tone,
            title: title,
            message: message,
            announce: !canOpen && !opening,
          ),
          if (canOpen || opening) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            PaymentButton(
              label: id ? 'Buka dompet' : 'Open wallet',
              variant: PaymentButtonVariant.secondary,
              busyLabel: id ? 'Membuka dompet' : 'Opening wallet',
              busy: opening,
              onPressed: canOpen ? open : null,
            ),
          ],
        ],
      ),
    );
  }
}
