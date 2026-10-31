import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controls/text_field.dart';
import '../foundation/field_decoration.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../foundation/search_fold.dart';
import 'chip.dart';

/// One host value and its visible search label.
@immutable
class PaymentSearchOption<T> {
  const PaymentSearchOption({required this.value, required this.label});

  /// Stable host value returned when this option is chosen.
  final T value;

  /// Visible label for the control.
  final String label;
}

/// Locally filtered or host-searched inline listbox with keyboard selection.
class PaymentSearchField<T> extends StatefulWidget {
  const PaymentSearchField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.onQueryChanged,
    this.initialQuery,
    this.loading = false,
    this.listboxSize = PaymentSize.medium,
    this.hint,
    this.description,
    this.errorText,
    this.enabled = true,
    this.focusNode,
  }) : _values = const <Never>{},
       onSelectionChanged = null,
       _multiple = false;

  /// Multiple values rendered as removable chips.
  factory PaymentSearchField.multiple({
    Key? key,
    required String label,
    required List<PaymentSearchOption<T>> options,
    required Set<T> selected,
    required ValueChanged<Set<T>> onSelectionChanged,
    ValueChanged<String>? onQueryChanged,
    String? initialQuery,
    bool loading = false,
    PaymentSize listboxSize = PaymentSize.medium,
    String? hint,
    String? description,
    String? errorText,
    bool enabled = true,
    FocusNode? focusNode,
  }) => PaymentSearchField._(
    key: key,
    label: label,
    options: options,
    values: selected,
    onSelectionChanged: onSelectionChanged,
    onQueryChanged: onQueryChanged,
    initialQuery: initialQuery,
    loading: loading,
    listboxSize: listboxSize,
    hint: hint,
    description: description,
    errorText: errorText,
    enabled: enabled,
    focusNode: focusNode,
  );
  const PaymentSearchField._({
    super.key,
    required this.label,
    required this.options,
    required this._values,
    required this.onSelectionChanged,
    this.onQueryChanged,
    this.initialQuery,
    this.loading = false,
    this.listboxSize = PaymentSize.medium,
    this.hint,
    this.description,
    this.errorText,
    this.enabled = true,
    this.focusNode,
  }) : selected = null,
       onSelected = null,
       _multiple = true;

  /// Visible label for the control.
  final String label;

  /// Allowed values with their visible labels.
  final List<PaymentSearchOption<T>> options;

  /// Current selected host value.
  final T? selected;

  /// Reports the selected value to the host.
  final ValueChanged<T?>? onSelected;

  /// Reports the current set of selected values.
  final ValueChanged<Set<T>>? onSelectionChanged;
  final Set<T> _values;
  final bool _multiple;

  /// Reports search edits for host filtering.
  final ValueChanged<String>? onQueryChanged;

  /// Initial query shown before the first edit.
  final String? initialQuery;

  /// Shows the pending search state.
  final bool loading;

  /// Density of the search result rows.
  final PaymentSize listboxSize;

  /// Example input shown while empty.
  final String? hint;

  /// Supporting explanation below the heading.
  final String? description;

  /// Safe error message displayed beside the control.
  final String? errorText;

  /// Whether the customer can edit the search.
  final bool enabled;

  /// Optional host focus node, for example to focus the first error.
  final FocusNode? focusNode;
  @override
  State<PaymentSearchField<T>> createState() => _PaymentSearchFieldState<T>();
}

class _PaymentSearchFieldState<T> extends State<PaymentSearchField<T>> {
  late final _controller = TextEditingController(
    text: widget.initialQuery ?? _label(widget.selected),
  );

  final _ownFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  late List<String> _folded = [
    for (final o in widget.options) foldForSearch(o.label),
  ];

  final Map<T, GlobalKey> _rowKeys = {};
  bool _open = false;
  int? _active;
  String _label(T? value) =>
      widget.options.where((o) => o.value == value).firstOrNull?.label ?? '';
  List<PaymentSearchOption<T>> get _visible => [
    for (var i = 0; i < widget.options.length; i++)
      if (widget.onQueryChanged != null ||
          matchesQuery(_folded[i], _controller.text))
        widget.options[i],
  ];
  @override
  void initState() {
    super.initState();
    _focus.addListener(_focused);
  }

  void _focused() => setState(() {
    _open = _focus.hasFocus;
    _active = null;
  });
  @override
  void didUpdateWidget(PaymentSearchField<T> old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus).removeListener(_focused);
      _focus.addListener(_focused);
    }
    if (!identical(old.options, widget.options)) {
      _folded = [for (final o in widget.options) foldForSearch(o.label)];
      _rowKeys.clear();
      _active = null;
    }
    if (!widget._multiple &&
        old.selected != widget.selected &&
        !_focus.hasFocus) {
      _controller.text = _label(widget.selected);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focused);
    _ownFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _pick(PaymentSearchOption<T> option) {
    if (widget._multiple) {
      final next = Set<T>.of(widget._values);
      if (!next.add(option.value)) next.remove(option.value);
      widget.onSelectionChanged!(next);
      _controller.clear();
    } else {
      widget.onSelected!(option.value);
      _controller.value = TextEditingValue(
        text: option.label,
        selection: TextSelection.collapsed(offset: option.label.length),
      );
    }
    setState(() {
      _open = widget._multiple;
      _active = null;
    });
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (!_open || event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final visible = _visible;
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _open = false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter &&
        _active != null &&
        _active! < visible.length) {
      _pick(visible[_active!]);
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowUp) &&
        visible.isNotEmpty) {
      setState(
        () => _active =
            ((_active ?? (key == LogicalKeyboardKey.arrowDown ? -1 : 0)) +
                (key == LogicalKeyboardKey.arrowDown ? 1 : -1)) %
            visible.length,
      );
      final activeValue = visible[_active!].value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = _rowKeys[activeValue]?.currentContext;
        if (c != null) Scrollable.ensureVisible(c);
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    final visible = _visible;
    final enabled =
        widget.enabled && !(FieldGroupScope.of(context)?.disabled ?? false);
    final rowHeight = math.max(
      48.0,
      PaymentType.firstLineHeight(context) + t.space(PaymentSpace.section),
    );
    final rows = switch (widget.listboxSize) {
      PaymentSize.small => 4,
      PaymentSize.medium => 6,
      PaymentSize.large => 8,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.space(PaymentSpace.inline),
      children: [
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _keys,
          child: PaymentTextField(
            label: widget.label,
            controller: _controller,
            focusNode: _focus,
            type: PaymentTextFieldType.search,
            hint: widget.hint,
            description: widget.description,
            errorText: widget.errorText,
            enabled: enabled,
            onChanged: (value) {
              widget.onQueryChanged?.call(value);
              if (!widget._multiple && widget.selected != null) {
                widget.onSelected!(null);
              }
              if (widget._multiple && value.isEmpty) {
                widget.onSelectionChanged!(<T>{});
              }
              setState(() {
                _open = true;
                _active = null;
              });
            },
          ),
        ),
        if (widget._multiple)
          PaymentChipList(
            children: [
              for (final value in widget._values)
                PaymentChip(
                  label: _label(value),
                  onClose: enabled
                      ? () => widget.onSelectionChanged!(
                          widget._values.difference({value}),
                        )
                      : null,
                ),
            ],
          ),
        if (_open && _focus.hasFocus && enabled)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: t.outline),
              borderRadius: t.controlBorderRadius,
            ),
            child: Column(
              children: [
                Semantics(
                  liveRegion: true,
                  label: widget.loading
                      ? l.loading
                      : l.resultsCount(visible.length),
                  child: const SizedBox.shrink(),
                ),
                if (widget.loading)
                  Padding(
                    padding: EdgeInsets.all(t.space(PaymentSpace.block)),
                    child: Row(
                      children: [
                        const PaymentSpinner(size: PaymentSize.small),
                        Text(l.loading, style: type.label),
                      ],
                    ),
                  )
                else if (visible.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(t.space(PaymentSpace.block)),
                    child: Row(
                      children: [
                        const PaymentIcon(PaymentIcons.noMatches),
                        Text(l.noMatchesTitle, style: type.label),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: rows * rowHeight),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final o = visible[i];
                        final selected = widget._multiple
                            ? widget._values.contains(o.value)
                            : widget.selected == o.value;
                        return Semantics(
                          key: _rowKeys.putIfAbsent(o.value, GlobalKey.new),
                          button: true,
                          selected: selected,
                          label: o.label,
                          excludeSemantics: true,
                          child: Material(
                            color: _active == i
                                ? t.surfaceMuted
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () => _pick(o),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: rowHeight,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    t.space(PaymentSpace.block),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(o.label, style: type.label),
                                      ),
                                      if (selected)
                                        const PaymentIcon(
                                          PaymentIcons.copied,
                                          color: PaymentTextColor.accent,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
