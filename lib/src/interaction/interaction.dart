import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';

/// A tappable row for settings, menus and action lists.
///
/// The row is flat: a plain outlined icon, a title and a muted detail line,
/// with no container. Put consecutive tiles in an [ActionTileGroup] so they
/// are separated by hairlines.
///
/// Disabled rows stay visible; pass [disabledReason] so people know why.
/// [destructive] uses the danger tone for both icon and label, never color
/// alone: the label must already say what happens.
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
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final enabled = onTap != null;
    final danger = destructive && enabled;
    final foreground = !enabled
        ? theme.textSecondary
        : danger
        ? theme.danger.foreground
        : theme.textPrimary;
    final detail = !enabled && disabledReason != null
        ? disabledReason
        : subtitle;
    // Icon and chevron center on the title's first line, not on the whole
    // block, so multi-line rows at large text keep them beside the title.
    final scaler = MediaQuery.textScalerOf(context);
    final line = scaler.scale(15) * 20 / 15;
    final iconSize = scaler.clamp(maxScaleFactor: 1.6).scale(20);
    return Semantics(
      button: true,
      enabled: enabled,
      child: PaymentFocusRing(
        radius: BorderRadius.zero,
        child: InkWell(
          focusColor: Colors.transparent,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            // Keeps a one-line row centered in the 48 dp minimum now that the
            // row itself aligns to the top.
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: theme.spacing * 1.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      SizedBox(
                        width: iconSize,
                        height: line,
                        child: Center(
                          child: Icon(
                            icon,
                            size: iconSize,
                            color: danger
                                ? theme.danger.foreground
                                : theme.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: theme.spacing * 1.5),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: type.label.copyWith(color: foreground),
                          ),
                          if (detail != null) Text(detail, style: type.caption),
                        ],
                      ),
                    ),
                    if (trailing != null)
                      // A minimum, never a fixed height, so a switch or a 48 dp
                      // button keeps its own size.
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: line),
                        child: Center(child: trailing),
                      )
                    else if (enabled)
                      SizedBox(
                        height: line,
                        child: Center(
                          child: ExcludeSemantics(
                            child: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                              size: 20,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A list of [ActionTile]s (or other rows) separated by hairlines. There is
/// no box around the group: it sits on the page surface like a section.
class ActionTileGroup extends StatelessWidget {
  const ActionTileGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: theme.outline),
          child,
        ],
      ],
    );
  }
}

/// One entry of an [ActionMenu].
@immutable
class ActionMenuEntry {
  const ActionMenuEntry({
    required this.label,
    required this.onSelected,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;

  /// Null shows the entry disabled.
  final VoidCallback? onSelected;
  final bool destructive;
}

/// Overflow menu behind an icon button.
///
/// Built on [MenuAnchor], so arrow keys move between entries, Escape closes
/// the menu and focus returns to the button. Opening is instant: a menu used
/// many times a day should not make people wait for it.
class ActionMenu extends StatelessWidget {
  const ActionMenu({
    super.key,
    required this.entries,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  final List<ActionMenuEntry> entries;
  final IconData icon;

  /// Spoken and shown on long-press; defaults to "More actions".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l10n = PaymentLocalizations.of(context);
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(theme.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        side: WidgetStatePropertyAll(BorderSide(color: theme.outline)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: theme.controlBorderRadius),
        ),
      ),
      builder: (context, controller, _) => PaymentFocusRing(
        radius: BorderRadius.circular(24),
        child: IconButton(
          style: PaymentFocusRing.withoutFocusFill(const ButtonStyle()),
          tooltip: tooltip ?? l10n.moreActions,
          icon: Icon(icon),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
      menuChildren: [
        for (final entry in entries)
          MenuItemButton(
            leadingIcon: entry.icon == null
                ? null
                : Icon(
                    entry.icon,
                    size: 20,
                    color: entry.destructive
                        ? theme.danger.foreground
                        : theme.textSecondary,
                  ),
            style: MenuItemButton.styleFrom(
              minimumSize: const Size(160, 48),
              foregroundColor: entry.destructive
                  ? theme.danger.foreground
                  : theme.textPrimary,
              textStyle: type.label,
            ),
            onPressed: entry.onSelected,
            child: Text(entry.label),
          ),
      ],
    );
  }
}

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
      final shape = RoundedRectangleBorder(
        borderRadius: theme.controlBorderRadius,
      );
      const minimumSize = Size(48, 48);
      final label = type.heading;
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
        actions: [
          TextButton(
            autofocus: destructive,
            style: TextButton.styleFrom(
              foregroundColor: theme.accent,
              minimumSize: minimumSize,
              shape: shape,
              textStyle: label,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel ?? l10n.cancel),
          ),
          FilledButton(
            autofocus: !destructive,
            style: FilledButton.styleFrom(
              backgroundColor: destructive
                  ? theme.danger.foreground
                  : theme.accent,
              foregroundColor: destructive ? theme.surface : theme.onAccent,
              minimumSize: minimumSize,
              shape: shape,
              textStyle: label,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Short feedback after an action ("Copied", "Share canceled").
///
/// The tone adds an icon so the message is not carried by color alone.
/// Snack bars are announced by screen readers automatically.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showPaymentSnackBar(
  BuildContext context, {
  required String message,
  StatusTone tone = StatusTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final theme = PaymentTheme.of(context);
  final icon = switch (tone) {
    StatusTone.success => Icons.check_circle_outline,
    StatusTone.warning => Icons.warning_amber_rounded,
    StatusTone.danger => Icons.error_outline,
    StatusTone.info || StatusTone.neutral => Icons.info_outline,
  };
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: theme.controlBorderRadius),
      content: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20)),
          SizedBox(width: theme.spacing * 1.5),
          Expanded(child: Text(message)),
        ],
      ),
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}

/// A titled section whose body can be shown or hidden.
///
/// Works uncontrolled ([initiallyExpanded]) or controlled ([expanded] plus
/// [onExpandedChanged]). Hidden content is removed from the tree, so it is
/// never reachable by Tab or a screen reader. Do not hide fees here: the
/// payment summary keeps every fee visible by design.
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget child;

  /// Controlled state. When null the section keeps its own state.
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final motion = PaymentMotion.of(context);
    final type = PaymentType.of(context);
    final open = _isExpanded;
    // Flat: no box, only a hairline under the section, so consecutive
    // sections read as one ruled list.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
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
                      vertical: theme.spacing * 1.5,
                    ),
                    child: Row(
                      children: [
                        if (widget.leading != null) ...[
                          Icon(
                            widget.leading,
                            size: 20,
                            color: theme.textSecondary,
                          ),
                          SizedBox(width: theme.spacing * 1.5),
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
                        SizedBox(width: theme.spacing),
                        // Rotation is a transform: no layout, no repaint of
                        // the row. 150 ms, the same as other state changes.
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: motion.quick,
                          curve: PaymentMotion.easeOut,
                          child: Icon(
                            Icons.expand_more,
                            size: 20,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                    padding: EdgeInsets.only(bottom: theme.spacing * 2),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

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
  });

  final int rows;

  /// Shows a small square before each row, where a row's icon would be.
  final bool leading;
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
    return Semantics(
      label: semanticLabel ?? l10n.loading,
      container: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.spacing),
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
                      SizedBox(width: theme.spacing * 1.5),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(i.isEven ? 0.7 : 0.55, 14),
                          SizedBox(height: theme.spacing),
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
    final scaler = MediaQuery.textScalerOf(context);
    final line = scaler.scale(15) * 20 / 15;
    final iconSize = scaler.clamp(maxScaleFactor: 1.6).scale(20);
    return Semantics(
      container: true,
      liveRegion: tone == StatusTone.danger,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing * 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: iconSize,
                height: line,
                child: Center(
                  child: Icon(icon, size: iconSize, color: theme.textSecondary),
                ),
              ),
            ),
            SizedBox(width: theme.spacing * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.heading),
                  if (message != null) ...[
                    SizedBox(height: theme.spacing * 0.5),
                    Text(
                      message!,
                      style: type.body.copyWith(color: theme.textSecondary),
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    SizedBox(height: theme.spacing * 1.5),
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
