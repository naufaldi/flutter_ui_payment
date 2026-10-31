import 'package:flutter/material.dart';
import '../controls/actions.dart';
import '../controls/text_field.dart';
import '../foundation/date_input.dart';
import '../foundation/field_decoration.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_tokens.dart';

/// Typed calendar date with a calendar-only picker. Host owns range rules.
class PaymentDateField extends StatefulWidget {
  const PaymentDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.validator,
    this.description,
    this.errorText,
    this.required = false,
    this.hiddenElements = const {},
    this.size = PaymentSize.medium,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
  });

  /// label for this field.
  final String label;

  /// value for this field.
  final DateTime? value;

  /// onChanged for this field.
  final ValueChanged<DateTime?> onChanged;

  /// firstDate for this field.
  final DateTime firstDate;

  /// lastDate for this field.
  final DateTime lastDate;

  /// validator for this field.
  final FormFieldValidator<DateTime>? validator;

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

  /// enabled for this field.
  final bool enabled;

  /// focusNode for this field.
  final FocusNode? focusNode;

  /// textInputAction for this field.
  final TextInputAction? textInputAction;
  @override
  State<PaymentDateField> createState() => _PaymentDateFieldState();
}

class _PaymentDateFieldState extends State<PaymentDateField> {
  /// TextEditingController() for this field.
  final _controller = TextEditingController();

  /// FocusNode() for this field.
  final _owned = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _owned;
  DateTime? _reported;
  String? _kitError;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _setValue(widget.value);
    }
  }

  void _setValue(DateTime? value) {
    _reported = value;
    _controller.text = value == null
        ? ''
        : formatDateInput(
            value,
            PaymentLocalizations.of(context).dateInputPattern,
          );
  }

  void _focusChanged() {
    if (!mounted) return;
    setState(
      () => _kitError =
          !_focus.hasFocus &&
              _controller.text.isNotEmpty &&
              parseDateInput(
                    _controller.text,
                    PaymentLocalizations.of(context).dateInputPattern,
                  ) ==
                  null
          ? PaymentLocalizations.of(context).enterValidDate
          : null,
    );
  }

  @override
  void didUpdateWidget(PaymentDateField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _owned).removeListener(_focusChanged);
      _focus.addListener(_focusChanged);
    }
    if (widget.value != _reported) _setValue(widget.value);
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _owned.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    var initial =
        widget.value ?? _reported ?? DateUtils.dateOnly(DateTime.now());
    if (initial.isBefore(widget.firstDate)) initial = widget.firstDate;
    if (initial.isAfter(widget.lastDate)) initial = widget.lastDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _setValue(result);
        _kitError = null;
      });
      widget.onChanged(result);
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    final enabled =
        widget.enabled && !(FieldGroupScope.of(context)?.disabled ?? false);
    return PaymentTextField(
      label: widget.label,
      controller: _controller,
      focusNode: _focus,
      type: PaymentTextFieldType.number,
      inputFormatters: [DateInputFormatter(l.dateInputPattern)],
      hint: l.dateInputHint,
      description: [widget.description, l.dateInputHint].nonNulls.join('\n'),
      errorText: widget.errorText ?? _kitError,
      required: widget.required,
      hiddenElements: widget.hiddenElements,
      size: widget.size,
      enabled: enabled,
      textInputAction: widget.textInputAction,
      validator: (text) {
        final date = parseDateInput(text ?? '', l.dateInputPattern);
        if ((text ?? '').isNotEmpty && date == null) return l.enterValidDate;
        return widget.validator?.call(date);
      },
      onChanged: (text) {
        final date = parseDateInput(text, l.dateInputPattern);
        if (date != null) setState(() => _kitError = null);
        if (date != _reported) {
          _reported = date;
          widget.onChanged(date);
        }
      },
      suffix: PaymentIconButton(
        icon: Icons.calendar_today_outlined,
        tooltip: l.chooseDate,
        onPressed: enabled ? _pick : null,
      ),
    );
  }
}
