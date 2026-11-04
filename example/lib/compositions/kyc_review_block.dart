import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

enum KycReviewStep { status, document, review }

/// Copyable host presentation. Document upload state and verification verdict
/// are separate inputs: replacing/uploading a document never verifies identity.
class KycReviewBlock extends StatelessWidget {
  const KycReviewBlock({
    super.key,
    required this.step,
    required this.snapshot,
    required this.requirement,
    required this.document,
    required this.fields,
    required this.values,
    required this.onAction,
    required this.onPick,
    required this.onReview,
    required this.onSubmit,
    this.busy = false,
    this.error,
  });
  final KycReviewStep step;
  final VerificationSnapshot snapshot;
  final DocumentRequirement requirement;
  final DocumentSlotState document;
  final List<IdentityFieldSpec> fields;
  final Map<String, String> values;
  final FutureOr<void> Function(VerificationAction) onAction;
  final VoidCallback onPick;
  final VoidCallback onReview;
  final Future<void> Function() onSubmit;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final documents = [(requirement, document)];
    if (step == KycReviewStep.status) {
      return VerificationStatusView(
        snapshot: snapshot,
        onAction: onAction,
        busyAction: busy ? VerificationAction.checkStatus : null,
      );
    }
    final correcting = step == KycReviewStep.document;
    return PaymentFullPageView(
      title: correcting ? 'Perbaiki dokumen' : 'Tinjau perbaikan',
      primaryAction: correcting
          ? PaymentButton(
              label: 'Lanjutkan tinjauan',
              onPressed: document.phase == DocumentSlotPhase.uploaded && !busy
                  ? onReview
                  : null,
            )
          : VerificationReview.submitButton(
              context,
              documents: documents,
              onSubmit: onSubmit,
              busy: busy,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          if (error != null)
            PaymentBanner(
              tone: StatusTone.danger,
              title: 'Perbaikan belum terkirim',
              message: error,
              icon: Icons.cloud_off_outlined,
            ),
          if (correcting) ...[
            Text(
              snapshot.safeReason ?? 'Perbarui dokumen yang diminta.',
              style: type.bodyFor(context),
            ),
            DocumentUploadTile(
              requirement: requirement,
              state: document,
              needsUpdate: document.phase != DocumentSlotPhase.uploaded,
              onPick: busy ? null : onPick,
            ),
          ] else
            VerificationReview(
              fields: fields,
              values: values,
              documents: documents,
              inlineSubmit: false,
              busy: busy,
              onSubmit: onSubmit,
              onEditDocuments: busy
                  ? null
                  : () => onAction(VerificationAction.fixDetails),
            ),
          Text(
            'Dokumen terunggah belum berarti identitas terverifikasi.',
            style: type.caption,
          ),
        ],
      ),
    );
  }
}
