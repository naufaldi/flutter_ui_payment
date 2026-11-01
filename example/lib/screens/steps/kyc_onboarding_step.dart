import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';
import '../../adapters/fake_host.dart';
import '../capture_screen.dart';
import 'kyc_fields.dart';

class KycOnboardingStep extends StatefulWidget {
  const KycOnboardingStep(this.c, {super.key});
  final DemoCoordinator c;

  @override
  State<KycOnboardingStep> createState() => _KycOnboardingStepState();
}

class _KycOnboardingStepState extends State<KycOnboardingStep> {
  // Submits the identity form from the pinned footer (D62).
  final _identity = IdentityFormController();

  @override
  void initState() {
    super.initState();
    // The pinned button shows the form's busy state, including a submit
    // started from the keyboard's done action.
    _identity.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = DemoStrings.of(context);
    final l10n = PaymentLocalizations.of(context);
    final reqs = documentRequirements(s);
    final documents = [for (final r in reqs) (r, c.documents[r.key]!)];
    final review = c.step == FlowStep.kycReview;
    final details = c.step == FlowStep.kycIdentity;
    PaymentTaskStatus slot(String key) => switch (c.documents[key]?.phase) {
      DocumentSlotPhase.uploaded => PaymentTaskStatus.complete,
      DocumentSlotPhase.failed => PaymentTaskStatus.blocked,
      DocumentSlotPhase.uploading => PaymentTaskStatus.inProgress,
      _ => PaymentTaskStatus.notStarted,
    };
    // Each step's submit pins at the bottom of the view (D62).
    final action = switch (c.step) {
      FlowStep.kycIdentity => PaymentButton(
        key: const Key('identity-continue'),
        label: l10n.continueLabel,
        busy: _identity.busy,
        onPressed: _identity.submit,
      ),
      FlowStep.kycDocuments => PaymentButton(
        key: const Key('to-review'),
        label: s.continueToReview,
        onPressed: VerificationReview.isReady(documents) ? c.goToReview : null,
      ),
      _ => VerificationReview.submitButton(
        context,
        key: const Key('submit-kyc'),
        documents: documents,
        onSubmit: c.submitKyc,
        busy: c.kycSubmitting,
      ),
    };
    return PaymentOnboardingView(
      primaryAction: action,
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
        FlowStep.kycIdentity => _KycIdentity(c, controller: _identity),
        FlowStep.kycDocuments => _KycDocuments(c),
        _ => _KycReview(c),
      },
    );
  }
}

class _KycIdentity extends StatelessWidget {
  const _KycIdentity(this.c, {required this.controller});
  final DemoCoordinator c;
  final IdentityFormController controller;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return IdentityForm(
      fields: identityFields(s),
      initialValues: c.identity,
      highlightFields: c.kyc.fieldsToFix,
      onSubmit: c.submitIdentity,
      controller: controller,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final req in documentRequirements(s))
          DocumentUploadTile(
            key: Key('slot-${req.key}'),
            requirement: req,
            state: c.documents[req.key]!,
            needsUpdate: c.kyc.fieldsToFix.contains(req.key),
            onPick: () => _pick(context, req),
            onOpenSettings: () => c.openSettings(req.key),
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
      inlineSubmit: false,
      onEditDetails: c.editIdentity,
      onEditDocuments: c.editDocuments,
    );
  }
}
