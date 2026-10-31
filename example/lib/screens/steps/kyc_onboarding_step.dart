import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';
import '../../adapters/fake_host.dart';
import '../capture_screen.dart';
import 'kyc_fields.dart';

class KycOnboardingStep extends StatelessWidget {
  const KycOnboardingStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final review = c.step == FlowStep.kycReview;
    final details = c.step == FlowStep.kycIdentity;
    PaymentTaskStatus slot(String key) => switch (c.documents[key]?.phase) {
      DocumentSlotPhase.uploaded => PaymentTaskStatus.complete,
      DocumentSlotPhase.failed => PaymentTaskStatus.blocked,
      DocumentSlotPhase.uploading => PaymentTaskStatus.inProgress,
      _ => PaymentTaskStatus.notStarted,
    };
    return PaymentOnboardingView(
      title: s.verifyTitle,
      description: s.verifyDescription,
      tasks: [
        PaymentTaskListItem(
          title: s.taskDetails,
          status: !details && c.identity.isNotEmpty
              ? PaymentTaskStatus.complete
              : PaymentTaskStatus.inProgress,
          onPressed: !details && c.identity.isNotEmpty ? c.editIdentity : null,
        ),
        PaymentTaskListItem(
          title: s.taskDocuments,
          status: details
              ? PaymentTaskStatus.notStarted
              : review
              ? PaymentTaskStatus.complete
              : PaymentTaskStatus.inProgress,
          onPressed: review ? c.editDocuments : null,
          subTasks: [
            PaymentTaskListItem(title: s.idCardLabel, status: slot(idCardSlot)),
            PaymentTaskListItem(title: s.selfieLabel, status: slot(selfieSlot)),
          ],
        ),
        PaymentTaskListItem(
          title: s.taskReview,
          status: review
              ? PaymentTaskStatus.inProgress
              : PaymentTaskStatus.notStarted,
        ),
      ],
      error: c.kyc.fieldsToFix.isEmpty
          ? null
          : PaymentBanner(tone: StatusTone.warning, title: s.fixHighlighted),
      child: switch (c.step) {
        FlowStep.kycIdentity => _KycIdentity(c),
        FlowStep.kycDocuments => _KycDocuments(c),
        _ => _KycReview(c),
      },
    );
  }
}

class _KycIdentity extends StatelessWidget {
  const _KycIdentity(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return IdentityForm(
      fields: identityFields(s),
      initialValues: c.identity,
      highlightFields: c.kyc.fieldsToFix,
      onSubmit: c.submitIdentity,
    );
  }
}

class _KycDocuments extends StatelessWidget {
  const _KycDocuments(this.c);
  final DemoCoordinator c;

  Future<void> _pick(BuildContext context, DocumentRequirement req) async {
    final source = await showCaptureSourceSheet(context: context);
    if (source == null || !context.mounted) return;
    if (source != CaptureSource.file) {
      final allowed = await c.requestCapture(req.key);
      if (!allowed || !context.mounted) return;
    }
    if (source == CaptureSource.camera) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KycCaptureScreen(
            c: c,
            requirement: req,
            kind: req.key == selfieSlot
                ? CaptureKind.selfieWithIdCard
                : CaptureKind.idCard,
          ),
        ),
      );
      return;
    }
    final s = DemoStrings.of(context);
    final l10n = PaymentLocalizations.of(context);
    final fixture = await showModalBottomSheet<DocumentFixture>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(s.pickFixture, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(s.fixtureNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final f in demoFixtures)
              ListTile(
                key: Key('fixture-${f.file.name}'),
                minTileHeight: 56,
                leading: Icon(
                  f.file.mimeType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(f.file.name),
                subtitle: Text(
                  '${l10n.formatBytes(f.file.sizeBytes)} · ${s.fixtureTag(f.description)}',
                ),
                onTap: () => Navigator.pop(context, f),
              ),
          ],
        ),
      ),
    );
    if (fixture != null) await c.uploadDocument(req, fixture.file);
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final reqs = documentRequirements(s);
    final ready = reqs.every(
      (r) => c.documents[r.key]?.phase == DocumentSlotPhase.uploaded,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final req in reqs) ...[
          DocumentUploadTile(
            key: Key('slot-${req.key}'),
            requirement: req,
            state: c.documents[req.key]!,
            needsUpdate: c.kyc.fieldsToFix.contains(req.key),
            onPick: () => _pick(context, req),
            onOpenSettings: () => c.openSettings(req.key),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        PaymentButton(
          key: const Key('to-review'),
          label: s.continueToReview,
          onPressed: ready ? c.goToReview : null,
        ),
      ],
    );
  }
}

class _KycReview extends StatelessWidget {
  const _KycReview(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return VerificationReview(
      fields: identityFields(s),
      values: c.identity,
      documents: [
        for (final r in documentRequirements(s)) (r, c.documents[r.key]!),
      ],
      busy: c.kycSubmitting,
      onSubmit: c.submitKyc,
      onEditDetails: c.editIdentity,
      onEditDocuments: c.editDocuments,
    );
  }
}
