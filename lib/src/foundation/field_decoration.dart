import 'payment_localizations.dart';
import 'kit_strings.dart';
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
        SizedBox(width: theme.space(PaymentSpace.inline)),
        Expanded(child: label),
      ],
    );
  }
}

/// Whether fields show their label above the box instead of floating it in
/// the border. Above 1.5× text a floating label keeps one line and
/// ellipsizes ("Date of birth (opt…"), hiding what the field is for, so it
/// moves above the box and wraps there (#73).
bool fieldLabelAbove(BuildContext context) => PaymentType.isLarge(context);

/// Internal: a field's label on its own lines above the box, used when
/// [fieldLabelAbove] is true. The label is visual only: the field keeps
/// its accessible name. [onTap] lets a text field take focus from it.
class FieldLabelAbove extends StatelessWidget {
  const FieldLabelAbove({
    super.key,
    required this.label,
    required this.enabled,
    required this.child,
    this.onTap,
  });
  final String label;
  final bool enabled;
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(PaymentSpace.inline),
      children: [
        ExcludeSemantics(
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Text(
              label,
              style: type.label.copyWith(
                color: enabled ? theme.textSecondary : theme.disabled,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// [labelAbove] drops the floating label; the caller shows it with
/// [FieldLabelAbove] instead.
InputDecoration paymentFieldDecoration(
  BuildContext context, {
  required String label,
  bool hideLabel = false,
  bool labelAbove = false,
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
    labelText: hideLabel || labelAbove ? null : label,
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

/// Horizontal gap an [OutlineInputBorder] adds inside the content padding
/// (its default `gapPadding`).
const _outlineGap = 4.0;

/// Content padding for every field size, so text, currency, date and select
/// fields share one text edge and one height per size: 48, 56 and 64 dp
/// with a 24 dp input line (#47).
///
/// The text starts `group` (16) in from the border: the outline adds its
/// 4 dp gap to the 12 given here. The top padding is 4 more than the
/// bottom, which the floating label takes back, so the text sits centred.
/// With the label above the box ([labelAbove]) nothing takes it back, so
/// the padding is even and the box keeps its height (#73).
EdgeInsetsGeometry fieldContentPadding(
  PaymentTheme theme,
  PaymentSize size, {
  bool labelAbove = false,
}) {
  final inset = theme.space(PaymentSpace.group) - _outlineGap;
  if (labelAbove) {
    final vertical = switch (size) {
      PaymentSize.small => theme.space(PaymentSpace.block),
      PaymentSize.medium => theme.space(PaymentSpace.group),
      PaymentSize.large =>
        theme.space(PaymentSpace.group) + theme.space(PaymentSpace.inline),
    };
    return EdgeInsetsDirectional.symmetric(
      horizontal: inset,
      vertical: vertical,
    );
  }
  return switch (size) {
    PaymentSize.small => EdgeInsetsDirectional.fromSTEB(
      inset,
      theme.space(PaymentSpace.group),
      inset,
      theme.space(PaymentSpace.related),
    ),
    PaymentSize.medium => EdgeInsetsDirectional.fromSTEB(
      inset,
      theme.space(PaymentSpace.group) + theme.space(PaymentSpace.inline),
      inset,
      theme.space(PaymentSpace.block),
    ),
    PaymentSize.large => EdgeInsetsDirectional.fromSTEB(
      inset,
      theme.space(PaymentSpace.section),
      inset,
      theme.space(PaymentSpace.group),
    ),
  };
}

class FieldGroupScope extends InheritedWidget {
  const FieldGroupScope({
    super.key,
    required this.disabled,
    required this.markOptional,
    required super.child,
  });
  final bool disabled;
  final bool markOptional;
  static FieldGroupScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FieldGroupScope>();
  @override
  bool updateShouldNotify(FieldGroupScope old) =>
      disabled != old.disabled || markOptional != old.markOptional;
}

String fieldLabel(
  BuildContext context,
  String label, {
  required bool required,
}) => FieldGroupScope.of(context)?.markOptional == true && !required
    ? '$label (${PaymentLocalizations.of(context).optional})'
    : label;
