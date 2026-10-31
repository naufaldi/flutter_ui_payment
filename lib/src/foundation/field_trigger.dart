import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'field_decoration.dart';
import 'payment_theme.dart';
import 'payment_tokens.dart';
import 'payment_type.dart';

String joinLabels(List<String> labels) => labels.length <= 2
    ? labels.join(', ')
    : '${labels.take(2).join(', ')} +${labels.length - 2}';

class FieldTrigger extends StatefulWidget {
  const FieldTrigger({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.description,
    this.errorText,
    this.hiddenElements = const {},
    this.size = PaymentSize.medium,
    this.enabled = true,
    this.required = false,
    required this.trailing,
    this.onPressed,
    this.focusNode,
  });
  final String label;
  final String? value;
  final String? hint;
  final String? description;
  final String? errorText;
  final Set<PaymentFieldPart> hiddenElements;
  final PaymentSize size;
  final bool enabled;
  final bool required;
  final Widget trailing;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  @override
  State<FieldTrigger> createState() => _FieldTriggerState();
}

class _FieldTriggerState extends State<FieldTrigger> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final label = fieldLabel(context, widget.label, required: widget.required);
    return Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      label: label,
      value: widget.value ?? '',
      hint: [widget.errorText, widget.description].nonNulls.join('. '),
      isRequired: widget.required ? true : null,
      validationResult: widget.errorText != null
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      onTap: widget.enabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: InkWell(
        focusNode: widget.focusNode,
        canRequestFocus: widget.enabled,
        onTap: widget.enabled ? widget.onPressed : null,
        onFocusChange: (v) => setState(() => focused = v),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: t.controlBorderRadius,
        child: InputDecorator(
          isFocused: focused,
          isEmpty: widget.value == null,
          decoration:
              paymentFieldDecoration(
                context,
                label: label,
                hideLabel: widget.hiddenElements.contains(
                  PaymentFieldPart.label,
                ),
                hint: widget.hint,
                enabled: widget.enabled,
                contentPadding: fieldContentPadding(t, widget.size),
                suffixIcon: widget.trailing,
                helper: widget.description == null
                    ? null
                    : FieldMessage(
                        widget.description!,
                        hidden: widget.hiddenElements.contains(
                          PaymentFieldPart.description,
                        ),
                      ),
              ).copyWith(
                error: widget.errorText == null
                    ? null
                    : FieldMessage(
                        widget.errorText!,
                        tone: StatusTone.danger,
                        hidden: widget.hiddenElements.contains(
                          PaymentFieldPart.error,
                        ),
                      ),
              ),
          child: Text(
            widget.value ?? '',
            style: PaymentType.of(context).input.copyWith(
              color: widget.enabled ? t.textPrimary : t.disabled,
            ),
          ),
        ),
      ),
    );
  }
}
