import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

enum KycOnboardingStep { consent, details, review, saved }

/// Copyable host composition: informed consent, identity details and a
/// review before the host saves them.
///
/// The consent box starts unchecked and Continue stays disabled until the
/// person checks it. Field rules belong to the host: [fields] carry their own
/// validators and [serverErrors] carries the host's answer after a save
/// attempt, while the form keeps what the person typed. Masked fields show
/// only their last four characters in review. Saving details never verifies
/// identity; the document photos come next. The block collects no PIN, OTP,
/// password or document bytes.
class KycOnboardingBlock extends StatelessWidget {
  const KycOnboardingBlock({
    super.key,
    required this.step,
    required this.requirements,
    required this.fields,
    required this.values,
    required this.formController,
    required this.onConsent,
    required this.onOpenPolicy,
    required this.onDetails,
    required this.onEditDetails,
    required this.onSave,
    this.serverErrors = const {},
    this.saving = false,
    this.saveError,
    this.savedAction,
  });

  final KycOnboardingStep step;

  /// What the host collects and why, shown before consent.
  final List<DataRequirement> requirements;
  final List<IdentityFieldSpec> fields;

  /// The person's details as last submitted from the form.
  final Map<String, String> values;
  final IdentityFormController formController;

  /// The person checked consent and continued; the host records it.
  final VoidCallback onConsent;
  final VoidCallback onOpenPolicy;

  /// The form passed the host rules on this device. The host may still
  /// answer with [serverErrors].
  final FutureOr<void> Function(Map<String, String> values) onDetails;
  final VoidCallback onEditDetails;
  final Future<void> Function() onSave;

  /// Host field errors, keyed by field; the form shows them on its fields.
  final Map<String, String> serverErrors;
  final bool saving;
  final String? saveError;

  /// Quiet follow-up on the saved step, for example returning to the app.
  final PaymentButton? savedAction;

  List<PaymentTaskListItem> get _tasks {
    PaymentTaskStatus at(int index) {
      final current = step.index;
      if (index < current) return PaymentTaskStatus.complete;
      if (index == current) return PaymentTaskStatus.inProgress;
      return PaymentTaskStatus.notStarted;
    }

    return [
      PaymentTaskListItem(title: 'Persetujuan', status: at(0)),
      PaymentTaskListItem(title: 'Data diri', status: at(1)),
      PaymentTaskListItem(title: 'Tinjau data', status: at(2)),
      // Photos belong to the capture block; saving details never finishes
      // verification.
      const PaymentTaskListItem(
        title: 'Foto identitas',
        status: PaymentTaskStatus.notStarted,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final type = PaymentType.of(context);
    return switch (step) {
      KycOnboardingStep.consent => VerificationIntro(
        requirements: requirements,
        onContinue: onConsent,
        onOpenPolicy: () {
          onOpenPolicy();
        },
        consentLabel:
            'Saya setuju data di atas diproses untuk verifikasi identitas.',
      ),
      KycOnboardingStep.details => ListenableBuilder(
        // The controller reports when the form is submitting.
        listenable: formController,
        builder: (context, form) => PaymentOnboardingView(
          title: 'Data diri',
          description: 'Isi sesuai KTP. Kami memeriksanya sebelum disimpan.',
          tasks: _tasks,
          primaryAction: PaymentButton(
            label: 'Lanjutkan',
            busy: formController.busy,
            busyLabel: 'Memeriksa data…',
            onPressed: formController.submit,
          ),
          // The step swap clips to its bounds, and a filled first field
          // floats its label above its box; keep that label inside.
          child: Padding(
            padding: EdgeInsets.only(
              top: PaymentTheme.of(context).space(PaymentSpace.related),
            ),
            child: form!,
          ),
        ),
        // The form keeps its state across host answers, so edits survive.
        child: IdentityForm(
          fields: fields,
          initialValues: values,
          serverErrors: serverErrors,
          controller: formController,
          onSubmit: onDetails,
        ),
      ),
      KycOnboardingStep.review => PaymentOnboardingView(
        title: 'Tinjau data',
        tasks: _tasks,
        error: saveError == null
            ? null
            : PaymentBanner(
                tone: StatusTone.danger,
                icon: Icons.cloud_off_outlined,
                title: 'Data belum tersimpan',
                message: saveError,
              ),
        primaryAction: PaymentButton(
          label: 'Simpan data',
          busy: saving,
          busyLabel: 'Menyimpan…',
          onPressed: onSave,
        ),
        child: _DetailsReview(
          fields: fields,
          values: values,
          onEdit: saving ? null : onEditDetails,
        ),
      ),
      KycOnboardingStep.saved => PaymentOnboardingView(
        title: 'Data diri tersimpan',
        tasks: _tasks,
        secondaryAction: savedAction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PaymentBanner(
              tone: StatusTone.neutral,
              icon: Icons.info_outline,
              title: 'Identitas belum terverifikasi',
              message:
                  'Langkah berikutnya: foto KTP dan swafoto. Verifikasi '
                  'dimulai setelah semua dokumen terkirim.',
            ),
            SizedBox(
              height: PaymentTheme.of(context).space(PaymentSpace.related),
            ),
            Text(
              'Anda dapat mengubah data ini sebelum mengirim verifikasi.',
              style: type.caption,
            ),
          ],
        ),
      ),
    };
  }
}

class _DetailsReview extends StatelessWidget {
  const _DetailsReview({
    required this.fields,
    required this.values,
    required this.onEdit,
  });
  final List<IdentityFieldSpec> fields;
  final Map<String, String> values;
  final VoidCallback? onEdit;

  String _display(BuildContext context, IdentityFieldSpec field) {
    final value = values[field.key] ?? '';
    if (field.maskInReview) return VerificationReview.mask(value);
    return switch (field.kind) {
      IdentityFieldKind.date => switch (DateTime.tryParse(value)) {
        final date? => PaymentLocalizations.of(context).formatDate(date),
        null => value,
      },
      IdentityFieldKind.choice || IdentityFieldKind.search =>
        field.options.where((o) => o.value == value).firstOrNull?.label ??
            value,
      IdentityFieldKind.text => value,
    };
  }

  @override
  Widget build(BuildContext context) => PaymentSection(
    title: 'Data diri',
    trailing: onEdit == null
        ? null
        : PaymentLink(
            label: 'Ubah',
            semanticLabel: 'Ubah data diri',
            onPressed: onEdit,
          ),
    child: PaymentPropertyList(
      items: [
        for (final field in fields)
          PaymentPropertyListItem(
            label: field.label,
            valueText: _display(context, field),
          ),
      ],
    ),
  );
}
