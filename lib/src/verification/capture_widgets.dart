import 'package:flutter/material.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../interaction/interaction.dart';
import '../overlay/sheets.dart';
import 'capture_geometry.dart';
import 'capture_models.dart';
import 'verification_models.dart';

/// Reports intent only. Host checks permission after source selection.
/// Rows always appear camera, gallery, file. Skip this sheet for one source.
Future<CaptureSource?> showCaptureSourceSheet({
  required BuildContext context,
  Set<CaptureSource> sources = const {
    CaptureSource.camera,
    CaptureSource.gallery,
    CaptureSource.file,
  },
  Map<CaptureSource, String> unavailable = const {},
  String? title,
  VoidCallback? onOpenSettings,
}) {
  assert(sources.isNotEmpty);
  final l10n = PaymentLocalizations.of(context);
  return showPaymentSheet<CaptureSource>(
    context: context,
    builder: (context) => PaymentSheet(
      header: PaymentSheetHeader(
        title: title ?? l10n.captureSourceTitle,
        onClose: () => Navigator.pop(context),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final source in CaptureSource.values)
            if (sources.contains(source))
              ActionTile(
                title: switch (source) {
                  CaptureSource.camera => l10n.captureSourceCamera,
                  CaptureSource.gallery => l10n.captureSourceGallery,
                  CaptureSource.file => l10n.captureSourceFile,
                },
                icon: switch (source) {
                  CaptureSource.camera => Icons.photo_camera_outlined,
                  CaptureSource.gallery => Icons.photo_library_outlined,
                  CaptureSource.file => Icons.folder_open_outlined,
                },
                disabledReason: unavailable[source],
                onTap: unavailable.containsKey(source)
                    ? null
                    : () => Navigator.pop(context, source),
              ),
        ],
      ),
      footer: onOpenSettings == null
          ? null
          : PaymentButton(
              label: l10n.openSettings,
              variant: PaymentButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(context);
                onOpenSettings();
              },
            ),
    ),
  );
}

/// Passive framing over a host preview. Never responds to image content.
class CaptureFrameOverlay extends StatelessWidget {
  const CaptureFrameOverlay({
    super.key,
    required this.kind,
    this.overPreview = true,
  });
  final CaptureKind kind;
  final bool overPreview;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      label: PaymentLocalizations.of(context).captureFrameLabel(kind),
      child: CustomPaint(
        painter: _CapturePainter(kind, overPreview, PaymentTheme.of(context)),
        size: Size.infinite,
      ),
    ),
  );
}

class _CapturePainter extends CustomPainter {
  _CapturePainter(this.kind, this.overPreview, this.theme);
  final CaptureKind kind;
  final bool overPreview;
  final PaymentTheme theme;
  @override
  void paint(Canvas canvas, Size size) {
    final frames = captureFrameRects(kind, size);
    final radius = Radius.circular(frames.card.width * 3.18 / 85.6);
    final card = RRect.fromRectAndRadius(frames.card, radius);
    final cutouts = Path()..addRRect(card);
    if (frames.face != null) cutouts.addOval(frames.face!);
    if (overPreview) {
      final scrim = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addPath(cutouts, Offset.zero);
      canvas.drawPath(scrim, Paint()..color = Colors.black54);
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = theme.surfaceMuted);
      canvas.drawRRect(card, Paint()..color = theme.surface);
      if (frames.face != null) {
        canvas.drawOval(
          frames.face!.deflate(frames.face!.width * .15),
          Paint()..color = theme.outline,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: frames.card.center,
            width: size.width * .7,
            height: size.height * .18,
          ),
          Paint()..color = theme.outline,
        );
        canvas.drawRRect(card, Paint()..color = theme.surface);
      }
      final r = frames.card;
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            r.left + r.width * .08,
            r.top + r.height * (.25 + i * .14),
            r.width * .48,
            r.height * .045,
          ),
          Paint()..color = theme.border,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(
          r.left + r.width * .7,
          r.top + r.height * .2,
          r.width * .22,
          r.height * .55,
        ),
        Paint()..color = theme.outline,
      );
    }
    final outline = Paint()
      ..color = overPreview ? Colors.white : theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(card, outline);
    if (frames.face != null) canvas.drawOval(frames.face!, outline);
    final bracket = frames.card.width * .07;
    for (final corner in [
      frames.card.topLeft,
      frames.card.topRight,
      frames.card.bottomLeft,
      frames.card.bottomRight,
    ]) {
      final dx = corner.dx == frames.card.left ? 1 : -1;
      final dy = corner.dy == frames.card.top ? 1 : -1;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy * bracket)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx * bracket, corner.dy),
        outline,
      );
    }
  }

  @override
  bool shouldRepaint(_CapturePainter oldDelegate) =>
      kind != oldDelegate.kind ||
      overPreview != oldDelegate.overPreview ||
      theme != oldDelegate.theme;
}

/// Framing, host photo review and upload state. Host owns all verdicts.
class KycCaptureGuide extends StatelessWidget {
  const KycCaptureGuide({
    super.key,
    required this.kind,
    this.state = const DocumentSlotState.empty(),
    this.photo,
    this.preview,
    this.requirement,
    this.tips,
    this.needsUpdate = false,
    this.updateReason,
    this.onCapture,
    this.onRetake,
    this.onUsePhoto,
    this.onOpenSettings,
    this.aspectRatio = 3 / 4,
  });
  final CaptureKind kind;
  final DocumentSlotState state;
  final ImageProvider? photo;
  final Widget? preview;
  final DocumentRequirement? requirement;
  final List<String>? tips;
  final bool needsUpdate;
  final String? updateReason;
  final VoidCallback? onCapture;
  final VoidCallback? onRetake;
  final VoidCallback? onUsePhoto;
  final VoidCallback? onOpenSettings;
  final double aspectRatio;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final issue = state.issue;
    final framing =
        photo == null &&
        (state.phase == DocumentSlotPhase.empty ||
            issue?.kind == DocumentIssueKind.permissionDenied ||
            issue?.kind == DocumentIssueKind.permissionPermanentlyDenied);
    final review = photo != null && state.phase == DocumentSlotPhase.empty;
    final retryUpload = issue?.kind == DocumentIssueKind.uploadInterrupted;
    final limits = requirement == null
        ? ''
        : l10n.documentLimits(
            requirement!.acceptedTypesLabel ??
                requirement!.acceptedTypes.join(', '),
            l10n.formatBytes(requirement!.maxBytes),
          );
    final guidance =
        tips ??
        [
          l10n.captureTipLight,
          if (kind == CaptureKind.selfieWithIdCard) l10n.captureTipFaceAndCard,
          l10n.captureTipGlare,
          l10n.captureTipCorners,
          if (kind == CaptureKind.idCard) l10n.captureTipNoCover,
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: theme.controlBorderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image(
                    image: photo!,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.capturePhotoLabel(kind),
                  )
                else
                  ?preview,
                if (photo == null)
                  CaptureFrameOverlay(kind: kind, overPreview: preview != null),
              ],
            ),
          ),
        ),
        SizedBox(height: theme.spacing),
        if (state.phase != DocumentSlotPhase.empty)
          StatusBadge(
            icon: Icons.cloud_outlined,
            label: switch (state.phase) {
              DocumentSlotPhase.uploading => l10n.documentUploading,
              DocumentSlotPhase.uploaded => l10n.documentUploaded,
              _ => l10n.documentFailed,
            },
            tone: switch (state.phase) {
              DocumentSlotPhase.uploading => StatusTone.info,
              DocumentSlotPhase.uploaded => StatusTone.success,
              _ => StatusTone.danger,
            },
          ),
        if (state.phase == DocumentSlotPhase.uploading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacing),
            child: LinearProgressIndicator(
              value: state.progress,
              color: theme.accent,
              backgroundColor: theme.surfaceMuted,
            ),
          ),
        if (needsUpdate)
          NoticeBanner(
            tone: StatusTone.warning,
            title: l10n.fieldNeedsUpdate,
            message: updateReason ?? l10n.fieldNeedsUpdate,
          ),
        if (issue != null)
          NoticeBanner(
            tone: StatusTone.danger,
            announce: true,
            title: l10n.documentIssueTitle(issue.kind),
            message:
                issue.safeMessage ??
                l10n.documentIssueMessage(issue.kind, limits),
          ),
        SizedBox(height: theme.spacing),
        Text(
          l10n.captureFramingHint(kind),
          style: PaymentType.of(context).heading,
        ),
        for (final tip in guidance)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tip, style: PaymentType.of(context).label),
                ),
              ],
            ),
          ),
        SizedBox(height: theme.spacing),
        Wrap(
          spacing: theme.spacing,
          runSpacing: theme.spacing,
          children: [
            if (framing && (issue == null || issue.canRetry))
              PaymentButton(label: l10n.captureTake, onPressed: onCapture),
            if (review || retryUpload)
              PaymentButton(
                label: retryUpload ? l10n.tryAgain : l10n.captureUse,
                onPressed: onUsePhoto,
              ),
            if (!framing && (issue == null || issue.canRetry))
              PaymentButton(
                label: l10n.captureRetake,
                onPressed: onRetake,
                variant: review || retryUpload
                    ? PaymentButtonVariant.secondary
                    : PaymentButtonVariant.primary,
              ),
            if (issue?.canOpenSettings == true && onOpenSettings != null)
              PaymentButton(
                label: l10n.openSettings,
                onPressed: onOpenSettings,
                variant: PaymentButtonVariant.secondary,
              ),
          ],
        ),
      ],
    );
  }
}
