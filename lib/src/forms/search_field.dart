import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controls/text_field.dart';
import '../foundation/field_decoration.dart';
import '../foundation/field_trigger.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../foundation/layout_rules.dart';
import '../foundation/search_fold.dart';
import '../overlay/modal_presenters.dart';
import '../overlay/sheets.dart';
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

/// Locally filtered or host-searched listbox with keyboard selection (D50).
///
/// Below 600 dp the field is a trigger that opens a full-height search sheet:
/// the search field on top, 48 dp result rows under it and, for multiple
/// selection, the chosen chips and a full-width Done in the footer. At
/// 600 dp and wider it is an inline field with an anchored, elevated list
/// that floats over the page instead of pushing it down.
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
  final _portal = OverlayPortalController();
  bool _open = false;
  int? _active;

  /// What an open phone sheet shows; updated after each host rebuild so new
  /// options, loading and remote results reach the sheet.
  late final _source = ValueNotifier(_snapshot());

  /// The phone sheet starts from [PaymentSearchField.initialQuery] once.
  String? _sheetQuery;

  String _label(T? value) =>
      widget.options.where((o) => o.value == value).firstOrNull?.label ?? '';
  _SearchSource<T> _snapshot() => _SearchSource(
    options: widget.options,
    loading: widget.loading,
    selected: widget.selected,
    values: widget._values,
  );
  List<PaymentSearchOption<T>> get _visible => [
    for (var i = 0; i < widget.options.length; i++)
      if (widget.onQueryChanged != null ||
          matchesQuery(_folded[i], _controller.text))
        widget.options[i],
  ];
  @override
  void initState() {
    super.initState();
    _sheetQuery = widget.initialQuery;
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
    // Listeners live in the sheet's route; notify them after this build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _source.value = _snapshot();
    });
  }

  @override
  void dispose() {
    _focus.removeListener(_focused);
    _ownFocus.dispose();
    _controller.dispose();
    _source.dispose();
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

  Future<void> _openSheet() async {
    final query = _sheetQuery ?? '';
    _sheetQuery = null;
    final result = await showKitBottomSheet<_SearchResult<T>>(
      context: context,
      fullHeight: true,
      showDragHandle: false,
      builder: (_) => _SearchSheet<T>(
        label: widget.label,
        hint: widget.hint,
        multiple: widget._multiple,
        source: _source,
        initialQuery: query,
        onQueryChanged: widget.onQueryChanged,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      if (widget._multiple) {
        widget.onSelectionChanged!(result.values);
      } else {
        widget.onSelected!(result.value);
        _controller.text = _label(result.value);
      }
    }
    _focus.requestFocus();
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
      setState(() => _active = _step(_active, key, visible.length));
      _reveal(_rowKeys[visible[_active!].value]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _reveal(GlobalKey? row) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = row?.currentContext;
        if (c != null) Scrollable.ensureVisible(c);
      });

  @override
  Widget build(BuildContext context) {
    final enabled =
        widget.enabled && !(FieldGroupScope.of(context)?.disabled ?? false);
    final chips = widget._multiple && widget._values.isNotEmpty
        ? PaymentChipList(
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
          )
        : null;
    final field = isCompact(context)
        ? FieldTrigger(
            label: widget.label,
            value: widget._multiple || widget.selected == null
                ? null
                : _label(widget.selected),
            hint: widget.hint,
            description: widget.description,
            errorText: widget.errorText,
            enabled: enabled,
            focusNode: _focus,
            trailing: const PaymentIcon(
              Icons.search,
              color: PaymentTextColor.secondary,
            ),
            onPressed: _openSheet,
          )
        : _wideField(context, enabled);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.inline),
      children: [field, ?chips],
    );
  }

  Widget _wideField(BuildContext context, bool enabled) {
    final t = PaymentTheme.of(context);
    final show = _open && _focus.hasFocus && enabled;
    if (show != _portal.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        show ? _portal.show() : _portal.hide();
      });
    }
    final rows = switch (widget.listboxSize) {
      PaymentSize.small => 4,
      PaymentSize.medium => 6,
      PaymentSize.large => 8,
    };
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, info) {
        final anchor = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        final gap = t.space(PaymentSpace.inline);
        final room = info.overlaySize.height - anchor.bottom - gap * 2;
        final visible = _visible;
        return Stack(
          children: [
            Positioned(
              left: anchor.left,
              top: anchor.bottom + gap,
              width: anchor.width,
              // A text-field tap region: tapping a row doesn't blur the
              // field, which would close the list before the tap lands.
              child: TextFieldTapRegion(
                child: Material(
                  color: t.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: t.border),
                    borderRadius: t.controlBorderRadius,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.max(
                        _rowHeight(context),
                        math.min(rows * _rowHeight(context), room),
                      ),
                    ),
                    child: _SearchResults<T>(
                      options: visible,
                      loading: widget.loading,
                      isSelected: (v) => widget._multiple
                          ? widget._values.contains(v)
                          : widget.selected == v,
                      active: _active,
                      rowKeys: _rowKeys,
                      onPick: _pick,
                      shrinkWrap: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: Focus(
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
    );
  }
}

int _step(int? active, LogicalKeyboardKey key, int length) {
  final down = key == LogicalKeyboardKey.arrowDown;
  return ((active ?? (down ? -1 : 0)) + (down ? 1 : -1)) % length;
}

double _rowHeight(BuildContext context) => math.max(
  48.0,
  PaymentType.firstLineHeight(context) +
      PaymentTheme.of(context).space(PaymentSpace.section),
);

@immutable
class _SearchSource<T> {
  const _SearchSource({
    required this.options,
    required this.loading,
    required this.selected,
    required this.values,
  });
  final List<PaymentSearchOption<T>> options;
  final bool loading;
  final T? selected;
  final Set<T> values;
}

/// What the phone sheet returns; null means it was closed without a choice.
class _SearchResult<T> {
  const _SearchResult.single(this.value) : values = const {};
  const _SearchResult.multiple(this.values) : value = null;
  final T? value;
  final Set<T> values;
}

/// Result rows shared by the wide list and the phone sheet: 48 dp rows with
/// text on the 16 dp inset, or one loading or empty row with an icon → text
/// gap of 12 (D46). Announces the result count.
class _SearchResults<T> extends StatelessWidget {
  const _SearchResults({
    required this.options,
    required this.loading,
    required this.isSelected,
    required this.active,
    required this.rowKeys,
    required this.onPick,
    this.shrinkWrap = false,
  });

  final List<PaymentSearchOption<T>> options;
  final bool loading;
  final bool Function(T value) isSelected;
  final int? active;
  final Map<T, GlobalKey> rowKeys;
  final ValueChanged<PaymentSearchOption<T>> onPick;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    final rowHeight = _rowHeight(context);
    final rowPadding = EdgeInsets.symmetric(
      horizontal: t.space(PaymentSpace.group),
      vertical: t.space(PaymentSpace.block),
    );
    Widget status(Widget icon, String text) => ConstrainedBox(
      constraints: BoxConstraints(minHeight: rowHeight),
      child: Padding(
        padding: rowPadding,
        child: Row(
          spacing: t.space(PaymentSpace.block),
          children: [
            icon,
            Expanded(child: Text(text, style: type.label)),
          ],
        ),
      ),
    );
    final count = Semantics(
      liveRegion: true,
      label: loading ? l.loading : l.resultsCount(options.length),
      child: const SizedBox.shrink(),
    );
    if (loading || options.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          count,
          if (loading)
            status(const PaymentSpinner(size: PaymentSize.small), l.loading)
          else
            status(const PaymentIcon(PaymentIcons.noMatches), l.noMatchesTitle),
        ],
      );
    }
    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        count,
        Flexible(
          fit: shrinkWrap ? FlexFit.loose : FlexFit.tight,
          child: ListView.builder(
            shrinkWrap: shrinkWrap,
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, i) {
              final o = options[i];
              final selected = isSelected(o.value);
              return Semantics(
                key: rowKeys.putIfAbsent(o.value, GlobalKey.new),
                button: true,
                selected: selected,
                label: o.label,
                excludeSemantics: true,
                child: Material(
                  color: active == i ? t.surfaceMuted : Colors.transparent,
                  child: InkWell(
                    onTap: () => onPick(o),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: rowHeight),
                      child: Padding(
                        padding: rowPadding,
                        child: Row(
                          spacing: t.space(PaymentSpace.block),
                          children: [
                            Expanded(child: Text(o.label, style: type.label)),
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
    );
  }
}

/// The phone search sheet (D50). Single selection closes on a pick; multiple
/// selection keeps a draft until Done, and close discards it, as
/// `PaymentSelect.multiple` does.
class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.label,
    required this.hint,
    required this.multiple,
    required this.source,
    required this.initialQuery,
    required this.onQueryChanged,
  });

  final String label;
  final String? hint;
  final bool multiple;
  final ValueListenable<_SearchSource<T>> source;
  final String initialQuery;
  final ValueChanged<String>? onQueryChanged;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();
  final Map<T, GlobalKey> _rowKeys = {};
  late final Set<T> _draft = Set.of(widget.source.value.values);
  List<PaymentSearchOption<T>>? _foldedFor;
  List<String> _folded = const [];
  int? _active;

  @override
  void initState() {
    super.initState();
    widget.source.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _changed() => setState(() => _active = null);

  @override
  void dispose() {
    widget.source.removeListener(_changed);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<PaymentSearchOption<T>> _visible(_SearchSource<T> source) {
    if (widget.onQueryChanged != null) return source.options;
    if (!identical(_foldedFor, source.options)) {
      _foldedFor = source.options;
      _folded = [for (final o in source.options) foldForSearch(o.label)];
    }
    return [
      for (var i = 0; i < source.options.length; i++)
        if (matchesQuery(_folded[i], _controller.text)) source.options[i],
    ];
  }

  void _pick(PaymentSearchOption<T> option) {
    if (!widget.multiple) {
      Navigator.pop(context, _SearchResult<T>.single(option.value));
      return;
    }
    setState(() {
      if (!_draft.add(option.value)) _draft.remove(option.value);
    });
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final visible = _visible(widget.source.value);
    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
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
      setState(() => _active = _step(_active, key, visible.length));
      final row = _rowKeys[visible[_active!].value];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = row?.currentContext;
        if (mounted && c != null) Scrollable.ensureVisible(c);
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final l = PaymentLocalizations.of(context);
    final source = widget.source.value;
    final visible = _visible(source);
    String label(T value) =>
        source.options.where((o) => o.value == value).firstOrNull?.label ??
        '$value';
    return KitFullSheet(
      header: PaymentSheetHeader(
        title: widget.label,
        onClose: () => Navigator.pop(context),
      ),
      top: Padding(
        padding: EdgeInsets.only(bottom: t.space(PaymentSpace.related)),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _keys,
          child: PaymentTextField(
            label: widget.label,
            hiddenElements: const {PaymentFieldPart.label},
            controller: _controller,
            focusNode: _focus,
            type: PaymentTextFieldType.search,
            hint: widget.hint ?? l.search,
            onChanged: (value) {
              widget.onQueryChanged?.call(value);
              setState(() => _active = null);
            },
          ),
        ),
      ),
      body: _SearchResults<T>(
        options: visible,
        loading: source.loading,
        isSelected: (v) =>
            widget.multiple ? _draft.contains(v) : source.selected == v,
        active: _active,
        rowKeys: _rowKeys,
        onPick: _pick,
      ),
      footer: widget.multiple
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: t.space(PaymentSpace.block),
              children: [
                if (_draft.isNotEmpty)
                  PaymentChipList(
                    children: [
                      for (final value in _draft)
                        PaymentChip(
                          label: label(value),
                          onClose: () => setState(() => _draft.remove(value)),
                        ),
                    ],
                  ),
                PaymentButton(
                  label: l.done,
                  onPressed: () => Navigator.pop(
                    context,
                    _SearchResult<T>.multiple(Set.of(_draft)),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
