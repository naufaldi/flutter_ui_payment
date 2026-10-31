import 'package:flutter/material.dart';
import '../foundation/field_decoration.dart';
import '../foundation/field_trigger.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/primitives.dart';
import '../foundation/search_fold.dart';
import '../controls/controls.dart';
import '../controls/text_field.dart';
import '../interaction/interaction.dart';
import '../overlay/sheets.dart';

/// One option; a disabled reason explains unavailable choices.
@immutable
class PaymentSelectOption<T> {
  const PaymentSelectOption({
    required this.value,
    required this.label,
    this.disabledReason,
  });

  /// Host value.
  final T value;

  /// Visible option name.
  final String label;

  /// Disables the option with an explanation.
  final String? disabledReason;
}

/// Field trigger with a radio sheet, or draft checkboxes and Apply.
class PaymentSelect<T> extends StatefulWidget {
  const PaymentSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.description,
    this.errorText,
    this.validator,
    this.required = false,
    this.hiddenElements = const {},
    this.size = PaymentSize.medium,
    this.focusNode,
  }) : values = const <Never>{},
       _onValues = null,
       _valuesValidator = null,
       _multiple = false;

  /// Stages a set of values in a checkbox sheet and reports on Apply.
  /// onChanged receives the complete selected set; null disables the field.
  factory PaymentSelect.multiple({
    Key? key,
    required String label,
    required List<PaymentSelectOption<T>> options,
    required Set<T> values,
    required ValueChanged<Set<T>>? onChanged,
    String? hint,
    String? description,
    String? errorText,
    FormFieldValidator<Set<T>>? validator,
    bool required = false,
    Set<PaymentFieldPart> hiddenElements = const {},
    PaymentSize size = PaymentSize.medium,
    FocusNode? focusNode,
  }) => PaymentSelect._(
    key: key,
    label: label,
    options: options,
    values: values,
    onValues: onChanged,
    hint: hint,
    description: description,
    errorText: errorText,
    valuesValidator: validator,
    required: required,
    hiddenElements: hiddenElements,
    size: size,
    focusNode: focusNode,
  );
  const PaymentSelect._({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this._onValues,
    this.hint,
    this.description,
    this.errorText,
    this._valuesValidator,
    this.required = false,
    this.hiddenElements = const {},
    this.size = PaymentSize.medium,
    this.focusNode,
  }) : value = null,
       onChanged = null,
       validator = null,
       _multiple = true;

  /// label for this field.
  final String label;

  /// options for this field.
  final List<PaymentSelectOption<T>> options;

  /// value for this field.
  final T? value;

  /// values for this field.
  final Set<T> values;

  /// onChanged for this field.
  final ValueChanged<T>? onChanged;
  final ValueChanged<Set<T>>? _onValues;

  /// validator for this field.
  final FormFieldValidator<T>? validator;
  final FormFieldValidator<Set<T>>? _valuesValidator;
  final bool _multiple;

  /// hint for this field.
  final String? hint;

  /// description for this field.
  final String? description;

  /// errorText for this field.
  final String? errorText;

  /// required for this field.
  final bool required;

  /// hiddenElements for this field.
  final Set<PaymentFieldPart> hiddenElements;

  /// size for this field.
  final PaymentSize size;

  /// focusNode for this field.
  final FocusNode? focusNode;
  @override
  State<PaymentSelect<T>> createState() => _PaymentSelectState<T>();
}

class _PaymentSelectState<T> extends State<PaymentSelect<T>> {
  final _field = GlobalKey<FormFieldState<Object?>>();

  /// FocusNode() for this field.
  final _ownedFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownedFocus;
  @override
  void dispose() {
    _ownedFocus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final result = await showPaymentSheet<Object?>(
      context: context,
      builder: (_) => _SelectSheet<T>(
        label: widget.label,
        options: widget.options,
        value: widget.value,
        values: widget.values,
        multiple: widget._multiple,
      ),
    );
    if (!mounted) return;
    if (widget._multiple && result is Set<T>) {
      widget._onValues?.call(result);
      _field.currentState?.didChange(result);
    } else if (!widget._multiple && result is T) {
      widget.onChanged?.call(result);
      _field.currentState?.didChange(result);
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.options
        .where(
          (o) => widget._multiple
              ? widget.values.contains(o.value)
              : widget.value == o.value,
        )
        .map((o) => o.label)
        .toList();
    final enabled =
        (widget._multiple
            ? widget._onValues != null
            : widget.onChanged != null) &&
        !(FieldGroupScope.of(context)?.disabled ?? false);
    return FormField<Object?>(
      key: _field,
      validator: (_) => widget._multiple
          ? widget._valuesValidator?.call(widget.values)
          : widget.validator?.call(widget.value),
      builder: (state) => FieldTrigger(
        label: widget.label,
        value: labels.isEmpty ? null : joinLabels(labels),
        hint: widget.hint,
        description: widget.description,
        errorText: widget.errorText ?? state.errorText,
        required: widget.required,
        hiddenElements: widget.hiddenElements,
        size: widget.size,
        enabled: enabled,
        focusNode: _focus,
        trailing: const PaymentIcon(
          Icons.expand_more,
          color: PaymentTextColor.secondary,
        ),
        onPressed: _open,
      ),
    );
  }
}

class _SelectSheet<T> extends StatefulWidget {
  const _SelectSheet({
    required this.label,
    required this.options,
    required this.value,
    required this.values,
    required this.multiple,
  });

  /// label for this field.
  final String label;

  /// options for this field.
  final List<PaymentSelectOption<T>> options;

  /// value for this field.
  final T? value;

  /// values for this field.
  final Set<T> values;

  /// multiple for this field.
  final bool multiple;
  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  late final _draft = Set<T>.of(widget.values);
  late final _folded = [for (final o in widget.options) foldForSearch(o.label)];
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    final visible = [
      for (var i = 0; i < widget.options.length; i++)
        if (matchesQuery(_folded[i], _query)) widget.options[i],
    ];
    return PaymentSheet(
      header: PaymentSheetHeader(
        title: widget.label,
        onClose: () => Navigator.pop(context),
      ),
      body: Column(
        spacing: PaymentTheme.of(context).space(PaymentSpace.related),
        children: [
          if (widget.options.length >= 7)
            PaymentTextField.search(
              query: _query,
              label: widget.label,
              onChanged: (v) => setState(() => _query = v),
            ),
          for (final o in visible)
            if (widget.multiple)
              PaymentCheckbox(
                value: _draft.contains(o.value),
                label: o.label,
                disabledReason: o.disabledReason,
                onChanged: o.disabledReason != null
                    ? null
                    : (v) => setState(() {
                        if (v) {
                          _draft.add(o.value);
                        } else {
                          _draft.remove(o.value);
                        }
                      }),
              )
            else
              PaymentRadio<T>(
                value: o.value,
                groupValue: widget.value,
                label: o.label,
                disabledReason: o.disabledReason,
                onChanged: o.disabledReason != null
                    ? null
                    : (v) => Navigator.pop(context, v),
              ),
          if (visible.isEmpty)
            StateMessage(icon: PaymentIcons.noMatches, title: l.noMatchesTitle),
        ],
      ),
      footer: widget.multiple
          ? PaymentButton(
              label: l.apply,
              onPressed: () => Navigator.pop(context, Set<T>.of(_draft)),
            )
          : null,
    );
  }
}
