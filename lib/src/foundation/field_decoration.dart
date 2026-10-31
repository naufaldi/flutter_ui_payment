import 'package:flutter/material.dart';
import 'payment_theme.dart';
import 'payment_type.dart';
import 'payment_tokens.dart';
import 'payment_icons.dart';
import 'token_resolvers.dart';

/// Internal shared subtext: optional tone icon and words.
class FieldMessage extends StatelessWidget {
  const FieldMessage(this.text, {super.key, this.tone, this.hidden = false});
  final String text;
  final StatusTone? tone;
  final bool hidden;
  @override
  Widget build(BuildContext context) {
    if (hidden) return Semantics(label: text, child: const SizedBox.shrink());
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final color = tone == null
        ? theme.textSecondary
        : theme.tone(tone!).foreground;
    final label = Text(text, style: type.caption.copyWith(color: color));
    if (tone == null) return label;
    final size = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.6).scale(14);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: size,
          height:
              MediaQuery.textScalerOf(context).scale(type.caption.fontSize!) *
              type.caption.height!,
          child: Center(
            child: Icon(
              tone == StatusTone.danger ? PaymentIcons.danger : toneIcon(tone!),
              size: size,
              color: color,
            ),
          ),
        ),
        SizedBox(width: theme.spacing * .5),
        Expanded(child: label),
      ],
    );
  }
}

InputDecoration paymentFieldDecoration(
  BuildContext context, {
  required String label,
  bool hideLabel = false,
  String? hint,
  Widget? helper,
  EdgeInsetsGeometry? contentPadding,
  String? prefixText,
  TextStyle? prefixStyle,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool enabled = true,
}) {
  final theme = PaymentTheme.of(context);
  final type = PaymentType.of(context);
  OutlineInputBorder edge(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: theme.controlBorderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: hideLabel ? null : label,
    hintText: hint,
    labelStyle: type.label.copyWith(
      color: enabled ? theme.textSecondary : theme.disabled,
    ),
    hintStyle: type.input.copyWith(color: theme.textSecondary),
    helper: helper,
    contentPadding: contentPadding,
    prefixText: prefixText,
    prefixStyle: prefixStyle,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    helperMaxLines: 4,
    errorMaxLines: 3,
    border: edge(theme.border),
    enabledBorder: edge(theme.border),
    focusedBorder: edge(theme.accent, 2),
    errorBorder: edge(theme.danger.foreground),
    focusedErrorBorder: edge(theme.danger.foreground, 2),
    disabledBorder: edge(theme.disabled),
  );
}

EdgeInsetsGeometry? fieldContentPadding(PaymentTheme theme, PaymentSize size) =>
    switch (size) {
      PaymentSize.small => EdgeInsetsDirectional.fromSTEB(
        theme.spacing * 1.5,
        theme.spacing * 2,
        theme.spacing * 1.5,
        theme.spacing,
      ),
      PaymentSize.medium => null,
      PaymentSize.large => EdgeInsetsDirectional.fromSTEB(
        theme.spacing * 1.5,
        theme.spacing * 3,
        theme.spacing * 1.5,
        theme.spacing * 2,
      ),
    };
