import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Details sent to the host when the registration form is valid.
@immutable
class RegisterSubmission {
  const RegisterSubmission({required this.email, required this.password});

  final String email;
  final String password;
}

/// Registration steps chosen by the host.
enum RegisterBlockStep {
  /// Email and password details.
  details,

  /// Host-required email verification before the account can continue.
  verification,
}

/// Copyable host composition: email/password registration, policy help,
/// validation, host failure and an optional host-owned verification step.
///
/// The block never creates an account, stores secrets, sends email or verifies
/// a code. [onSubmit], [onVerify] and [onResendVerification] are host
/// boundaries; [onLogin], [onPolicy] and [step] are host-owned navigation and
/// state. [busy] and [errorText] describe the current host attempt.
class RegisterBlock extends StatefulWidget {
  const RegisterBlock({
    super.key,
    required this.onSubmit,
    required this.onVerify,
    required this.onResendVerification,
    required this.onLogin,
    required this.onPolicy,
    this.step = RegisterBlockStep.details,
    this.initialEmail = '',
    this.verificationEmail,
    this.busy = false,
    this.errorText,
  });

  final Future<void> Function(RegisterSubmission submission) onSubmit;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResendVerification;
  final VoidCallback onLogin;
  final VoidCallback onPolicy;
  final RegisterBlockStep step;
  final String initialEmail;

  /// Address the host says received the code.
  final String? verificationEmail;
  final bool busy;

  /// Safe host message for the current failed step.
  final String? errorText;

  @override
  State<RegisterBlock> createState() => _RegisterBlockState();
}

class _RegisterBlockState extends State<RegisterBlock> {
  final _detailsKey = GlobalKey<FormState>();
  final _verificationKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email address.';
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Use at least one letter and one number.';
    }
    return null;
  }

  String? _validateCode(String? value) =>
      RegExp(r'^\d{6}$').hasMatch(value ?? '')
      ? null
      : 'Enter the 6-digit code.';

  void _submitDetails() {
    FocusScope.of(context).unfocus();
    if (!(_detailsKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      RegisterSubmission(email: _email.text.trim(), password: _password.text),
    );
  }

  void _submitCode() {
    FocusScope.of(context).unfocus();
    if (!(_verificationKey.currentState?.validate() ?? false)) return;
    widget.onVerify(_code.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final verification = widget.step == RegisterBlockStep.verification;
    final email = widget.verificationEmail ?? _email.text.trim();
    return PaymentFullPageView(
      title: verification ? 'Verify your email' : 'Create account',
      pageLink: PaymentLink(
        label: 'Log in',
        onPressed: widget.busy ? null : widget.onLogin,
      ),
      primaryAction: verification
          ? PaymentButton(
              label: 'Verify email',
              busy: widget.busy,
              busyLabel: 'Verifying your email',
              onPressed: widget.busy ? null : _submitCode,
            )
          : PaymentButton(
              label: 'Create account',
              busy: widget.busy,
              busyLabel: 'Creating your account',
              onPressed: widget.busy ? null : _submitDetails,
            ),
      secondaryAction: verification
          ? PaymentButton(
              label: 'Resend code',
              variant: PaymentButtonVariant.quiet,
              onPressed: widget.busy ? null : widget.onResendVerification,
            )
          : null,
      child: verification
          ? Form(
              key: _verificationKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(PaymentSpace.group),
                children: [
                  if (widget.errorText != null)
                    PaymentBanner(
                      tone: StatusTone.danger,
                      title: 'Couldn’t verify your email',
                      message: widget.errorText,
                      announce: true,
                    ),
                  Text(
                    'Enter the 6-digit code the host sent to $email.',
                    style: type.body.copyWith(color: theme.textPrimary),
                  ),
                  PaymentTextField(
                    label: 'Verification code',
                    controller: _code,
                    type: PaymentTextFieldType.number,
                    required: true,
                    enabled: !widget.busy,
                    validator: _validateCode,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitCode(),
                    autofillHints: const [AutofillHints.oneTimeCode],
                  ),
                ],
              ),
            )
          : Form(
              key: _detailsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(PaymentSpace.group),
                children: [
                  if (widget.errorText != null)
                    PaymentBanner(
                      tone: StatusTone.danger,
                      title: 'Couldn’t create your account',
                      message: widget.errorText,
                      announce: true,
                    ),
                  PaymentTextField(
                    label: 'Email address',
                    controller: _email,
                    type: PaymentTextFieldType.email,
                    required: true,
                    enabled: !widget.busy,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  RegisterPasswordField(
                    label: 'Password',
                    controller: _password,
                    enabled: !widget.busy,
                    validator: _validatePassword,
                    description:
                        'Use at least 8 characters with a letter and a number.',
                    autofillHint: AutofillHints.newPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitDetails(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(PaymentSpace.inline),
                    children: [
                      Text(
                        'By continuing, you agree to the host’s terms and privacy policy. The host owns the policy, consent record and account decision.',
                        style: type.caption.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                      PaymentLink(
                        label: 'Read terms and privacy policy',
                        variant: PaymentLinkVariant.secondary,
                        onPressed: widget.busy ? null : widget.onPolicy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

/// Host-owned password input. The kit deliberately has no secret-input mode;
/// a copied block keeps this control in host code.
class RegisterPasswordField extends StatefulWidget {
  const RegisterPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.errorText,
    this.description,
    this.autofillHint = AutofillHints.newPassword,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final String? description;
  final String autofillHint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<RegisterPasswordField> createState() => _RegisterPasswordFieldState();
}

class _RegisterPasswordFieldState extends State<RegisterPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final labelAbove = PaymentType.isLarge(context);
    final border = OutlineInputBorder(
      borderRadius: theme.controlBorderRadius,
      borderSide: BorderSide(color: theme.border),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: theme.controlBorderRadius,
      borderSide: BorderSide(color: theme.danger.foreground),
    );
    return Semantics(
      label: labelAbove ? widget.label : null,
      isRequired: true,
      validationResult: widget.errorText == null
          ? SemanticsValidationResult.none
          : SemanticsValidationResult.invalid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.inline),
        children: [
          if (labelAbove)
            ExcludeSemantics(
              child: Text(
                widget.label,
                style: type.label.copyWith(
                  color: widget.enabled ? theme.textSecondary : theme.disabled,
                ),
              ),
            ),
          TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            obscureText: _obscured,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: [widget.autofillHint],
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            forceErrorText: widget.errorText,
            style: type.input.copyWith(
              color: widget.enabled ? theme.textPrimary : theme.disabled,
            ),
            decoration: InputDecoration(
              labelText: labelAbove ? null : widget.label,
              labelStyle: type.label.copyWith(
                color: widget.enabled ? theme.textSecondary : theme.disabled,
              ),
              filled: true,
              fillColor: theme.surface,
              contentPadding: labelAbove
                  ? EdgeInsetsDirectional.symmetric(
                      horizontal: theme.space(PaymentSpace.group) - 4,
                      vertical: theme.space(PaymentSpace.group),
                    )
                  : EdgeInsetsDirectional.fromSTEB(
                      theme.space(PaymentSpace.group) - 4,
                      theme.space(PaymentSpace.group) +
                          theme.space(PaymentSpace.inline),
                      theme.space(PaymentSpace.group) - 4,
                      theme.space(PaymentSpace.block),
                    ),
              enabledBorder: border,
              disabledBorder: border.copyWith(
                borderSide: BorderSide(color: theme.outline),
              ),
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: theme.accent, width: 2),
              ),
              errorBorder: errorBorder,
              focusedErrorBorder: errorBorder.copyWith(
                borderSide: BorderSide(
                  color: theme.danger.foreground,
                  width: 2,
                ),
              ),
              errorStyle: type.caption.copyWith(color: theme.danger.foreground),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: PaymentIconButton(
                icon: _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: widget.enabled
                    ? () => setState(() => _obscured = !_obscured)
                    : null,
              ),
            ),
          ),
          if (widget.description != null)
            Text(
              widget.description!,
              style: type.caption.copyWith(color: theme.textSecondary),
            ),
        ],
      ),
    );
  }
}
