part of 'gallery_screen.dart';

class _CaptureSourceDemo extends StatefulWidget {
  const _CaptureSourceDemo();
  @override
  State<_CaptureSourceDemo> createState() => _CaptureSourceDemoState();
}

class _CaptureSourceDemoState extends State<_CaptureSourceDemo> {
  String state = 'all';
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'showCaptureSourceSheet',
    states: _StatePicker(
      values: const ['all', 'camera+file', 'camera-blocked'],
      selected: state,
      onSelected: (value) => setState(() => state = value),
      label: (value) => value,
    ),
    child: PaymentButton(
      label: PaymentLocalizations.of(context).captureSourceTitle,
      onPressed: () async {
        final result = await showCaptureSourceSheet(
          context: context,
          sources: state == 'camera+file'
              ? {CaptureSource.camera, CaptureSource.file}
              : CaptureSource.values.toSet(),
          unavailable: state == 'camera-blocked'
              ? {
                  CaptureSource.camera: _t(
                    context,
                    'Camera access is off',
                    'Akses kamera dinonaktifkan',
                  ),
                }
              : {},
          onOpenSettings: () => _galleryFeedback(
            context,
            'Host: open settings',
            'Host: buka pengaturan',
          ),
        );
        if (context.mounted) {
          _galleryFeedback(
            context,
            'Host: ${result?.name ?? 'dismissed'}',
            'Host: ${result?.name ?? 'ditutup'}',
          );
        }
      },
    ),
  );
}

class _CaptureGuideDemo extends StatefulWidget {
  const _CaptureGuideDemo();
  @override
  State<_CaptureGuideDemo> createState() => _CaptureGuideDemoState();
}

class _CaptureGuideDemoState extends State<_CaptureGuideDemo> {
  String state = 'ktp';
  ImageProvider? photo;
  int generation = 0;
  Future<void> select(String value) async {
    final token = ++generation;
    setState(() {
      state = value;
      photo = null;
    });
    if (['review', 'uploading', 'uploaded', 'rejected'].contains(value)) {
      final image = await renderSyntheticPhoto(
        CaptureKind.idCard,
        blurry: value == 'rejected',
      );
      if (mounted && token == generation) setState(() => photo = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    const file = DocumentFile(
      name: 'kamera_ktp_demo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1048576,
    );
    final slot = switch (state) {
      'uploading' => const DocumentSlotState.uploading(
        file,
        requestId: 'demo',
        progress: .45,
      ),
      'uploaded' => const DocumentSlotState.uploaded(file, requestId: 'demo'),
      'rejected' => const DocumentSlotState.failed(
        DocumentIssue(
          DocumentIssueKind.rejectedByHost,
          safeMessage: 'Foto KTP buram. Ambil ulang di tempat yang terang.',
        ),
      ),
      'permission' => const DocumentSlotState.failed(
        DocumentIssue(
          DocumentIssueKind.permissionPermanentlyDenied,
          canRetry: false,
          canOpenSettings: true,
        ),
      ),
      _ => const DocumentSlotState.empty(),
    };
    void feedback() =>
        _galleryFeedback(context, 'Host action requested', 'Aksi host diminta');
    return _Entry(
      name: 'KycCaptureGuide',
      states: _StatePicker(
        values: const [
          'ktp',
          'selfie',
          'preview',
          'review',
          'uploading',
          'uploaded',
          'rejected',
          'permission',
          'needsUpdate',
        ],
        selected: state,
        onSelected: select,
        label: (value) => value,
      ),
      child: KycCaptureGuide(
        kind: state == 'selfie'
            ? CaptureKind.selfieWithIdCard
            : CaptureKind.idCard,
        state: slot,
        photo: photo,
        preview: state == 'preview'
            ? const SyntheticCameraPreview(kind: CaptureKind.idCard)
            : null,
        needsUpdate: state == 'needsUpdate',
        onCapture: feedback,
        onRetake: feedback,
        onUsePhoto: feedback,
        onOpenSettings: feedback,
      ),
    );
  }
}
