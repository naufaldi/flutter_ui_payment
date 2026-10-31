import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
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
    required this.label,
    this.description,
    this.disabledReason,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// What checking the box agrees to, as a full phrase: "Save this card for
  /// next time", not "Save".
  final String label;

  /// A muted line under the label.
  final String? description;

  /// Replaces [description] while the row is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final enabled = onChanged != null;
    return MergeSemantics(
      child: Semantics(
        checked: value,
        enabled: enabled,
        child: _ControlRow(
          label: label,
          detail: !enabled && disabledReason != null
              ? disabledReason
              : description,
          enabled: enabled,
          onTap: enabled ? () => onChanged!(!value) : null,
          // Painted by Material, so it matches the kit's other checkboxes;
          // the row owns taps, focus and semantics.
          mark: Checkbox(
            value: value,
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
  });

  final T value;
  final T? groupValue;

  /// Called with [value] when this option is chosen. Null disables it.
  final ValueChanged<T>? onChanged;
  final String label;
  final String? description;

  /// Replaces [description] while the option is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final enabled = onChanged != null;
    final selected = value == groupValue;
    final color = !enabled
        ? theme.disabled
        : selected
        ? theme.accent
        : theme.textSecondary;
    return MergeSemantics(
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        enabled: enabled,
        child: _ControlRow(
          label: label,
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
          mark: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: selected ? 6 : 1.5),
            ),
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
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;

  /// Replaces [description] while the row is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final enabled = onChanged != null;
    return MergeSemantics(
      child: Semantics(
        toggled: value,
        enabled: enabled,
        child: _ControlRow(
          label: label,
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
  });

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
    // The mark centers on the label's first line, as ActionTile's icon does.
    final line = MediaQuery.textScalerOf(context).scale(15) * 20 / 15;
    // The row takes taps, focus and semantics; the painted mark takes none.
    final painted = ExcludeFocus(
      child: IgnorePointer(child: ExcludeSemantics(child: mark)),
    );
    return PaymentFocusRing(
      radius: BorderRadius.zero,
      child: InkWell(
        focusColor: Colors.transparent,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: theme.spacing * 1.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!markAtEnd) ...[
                    SizedBox(
                      width: 20,
                      height: line,
                      child: OverflowBox(
                        maxWidth: 48,
                        maxHeight: 48,
                        child: painted,
                      ),
                    ),
                    SizedBox(width: theme.spacing * 1.5),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: type.label.copyWith(
                            color: enabled
                                ? theme.textPrimary
                                : theme.textSecondary,
                          ),
                        ),
                        if (detail != null) Text(detail!, style: type.caption),
                      ],
                    ),
                  ),
                  if (markAtEnd) ...[
                    SizedBox(width: theme.spacing * 2),
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: line),
                      child: Center(child: painted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text tabs on a hairline, for switching between views of the same
/// content: filters of a list, or "Card" and "Bank transfer" details.
///
/// Controlled: the host owns [selectedIndex] and shows the matching content.
/// The selected tab changes color and gains an underline; the weight stays
/// the same so labels do not shift. The row scrolls sideways rather than
/// wrapping, so long or enlarged labels never stack.
class PaymentTabs extends StatelessWidget {
  const PaymentTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Short nouns, one or two words each.
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.outline)),
      ),
      // The row clips at its sides only, so a focused tab's ring, which sits
      // 4 px outside it, shows above and below; the 4 px inset keeps the
      // first and last rings inside the sides.
      child: ClipRect(
        clipper: const _SidesClipper(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              for (final (i, label) in labels.indexed)
                _Tab(
                  label: label,
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        button: true,
        child: PaymentFocusRing(
          radius: BorderRadius.zero,
          child: PaymentPressScale(
            child: InkWell(
              focusColor: Colors.transparent,
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                padding: EdgeInsets.symmetric(horizontal: theme.spacing * 1.5),
                alignment: Alignment.center,
                // The unselected underline is transparent, not absent, so the
                // tab keeps its height when selected.
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
                  label,
                  style: PaymentType.of(context).label.copyWith(
                    color: selected ? theme.accent : theme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

/// A short hint shown on long press, hover or keyboard focus, in ink on the
/// page with the caption type.
///
/// A tooltip is easy to miss on touch screens, so it may only repeat or name
/// something: an icon button's label, a full date behind "2d ago". Never put
/// a fee, a requirement or an error only in a tooltip.
class PaymentTooltip extends StatelessWidget {
  const PaymentTooltip({super.key, required this.message, required this.child});

  /// One short sentence or a label. Also what screen readers hear.
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Tooltip(
      message: message,
      // Ink on paper, inverted: the strongest contrast the theme has.
      decoration: BoxDecoration(
        color: theme.textPrimary,
        borderRadius: theme.controlBorderRadius,
      ),
      textStyle: PaymentType.of(context).caption.copyWith(color: theme.surface),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing,
        vertical: theme.spacing * 0.5,
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}
