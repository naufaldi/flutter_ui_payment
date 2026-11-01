import '../controls/button_group.dart';
import '../foundation/table_grid.dart';
import '../layout/content.dart';
import '../controls/actions.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
import '../foundation/row_shell.dart';
import '../foundation/payment_icons.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/token_resolvers.dart';
import '../foundation/primitives.dart';
import '../foundation/layout_rules.dart';

/// A tappable row for settings, menus and action lists.
///
/// The row is flat: a plain outlined icon, a title and a muted detail line,
/// with no container. Put consecutive tiles in a [PaymentList] so they
/// are separated by hairlines.
///
/// Disabled rows stay visible; pass [disabledReason] so people know why.
/// [destructive] uses the danger tone for both icon and label, never color
/// alone: the label must already say what happens.
/// Stripe ListItem sizes. Both keep at least a 48 dp target.
enum PaymentListItemSize {
  /// Standard label row.
  standard,

  /// Heading row with a 64 dp minimum.
  large,
}

/// A payment list row with a host action, icon or image.
class PaymentListItem extends StatelessWidget {
  const PaymentListItem({
    super.key,
    required this.title,
    this.secondaryTitle,
    this.icon,
    this.image,
    this.trailing,
    this.value,
    this.id,
    this.size = PaymentListItemSize.standard,
    this.onPressed,
    this.destructive = false,
    this.disabledReason,
  });

  /// Host action identifier..
  final String? id;

  /// Trailing value, mutually exclusive with trailing..
  final Widget? value;

  /// Row size..
  final PaymentListItemSize size;

  /// Primary row label..
  final String title;

  /// Supporting row text..
  final String? secondaryTitle;

  /// Leading host image; mutually exclusive with icon.
  final PaymentImage? image;

  /// Leading decorative glyph..
  final IconData? icon;

  /// Defaults to a chevron when [onPressed] is set.
  final Widget? trailing;

  /// Host row action..
  final VoidCallback? onPressed;

  /// Use the danger foreground for the action..
  final bool destructive;

  /// Explanation when the action is unavailable..
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    assert(
      value == null || trailing == null,
      'PaymentListItem takes value or trailing, not both.',
    );
    assert(image == null || icon == null);
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PaymentListScope>();
    final handler =
        onPressed ??
        (id != null && scope?.onAction != null
            ? () => scope!.onAction!(id!)
            : null);
    final enabled = handler != null;
    final disabled = !enabled && disabledReason != null;
    final danger = destructive && enabled;
    final foreground = disabled
        ? theme.textSecondary
        : danger
        ? theme.danger.foreground
        : theme.textPrimary;
    final detail = !enabled && disabledReason != null
        ? disabledReason
        : secondaryTitle;
    // Icon and chevron center on the title's first line, not on the whole
    // block, so multi-line rows at large text keep them beside the title.
    final line = PaymentType.firstLineHeight(context);
    final row = RowShell(
      onTap: handler,
      minHeight: size == PaymentListItemSize.large ? 64 : 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null) ...[
            SizedBox(
              width: size == PaymentListItemSize.large
                  ? theme.space(PaymentSpace.related) * 5
                  : PaymentIconSize.medium.resolve(context),
              height: size == PaymentListItemSize.large
                  ? theme.space(PaymentSpace.related) * 5
                  : line,
              child: Center(
                child: SizedBox.square(
                  dimension: size == PaymentListItemSize.large
                      ? theme.space(PaymentSpace.related) * 5
                      : PaymentIconSize.medium.resolve(context),
                  child: image,
                ),
              ),
            ),
            SizedBox(width: theme.space(PaymentSpace.block)),
          ],
          if (icon != null) ...[
            PaymentIcon(
              icon,
              color: danger
                  ? PaymentTextColor.danger
                  : PaymentTextColor.secondary,
            ),
            SizedBox(width: theme.space(PaymentSpace.block)),
          ],
          Expanded(
            flex: value == null ? 1 : 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      (size == PaymentListItemSize.large
                              ? type.heading
                              : type.label)
                          .copyWith(color: foreground),
                ),
                if (detail != null) Text(detail, style: type.caption),
              ],
            ),
          ),
          if (value != null) ...[
            SizedBox(width: theme.space(PaymentSpace.group)),
            Flexible(
              flex: 2,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: line),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DefaultTextStyle.merge(
                    style: type.label.copyWith(color: theme.textPrimary),
                    textAlign: TextAlign.end,
                    child: value!,
                  ),
                ),
              ),
            ),
            if (enabled) SizedBox(width: theme.space(PaymentSpace.related)),
          ],
          if (trailing != null)
            // A minimum, never a fixed height, so a switch or a 48 dp
            // button keeps its own size.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: line),
              child: Center(child: trailing),
            )
          else if (enabled)
            const PaymentIcon(
              PaymentIcons.forward,
              color: PaymentTextColor.secondary,
            ),
        ],
      ),
    );
    return enabled || disabled
        ? Semantics(button: true, enabled: enabled, child: row)
        : MergeSemantics(child: row);
  }
}

/// A list of [PaymentListItem]s (or other rows) separated by hairlines. There is
/// no box around the group: it sits on the page surface like a section.
class PaymentList extends StatelessWidget {
  const PaymentList({super.key, required this.children, this.onAction});
  final ValueChanged<String>? onAction;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _PaymentListScope(
      onAction: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const PaymentDivider(),
            child,
          ],
        ],
      ),
    );
  }
}

class _PaymentListScope extends InheritedWidget {
  const _PaymentListScope({required this.onAction, required super.child});
  final ValueChanged<String>? onAction;
  @override
  bool updateShouldNotify(_PaymentListScope oldWidget) =>
      onAction != oldWidget.onAction;
}

/// Deprecated alias of [PaymentList].
@Deprecated('Use PaymentList. Removed in 0.2.0.')
typedef ActionTileGroup = PaymentList;

/// Deprecated wrapper: subtitle is secondaryTitle and onTap is onPressed.
@Deprecated('Use PaymentListItem. Removed in 0.2.0.')
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.disabledReason,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Defaults to a chevron when [onTap] is set.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) => PaymentListItem(
    title: title,
    secondaryTitle: subtitle,
    icon: icon,
    trailing: trailing,
    onPressed: onTap,
    destructive: destructive,
    disabledReason: disabledReason,
  );
}

/// One entry of a [PaymentMenu].
@immutable
abstract class PaymentMenuEntry {
  const PaymentMenuEntry._();
}

class PaymentMenuItem extends PaymentMenuEntry {
  const PaymentMenuItem({
    required this.label,
    this.onSelected,
    this.id,
    this.disabled = false,
    this.icon,
    this.destructive = false,
  }) : super._();

  final String? id;
  final bool disabled;
  final String label;
  final IconData? icon;

  /// Null shows the entry disabled.
  final VoidCallback? onSelected;
  final bool destructive;
}

/// A titled run of menu actions, separated from neighboring groups.
class PaymentMenuGroup extends PaymentMenuEntry {
  const PaymentMenuGroup({this.title, required this.items}) : super._();
  final String? title;
  final List<PaymentMenuItem> items;
}

/// Overflow menu behind an icon button.
///
/// Built on [MenuAnchor], so arrow keys move between entries, Escape closes
/// the menu and focus returns to the button. Opening is instant: a menu used
/// many times a day should not make people wait for it.
class PaymentMenu extends StatefulWidget {
  const PaymentMenu({
    super.key,
    required this.entries,
    this.onAction,
    this.icon = Icons.more_vert,
    this.tooltip,
    this.trigger,
  }) : assert(trigger == null || tooltip == null);

  /// Menu entries and groups.
  final List<PaymentMenuEntry> entries;

  /// Reports a selected entry identifier.
  final ValueChanged<String>? onAction;

  /// Default trigger glyph.
  final IconData icon;

  /// Spoken and shown on long-press; defaults to "More actions".
  final String? tooltip;

  /// Builds a button using toggle and focusNode for focus return.
  final Widget Function(VoidCallback toggle, FocusNode focusNode)? trigger;

  @override
  State<PaymentMenu> createState() => _PaymentMenuState();
}

class _PaymentMenuState extends State<PaymentMenu> {
  final _triggerFocus = FocusNode();
  @override
  void dispose() {
    _triggerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final onAction = widget.onAction;
    final icon = widget.icon;
    final tooltip = widget.tooltip;
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l10n = PaymentLocalizations.of(context);
    Widget menuItem(PaymentMenuItem entry) => MenuItemButton(
      leadingIcon: entry.icon == null
          ? null
          : PaymentIcon(
              entry.icon,
              color: entry.destructive
                  ? PaymentTextColor.danger
                  : PaymentTextColor.secondary,
            ),
      style: MenuItemButton.styleFrom(
        minimumSize: const Size(160, 48),
        maximumSize: Size(
          MediaQuery.sizeOf(context).width -
              2 * theme.space(PaymentSpace.group),
          double.infinity,
        ),
        foregroundColor: entry.destructive
            ? theme.danger.foreground
            : theme.textPrimary,
        textStyle: type.label,
      ),
      onPressed: entry.disabled
          ? null
          : entry.onSelected ??
                (entry.id != null && onAction != null
                    ? () => onAction(entry.id!)
                    : null),
      child: Text(entry.label, softWrap: true),
    );
    return MenuAnchor(
      childFocusNode: _triggerFocus,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(theme.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        side: WidgetStatePropertyAll(BorderSide(color: theme.outline)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: theme.controlBorderRadius),
        ),
      ),
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        final built =
            widget.trigger?.call(toggle, _triggerFocus) ??
            PaymentIconButton(
              focusNode: _triggerFocus,
              icon: icon,
              tooltip: tooltip ?? l10n.moreActions,
              onPressed: toggle,
            );
        assert(built is PaymentButton || built is PaymentIconButton);
        return built;
      },
      menuChildren: [
        for (final (i, entry) in entries.indexed) ...[
          if (i > 0 &&
              (entry is PaymentMenuGroup || entries[i - 1] is PaymentMenuGroup))
            const PaymentDivider(),
          if (entry is PaymentMenuGroup) ...[
            if (entry.title != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  theme.space(PaymentSpace.block),
                  theme.space(PaymentSpace.related),
                  theme.space(PaymentSpace.block),
                  theme.space(PaymentSpace.inline),
                ),
                child: Semantics(
                  header: true,
                  child: Text(entry.title!, style: type.caption),
                ),
              ),
            for (final item in entry.items) menuItem(item),
          ] else if (entry is PaymentMenuItem)
            menuItem(entry),
        ],
      ],
    );
  }
}

/// Deprecated alias of [PaymentMenu].
@Deprecated('Use PaymentMenu. Removed in 0.2.0.')
typedef ActionMenu = PaymentMenu;

/// Deprecated alias of [PaymentMenuItem].
@Deprecated('Use PaymentMenuItem. Removed in 0.2.0.')
typedef ActionMenuEntry = PaymentMenuItem;

/// Asks before an action that cannot be undone. Resolves to true only when
/// the person confirms; dismissing, Back and Escape all resolve to false.
///
/// For [destructive] actions the safe choice (cancel) receives focus first,
/// so Enter never confirms by accident.
Future<bool> showPaymentConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = PaymentTheme.of(context);
      final l10n = PaymentLocalizations.of(context);
      final type = PaymentType.of(context);
      // One filled button: the confirm action, in the danger tone when it
      // cannot be undone. Cancel stays a quiet text button.
      return AlertDialog(
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: theme.sheetBorderRadius),
        title: Text(title, style: type.title),
        content: Text(
          message,
          style: type.bodyFor(context).copyWith(color: theme.textSecondary),
        ),
        actionsPadding: EdgeInsets.all(theme.space(PaymentSpace.group)),
        actions: [
          PaymentButtonGroup(
            collapse: PaymentButtonGroupCollapse.none,
            children: [
              PaymentButton(
                label: cancelLabel ?? l10n.cancel,
                variant: PaymentButtonVariant.quiet,
                width: PaymentWidth.hug,
                autofocus: destructive,
                onPressed: () => Navigator.pop(context, false),
              ),
              PaymentButton(
                label: confirmLabel,
                variant: destructive
                    ? PaymentButtonVariant.destructive
                    : PaymentButtonVariant.primary,
                width: PaymentWidth.hug,
                autofocus: !destructive,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Controls one toast from [showPaymentToast].
class PaymentToastController {
  PaymentToastController._(this._state, this._hasAction, this._waitForUser);
  final ValueNotifier<_ToastState> _state;
  final bool _hasAction;
  final bool _waitForUser;
  late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _feature;
  Timer? _timer;
  bool _visible = false;
  bool _closed = false;
  bool _dismissRequested = false;

  /// Completes when the toast leaves the screen.
  Future<void> get closed => _feature.closed.then((_) {});

  /// Replaces the entire state in place and restarts its reading time.
  void update(
    String message, {
    StatusTone tone = StatusTone.neutral,
    bool pending = false,
  }) {
    if (_closed) return;
    _state.value = _ToastState(message, tone, pending);
    _schedule();
  }

  /// Safe before visibility, after closing, and when called repeatedly.
  void dismiss() {
    if (_closed) return;
    if (!_visible) {
      _dismissRequested = true;
      return;
    }
    _timer?.cancel();
    _feature.close();
  }

  void _detach() {
    _timer?.cancel();
    _closed = true;
  }

  void _onVisible() {
    _visible = true;
    if (_dismissRequested) {
      dismiss();
    } else {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_closed ||
        !_visible ||
        _state.value.pending ||
        (_hasAction && _waitForUser)) {
      return;
    }
    final words = _state.value.message.trim().split(RegExp(r'\s+')).length;
    final ms = (1000 + 300 * words).clamp(_hasAction ? 6000 : 4000, 10000);
    _timer = Timer(Duration(milliseconds: ms), dismiss);
  }
}

class _ToastState {
  const _ToastState(this.message, this.tone, this.pending);
  final String message;
  final StatusTone tone;
  final bool pending;
}

/// Short feedback after an action. Failures requiring a fix use [PaymentBanner].
/// Neutral, success, warning, or pending. Reading time is 4–10 seconds,
/// at least 6 with an action; pending and accessible actions never time out.
PaymentToastController showPaymentToast(
  BuildContext context, {
  required String message,
  StatusTone tone = StatusTone.neutral,
  bool pending = false,
  String? actionLabel,
  VoidCallback? onAction,
}) => _showToast(
  context,
  message: message,
  tone: tone,
  pending: pending,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// Deprecated wrapper of [showPaymentToast] returning the Material controller.
@Deprecated('Use showPaymentToast. Removed in 0.2.0.')
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showPaymentSnackBar(
  BuildContext context, {
  required String message,
  StatusTone tone = StatusTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) => _showToast(
  context,
  message: message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
)._feature;

PaymentToastController _showToast(
  BuildContext context, {
  required String message,
  StatusTone tone = StatusTone.neutral,
  bool pending = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final theme = PaymentTheme.of(context);
  final hasAction = actionLabel != null && onAction != null;
  final controller = PaymentToastController._(
    ValueNotifier(_ToastState(message, tone, pending)),
    hasAction,
    MediaQuery.maybeAccessibleNavigationOf(context) ?? false,
  );
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  controller._feature = messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      persist: true,
      backgroundColor: theme.textPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: theme.controlBorderRadius),
      margin: EdgeInsets.fromLTRB(
        theme.space(PaymentSpace.group),
        0,
        theme.space(PaymentSpace.group),
        theme.space(PaymentSpace.group),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.space(PaymentSpace.group),
        theme.space(PaymentSpace.related),
        hasAction
            ? theme.space(PaymentSpace.related)
            : theme.space(PaymentSpace.group),
        theme.space(PaymentSpace.related),
      ),
      onVisible: controller._onVisible,
      content: _ToastContent(
        controller: controller,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    ),
    snackBarAnimationStyle: PaymentMotion.of(context).reduced
        ? AnimationStyle.noAnimation
        : null,
  );
  controller._feature.closed.then((_) => controller._detach());
  return controller;
}

class _ToastContent extends StatefulWidget {
  const _ToastContent({
    required this.controller,
    this.actionLabel,
    this.onAction,
  });
  final PaymentToastController controller;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  State<_ToastContent> createState() => _ToastContentState();
}

class _ToastContentState extends State<_ToastContent> {
  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final iconSize = PaymentIconSize.medium.resolve(context);
    return ValueListenableBuilder<_ToastState>(
      valueListenable: widget.controller._state,
      builder: (context, state, _) => DefaultTextStyle(
        style: type.label.copyWith(color: theme.surface),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: iconSize,
                height: PaymentType.firstLineHeight(context),
                child: Center(
                  child: state.pending
                      ? PaymentSpinner(
                          size: PaymentSize.small,
                          color: theme.surface,
                        )
                      : Icon(
                          toneIcon(state.tone),
                          size: iconSize,
                          color: theme.surface,
                        ),
                ),
              ),
            ),
            SizedBox(width: theme.space(PaymentSpace.block)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: theme.space(PaymentSpace.inline),
                ),
                child: Text(state.message),
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              SizedBox(width: theme.space(PaymentSpace.related)),
              PaymentFocusRing(
                radius: theme.controlBorderRadius,
                color: theme.surface,
                child: TextButton(
                  onPressed: () {
                    widget.controller.dismiss();
                    widget.onAction!();
                  },
                  style: PaymentFocusRing.withoutFocusFill(
                    TextButton.styleFrom(
                      foregroundColor: theme.surface,
                      textStyle: type.label.copyWith(
                        fontWeight: type.heading.fontWeight,
                      ),
                      minimumSize: const Size(48, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.space(PaymentSpace.block),
                      ),
                    ),
                  ),
                  child: Text(widget.actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A titled section whose body can be shown or hidden.
///
/// Works uncontrolled ([initiallyExpanded]) or controlled ([expanded] plus
/// [onExpandedChanged]). Hidden content is removed from the tree, so it is
/// never reachable by Tab or a screen reader. Do not hide fees here: the
/// payment summary keeps every fee visible by design.
class PaymentAccordionItem extends StatefulWidget {
  const PaymentAccordionItem({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    @Deprecated('Use media: PaymentIcon(icon). Removed in 0.2.0.') this.leading,
    this.media,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.actions = const [],
  });

  /// actions for this section.
  final List<Widget> actions;

  /// title for this section.
  final String title;

  /// subtitle for this section.
  final String? subtitle;

  /// Header icon or image.
  final Widget? media;

  /// Legacy header glyph; use media.
  @Deprecated('Use media: PaymentIcon(icon). Removed in 0.2.0.')
  final IconData? leading;

  /// child for this section.
  final Widget child;

  /// Controlled state. When null the section keeps its own state.
  final bool? expanded;

  /// initiallyExpanded for this section.
  final bool initiallyExpanded;

  /// onExpandedChanged for this section.
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<PaymentAccordionItem> createState() => _PaymentAccordionItemState();
}

class _PaymentAccordionItemState extends State<PaymentAccordionItem> {
  late bool _expanded = widget.initiallyExpanded;

  // ignore: deprecated_member_use_from_same_package
  Widget? get _media =>
      widget.media ??
      (widget.leading == null
          ? null
          : PaymentIcon(widget.leading!, color: PaymentTextColor.secondary));

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.actions.where((a) => a is! PaymentMenu).length <= 2 &&
          widget.actions.whereType<PaymentMenu>().length <= 1 &&
          widget.actions.every(
            (a) =>
                a is PaymentMenu ||
                (a is PaymentButton &&
                    a.size == PaymentSize.small &&
                    a.width == PaymentWidth.hug),
          ),
      'Accordion actions need up to two small hug buttons and one menu.',
    );
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final motion = PaymentMotion.of(context);
    final type = PaymentType.of(context);
    // ignore: deprecated_member_use_from_same_package
    assert(widget.media == null || widget.leading == null);
    assert(
      widget.media == null ||
          widget.media is PaymentIcon ||
          widget.media is PaymentImage,
    );
    final open = _isExpanded;
    // Flat: no box, only a hairline under the section, so consecutive
    // sections read as one ruled list.
    final header = Semantics(
      button: true,
      expanded: open,
      hint: open ? l10n.collapse : l10n.expand,
      child: PaymentFocusRing(
        radius: BorderRadius.zero,
        child: InkWell(
          focusColor: Colors.transparent,
          onTap: _toggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: theme.space(PaymentSpace.block),
              ),
              child: Row(
                children: [
                  if (_media != null) ...[
                    _media is PaymentImage
                        ? SizedBox.square(dimension: kMediaTile, child: _media)
                        : _media!,
                    SizedBox(width: theme.space(PaymentSpace.block)),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: type.heading),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!, style: type.caption),
                      ],
                    ),
                  ),
                  SizedBox(width: theme.space(PaymentSpace.related)),
                  // Rotation is a transform: no layout, no repaint of
                  // the row. 150 ms, the same as other state changes.
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: motion.quick,
                    curve: PaymentMotion.easeOut,
                    child: const PaymentIcon(
                      Icons.expand_more,
                      color: PaymentTextColor.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.actions.isEmpty)
            header
          else
            LayoutBuilder(
              builder: (context, box) =>
                  box.maxWidth < 400 || PaymentType.isLarge(context)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: theme.space(PaymentSpace.related),
                          ),
                          child: Wrap(
                            spacing: theme.space(PaymentSpace.related),
                            runSpacing: theme.space(PaymentSpace.related),
                            children: widget.actions,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: header),
                        SizedBox(width: theme.space(PaymentSpace.related)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final (i, action)
                                in widget.actions.indexed) ...[
                              if (i > 0)
                                SizedBox(
                                  width: theme.space(PaymentSpace.related),
                                ),
                              action,
                            ],
                          ],
                        ),
                      ],
                    ),
            ),
          // Size eases so the content below does not jump; collapses to an
          // instant change under reduced motion.
          AnimatedSize(
            duration: motion.enter,
            reverseDuration: motion.exit,
            curve: PaymentMotion.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: theme.space(PaymentSpace.group),
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A ruled list of disclosure items; items own their hairlines.
class PaymentAccordion extends StatelessWidget {
  const PaymentAccordion({super.key, required this.children});
  final List<PaymentAccordionItem> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

/// Deprecated alias of [PaymentAccordionItem].
@Deprecated('Use PaymentAccordionItem. Removed in 0.2.0.')
typedef ExpandableSection = PaymentAccordionItem;

/// Placeholder blocks shaped like the content that is loading.
///
/// Deliberately static: a shimmer repaints every frame for as long as the
/// load takes and says nothing a still placeholder doesn't. Announced once as
/// "Loading" instead of as empty boxes.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.rows = 3,
    this.leading = true,
    this.semanticLabel,
  }) : columns = null;

  /// Table placeholders collapse to list rows on narrow surfaces.
  const LoadingSkeleton.table({
    super.key,
    this.rows = 5,
    this.columns = 3,
    this.semanticLabel,
  }) : leading = false,
       assert(columns != null && columns >= 2);

  /// Table column count, or null for a list placeholder.
  final int? columns;

  /// Number of placeholder rows.
  final int rows;

  /// Shows a small square before each row, where a row's icon would be.
  final bool leading;

  /// Spoken loading description, defaulting to localized Loading.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final fill = theme.surfaceMuted;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: theme.tagBorderRadius,
        ),
      ),
    );
    if (columns != null) {
      return LayoutBuilder(
        builder: (context, k) {
          if (tableIsNarrow(context, k)) {
            return LoadingSkeleton(
              rows: rows,
              leading: false,
              semanticLabel: semanticLabel,
            );
          }
          final height =
              PaymentType.firstLineHeight(context) +
              2 * theme.space(PaymentSpace.block);
          return Semantics(
            label: semanticLabel ?? l10n.loading,
            container: true,
            child: ExcludeSemantics(
              child: Column(
                children: [
                  for (var r = 0; r <= rows; r++)
                    Container(
                      height: height < 48 ? 48 : height,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.outline),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var c = 0; c < columns!; c++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  theme.space(PaymentSpace.related),
                                ),
                                child: bar(0.5, r == 0 ? 10 : 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Semantics(
      label: semanticLabel ?? l10n.loading,
      container: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: theme.space(PaymentSpace.related),
                ),
                child: Row(
                  children: [
                    if (leading) ...[
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: theme.tagBorderRadius,
                        ),
                      ),
                      SizedBox(width: theme.space(PaymentSpace.block)),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(i.isEven ? 0.7 : 0.55, 14),
                          SizedBox(height: theme.space(PaymentSpace.related)),
                          bar(0.4, 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty, error and "nothing matches" states: what happened, one line on
/// why, and at most one way forward. Compact and left-aligned, so it reads
/// as part of the list it replaces rather than as an illustration.
/// Padded by `group` (16) above and below.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = StatusTone.neutral,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// [StatusTone.danger] announces the message when it appears. The headline
  /// carries the meaning, so the icon stays muted in every tone.
  final StatusTone tone;
  final String? actionLabel;
  final FutureOr<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return Semantics(
      container: true,
      liveRegion: tone == StatusTone.danger,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: theme.space(PaymentSpace.group),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: PaymentIcon(icon, color: PaymentTextColor.secondary),
            ),
            SizedBox(width: theme.space(PaymentSpace.block)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.heading),
                  if (message != null) ...[
                    SizedBox(height: theme.space(PaymentSpace.inline)),
                    Text(
                      message!,
                      style: type.body.copyWith(color: theme.textSecondary),
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    SizedBox(height: theme.space(PaymentSpace.block)),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: PaymentButton(
                        label: actionLabel!,
                        variant: PaymentButtonVariant.secondary,
                        onPressed: onAction,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
