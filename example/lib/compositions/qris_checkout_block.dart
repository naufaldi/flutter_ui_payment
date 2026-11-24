import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Host-issued QRIS instructions tied to one payment attempt. The image must
/// include the QR quiet zone and keep its original light background.
typedef QrisCode = ({
  String attemptId,
  String payee,
  ImageProvider image,
  DateTime expiresAt,
});

/// Copyable host composition. It never issues a code, submits a payment or
/// changes the business status. Only the host can reconcile the attempt.
class QrisCheckoutBlock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final snapshot = attempt.snapshot;
    final qr = code;
    final showInstructions =
        qr != null &&
        qr.attemptId == attempt.attemptId &&
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
              allowedActions: {
                if (snapshot.allowedActions.contains(PaymentAction.checkStatus))
                  PaymentAction.checkStatus,
              },
            ),
          )
        : attempt;

    return PaymentStatusView(
      attempt: statusAttempt,
      amount: showInstructions ? null : amount,
      header: showInstructions
          ? _QrisInstructions(
              key: ValueKey((qr.attemptId, qr.expiresAt)),
              code: qr,
              amount: amount,
              clock: clock,
            )
          : null,
      onAction: (action) async {
        if (action == PaymentAction.checkStatus) {
          await onCheckStatus(attempt.attemptId);
        }
      },
    );
  }
}

class _QrisInstructions extends StatefulWidget {
  const _QrisInstructions({
    super.key,
    required this.code,
    required this.amount,
    required this.clock,
  });

  final QrisCode code;
  final Money amount;
  final DateTime Function() clock;

  @override
  State<_QrisInstructions> createState() => _QrisInstructionsState();
}

class _QrisInstructionsState extends State<_QrisInstructions> {
  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    final elapsed = !widget.clock().isBefore(code.expiresAt);
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
            child: AmountText(
              widget.amount,
              variant: AmountTextVariant.display,
            ),
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
                  clock: widget.clock,
                  onElapsed: () => setState(() {}),
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
