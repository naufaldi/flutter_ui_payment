import '../forms/select.dart';
import '../forms/search_field.dart';
import '../forms/field_group.dart';
import '../forms/date_field.dart';
import '../foundation/date_input.dart';
import '../foundation/action_frame.dart';
import '../controls/button_group.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_tokens.dart';
import '../controls/actions.dart';
import '../controls/text_field.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../controls/controls.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import 'verification_models.dart';

/// Explains what data the host requests and why, then asks for consent.
///
/// Consent always starts unchecked; [onContinue] is unreachable without it.
///
/// Given a bounded height, the explanation and consent scroll and Continue
/// pins to a footer at the bottom (D62). Inside a scroll view it follows the
/// consent, as before.
class VerificationIntro extends StatefulWidget {
  const VerificationIntro({
    super.key,
    required this.requirements,
    required this.onContinue,
    this.onOpenPolicy,
    this.consentLabel,
    this.header,
  });

  final List<DataRequirement> requirements;
  final VoidCallback onContinue;

  /// Opens the host's privacy policy; hidden when null.
  final VoidCallback? onOpenPolicy;
  final String? consentLabel;

  /// Host content shown above this widget's content, inside its scroll
  /// region (D62).
  final Widget? header;

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
    final go = PaymentButton(
      label: l10n.continueLabel,
      onPressed: _consented ? widget.onContinue : null,
    );
    final hint = _consented
        ? null
        : Text(l10n.consentRequiredHint, style: type.caption);
    return ActionFrame(
      header: widget.header,
      primaryAction: go,
      note: hint,
      builder: (context, pinned) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentSection(
            title: l10n.kycIntroTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.kycIntroMessage, style: type.bodyFor(context)),
                SizedBox(height: theme.space(PaymentSpace.related)),
                for (final r in widget.requirements)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: theme.space(PaymentSpace.related),
                    ),
                    child: MergeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Centered on the title's first line at any scale.
                          const PaymentIcon(
                            Icons.check_circle_outline,
                            color: PaymentTextColor.secondary,
                          ),
                          SizedBox(width: theme.space(PaymentSpace.block)),
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
          SizedBox(height: theme.space(PaymentSpace.block)),
          if (widget.onOpenPolicy != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PaymentLink(
                label: l10n.readPrivacyPolicy,
                external: true,
                onPressed: widget.onOpenPolicy,
              ),
            ),
          PaymentCheckbox(
            value: _consented,
            onChanged: (v) => setState(() => _consented = v),
            label: widget.consentLabel ?? l10n.consentLabel,
          ),
          if (!pinned) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            go,
            if (hint != null)
              Padding(
                padding: EdgeInsets.only(
                  top: theme.space(PaymentSpace.related),
                ),
                child: hint,
              ),
          ],
        ],
      ),
    );
  }
}

/// Submits an [IdentityForm] from outside it, so a host can pin the submit
/// in a footer, e.g. [PaymentOnboardingView.primaryAction] (D62).
///
/// [submit] runs the same validation as the form's own button: it shows the
/// errors, moves focus to the first invalid field and resolves `false`, or
/// calls [IdentityForm.onSubmit] and resolves `true` once it completes. The
/// host owns the controller and disposes it.
class IdentityFormController extends ChangeNotifier {
  /// Creates a controller with no form attached.
  IdentityFormController();

  _IdentityFormState? _form;
  bool _busy = false;
  bool _disposed = false;

  /// True while [IdentityForm.onSubmit] runs.
  bool get busy => _busy;

  /// A form is attached and no submit is running.
  bool get canSubmit => _form != null && !_busy;

  /// Validates the attached form and submits it when valid. Resolves `false`
  /// when the form is invalid, detached or already submitting.
  Future<bool> submit() async {
    final form = _form;
    if (form == null || _busy) return false;
    _setBusy(true);
    try {
      return await form._submit();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    if (!_disposed) notifyListeners();
  }

  void _attach(_IdentityFormState form) {
    _form = form;
    _notifyAfterFrame();
  }

  void _detach(_IdentityFormState form) {
    if (_form != form) return;
    _form = null;
    _notifyAfterFrame();
  }

  // Attaching happens while the tree builds; a host listener rebuilding
  // then would mark itself dirty mid-build.
  void _notifyAfterFrame() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_disposed) notifyListeners();
  });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Identity form driven by host [IdentityFieldSpec]s.
///
/// Submit validates every field, shows errors on the relevant fields and
/// moves focus to the first invalid one. Names accept any script.
///
/// With a [controller] the form has no submit button of its own: the host
/// places one that calls [IdentityFormController.submit], e.g. pinned in
/// [PaymentOnboardingView.primaryAction] (D62).
class IdentityForm extends StatefulWidget {
  const IdentityForm({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.initialValues = const {},
    this.serverErrors = const {},
    this.highlightFields = const {},
    this.submitLabel,
    this.controller,
  });

  final List<IdentityFieldSpec> fields;
  final FutureOr<void> Function(Map<String, String> values) onSubmit;
  final Map<String, String> initialValues;

  /// Field errors returned by the host after submission.
  final Map<String, String> serverErrors;

  /// Fields the host asked to correct (actionRequired).
  final Set<String> highlightFields;

  /// The inline button's label; unused with a [controller].
  final String? submitLabel;

  /// Submits the form from a host button and hides the inline one.
  final IdentityFormController? controller;

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
  late final Map<String, DateTime?> _dates = {
    for (final f in widget.fields)
      f.key: parseIsoDate(widget.initialValues[f.key] ?? ''),
  };
  late final Map<String, String?> _choices = {
    for (final f in widget.fields)
      f.key: widget.initialValues[f.key]?.isEmpty == true
          ? null
          : widget.initialValues[f.key],
  };
  String _valueOf(IdentityFieldSpec f) => switch (f.kind) {
    IdentityFieldKind.text => _controllers[f.key]!.text.trim(),
    IdentityFieldKind.date =>
      _dates[f.key] == null ? '' : isoDate(_dates[f.key]!),
    IdentityFieldKind.choice ||
    IdentityFieldKind.search => _choices[f.key] ?? '',
  };
  void _markEdited(String key) {
    if (widget.serverErrors.containsKey(key) &&
        _editedSinceServerErrors.add(key)) {
      setState(() {});
    }
  }

  bool _submitted = false;
  final Map<String, String?> _searchErrors = {};

  /// Fields edited since the host last reported server errors.
  final Set<String> _editedSinceServerErrors = {};

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(IdentityForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverErrors != widget.serverErrors) {
      _editedSinceServerErrors.clear();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  bool _submitting = false;

  /// The one submit path for the inline button, the keyboard's done action
  /// and [IdentityFormController.submit].
  Future<bool> _submit() async {
    if (_submitting) return false;
    setState(() => _submitted = true);
    for (final f in widget.fields.where(
      (f) => f.kind == IdentityFieldKind.search,
    )) {
      _searchErrors[f.key] = f.validator?.call(_valueOf(f));
    }
    if (!_formKey.currentState!.validate() ||
        _searchErrors.values.any((e) => e != null)) {
      for (final f in widget.fields) {
        final error = f.validator?.call(_valueOf(f));
        if (error != null) {
          _focus[f.key]!.requestFocus();
          break;
        }
      }
      return false;
    }
    _submitting = true;
    try {
      await widget.onSubmit({
        for (final f in widget.fields) f.key: _valueOf(f),
      });
      return true;
    } finally {
      _submitting = false;
    }
  }

  /// The keyboard's done action goes through the controller when there is
  /// one, so a pinned button shows the same busy state.
  void _requestSubmit() =>
      widget.controller == null ? _submit() : widget.controller!.submit();

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    Widget field(int i, IdentityFieldSpec f) => switch (f.kind) {
      IdentityFieldKind.search => PaymentSearchField<String>(
        label: f.label,
        options: [
          for (final o in f.options)
            PaymentSearchOption(value: o.value, label: o.label),
        ],
        selected: _choices[f.key],
        focusNode: _focus[f.key],
        onSelected: (v) {
          setState(() {
            _choices[f.key] = v;
            if (_submitted) _searchErrors[f.key] = f.validator?.call(v ?? '');
          });
          _markEdited(f.key);
        },
        errorText:
            _searchErrors[f.key] ??
            (_editedSinceServerErrors.contains(f.key)
                ? null
                : widget.serverErrors[f.key]),
        description: widget.highlightFields.contains(f.key)
            ? l10n.fieldNeedsUpdate
            : null,
      ),
      IdentityFieldKind.date => PaymentDateField(
        label: f.label,
        value: _dates[f.key],
        onChanged: (v) {
          setState(() => _dates[f.key] = v);
          _markEdited(f.key);
        },
        firstDate: f.firstDate ?? DateTime(1900),
        lastDate: f.lastDate ?? DateUtils.dateOnly(DateTime.now()),
        focusNode: _focus[f.key],
        textInputAction: i == widget.fields.length - 1
            ? TextInputAction.done
            : TextInputAction.next,
        description: widget.highlightFields.contains(f.key)
            ? l10n.fieldNeedsUpdate
            : null,
        validator: (v) => f.validator?.call(v == null ? '' : isoDate(v)),
        errorText: _editedSinceServerErrors.contains(f.key)
            ? null
            : widget.serverErrors[f.key],
      ),
      IdentityFieldKind.choice => PaymentSelect<String>(
        label: f.label,
        options: f.options,
        value: _choices[f.key],
        onChanged: (v) {
          setState(() => _choices[f.key] = v);
          _markEdited(f.key);
        },
        focusNode: _focus[f.key],
        description: widget.highlightFields.contains(f.key)
            ? l10n.fieldNeedsUpdate
            : null,
        validator: (v) => f.validator?.call(v ?? ''),
        errorText: _editedSinceServerErrors.contains(f.key)
            ? null
            : widget.serverErrors[f.key],
      ),
      IdentityFieldKind.text => PaymentTextField(
        label: f.label,
        hint: f.hint,
        description: widget.highlightFields.contains(f.key)
            ? l10n.fieldNeedsUpdate
            : null,
        descriptionTone: StatusTone.warning,
        controller: _controllers[f.key],
        focusNode: _focus[f.key],
        keyboardType: f.keyboardType,
        inputFormatters: f.inputFormatters,
        textCapitalization: f.textCapitalization,
        autofillHints: f.autofillHints,
        textInputAction: i == widget.fields.length - 1
            ? TextInputAction.done
            : TextInputAction.next,
        onSubmitted: (_) {
          if (i == widget.fields.length - 1) _requestSubmit();
        },
        onChanged: (_) {
          if (widget.serverErrors.containsKey(f.key) &&
              _editedSinceServerErrors.add(f.key)) {
            setState(() {});
          }
        },
        validator: (value) => f.validator?.call((value ?? '').trim()),
        errorText: _editedSinceServerErrors.contains(f.key)
            ? null
            : widget.serverErrors[f.key],
      ),
    };
    final grouped = <Widget>[];
    for (var i = 0; i < widget.fields.length;) {
      final f = widget.fields[i];
      if (f.group == null) {
        grouped.add(field(i, f));
        i++;
      } else {
        final children = <Widget>[];
        final group = f.group!;
        while (i < widget.fields.length && widget.fields[i].group == group) {
          children.add(field(i, widget.fields[i]));
          i++;
        }
        grouped.add(PaymentFormFieldGroup(legend: group, children: children));
      }
      // 24 around a field group and before the action, 16 between fields
      // (D46, #65).
      final next = i < widget.fields.length ? widget.fields[i] : null;
      if (next == null && widget.controller != null) break;
      grouped.add(
        SizedBox(
          height: theme.space(
            f.group == null && next != null && next.group == null
                ? PaymentSpace.group
                : PaymentSpace.section,
          ),
        ),
      );
    }
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...grouped,
            if (widget.controller == null)
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
        Icons.upload_file_outlined,
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
              SizedBox(width: theme.space(PaymentSpace.related)),
              Flexible(
                child: PaymentBadge(tone: tone, icon: icon, label: statusLabel),
              ),
            ],
          ),
          if (needsUpdate && state.phase != DocumentSlotPhase.uploaded) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            Text(
              l10n.fieldNeedsUpdate,
              style: type.caption.copyWith(color: theme.warning.foreground),
            ),
          ],
          if (file != null) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            Row(
              children: [
                const PaymentIcon(
                  Icons.description_outlined,
                  size: PaymentIconSize.medium,
                  color: PaymentTextColor.secondary,
                ),
                SizedBox(width: theme.space(PaymentSpace.related)),
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
            SizedBox(height: theme.space(PaymentSpace.related)),
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
            SizedBox(height: theme.space(PaymentSpace.related)),
            PaymentBanner(
              tone: StatusTone.danger,
              announce: true,
              title: l10n.documentIssueTitle(issue.kind),
              message:
                  issue.safeMessage ??
                  l10n.documentIssueMessage(issue.kind, limits),
            ),
          ],
          SizedBox(height: theme.space(PaymentSpace.block)),
          // Controls use the theme's control radius, never the default pill.
          Wrap(
            spacing: theme.space(PaymentSpace.related),
            runSpacing: theme.space(PaymentSpace.related),
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
///
/// With [inlineSubmit] false the review leaves its submit to the host, which
/// pins [submitButton] in a footer, e.g. [PaymentOnboardingView.primaryAction]
/// (D62).
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
    this.inlineSubmit = true,
  });

  final List<IdentityFieldSpec> fields;
  final Map<String, String> values;
  final List<(DocumentRequirement, DocumentSlotState)> documents;

  /// Disabled until every document slot is uploaded.
  final Future<void> Function()? onSubmit;
  final VoidCallback? onEditDetails;
  final VoidCallback? onEditDocuments;
  final bool busy;

  /// Shows the submit button at the end of the review. False when the host
  /// places [submitButton] itself.
  final bool inlineSubmit;

  /// Whether every document slot is uploaded, so submitting is allowed.
  static bool isReady(
    List<(DocumentRequirement, DocumentSlotState)> documents,
  ) => documents.every((d) => d.$2.phase == DocumentSlotPhase.uploaded);

  /// The review's submit button: disabled until [isReady], busy with the
  /// submitting label. The inline button is this one.
  static PaymentButton submitButton(
    BuildContext context, {
    Key? key,
    required List<(DocumentRequirement, DocumentSlotState)> documents,
    required Future<void> Function()? onSubmit,
    bool busy = false,
  }) {
    final l10n = PaymentLocalizations.of(context);
    return PaymentButton(
      key: key,
      label: l10n.submitVerification,
      busy: busy,
      busyLabel: l10n.submitting,
      onPressed: isReady(documents) ? onSubmit : null,
    );
  }

  static String mask(String value) {
    if (value.length <= 4) return value;
    return '${'•' * (value.length - 4)}${value.substring(value.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final ready = isReady(documents);
    // Two "Edit" buttons on one screen: the spoken label names the section.
    Widget? editButton(VoidCallback? onTap, String section) => onTap == null
        ? null
        : PaymentLink(
            label: l10n.edit,
            semanticLabel: '${l10n.edit}: $section',
            onPressed: busy ? null : onTap,
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
                      : switch (f.kind) {
                          IdentityFieldKind.text => values[f.key] ?? '',
                          IdentityFieldKind.date =>
                            parseIsoDate(values[f.key] ?? '') == null
                                ? values[f.key] ?? ''
                                : l10n.formatDate(
                                    parseIsoDate(values[f.key]!)!,
                                  ),
                          IdentityFieldKind.choice ||
                          IdentityFieldKind.search =>
                            f.options
                                    .where((o) => o.value == values[f.key])
                                    .firstOrNull
                                    ?.label ??
                                values[f.key] ??
                                '',
                        },
                ),
            ],
          ),
        ),
        SizedBox(height: theme.space(PaymentSpace.block)),
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
        if (!ready || inlineSubmit)
          SizedBox(height: theme.space(PaymentSpace.group)),
        if (!ready)
          Padding(
            padding: EdgeInsets.only(
              bottom: inlineSubmit ? theme.space(PaymentSpace.related) : 0,
            ),
            child: PaymentBanner(
              tone: StatusTone.warning,
              title: l10n.documentsIncomplete,
            ),
          ),
        if (inlineSubmit)
          submitButton(
            context,
            documents: documents,
            onSubmit: onSubmit,
            busy: busy,
          ),
      ],
    );
  }
}

/// Explains a verification state and offers only host-allowed actions.
/// There is never a bypass action.
///
/// Given a bounded height, the status scrolls and the first action pins to a
/// footer at the bottom; the others stay in the content as hug buttons (D62).
/// Inside a scroll view all actions follow the status, as before.
class VerificationStatusView extends StatelessWidget {
  const VerificationStatusView({
    super.key,
    required this.snapshot,
    required this.onAction,
    this.outcomeUnknown = false,
    this.busyAction,
    this.header,
  });

  final VerificationSnapshot snapshot;
  final FutureOr<void> Function(VerificationAction action) onAction;

  /// The last submit timed out: the host may or may not have received it.
  final bool outcomeUnknown;
  final VerificationAction? busyAction;

  /// Host content shown above this widget's content, inside its scroll
  /// region (D62), e.g. a banner.
  final Widget? header;

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
    PaymentButton button(int i, VerificationAction action) => PaymentButton(
      label: l10n.verificationActionLabel(action),
      variant: i == 0
          ? PaymentButtonVariant.primary
          : PaymentButtonVariant.secondary,
      busy: busyAction == action,
      busyLabel: l10n.checkingStatus,
      onPressed: () => onAction(action),
    );
    return ActionFrame(
      header: header,
      primaryAction: actions.isEmpty ? null : button(0, actions.first),
      builder: (context, pinned) => Column(
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
                SizedBox(height: theme.space(PaymentSpace.block)),
                Text(message, style: type.bodyFor(context)),
                if (snapshot.updatedAt != null && !outcomeUnknown) ...[
                  SizedBox(height: theme.space(PaymentSpace.related)),
                  Text(
                    l10n.updatedAt(l10n.formatDateTime(snapshot.updatedAt!)),
                    style: type.caption,
                  ),
                ],
              ],
            ),
          ),
          if (!pinned) ...[
            SizedBox(height: theme.space(PaymentSpace.section)),
            for (final (i, action) in actions.indexed)
              Padding(
                padding: EdgeInsets.only(
                  bottom: theme.space(PaymentSpace.related),
                ),
                child: button(i, action),
              ),
          ] else if (actions.length > 1) ...[
            SizedBox(height: theme.space(PaymentSpace.group)),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PaymentButtonGroup(
                collapse: PaymentButtonGroupCollapse.none,
                children: [
                  for (final (i, action) in actions.indexed.skip(1))
                    button(i, action),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
