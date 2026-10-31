import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../adapters/synthetic_capture.dart';
import '../coordinator/demo_coordinator.dart';

class KycCaptureScreen extends StatefulWidget {
  const KycCaptureScreen({
    super.key,
    required this.c,
    required this.requirement,
    required this.kind,
  });
  final DemoCoordinator c;
  final DocumentRequirement requirement;
  final CaptureKind kind;
  @override
  State<KycCaptureScreen> createState() => _KycCaptureScreenState();
}

class _KycCaptureScreenState extends State<KycCaptureScreen> {
  ImageProvider? photo;
  String? requestId;
  int capture = 0;
  bool rendering = false;
  int generation = 0;
  Future<void> take() async {
    if (rendering) return;
    rendering = true;
    final token = ++generation;
    final image = await renderSyntheticPhoto(
      widget.kind,
      blurry: widget.c.config.rejectFirstCapture && capture++ == 0,
    );
    if (!mounted || token != generation) return;
    setState(() {
      photo = image;
      rendering = false;
      requestId = null;
    });
  }

  Future<void> use() async {
    final operation = widget.c.uploadCapture(widget.requirement, widget.kind);
    final uploadId = widget.c.documents[widget.requirement.key]?.requestId;
    setState(() => requestId = uploadId);
    await operation;
    if (!mounted || uploadId == null || requestId != uploadId) return;
    final slot = widget.c.documents[widget.requirement.key];
    if (slot?.requestId == uploadId &&
        slot?.phase == DocumentSlotPhase.uploaded) {
      Navigator.pop(context);
    }
  }

  void retake() => setState(() {
    generation++;
    photo = null;
    requestId = null;
    rendering = false;
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(PaymentLocalizations.of(context).captureTitle(widget.kind)),
    ),
    body: ListenableBuilder(
      listenable: widget.c,
      builder: (context, _) {
        final slot = widget.c.documents[widget.requirement.key];
        final state = requestId != null && slot?.requestId == requestId
            ? slot!
            : const DocumentSlotState.empty();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: KycCaptureGuide(
            kind: widget.kind,
            requirement: widget.requirement,
            state: state,
            photo: photo,
            preview: SyntheticCameraPreview(kind: widget.kind),
            onCapture: take,
            onRetake: retake,
            onUsePhoto: use,
            onOpenSettings: () => widget.c.openSettings(widget.requirement.key),
          ),
        );
      },
    ),
  );
}
