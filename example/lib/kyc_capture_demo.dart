import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'adapters/synthetic_capture.dart';
import 'block_demo_shell.dart';
import 'compositions/kyc_capture_block.dart';

void main() => runBlockDemo(const KycCaptureDemo());

enum KycCaptureScenario { normal, permissionDenied, blurry, interrupted }

const kycCaptureRequirement = DocumentRequirement(
  key: 'idCard',
  label: 'Foto KTP',
  acceptedTypes: {'image/jpeg'},
  acceptedTypesLabel: 'JPG',
  maxBytes: 5 * 1024 * 1024,
);

/// Metadata only: the demo photo is drawn on the device and never leaves it.
const kycCaptureFile = DocumentFile(
  name: 'ktp_contoh.jpg',
  mimeType: 'image/jpeg',
  sizeBytes: 412000,
);

/// The host's upload answer for one request: null when stored.
typedef KycUpload = Future<DocumentIssue?> Function(String requestId);

/// Synthetic capture host. The camera is a drawn specimen, permission and
/// upload answers are declared fixtures, and settings never open. Nothing
/// leaves the device and nothing is verified.
class KycCaptureDemo extends StatefulWidget {
  const KycCaptureDemo({
    super.key,
    this.initialScenario = KycCaptureScenario.normal,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 700),
    this.takePhoto,
    this.upload,
  });
  final KycCaptureScenario initialScenario;
  final bool initialDark;
  final Duration delay;

  /// Test hooks standing in for the camera and the upload service.
  final Future<ImageProvider> Function()? takePhoto;
  final KycUpload? upload;

  @override
  State<KycCaptureDemo> createState() => _KycCaptureDemoState();
}

class _KycCaptureDemoState extends State<KycCaptureDemo> {
  late bool dark = widget.initialDark;
  late KycCaptureScenario scenario = widget.initialScenario;
  ImageProvider? photo;
  DocumentSlotState slot = const DocumentSlotState.empty();
  bool cameraAllowed = false;
  bool submitting = false;
  VerificationSnapshot? verification;
  int uploads = 0;
  int captures = 0;
  int generation = 0;

  void reset(KycCaptureScenario value) => setState(() {
    generation++;
    scenario = value;
    photo = null;
    slot = const DocumentSlotState.empty();
    cameraAllowed = false;
    submitting = false;
    verification = null;
    uploads = 0;
    captures = 0;
  });

  Future<void> capture(BuildContext context) async {
    if (scenario == KycCaptureScenario.permissionDenied && !cameraAllowed) {
      setState(() {
        slot = const DocumentSlotState.failed(
          DocumentIssue(
            DocumentIssueKind.permissionDenied,
            safeMessage:
                'Izinkan kamera agar Anda dapat memotret KTP, atau pilih foto '
                'dari galeri.',
            canOpenSettings: true,
          ),
        );
      });
      return;
    }
    final current = generation;
    final source = await showCaptureSourceSheet(
      context: context,
      sources: const {CaptureSource.camera, CaptureSource.gallery},
    );
    if (source == null || !mounted || current != generation) return;
    final image = await (widget.takePhoto ?? _drawPhoto)();
    if (!mounted || current != generation) return;
    setState(() {
      photo = image;
      slot = const DocumentSlotState.empty();
    });
  }

  Future<ImageProvider> _drawPhoto() => renderSyntheticPhoto(
    CaptureKind.idCard,
    // The blurry scenario draws its first photo out of focus, so the host's
    // quality answer matches what the person sees.
    blurry: scenario == KycCaptureScenario.blurry && captures++ == 0,
  );

  Future<DocumentIssue?> _upload(String requestId) async {
    final first = uploads == 1;
    await Future<void>.delayed(widget.delay);
    return switch (scenario) {
      KycCaptureScenario.blurry when first => const DocumentIssue(
        DocumentIssueKind.rejectedByHost,
        safeMessage:
            'Foto buram sehingga teks KTP tidak terbaca. Foto ulang di tempat '
            'terang.',
      ),
      KycCaptureScenario.interrupted when first => const DocumentIssue(
        DocumentIssueKind.uploadInterrupted,
        safeMessage: 'Koneksi terputus. Foto Anda masih di sini.',
      ),
      _ => null,
    };
  }

  Future<void> usePhoto() async {
    if (photo == null || slot.phase == DocumentSlotPhase.uploading) return;
    final requestId = 'UPLOAD-DEMO-${++uploads}';
    setState(() {
      slot = DocumentSlotState.uploading(kycCaptureFile, requestId: requestId);
    });
    final issue = await (widget.upload ?? _upload)(requestId);
    // An answer for an earlier photo or session never replaces the current
    // photo's state.
    if (!mounted || slot.requestId != requestId) return;
    setState(() {
      slot = issue == null
          ? DocumentSlotState.uploaded(kycCaptureFile, requestId: requestId)
          : DocumentSlotState.failed(
              issue,
              file: kycCaptureFile,
              requestId: requestId,
            );
    });
  }

  void retake() => setState(() {
    photo = null;
    slot = const DocumentSlotState.empty();
  });

  void openSettings(BuildContext context) => showPaymentSheet<void>(
    context: context,
    builder: (sheet) => PaymentSheet(
      header: PaymentSheetHeader(
        title: 'Pengaturan kamera · Demo',
        onClose: () => Navigator.pop(sheet),
      ),
      body: const Text(
        'Demo ini tidak membuka pengaturan perangkat. Aplikasi Anda membuka '
        'pengaturan izin, lalu memeriksa izin lagi saat Anda kembali.',
      ),
      footer: PaymentButton(
        label: 'Simulasikan izin kamera',
        variant: PaymentButtonVariant.secondary,
        onPressed: () {
          // Declared synthetic answer: the person allowed the camera.
          setState(() {
            cameraAllowed = true;
            slot = const DocumentSlotState.empty();
          });
          Navigator.pop(sheet);
        },
      ),
    ),
  );

  Future<void> submit() async {
    if (submitting) return;
    final current = generation;
    setState(() => submitting = true);
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      submitting = false;
      // The host's verification answer, separate from the upload.
      verification = VerificationSnapshot(
        status: VerificationStatus.inReview,
        requestId: 'KYC-DEMO-221',
        updatedAt: DateTime(2026, 11, 4, 10, 30),
        allowedActions: const {VerificationAction.checkStatus},
      );
    });
  }

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Foto KTP · Demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    scenarios: [
      for (final (value, label) in [
        (KycCaptureScenario.normal, 'Foto diterima'),
        (KycCaptureScenario.permissionDenied, 'Izin kamera ditolak'),
        (KycCaptureScenario.blurry, 'Foto buram'),
        (KycCaptureScenario.interrupted, 'Unggahan terputus'),
      ])
        (label: label, onSelected: () => reset(value)),
    ],
    body: (context) => verification != null
        ? VerificationStatusView(
            key: ValueKey('status-$generation'),
            snapshot: verification!,
            // Checking again returns the same in-review answer in this demo.
            onAction: (_) {},
          )
        : KycCaptureBlock(
            key: ValueKey(generation),
            requirement: kycCaptureRequirement,
            slot: slot,
            photo: photo,
            preview: const SyntheticCameraPreview(kind: CaptureKind.idCard),
            submitting: submitting,
            onCapture: () => capture(context),
            onRetake: retake,
            onUsePhoto: usePhoto,
            onOpenSettings: () => openSettings(context),
            onSubmit: submit,
          ),
  );
}
