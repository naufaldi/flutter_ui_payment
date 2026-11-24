import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Host-issued QRIS instructions tied to one payment attempt. The image must
/// include the QR quiet zone and keep its original light background.
/// Keep `expiresAt` unchanged for the same issuance.
typedef QrisCode = ({
  String attemptId,
  String payee,
  ImageProvider image,
  DateTime expiresAt,
});

/// Copyable host composition. It never issues a code, submits a payment or
/// changes the business status. Only the host can reconcile the attempt.
class QrisCheckoutBlock extends StatefulWidget {
  const QrisCheckoutBlock({
    super.key,
    required this.attempt,
    required this.amount,
    required this.clock,
    required this.onCheckStatus,
    this.code,
  });

  final PaymentAttempt attempt;
  final Money amount;
  final DateTime Function() clock;
  final Future<void> Function(String attemptId) onCheckStatus;
  final QrisCode? code;

  @override
  State<QrisCheckoutBlock> createState() => _QrisCheckoutBlockState();
}

class _QrisCheckoutBlockState extends State<QrisCheckoutBlock> {
  final _elapsedIssuances = <(String, int)>{};

  DateTime _readClock(QrisCode code) {
    final now = widget.clock();
    final issuance = (code.attemptId, code.expiresAt.microsecondsSinceEpoch);
    if (!now.isBefore(code.expiresAt)) {
      _elapsedIssuances.add(issuance);
      return now;
    }
    // Expiry is one-way for this issuance, even if instructions unmount during
    // recovery or the host clock later moves backward.
    return _elapsedIssuances.contains(issuance) ? code.expiresAt : now;
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;
    final snapshot = attempt.snapshot;
    final qr = widget.code;
    final matchesAttempt = qr != null && qr.attemptId == attempt.attemptId;
    final elapsed = matchesAttempt && !_readClock(qr).isBefore(qr.expiresAt);
    final showInstructions =
        matchesAttempt &&
        attempt.submission == SubmissionState.accepted &&
        // Don't invite another scan while the host is checking or unreachable.
        attempt.observation == Observation.fresh &&
        (attempt.status == PaymentStatus.pending ||
            attempt.status == PaymentStatus.requiresAction);

    // This view has only one supported action, even if a host snapshot also
    // permits recovery actions elsewhere. Never mutate or reconcile this copy.
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
      // A press or in-flight button must never survive an attempt change.
      key: ValueKey(attempt.attemptId),
      attempt: statusAttempt,
      amount: showInstructions ? null : widget.amount,
      header: showInstructions
          ? _QrisInstructions(
              key: ValueKey((qr.attemptId, qr.expiresAt)),
              code: qr,
              amount: widget.amount,
              elapsed: elapsed,
              clock: () => _readClock(qr),
              onElapsed: () => setState(() {}),
            )
          : null,
      onAction: (action) async {
        if (action == PaymentAction.checkStatus) {
          await widget.onCheckStatus(attempt.attemptId);
        }
      },
    );
  }
}

class _QrisInstructions extends StatelessWidget {
  const _QrisInstructions({
    super.key,
    required this.code,
    required this.amount,
    required this.elapsed,
    required this.clock,
    required this.onElapsed,
  });

  final QrisCode code;
  final Money amount;
  final bool elapsed;
  final DateTime Function() clock;
  final VoidCallback onElapsed;

  @override
  Widget build(BuildContext context) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final expiresAt = l10n.formatDateTime(code.expiresAt.toLocal());
    final gap = SizedBox(height: theme.space(PaymentSpace.related));

    return Padding(
      padding: EdgeInsets.only(bottom: theme.space(PaymentSpace.group)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              id ? 'Pembayaran QRIS' : 'QRIS payment',
              style: type.heading,
            ),
          ),
          gap,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(amount, variant: AmountTextVariant.display),
          ),
          gap,
          InfoRow(label: id ? 'Penerima' : 'Payee', valueText: code.payee),
          gap,
          Text(
            id ? 'Berlaku hingga $expiresAt' : 'Valid until $expiresAt',
            style: type.caption,
          ),
          if (elapsed) ...[
            gap,
            PaymentBanner(
              tone: StatusTone.warning,
              title: id ? 'Kode QR kedaluwarsa' : 'QR code expired',
              message: id
                  ? 'Cek status sebelum membayar lagi.'
                  : 'Check status before paying again.',
              announce: true,
            ),
          ] else ...[
            Wrap(
              spacing: theme.space(PaymentSpace.inline),
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Text(
                    id ? 'Sisa waktu' : 'Time left',
                    style: type.caption,
                  ),
                ),
                CountdownText(
                  expiresAt: code.expiresAt,
                  clock: clock,
                  onElapsed: onElapsed,
                ),
              ],
            ),
            gap,
            Text(
              id ? 'Pindai dari perangkat lain.' : 'Scan from another device.',
              textAlign: TextAlign.center,
              style: type.bodyFor(context),
            ),
            SizedBox(height: theme.space(PaymentSpace.inline)),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 192),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PaymentImage(
                    image: code.image,
                    alt: id ? 'Kode pembayaran QRIS' : 'QRIS payment code',
                    fit: BoxFit.contain,
                    errorFallback: Center(
                      child: Text(
                        id
                            ? 'Kode QR tidak dapat ditampilkan.'
                            : 'The QR code could not be displayed.',
                        textAlign: TextAlign.center,
                        style: type.bodyFor(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
