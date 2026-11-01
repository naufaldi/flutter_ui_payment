import '../foundation/field_decoration.dart';
import 'dart:ui' show SemanticsRole, SemanticsValidationResult;
import '../foundation/payment_tokens.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../foundation/payment_motion.dart';
import '../foundation/tooltip_geometry.dart';
import 'package:flutter/material.dart';

import '../foundation/row_shell.dart';
import '../foundation/focus_ring.dart';
import '../foundation/radio_mark.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';

/// A checkbox with its label, for consent and opt-in choices.
///
/// The whole row is one 48 dp target and one screen-reader node ("Save this
/// card, checkbox, checked"). Controlled: the host owns [value] and gets
/// [onChanged]. A null [onChanged] disables the row; pass [disabledReason]
/// so people know why.
class PaymentCheckbox extends StatelessWidget {
  const PaymentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.indeterminate = false,
    required this.label,
    this.description,
    this.disabledReason,
    this.errorText,
    this.required = false,
    this.hiddenElements = const {},
  });

  /// A select-all dash. Value is ignored while mixed; tapping reports true.
  final bool indeterminate;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// What checking the box agrees to, as a full phrase: "Save this card for
  /// next time", not "Save".
  /// Validation message, with a danger icon and edge.
  final String? errorText;

  /// Spoken as required; the host gates the next step.
  final bool required;

  /// Visually hidden parts remain in semantics.
  final Set<PaymentFieldPart> hiddenElements;
  final String label;

  /// A muted line under the label.
  final String? description;

  /// Replaces [description] while the row is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final enabled =
        onChanged != null && !(FieldGroupScope.of(context)?.disabled ?? false);
    return MergeSemantics(
      child: Semantics(
        checked: indeterminate ? false : value,
        mixed: indeterminate ? true : null,
        enabled: enabled,
        isRequired: required ? true : null,
        validationResult: errorText == null
            ? SemanticsValidationResult.none
            : SemanticsValidationResult.invalid,
        child: _ControlRow(
          label: label,
          errorText: errorText,
          hidden: hiddenElements,
          detail: !enabled && disabledReason != null
              ? disabledReason
              : description,
          enabled: enabled,
          onTap: enabled
              ? () => onChanged!(indeterminate ? true : !value)
              : null,
          // Painted by Material, so it matches the kit's other checkboxes;
          // the row owns taps, focus and semantics.
          mark: Checkbox(
            value: indeterminate ? null : value,
            tristate: indeterminate,
            onChanged: enabled ? (_) {} : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            checkColor: theme.onAccent,
            fillColor: WidgetStateProperty.resolveWith(
              (states) => !states.contains(WidgetState.selected)
                  ? Colors.transparent
                  : states.contains(WidgetState.disabled)
                  ? theme.disabled
                  : theme.accent,
            ),
            // The unchecked box is a control edge, so it uses the 3:1 border.
            side: WidgetStateBorderSide.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? null
                  : BorderSide(
                      color: states.contains(WidgetState.disabled)
                          ? theme.disabled
                          : errorText != null
                          ? theme.danger.foreground
                          : theme.border,
                      width: 2,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option of a single choice. Give every option in the group the same
/// [groupValue] and [onChanged]; the option whose [value] equals
/// [groupValue] is selected.
///
/// Selection shows as a filled ring, not only a color: the selected mark is
/// a thick accent ring, the others a thin muted one. Use radios for two to
/// about five options that all fit on screen.
class PaymentRadio<T> extends StatelessWidget {
  const PaymentRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.description,
    this.disabledReason,
    this.errorText,
    this.required = false,
    this.hiddenElements = const {},
  });

  final T value;
  final T? groupValue;

  /// Called with [value] when this option is chosen. Null disables it.
  final ValueChanged<T>? onChanged;

  /// Validation message, with a danger icon and edge.
  final String? errorText;

  /// Spoken as required; the host gates the next step.
  final bool required;

  /// Visually hidden parts remain in semantics.
  final Set<PaymentFieldPart> hiddenElements;
  final String label;
  final String? description;

  /// Replaces [description] while the option is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled =
        onChanged != null && !(FieldGroupScope.of(context)?.disabled ?? false);
    final selected = value == groupValue;
    return MergeSemantics(
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        enabled: enabled,
        isRequired: required ? true : null,
        validationResult: errorText == null
            ? SemanticsValidationResult.none
            : SemanticsValidationResult.invalid,
        child: _ControlRow(
          label: label,
          errorText: errorText,
          hidden: hiddenElements,
          detail: !enabled && disabledReason != null
              ? disabledReason
              : description,
          enabled: enabled,
          // Choosing the selected option again is a no-op, but the row stays
          // tappable so it keeps its place in the focus order.
          onTap: enabled
              ? () {
                  if (!selected) onChanged!(value);
                }
              : null,
          mark: RadioMark(
            selected: selected,
            enabled: enabled,
            error: errorText != null,
          ),
        ),
      ),
    );
  }
}

/// An on/off setting that takes effect at once, such as "Notify me about
/// refunds". For a choice that is only applied after a button press, use a
/// [PaymentCheckbox] instead.
///
/// The switch sits at the end of the row; the whole row is the target. The
/// thumb moves and shows a check when on, so the state is never carried by
/// color alone.
class PaymentSwitch extends StatelessWidget {
  const PaymentSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    this.disabledReason,
    this.errorText,
    this.required = false,
    this.hiddenElements = const {},
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Validation message, with a danger icon and edge.
  final String? errorText;

  /// Spoken as required; the host gates the next step.
  final bool required;

  /// Visually hidden parts remain in semantics.
  final Set<PaymentFieldPart> hiddenElements;
  final String label;
  final String? description;

  /// Replaces [description] while the row is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final enabled =
        onChanged != null && !(FieldGroupScope.of(context)?.disabled ?? false);
    return MergeSemantics(
      child: Semantics(
        toggled: value,
        enabled: enabled,
        isRequired: required ? true : null,
        validationResult: errorText == null
            ? SemanticsValidationResult.none
            : SemanticsValidationResult.invalid,
        child: _ControlRow(
          label: label,
          errorText: errorText,
          hidden: hiddenElements,
          detail: !enabled && disabledReason != null
              ? disabledReason
              : description,
          enabled: enabled,
          onTap: enabled ? () => onChanged!(!value) : null,
          markAtEnd: true,
          mark: Switch(
            value: value,
            onChanged: enabled ? (_) {} : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            thumbIcon: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Icon(
                      Icons.check,
                      color: states.contains(WidgetState.disabled)
                          ? theme.disabled
                          : theme.accent,
                    )
                  : null,
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? theme.onAccent
                  : states.contains(WidgetState.disabled)
                  ? theme.disabled
                  : errorText != null
                  ? theme.danger.foreground
                  : theme.border,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? theme.surfaceMuted
                  : states.contains(WidgetState.selected)
                  ? theme.accent
                  : theme.surface,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.transparent
                  : states.contains(WidgetState.disabled)
                  ? theme.disabled
                  : errorText != null
                  ? theme.danger.foreground
                  : theme.border,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared layout of the selection controls: a mark beside a label and an
/// optional detail line, with the whole row as one 48 dp minimum target.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.mark,
    required this.label,
    required this.detail,
    required this.enabled,
    required this.onTap,
    this.markAtEnd = false,
    this.errorText,
    this.hidden = const {},
  });

  final String? errorText;
  final Set<PaymentFieldPart> hidden;
  final Widget mark;
  final String label;
  final String? detail;
  final bool enabled;
  final VoidCallback? onTap;
  final bool markAtEnd;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    // The mark centers on the label's first line, as PaymentListItem's icon does.
    final line = PaymentType.firstLineHeight(context);
    // The row takes taps, focus and semantics; the painted mark takes none.
    final painted = ExcludeFocus(
      child: IgnorePointer(child: ExcludeSemantics(child: mark)),
    );
    return RowShell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!markAtEnd) ...[
            SizedBox(
              width: 20,
              height: line,
              child: OverflowBox(maxWidth: 48, maxHeight: 48, child: painted),
            ),
            SizedBox(width: theme.space(PaymentSpace.block)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hidden.contains(PaymentFieldPart.label))
                  Semantics(label: label, child: const SizedBox.shrink())
                else
                  Text(
                    label,
                    style: type.label.copyWith(
                      color: enabled ? theme.textPrimary : theme.textSecondary,
                    ),
                  ),
                if (detail != null)
                  if (hidden.contains(PaymentFieldPart.description))
                    Semantics(label: detail, child: const SizedBox.shrink())
                  else
                    Text(detail!, style: type.caption),
                if (errorText != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: theme.space(PaymentSpace.inline),
                    ),
                    child: FieldMessage(
                      errorText!,
                      tone: StatusTone.danger,
                      hidden: hidden.contains(PaymentFieldPart.error),
                    ),
                  ),
              ],
            ),
          ),
          if (markAtEnd) ...[
            SizedBox(width: theme.space(PaymentSpace.group)),
            SizedBox(
              width: 52,
              height: line,
              child: OverflowBox(maxHeight: 48, child: painted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tab label and optional unavailability reason (Stripe Tab).
@immutable
class PaymentTab {
  const PaymentTab({required this.label, this.disabledReason});

  /// Visible tab label.
  final String label;

  /// Explanation for an unavailable tab.
  final String? disabledReason;
}

/// Controlled tabs. Arrows move focus, skipping disabled tabs; Enter or Space
/// selects. Sizes change typography and padding, never the 48 dp target.
class PaymentTabs extends StatefulWidget {
  const PaymentTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.size = PaymentSize.medium,
    this.fitted = false,
  });

  /// Tabs in reading order.
  final List<PaymentTab> tabs;

  /// Host-owned active tab index.
  final int selectedIndex;

  /// Reports manual tab activation.
  final ValueChanged<int> onSelected;

  /// Typography and padding size.
  final PaymentSize size;

  /// Divide available width equally when every label fits; otherwise scroll.
  final bool fitted;
  @override
  State<PaymentTabs> createState() => _PaymentTabsState();
}

class _PaymentTabsState extends State<PaymentTabs> {
  final List<FocusNode> _nodes = [];
  void _syncNodes() {
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.tabs.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(PaymentTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.arrowLeft &&
        key != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    final forward =
        (key == LogicalKeyboardKey.arrowRight) !=
        (Directionality.of(context) == TextDirection.rtl);
    for (var n = 1; n <= widget.tabs.length; n++) {
      final next = (index + (forward ? n : -n)) % widget.tabs.length;
      if (widget.tabs[next].disabledReason == null) {
        _nodes[next].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.selectedIndex >= 0 && widget.selectedIndex < widget.tabs.length,
    );
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final metrics = switch (widget.size) {
      PaymentSize.small => (
        style: type.caption,
        pad: theme.space(PaymentSpace.related),
      ),
      PaymentSize.medium => (
        style: type.label,
        pad: theme.space(PaymentSpace.block),
      ),
      PaymentSize.large => (
        style: type.heading,
        pad: theme.space(PaymentSpace.group),
      ),
    };
    Widget tab(int i) => _Tab(
      tab: widget.tabs[i],
      selected: widget.selectedIndex == i,
      onTap: () => widget.onSelected(i),
      focusNode: _nodes[i],
      onKey: (event) => _key(i, event),
      style: metrics.style,
      padding: metrics.pad,
    );
    return LayoutBuilder(
      builder: (context, k) {
        var need = 0.0;
        for (final tab in widget.tabs) {
          final painter = TextPainter(
            text: TextSpan(text: tab.label, style: metrics.style),
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
          )..layout();
          final width = painter.width + 2 * metrics.pad;
          if (width > need) need = width;
          painter.dispose();
        }
        final fitted = widget.fitted && need * widget.tabs.length <= k.maxWidth;
        final row = Semantics(
          role: SemanticsRole.tabBar,
          container: true,
          explicitChildNodes: true,
          child: Row(
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                if (fitted) Expanded(child: tab(i)) else tab(i),
            ],
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.outline)),
          ),
          child: ClipRect(
            clipper: const _SidesClipper(),
            child: fitted
                ? row
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.space(PaymentSpace.inline),
                    ),
                    child: row,
                  ),
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.focusNode,
    required this.onKey,
    required this.style,
    required this.padding,
  });
  final PaymentTab tab;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final KeyEventResult Function(KeyEvent) onKey;
  final TextStyle style;
  final double padding;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final enabled = tab.disabledReason == null;
    final content = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => onKey(event),
      child: PaymentFocusRing(
        radius: BorderRadius.zero,
        child: PaymentPressScale(
          child: InkWell(
            focusNode: focusNode,
            focusColor: Colors.transparent,
            onTap: enabled ? onTap : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: EdgeInsets.symmetric(horizontal: padding),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? theme.accent
                        : theme.accent.withValues(alpha: 0),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab.label,
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: !enabled
                      ? theme.disabled
                      : selected
                      ? theme.accent
                      : theme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        enabled: enabled,
        button: true,
        hint: tab.disabledReason,
        child: enabled
            ? content
            : PaymentTooltip(
                message: tab.disabledReason!,
                type: PaymentTooltipType.description,
                child: content,
              ),
      ),
    );
  }
}

/// Lazily builds selected panels and preserves visited state. Hidden panels
/// are offstage, excluded from focus and semantics, and have paused tickers.
class PaymentTabPanels extends StatefulWidget {
  const PaymentTabPanels({
    super.key,
    required this.selectedIndex,
    required this.children,
  });
  final int selectedIndex;
  final List<Widget> children;
  @override
  State<PaymentTabPanels> createState() => _PaymentTabPanelsState();
}

class _PaymentTabPanelsState extends State<PaymentTabPanels> {
  final Set<int> _built = {};
  @override
  Widget build(BuildContext context) {
    assert(
      widget.selectedIndex >= 0 &&
          widget.selectedIndex < widget.children.length,
    );
    _built.add(widget.selectedIndex);
    return Stack(
      children: [
        for (final (i, child) in widget.children.indexed)
          if (_built.contains(i))
            Offstage(
              key: ValueKey(i),
              offstage: i != widget.selectedIndex,
              child: TickerMode(
                enabled: i == widget.selectedIndex,
                child: ExcludeFocus(
                  excluding: i != widget.selectedIndex,
                  child: Semantics(
                    role: SemanticsRole.tabPanel,
                    container: true,
                    child: KeyedSubtree(key: ValueKey(i), child: child),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _SidesClipper extends CustomClipper<Rect> {
  const _SidesClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, -4, size.width, size.height + 4);

  @override
  bool shouldReclip(_SidesClipper oldClipper) => false;
}

/// Twelve placements; start and end follow the text direction.
enum PaymentTooltipPlacement {
  /// Stripe top.
  top,

  /// Stripe top start.
  topStart,

  /// Stripe top end.
  topEnd,

  /// Stripe bottom.
  bottom,

  /// Stripe bottom start.
  bottomStart,

  /// Stripe bottom end.
  bottomEnd,

  /// Stripe left in LTR.
  start,

  /// Stripe left top in LTR.
  startTop,

  /// Stripe left bottom in LTR.
  startBottom,

  /// Stripe right in LTR.
  end,

  /// Stripe right top in LTR.
  endTop,

  /// Stripe right bottom in LTR.
  endBottom,
}

/// Whether the message names the trigger or adds detail.
enum PaymentTooltipType {
  /// Becomes the trigger's semantic label.
  label,

  /// Becomes the trigger's semantic tooltip.
  description,
}

/// A noninteractive hint shown on hover, long press or keyboard focus.
/// Escape, blur, exit and an outside tap hide it. Requires an Overlay.
/// Never put a fee, a requirement or an error only in a tooltip.
class PaymentTooltip extends StatefulWidget {
  const PaymentTooltip({
    super.key,
    required this.message,
    required this.child,
    this.placement = PaymentTooltipPlacement.bottom,
    this.type = PaymentTooltipType.description,
    this.delay = const Duration(milliseconds: 500),
  });
  final String message;
  final Widget child;
  final PaymentTooltipPlacement placement;
  final PaymentTooltipType type;
  final Duration delay;
  @override
  State<PaymentTooltip> createState() => _PaymentTooltipState();
}

class _PaymentTooltipState extends State<PaymentTooltip> {
  final _portal = OverlayPortalController();
  Timer? _showTimer;
  Timer? _hideTimer;
  static _PaymentTooltipState? _open;
  void _show() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (_open != this) _open?._hide();
    _open = this;
    _portal.show();
  }

  void _hide() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _portal.hide();
    if (_open == this) _open = null;
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (_open == this) _open = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: widget.type == PaymentTooltipType.label ? widget.message : null,
      tooltip: widget.type == PaymentTooltipType.description
          ? widget.message
          : null,
      child: TapRegion(
        onTapOutside: (_) => _hide(),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (focused) =>
              focused &&
                  FocusManager.instance.highlightMode ==
                      FocusHighlightMode.traditional
              ? _show()
              : _hide(),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape &&
                _portal.isShowing) {
              _hide();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) {
              _showTimer?.cancel();
              if (_open != null) {
                _show();
              } else {
                _showTimer = Timer(widget.delay, _show);
              }
            },
            onExit: (_) => _hide(),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              excludeFromSemantics: true,
              onLongPress: _show,
              onLongPressEnd: (_) =>
                  _hideTimer = Timer(const Duration(milliseconds: 1500), _hide),
              child: OverlayPortal.overlayChildLayoutBuilder(
                controller: _portal,
                overlayChildBuilder: (context, info) {
                  final theme = PaymentTheme.of(context);
                  return CustomSingleChildLayout(
                    delegate: _TooltipDelegate(
                      MatrixUtils.transformRect(
                        info.childPaintTransform,
                        Offset.zero & info.childSize,
                      ),
                      widget.placement,
                      Directionality.of(context),
                      theme.space(PaymentSpace.related),
                    ),
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: PaymentMotion.of(context).quick,
                          builder: (_, opacity, child) =>
                              Opacity(opacity: opacity, child: child),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.textPrimary,
                                borderRadius: theme.controlBorderRadius,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: theme.space(PaymentSpace.related),
                                  vertical: theme.space(PaymentSpace.inline),
                                ),
                                child: Text(
                                  widget.message,
                                  style: PaymentType.of(
                                    context,
                                  ).caption.copyWith(color: theme.surface),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TooltipDelegate extends SingleChildLayoutDelegate {
  const _TooltipDelegate(
    this.target,
    this.placement,
    this.direction,
    this.spacing,
  );
  final Rect target;
  final PaymentTooltipPlacement placement;
  final TextDirection direction;
  final double spacing;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();
  @override
  Offset getPositionForChild(Size size, Size childSize) => placeTooltip(
    target: target,
    size: childSize,
    overlay: size,
    placement: placement,
    direction: direction,
    gap: spacing,
    margin: spacing,
  ).offset;
  @override
  bool shouldRelayout(_TooltipDelegate old) =>
      target != old.target ||
      placement != old.placement ||
      direction != old.direction ||
      spacing != old.spacing;
}
