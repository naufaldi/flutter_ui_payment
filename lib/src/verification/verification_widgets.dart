import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import 'verification_models.dart';

/// Explains what data the host requests and why, then asks for consent.
///
/// Consent always starts unchecked; [onContinue] is unreachable without it.
class VerificationIntro extends StatefulWidget {
  const VerificationIntro({
    super.key,
    required this.requirements,
    required this.onContinue,
    this.onOpenPolicy,
    this.consentLabel,
  });

  final List<DataRequirement> requirements;
  final VoidCallback onContinue;

  /// Opens the host's privacy policy; hidden when null.
  final VoidCallback? onOpenPolicy;
  final String? consentLabel;

  @override
  State<VerificationIntro> createState() => _VerificationIntroState();
}

class _VerificationIntroState extends State<VerificationIntro> {
  bool _consented = false;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final controlShape = RoundedRectangleBorder(
      borderRadius: theme.controlBorderRadius,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final line = PaymentType.firstLineHeight(context);
    final iconSize = scaler.clamp(maxScaleFactor: 1.6).scale(20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentSection(
          title: l10n.kycIntroTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.kycIntroMessage, style: type.bodyFor(context)),
              SizedBox(height: theme.spacing),
              for (final r in widget.requirements)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: theme.spacing),
                  child: MergeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Centered on the title's first line at any scale.
                        SizedBox(
                          width: iconSize,
                          height: line,
                          child: Center(
                            child: Icon(
                              Icons.check_circle_outline,
                              size: iconSize,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: theme.spacing * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: type.heading),
                              Text(r.purpose, style: type.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing * 1.5),
        if (widget.onOpenPolicy != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onOpenPolicy,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                shape: controlShape,
                textStyle: type.heading,
              ),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: Text(l10n.readPrivacyPolicy),
            ),
          ),
        CheckboxListTile(
          value: _consented,
          onChanged: (v) => setState(() => _consented = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          // The unchecked box is a control edge, so it uses the border
          // token rather than the decorative rule.
          side: BorderSide(color: theme.border, width: 2),
          title: Text(
            widget.consentLabel ?? l10n.consentLabel,
            style: type.body,
          ),
        ),
        SizedBox(height: theme.spacing),
        PaymentButton(
          label: l10n.continueLabel,
          onPressed: _consented ? widget.onContinue : null,
        ),
        if (!_consented)
          Padding(
            padding: EdgeInsets.only(top: theme.spacing),
            child: Text(l10n.consentRequiredHint, style: type.caption),
          ),
      ],
    );
  }
}

/// Identity form driven by host [IdentityFieldSpec]s.
///
/// Submit validates every field, shows errors on the relevant fields and
/// moves focus to the first invalid one. Names accept any script.
class IdentityForm extends StatefulWidget {
  const IdentityForm({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.initialValues = const {},
    this.serverErrors = const {},
    this.highlightFields = const {},
    this.submitLabel,
  });

  final List<IdentityFieldSpec> fields;
  final FutureOr<void> Function(Map<String, String> values) onSubmit;
  final Map<String, String> initialValues;

  /// Field errors returned by the host after submission.
  final Map<String, String> serverErrors;

  /// Fields the host asked to correct (actionRequired).
  final Set<String> highlightFields;
  final String? submitLabel;

  @override
  State<IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<IdentityForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: widget.initialValues[f.key] ?? ''),
  };
  late final Map<String, FocusNode> _focus = {
    for (final f in widget.fields) f.key: FocusNode(),
  };
  bool _submitted = false;

  /// Fields edited since the host last reported server errors.
  final Set<String> _editedSinceServerErrors = {};

  @override
  void didUpdateWidget(IdentityForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverErrors != widget.serverErrors) {
      _editedSinceServerErrors.clear();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      for (final f in widget.fields) {
        final error = f.validator?.call(_controllers[f.key]!.text.trim());
        if (error != null) {
          _focus[f.key]!.requestFocus();
          break;
        }
      }
      return;
    }
    await widget.onSubmit({
      for (final f in widget.fields) f.key: _controllers[f.key]!.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, f) in widget.fields.indexed) ...[
              TextFormField(
                controller: _controllers[f.key],
                focusNode: _focus[f.key],
                keyboardType: f.keyboardType,
                inputFormatters: f.inputFormatters,
                textCapitalization: f.textCapitalization,
                autofillHints: f.autofillHints,
                textInputAction: i == widget.fields.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                onFieldSubmitted: (_) {
                  if (i == widget.fields.length - 1) _submit();
                },
                onChanged: (_) {
                  if (widget.serverErrors.containsKey(f.key) &&
                      _editedSinceServerErrors.add(f.key)) {
                    setState(() {});
                  }
                },
                validator: (value) => f.validator?.call((value ?? '').trim()),
                style: type.input,
                forceErrorText: _editedSinceServerErrors.contains(f.key)
                    ? null
                    : widget.serverErrors[f.key],
                decoration: InputDecoration(
                  labelText: f.label,
                  hintText: f.hint,
                  errorMaxLines: 3,
                  helperText: widget.highlightFields.contains(f.key)
                      ? l10n.fieldNeedsUpdate
                      : null,
                  helperStyle: type.caption.copyWith(
                    color: theme.warning.foreground,
                  ),
                  errorStyle: type.caption.copyWith(
                    color: theme.danger.foreground,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: theme.controlBorderRadius,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: theme.controlBorderRadius,
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: theme.controlBorderRadius,
                    borderSide: BorderSide(color: theme.accent, width: 2),
                  ),
                ),
              ),
              SizedBox(height: theme.spacing * 2),
            ],
            PaymentButton(
              label: widget.submitLabel ?? l10n.continueLabel,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// One document slot: limits, picking, upload progress and recoverable errors.
class DocumentUploadTile extends StatelessWidget {
  const DocumentUploadTile({
    super.key,
    required this.requirement,
    required this.state,
    required this.onPick,
    this.onOpenSettings,
    this.needsUpdate = false,
  });

  final DocumentRequirement requirement;
  final DocumentSlotState state;

  /// Host picker/capture. Also used to replace a file mid-upload.
  final VoidCallback? onPick;
  final VoidCallback? onOpenSettings;
  final bool needsUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final file = state.file;
    final issue = state.issue;
    final fileSize = file == null
        ? null
        : Text(
            ' · ${l10n.formatBytes(file.sizeBytes)}',
            style: type.label.copyWith(color: theme.textSecondary),
          );
    final outlined =
        OutlinedButton.styleFrom(
          foregroundColor: theme.accent,
          disabledForegroundColor: theme.disabled,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: theme.controlBorderRadius,
          ),
          textStyle: type.heading,
        ).copyWith(
          // A control edge, so the border token; the disabled token when
          // there is nothing to pick.
          side: WidgetStateBorderSide.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? theme.disabled
                  : theme.border,
            ),
          ),
        );
    final limits = l10n.documentLimits(
      requirement.acceptedTypesLabel ?? requirement.acceptedTypes.join(', '),
      l10n.formatBytes(requirement.maxBytes),
    );
    final (statusLabel, tone, icon) = switch (state.phase) {
      DocumentSlotPhase.empty => (
        l10n.documentEmpty,
        StatusTone.neutral,
        Icons.upload_file,
      ),
      DocumentSlotPhase.uploading => (
        l10n.documentUploading,
        StatusTone.info,
        Icons.cloud_upload_outlined,
      ),
      DocumentSlotPhase.uploaded => (
        l10n.documentUploaded,
        StatusTone.success,
        Icons.check_circle_outline,
      ),
      DocumentSlotPhase.failed => (
        l10n.documentFailed,
        StatusTone.danger,
        Icons.error_outline,
      ),
    };
    return PaymentSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requirement.label, style: type.heading),
                    Text(limits, style: type.caption),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing),
              Flexible(
                child: StatusBadge(tone: tone, icon: icon, label: statusLabel),
              ),
            ],
          ),
          if (needsUpdate && state.phase != DocumentSlotPhase.uploaded) ...[
            SizedBox(height: theme.spacing),
            Text(
              l10n.fieldNeedsUpdate,
              style: type.caption.copyWith(color: theme.warning.foreground),
            ),
          ],
          if (file != null) ...[
            SizedBox(height: theme.spacing),
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: theme.textSecondary,
                ),
                SizedBox(width: theme.spacing),
                Flexible(
                  child: MiddleEllipsisText(
                    file.name,
                    style: type.label,
                    textAlign: TextAlign.start,
                  ),
                ),
                // At large text the size may wrap, so the row never
                // overflows; at normal sizes the name keeps the room.
                if (PaymentType.isLarge(context))
                  Flexible(child: fileSize!)
                else
                  ?fileSize,
              ],
            ),
          ],
          if (state.phase == DocumentSlotPhase.uploading) ...[
            SizedBox(height: theme.spacing),
            Semantics(
              label: l10n.documentUploading,
              value: state.progress == null
                  ? null
                  : '${(state.progress! * 100).round()}%',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: PaymentMotion.of(context).reduced
                      ? (state.progress ?? 0.5)
                      : state.progress,
                  minHeight: 4,
                  color: theme.accent,
                  backgroundColor: theme.surfaceMuted,
                ),
              ),
            ),
          ],
          if (issue != null) ...[
            SizedBox(height: theme.spacing),
            NoticeBanner(
              tone: StatusTone.danger,
              announce: true,
              title: l10n.documentIssueTitle(issue.kind),
              message:
                  issue.safeMessage ??
                  l10n.documentIssueMessage(issue.kind, limits),
            ),
          ],
          SizedBox(height: theme.spacing * 1.5),
          // Controls use the theme's control radius, never the default pill.
          Wrap(
            spacing: theme.spacing,
            runSpacing: theme.spacing,
            children: [
              if (issue?.canOpenSettings == true && onOpenSettings != null)
                OutlinedButton(
                  onPressed: onOpenSettings,
                  style: outlined,
                  child: Text(l10n.openSettings),
                ),
              if (issue == null || issue.canRetry)
                OutlinedButton(
                  onPressed: onPick,
                  style: outlined,
                  child: Text(switch (state.phase) {
                    DocumentSlotPhase.empty => l10n.chooseDocument,
                    DocumentSlotPhase.failed => l10n.tryAgain,
                    _ => l10n.replaceDocument,
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Read-only review before submitting verification.
///
/// Values marked [IdentityFieldSpec.maskInReview] show only the last four
/// characters, keeping identity data to the minimum needed.
class VerificationReview extends StatelessWidget {
  const VerificationReview({
    super.key,
    required this.fields,
    required this.values,
    required this.documents,
    required this.onSubmit,
    this.onEditDetails,
    this.onEditDocuments,
    this.busy = false,
  });

  final List<IdentityFieldSpec> fields;
  final Map<String, String> values;
  final List<(DocumentRequirement, DocumentSlotState)> documents;

  /// Disabled until every document slot is uploaded.
  final Future<void> Function()? onSubmit;
  final VoidCallback? onEditDetails;
  final VoidCallback? onEditDocuments;
  final bool busy;

  static String mask(String value) {
    if (value.length <= 4) return value;
    return '${'•' * (value.length - 4)}${value.substring(value.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final ready = documents.every(
      (d) => d.$2.phase == DocumentSlotPhase.uploaded,
    );
    // Two "Edit" buttons on one screen: the spoken label names the section.
    Widget? editButton(VoidCallback? onTap, String section) => onTap == null
        ? null
        : PaymentFocusRing(
            radius: theme.controlBorderRadius,
            child: PaymentPressScale(
              enabled: !busy,
              child: TextButton(
                onPressed: busy ? null : onTap,
                // No inner padding, so the label's edge lines up with the
                // value column; the 48 dp target is kept.
                style: PaymentFocusRing.withoutFocusFill(
                  TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    alignment: AlignmentDirectional.centerEnd,
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.controlBorderRadius,
                    ),
                    textStyle: type.heading,
                  ),
                ),
                child: Text(
                  l10n.edit,
                  semanticsLabel: '${l10n.edit}: $section',
                ),
              ),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentSection(
          title: l10n.reviewDetailsTitle,
          trailing: editButton(onEditDetails, l10n.reviewDetailsTitle),
          child: Column(
            children: [
              for (final f in fields)
                InfoRow(
                  label: f.label,
                  valueText: f.maskInReview
                      ? mask(values[f.key] ?? '')
                      : (values[f.key] ?? ''),
                ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing * 1.5),
        PaymentSection(
          title: l10n.reviewDocumentsTitle,
          trailing: editButton(onEditDocuments, l10n.reviewDocumentsTitle),
          child: Column(
            children: [
              for (final (req, slot) in documents)
                InfoRow(
                  label: req.label,
                  value: slot.phase == DocumentSlotPhase.uploaded
                      ? MiddleEllipsisText(slot.file!.name, style: type.label)
                      : null,
                  valueText: l10n.documentMissing,
                ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing * 2),
        if (!ready)
          Padding(
            padding: EdgeInsets.only(bottom: theme.spacing),
            child: NoticeBanner(
              tone: StatusTone.warning,
              title: l10n.documentsIncomplete,
            ),
          ),
        PaymentButton(
          label: l10n.submitVerification,
          busy: busy,
          busyLabel: l10n.submitting,
          onPressed: ready ? onSubmit : null,
        ),
      ],
    );
  }
}

/// Explains a verification state and offers only host-allowed actions.
/// There is never a bypass action.
class VerificationStatusView extends StatelessWidget {
  const VerificationStatusView({
    super.key,
    required this.snapshot,
    required this.onAction,
    this.outcomeUnknown = false,
    this.busyAction,
  });

  final VerificationSnapshot snapshot;
  final FutureOr<void> Function(VerificationAction action) onAction;

  /// The last submit timed out: the host may or may not have received it.
  final bool outcomeUnknown;
  final VerificationAction? busyAction;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final (tone, icon) = outcomeUnknown
        ? (StatusTone.warning, Icons.help_outline)
        : switch (snapshot.status) {
            VerificationStatus.notStarted => (
              StatusTone.neutral,
              Icons.badge_outlined,
            ),
            VerificationStatus.inReview => (StatusTone.info, Icons.schedule),
            VerificationStatus.actionRequired => (
              StatusTone.warning,
              Icons.edit_note,
            ),
            VerificationStatus.verified => (
              StatusTone.success,
              Icons.verified_outlined,
            ),
            VerificationStatus.rejected => (
              StatusTone.danger,
              Icons.gpp_bad_outlined,
            ),
            VerificationStatus.expired => (
              StatusTone.warning,
              Icons.event_busy_outlined,
            ),
          };
    final motion = PaymentMotion.of(context);
    final title = outcomeUnknown
        ? l10n.kycUnknownTitle
        : l10n.kycStatusTitle(snapshot.status);
    final message = outcomeUnknown
        ? l10n.kycUnknownMessage
        : (snapshot.safeReason ?? l10n.kycStatusMessage(snapshot.status));
    final actions = outcomeUnknown
        ? const [VerificationAction.checkStatus]
        : VerificationAction.values
              .where(snapshot.allowedActions.contains)
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: motion.enter,
                reverseDuration: motion.exit,
                switchInCurve: PaymentMotion.easeOut,
                transitionBuilder: PaymentMotion.fadeScale,
                layoutBuilder: PaymentMotion.topLayout,
                // As in the payment status view: a hatched band when the
                // submit may not have arrived, solid otherwise.
                child: StatusHeader(
                  key: ValueKey(title),
                  tone: tone,
                  icon: icon,
                  title: title,
                  hatched: outcomeUnknown,
                ),
              ),
              SizedBox(height: theme.spacing * 1.5),
              Text(message, style: type.bodyFor(context)),
              if (snapshot.updatedAt != null && !outcomeUnknown) ...[
                SizedBox(height: theme.spacing),
                Text(
                  l10n.updatedAt(l10n.formatDateTime(snapshot.updatedAt!)),
                  style: type.caption,
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: theme.spacing * 3),
        for (final (i, action) in actions.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: theme.spacing),
            child: PaymentButton(
              label: l10n.verificationActionLabel(action),
              variant: i == 0
                  ? PaymentButtonVariant.primary
                  : PaymentButtonVariant.secondary,
              busy: busyAction == action,
              busyLabel: l10n.checkingStatus,
              onPressed: () => onAction(action),
            ),
          ),
      ],
    );
  }
}
