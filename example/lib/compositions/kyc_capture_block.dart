import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Copyable host composition: take an ID photo, recover from permission,
/// quality and upload problems, then send it for review.
///
/// The host owns the camera, picker, permission prompts, settings and upload.
/// [slot] is the upload state of the photo on screen, and the host keeps it
/// keyed by request id: when the person retakes during an upload, the older
/// upload's answer must not replace the new photo's state. A finished upload
/// is not a verdict. Only the host's verification status says whether the
/// identity is verified.
class KycCaptureBlock extends StatelessWidget {
  const KycCaptureBlock({
    super.key,
    required this.requirement,
    required this.slot,
    required this.onCapture,
    required this.onRetake,
    required this.onUsePhoto,
    required this.onOpenSettings,
    required this.onSubmit,
    this.photo,
    this.preview,
    this.submitting = false,
  });

  final DocumentRequirement requirement;

  /// Upload state for the photo on screen; empty before the person uses it.
  final DocumentSlotState slot;

  /// The host's synthetic or real photo; null while framing.
  final ImageProvider? photo;

  /// Live camera preview from the host, shown while framing.
  final Widget? preview;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  /// Starts or retries the upload of the photo on screen.
  final VoidCallback onUsePhoto;
  final VoidCallback onOpenSettings;

  /// Sends the uploaded document for verification.
  final Future<void> Function() onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    if (slot.phase != DocumentSlotPhase.uploaded) {
      return KycCaptureGuide(
        kind: CaptureKind.idCard,
        aspectRatio: 1.25,
        requirement: requirement,
        state: slot,
        photo: photo,
        preview: preview,
        // Block bodies: a host sheet or camera Future must not keep the
        // button busy behind the sheet it opened.
        onCapture: () {
          onCapture();
        },
        onRetake: onRetake,
        onUsePhoto: onUsePhoto,
        onOpenSettings: () {
          onOpenSettings();
        },
      );
    }
    return PaymentFullPageView(
      title: 'Foto KTP terunggah',
      primaryAction: PaymentButton(
        label: 'Kirim untuk verifikasi',
        busy: submitting,
        busyLabel: 'Mengirim…',
        onPressed: onSubmit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          DocumentUploadTile(
            requirement: requirement,
            state: slot,
            onPick: submitting ? null : onRetake,
          ),
          Text(
            'Unggahan selesai belum berarti identitas terverifikasi. '
            'Kami memeriksanya setelah Anda mengirim.',
            style: type.caption,
          ),
        ],
      ),
    );
  }
}
