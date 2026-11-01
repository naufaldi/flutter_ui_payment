import '../foundation/payment_icons.dart';
import '../controls/actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../foundation/field_decoration.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';

/// Input traits; sensitive input belongs to the host.
enum PaymentTextFieldType {
  /// Free text.
  text,

  /// Numeric quantity.
  number,

  /// Telephone number.
  tel,

  /// Web address.
  url,

  /// Email address.
  email,

  /// Local list filter.
  search,
}

/// Labeled single-line input integrated with Form validation.
class PaymentTextField extends StatefulWidget {
  /// Creates a field. The host owns validation timing.
  const PaymentTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hint,
    this.description,
    this.descriptionTone = StatusTone.neutral,
    this.errorText,
    this.validator,
    this.required = false,
    this.hiddenElements = const {},
    this.type = PaymentTextFieldType.text,
    this.size = PaymentSize.medium,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.inputFormatters = const [],
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.autofillHints,
    this.enabled = true,
    this.readOnly = false,
    this.reference = false,
    this.prefixText,
    this.prefixIcon,
    this.suffix,
  }) : _multiline = false,
       _minLines = 1,
       _maxLines = 1,
       _maxLength = null,
       query = null,
       assert(controller == null || initialValue == null);

  const PaymentTextField._area({
    required this.label,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hint,
    this.description,
    this.errorText,
    this.validator,
    this.required = false,
    this.hiddenElements = const {},
    this.size = PaymentSize.medium,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    required this._minLines,
    required this._maxLines,
    this._maxLength,
  }) : descriptionTone = StatusTone.neutral,
       type = PaymentTextFieldType.text,
       textInputAction = null,
       inputFormatters = const [],
       textCapitalization = TextCapitalization.none,
       keyboardType = null,
       autofillHints = null,
       reference = false,
       prefixText = null,
       prefixIcon = null,
       suffix = null,
       _multiline = true,
       query = null,
       assert(controller == null || initialValue == null);

  /// Controlled local list filter, with clear and refocus.
  factory PaymentTextField.search({
    Key? key,
    required String query,
    required ValueChanged<String> onChanged,
    String? label,
  }) => PaymentTextField._search(
    key: key,
    query: query,
    onChanged: onChanged,
    label: label ?? '',
  );
  const PaymentTextField._search({
    super.key,
    required this.query,
    required this.onChanged,
    required this.label,
  }) : _multiline = false,
       _minLines = 1,
       _maxLines = 1,
       _maxLength = null,
       controller = null,
       initialValue = null,
       focusNode = null,
       hint = null,
       description = null,
       descriptionTone = StatusTone.neutral,
       errorText = null,
       validator = null,
       required = false,
       hiddenElements = const {},
       type = PaymentTextFieldType.search,
       size = PaymentSize.medium,
       onSubmitted = null,
       textInputAction = TextInputAction.search,
       inputFormatters = const [],
       textCapitalization = TextCapitalization.none,
       keyboardType = null,
       autofillHints = null,
       enabled = true,
       readOnly = false,
       reference = false,
       prefixText = null,
       prefixIcon = null,
       suffix = null;

  final bool _multiline;
  final int _minLines;
  final int? _maxLines;
  final int? _maxLength;

  /// Always visible; floats above the value, or sits above the box and
  /// wraps when text is scaled above 1.5×.
  final String label;

  /// Host-owned editing controller.
  final TextEditingController? controller;

  /// Starting value when no controller is supplied.
  final String? initialValue;

  /// Host focus node; otherwise owned internally.
  final FocusNode? focusNode;

  /// Supplemental hint; never the only instruction.
  final String? hint;

  /// Caption beneath the field.
  final String? description;

  /// Optional semantic tone for the description.
  final StatusTone descriptionTone;

  /// Host error; hides on edit. Pass null between identical attempts.
  final String? errorText;

  /// Form validation; errors include an icon.
  final FormFieldValidator<String>? validator;

  /// Spoken as required; enforced by the host validator.
  final bool required;

  /// Hidden parts remain in semantics.
  final Set<PaymentFieldPart> hiddenElements;

  /// Keyboard, autofill and correction traits.
  final PaymentTextFieldType type;

  /// Padding size; input text always remains 16 px.
  final PaymentSize size;

  /// Reports edits immediately; remote debounce belongs to the host.
  final ValueChanged<String>? onChanged;

  /// Reports keyboard submission.
  final ValueChanged<String>? onSubmitted;

  /// Keyboard action override.
  final TextInputAction? textInputAction;

  /// Host input constraints.
  final List<TextInputFormatter> inputFormatters;

  /// Capitalization trait.
  final TextCapitalization textCapitalization;

  /// Overrides the keyboard chosen by type.
  final TextInputType? keyboardType;

  /// Overrides autofill traits.
  final Iterable<String>? autofillHints;

  /// False disables editing and changes the edge and text.
  final bool enabled;

  /// Prevents edits while retaining the default appearance.
  final bool readOnly;

  /// Uses reference typography and disables correction.
  final bool reference;

  /// Text before the value.
  final String? prefixText;

  /// Decorative leading content.
  final Widget? prefixIcon;

  /// Trailing content.
  final Widget? suffix;

  /// Controlled query used by the search constructor.
  final String? query;
  @override
  State<PaymentTextField> createState() => _PaymentTextFieldState();
}

class _PaymentTextFieldState extends State<PaymentTextField> {
  TextEditingController? _search;
  FocusNode? _ownedFocus;
  bool _hideHostError = false;
  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());
  @override
  void initState() {
    super.initState();
    if (widget.query != null) {
      _search = TextEditingController(text: widget.query);
    }
  }

  @override
  void didUpdateWidget(PaymentTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) _hideHostError = false;
    if (widget.query != null) {
      _search ??= TextEditingController();
      if (_search!.text != widget.query) {
        _search!.value = TextEditingValue(
          text: widget.query!,
          selection: TextSelection.collapsed(offset: widget.query!.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _search?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l10n = PaymentLocalizations.of(context);
    final enabled =
        widget.enabled && !(FieldGroupScope.of(context)?.disabled ?? false);
    final label = fieldLabel(
      context,
      widget.label.isEmpty ? l10n.search : widget.label,
      required: widget.required,
    );
    final correct =
        widget.type == PaymentTextFieldType.text && !widget.reference;
    final tabular =
        widget.reference ||
        widget.type == PaymentTextFieldType.number ||
        widget.type == PaymentTextFieldType.tel;
    final keyboard = switch (widget.type) {
      PaymentTextFieldType.text ||
      PaymentTextFieldType.search => TextInputType.text,
      PaymentTextFieldType.number => TextInputType.number,
      PaymentTextFieldType.tel => TextInputType.phone,
      PaymentTextFieldType.url => TextInputType.url,
      PaymentTextFieldType.email => TextInputType.emailAddress,
    };
    final hints = switch (widget.type) {
      PaymentTextFieldType.tel => [AutofillHints.telephoneNumber],
      PaymentTextFieldType.url => [AutofillHints.url],
      PaymentTextFieldType.email => [AutofillHints.email],
      PaymentTextFieldType.text ||
      PaymentTextFieldType.search ||
      PaymentTextFieldType.number => null,
    };
    final hidden = widget.hiddenElements;
    final error = _hideHostError ? null : widget.errorText;
    final above =
        !hidden.contains(PaymentFieldPart.label) && fieldLabelAbove(context);
    final input = Semantics(
      label: hidden.contains(PaymentFieldPart.label) || above ? label : null,
      isRequired: widget.required ? true : null,
      validationResult: error != null
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: TextFormField(
        controller: widget.query == null ? widget.controller : _search,
        initialValue: widget.query == null ? widget.initialValue : null,
        focusNode: _focus,
        enabled: enabled,
        readOnly: widget.readOnly,
        minLines: widget._minLines,
        maxLines: widget._maxLines,
        maxLength: widget._maxLength,
        buildCounter: widget._maxLength == null
            ? null
            : (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => Semantics(
                liveRegion: currentLength >= (maxLength! * .9).floor(),
                label: l10n.charactersLeft(maxLength - currentLength),
                child: ExcludeSemantics(
                  child: Text(
                    '$currentLength/$maxLength',
                    style: type.caption.tabular,
                  ),
                ),
              ),
        keyboardType: widget._multiline
            ? TextInputType.multiline
            : widget.keyboardType ?? keyboard,
        autofillHints: widget.autofillHints ?? hints,
        autocorrect: correct,
        enableSuggestions: correct,
        smartDashesType: correct
            ? SmartDashesType.enabled
            : SmartDashesType.disabled,
        smartQuotesType: correct
            ? SmartQuotesType.enabled
            : SmartQuotesType.disabled,
        textCapitalization: widget._multiline
            ? TextCapitalization.sentences
            : widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        textInputAction:
            (widget._multiline
                ? TextInputAction.newline
                : widget.textInputAction) ??
            (widget.type == PaymentTextFieldType.search
                ? TextInputAction.search
                : null),
        style:
            (widget.reference
                    ? type.input.reference(theme)
                    : tabular
                    ? type.input.tabular
                    : type.input)
                .copyWith(color: enabled ? theme.textPrimary : theme.disabled),
        onChanged: (value) {
          if (widget.errorText != null && !_hideHostError) {
            setState(() => _hideHostError = true);
          }
          widget.onChanged?.call(value);
        },
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        forceErrorText: error,
        errorBuilder: (_, text) => FieldMessage(
          text,
          tone: StatusTone.danger,
          hidden: hidden.contains(PaymentFieldPart.error),
        ),
        decoration: paymentFieldDecoration(
          context,
          label: label,
          hideLabel: hidden.contains(PaymentFieldPart.label),
          labelAbove: above,
          hint: widget.hint,
          enabled: enabled,
          contentPadding: fieldContentPadding(
            theme,
            widget.size,
            labelAbove: above,
          ),
          helper: widget.description == null
              ? null
              : FieldMessage(
                  widget.description!,
                  tone: widget.descriptionTone == StatusTone.neutral
                      ? null
                      : widget.descriptionTone,
                  hidden: hidden.contains(PaymentFieldPart.description),
                ),
          prefixText: widget.prefixText,
          prefixIcon: widget.query == null
              ? widget.prefixIcon
              : const PaymentIcon(
                  Icons.search,
                  color: PaymentTextColor.secondary,
                ),
          suffixIcon: widget.query == null
              ? widget.suffix
              : widget.query!.isEmpty
              ? null
              : PaymentIconButton(
                  icon: PaymentIcons.close,
                  tooltip: l10n.clearSearch,
                  onPressed: () {
                    widget.onChanged!('');
                    _focus.requestFocus();
                  },
                ),
        ).copyWith(alignLabelWithHint: widget._multiline),
      ),
    );
    final field = above
        ? FieldLabelAbove(
            label: label,
            enabled: enabled,
            onTap: _focus.requestFocus,
            child: input,
          )
        : input;
    if (!widget._multiline || widget.onSubmitted == null) return field;
    void submit() => widget.onSubmitted!(widget.controller?.text ?? '');
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): submit,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): submit,
      },
      child: field,
    );
  }
}

/// Several lines of free text. Enter inserts a newline; modified Enter submits.
class PaymentTextArea extends StatefulWidget {
  const PaymentTextArea({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hint,
    this.description,
    this.errorText,
    this.validator,
    this.required = false,
    this.hiddenElements = const {},
    this.minLines = 3,
    this.maxLines = 8,
    this.maxLength,
    this.size = PaymentSize.medium,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
  }) : assert(minLines > 0),
       assert(maxLines == null || maxLines >= minLines),
       assert(controller == null || initialValue == null);

  /// label for this field.
  final String label;

  /// controller for this field.
  final TextEditingController? controller;

  /// initialValue for this field.
  final String? initialValue;

  /// focusNode for this field.
  final FocusNode? focusNode;

  /// hint for this field.
  final String? hint;

  /// description for this field.
  final String? description;

  /// errorText for this field.
  final String? errorText;

  /// validator for this field.
  final FormFieldValidator<String>? validator;

  /// required for this field.
  final bool required;

  /// hiddenElements for this field.
  final Set<PaymentFieldPart> hiddenElements;

  /// minLines for this field.
  final int minLines;

  /// maxLines for this field.
  final int? maxLines;

  /// maxLength for this field.
  final int? maxLength;

  /// size for this field.
  final PaymentSize size;

  /// onChanged for this field.
  final ValueChanged<String>? onChanged;

  /// onSubmitted for this field.
  final ValueChanged<String>? onSubmitted;

  /// enabled for this field.
  final bool enabled;

  /// readOnly for this field.
  final bool readOnly;
  @override
  State<PaymentTextArea> createState() => _PaymentTextAreaState();
}

class _PaymentTextAreaState extends State<PaymentTextArea> {
  late final _owned = TextEditingController(text: widget.initialValue);
  @override
  void dispose() {
    _owned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PaymentTextField._area(
    label: widget.label,
    controller: widget.controller ?? _owned,
    focusNode: widget.focusNode,
    hint: widget.hint,
    description: widget.description,
    errorText: widget.errorText,
    validator: widget.validator,
    required: widget.required,
    hiddenElements: widget.hiddenElements,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    size: widget.size,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    enabled: widget.enabled,
    readOnly: widget.readOnly,
  );
}
