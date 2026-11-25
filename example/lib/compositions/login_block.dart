import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// Credentials sent to the host when the form is valid.
@immutable
class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

/// Copyable host composition: email/password login with local validation,
/// show/hide password, host failure, recovery and registration navigation.
///
/// The block never authenticates, stores or transmits credentials. [onSubmit]
/// is the host's authentication boundary; the host also owns recovery and
/// routing through [onForgotPassword] and [onRegister]. [busy] and
/// [errorText] describe the host's current attempt.
class LoginBlock extends StatefulWidget {
  const LoginBlock({
    super.key,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
    this.initialEmail = '',
    this.busy = false,
    this.errorText,
  });

  final Future<void> Function(LoginCredentials credentials) onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final String initialEmail;
  final bool busy;

  /// Safe host message for the failed attempt. Never include the password.
  final String? errorText;

  @override
  State<LoginBlock> createState() => _LoginBlockState();
}

class _LoginBlockState extends State<LoginBlock> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;

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
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email address.';
  }

  String? _validatePassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password.' : null;

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      LoginCredentials(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return PaymentFullPageView(
      title: 'Log in',
      pageLink: PaymentLink(
        label: 'Create account',
        onPressed: widget.busy ? null : widget.onRegister,
      ),
      primaryAction: PaymentButton(
        label: 'Log in',
        busy: widget.busy,
        busyLabel: 'Signing you in',
        onPressed: widget.busy ? null : _submit,
      ),
      secondaryAction: PaymentButton(
        label: 'Forgot password?',
        variant: PaymentButtonVariant.quiet,
        onPressed: widget.busy ? null : widget.onForgotPassword,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(PaymentSpace.group),
          children: [
            if (widget.errorText != null)
              PaymentBanner(
                tone: StatusTone.danger,
                title: 'Couldn’t log you in',
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
              autofillHints: const [AutofillHints.username],
            ),
            LoginPasswordField(
              label: 'Password',
              controller: _password,
              enabled: !widget.busy,
              validator: _validatePassword,
              autofillHint: AutofillHints.password,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Host-owned password input. The kit deliberately has no secret-input mode;
/// a copied block keeps this control in host code.
class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.errorText,
    this.autofillHint = AutofillHints.password,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final String autofillHint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
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
        ],
      ),
    );
  }
}
