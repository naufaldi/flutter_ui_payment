import '../foundation/payment_icons.dart';
import '../foundation/payment_tokens.dart';
import 'dart:math' as math;
import '../controls/actions.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'focus_ring.dart';
import 'hatch.dart';
import 'kit_strings.dart';
import 'money.dart';
import 'payment_localizations.dart';
import 'payment_motion.dart';
import 'payment_theme.dart';
import 'payment_type.dart';
import 'token_resolvers.dart';
import 'tap_target.dart';

/// The five amount looks. Nothing else exists.
enum AmountTextVariant {
  /// 13/18 caption for legends and meta lines.
  caption,

  /// 15/20 regular label for line items. Default.
  row,

  /// 15/20 at heading weight for Total values.
  total,

  /// 20/28 headline amount, capped at 1.6 times text scale.
  large,

  /// 32/36 display amount, capped at 1.6 times text scale.
  display,
}

/// Renders [Money] with the active locale's formatter and a spoken label.
class AmountText extends StatelessWidget {
  const AmountText(
    this.money, {
    super.key,
    this.style,
    this.variant = AmountTextVariant.row,
    @Deprecated('Use variant: AmountTextVariant.display. Removed in 0.2.0.')
    this.emphasis = false,
  }) : assert(!emphasis || variant == AmountTextVariant.row);

  final Money money;

  /// Color and decoration only: muted or struck amounts.
  final TextStyle? style;

  /// Semantic amount role. Default is the regular row label.
  final AmountTextVariant variant;

  /// Legacy display amount, replaced by the display variant.
  @Deprecated('Use variant: AmountTextVariant.display. Removed in 0.2.0.')
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final row = type.label.tabular.copyWith(fontFamily: theme.amountFontFamily);
    // ignore: deprecated_member_use_from_same_package
    final effective = emphasis ? AmountTextVariant.display : variant;
    final base = switch (effective) {
      AmountTextVariant.caption => row.merge(type.caption),
      AmountTextVariant.row => row,
      AmountTextVariant.total => row.copyWith(
        fontWeight: type.heading.fontWeight,
      ),
      AmountTextVariant.large => row.merge(type.amountLarge),
      AmountTextVariant.display => type.display,
    };
    final merged = base.merge(style);
    // Large amounts (20 px and up) follow text scaling only up to 1.6×, as
    // platform large titles do. Any amount that still does not fit scales
    // down instead of being clipped: a hidden digit is worse than a smaller
    // one.
    final scaler =
        effective == AmountTextVariant.display || (merged.fontSize ?? 0) >= 20
        ? MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6)
        : null;
    return Semantics(
      label: l10n.moneyFormat.spoken(money),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          l10n.moneyFormat.format(money),
          style: merged,
          textAlign: TextAlign.end,
          textScaler: scaler,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}

/// Single-line text that, when too long, keeps both ends and elides the
/// middle: `ktp_demo_ret…ake.png`. Use it for file names, references and IDs
/// whose start and extension both matter. Screen readers get the full text.
class MiddleEllipsisText extends StatelessWidget {
  const MiddleEllipsisText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.end,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool fits(String value) {
          final painter = TextPainter(
            text: TextSpan(text: value, style: effective),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width <= constraints.maxWidth;
        }

        var shown = text;
        if (constraints.hasBoundedWidth && !fits(text)) {
          final chars = text.characters.toList();
          final dot = text.lastIndexOf('.');
          // Keep the extension plus a few characters before it visible.
          final minTail = dot > 0 ? (text.length - dot + 3) : 4;
          String elide(int keep) {
            final tail = keep < minTail
                ? keep ~/ 2
                : (keep ~/ 2).clamp(minTail, keep);
            final head = keep - tail;
            return '${chars.take(head).join()}…${chars.skip(chars.length - tail).join()}';
          }

          var low = 1;
          var high = chars.length - 1;
          shown = elide(1);
          while (low <= high) {
            final mid = (low + high) ~/ 2;
            final candidate = elide(mid);
            if (fits(candidate)) {
              shown = candidate;
              low = mid + 1;
            } else {
              high = mid - 1;
            }
          }
        }
        return Semantics(
          label: text,
          excludeSemantics: true,
          child: Text(
            shown,
            style: style,
            textAlign: textAlign,
            maxLines: 1,
            softWrap: false,
          ),
        );
      },
    );
  }
}

/// A label/value row. At large text scales the value moves under the label
/// only when the two do not fit on one line, so long labels and big amounts
/// never overflow and short rows stay one line.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueText,
    this.emphasis = false,
    this.caption,
    this.trailing,
  }) : assert(value != null || valueText != null);

  final String label;
  final Widget? value;
  final String? valueText;
  final String? caption;
  final bool emphasis;

  /// Optional action after the value, such as a 48 dp copy button. Label and
  /// value keep the top line; the action centers against them.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final large = PaymentType.isLarge(context);
    final labelStyle = emphasis
        ? type.heading
        : type.label.copyWith(color: theme.textSecondary);
    final valueWidget =
        value ??
        Text(
          valueText!,
          // A value that wraps under its label at large text starts at the
          // left edge, as the label does.
          textAlign: large ? TextAlign.start : TextAlign.end,
          style: type.label,
        );
    final labelWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        if (caption != null) Text(caption!, style: type.caption),
      ],
    );
    final Widget row = large
        // Label and value share a line when they fit; otherwise the value
        // starts the next line instead of every row stacking. Full width, so
        // spaceBetween pushes a value that fits to the end edge like the
        // normal-size row, instead of hugging the label.
        ? SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: theme.space(PaymentSpace.group),
              runSpacing: theme.space(PaymentSpace.inline),
              children: [labelWidget, valueWidget],
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: labelWidget),
                SizedBox(width: theme.space(PaymentSpace.group)),
                // The value keeps its natural width up to 60% of the row
                // and the label wraps in what is left, so a short label
                // never squeezes a file name or reference into breaking
                // mid-word. Amounts keep their natural width.
                if (value is AmountText)
                  valueWidget
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.6,
                    ),
                    child: valueWidget,
                  ),
              ],
            ),
          );
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.space(PaymentSpace.related),
      ),
      child: MergeSemantics(
        child: trailing == null
            ? row
            : Row(
                children: [
                  Expanded(child: row),
                  trailing!,
                ],
              ),
      ),
    );
  }
}

/// How much weight a [PaymentButton] carries. Use one [primary] per screen.
enum PaymentButtonVariant {
  /// The one main action: filled with the accent.
  primary,

  /// An alternative to the main action: outlined.
  secondary,

  /// A low-emphasis action such as "Cancel" or "Not now": text only.
  quiet,

  /// An action that cannot be undone, such as removing a saved card: filled
  /// in the danger tone. The label must say what happens, so color is never
  /// the only signal. Usually the confirm step after a
  /// [showPaymentConfirmDialog], never the pay button.
  destructive,
}

/// Button with consistent idle/busy/disabled feedback.
///
/// When [onPressed] returns a Future the button locks itself until it
/// completes, so only one callback is active at a time. This is interaction
/// protection; hosts still deduplicate on the server.
class PaymentButton extends StatefulWidget {
  const PaymentButton({
    super.key,
    this.focusNode,
    required this.label,
    required this.onPressed,
    this.variant = PaymentButtonVariant.primary,
    this.size = PaymentSize.medium,
    this.width = PaymentWidth.fill,
    this.autofocus = false,
    this.busy = false,
    this.busyLabel,
    this.icon,
  });

  /// Host focus node, for example for menu focus return.
  final FocusNode? focusNode;

  /// Specific outcome of pressing the button. Wraps rather than truncates.
  final String label;

  /// Called once per action; null disables the button. Futures lock repeat presses.
  final FutureOr<void> Function()? onPressed;

  /// Visual priority: one primary action per view.
  final PaymentButtonVariant variant;

  /// Drawn height: small 36, medium 48, large 56 dp. Hit box stays at least 48.
  final PaymentSize size;

  /// Fill the parent or hug the wrapped label, at least 112 dp wide.
  final PaymentWidth width;

  /// Initial route focus, useful for the safe choice in destructive dialogs.
  final bool autofocus;

  /// Externally owned busy state, e.g. a submit the coordinator is running.
  final bool busy;

  /// Spoken status while busy, defaulting to the localized working label.
  final String? busyLabel;

  /// Optional leading icon in the label color.
  final IconData? icon;

  @override
  State<PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<PaymentButton> {
  bool _running = false;

  bool get _busy => _running || widget.busy;

  Future<void> _handle() async {
    if (_busy) return;
    final result = widget.onPressed?.call();
    if (result is Future) {
      setState(() => _running = true);
      try {
        await result;
      } finally {
        if (mounted) setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l10n = PaymentLocalizations.of(context);
    final enabled = widget.onPressed != null;
    final motion = PaymentMotion.of(context);
    final foreground = switch (widget.variant) {
      PaymentButtonVariant.primary => theme.onAccent,
      PaymentButtonVariant.destructive => theme.surface,
      _ => theme.accent,
    };
    final m = MediaQuery.textScalerOf(context).scale(14) / 14;
    final metrics = switch (widget.size) {
      PaymentSize.small => (
        height: 36.0,
        padding: ButtonStyleButton.scaledPadding(
          EdgeInsets.symmetric(horizontal: theme.space(PaymentSpace.block)),
          EdgeInsets.symmetric(horizontal: theme.space(PaymentSpace.related)),
          EdgeInsets.symmetric(horizontal: theme.space(PaymentSpace.inline)),
          m,
        ),
        icon: PaymentIconSize.small.resolve(context),
      ),
      PaymentSize.medium => (height: 48.0, padding: null, icon: 20.0),
      PaymentSize.large => (
        height: 56.0,
        padding: ButtonStyleButton.scaledPadding(
          EdgeInsets.symmetric(horizontal: theme.space(PaymentSpace.section)),
          EdgeInsets.symmetric(horizontal: theme.space(PaymentSpace.block)),
          EdgeInsets.symmetric(horizontal: theme.space(PaymentSpace.inline)),
          m,
        ),
        icon: 20.0,
      ),
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: metrics.icon),
          SizedBox(width: theme.space(PaymentSpace.related)),
        ],
        Flexible(child: Text(widget.label, textAlign: TextAlign.center)),
      ],
    );
    final child = Stack(
      alignment: Alignment.center,
      children: [
        // The label keeps its size while busy so the layout does not jump;
        // implicit fades retarget if the call finishes mid-transition.
        AnimatedOpacity(
          opacity: _busy ? 0 : 1,
          duration: motion.quick,
          curve: PaymentMotion.easeOut,
          child: content,
        ),
        AnimatedOpacity(
          opacity: _busy ? 1 : 0,
          duration: motion.quick,
          curve: PaymentMotion.easeOut,
          // The button announces busy through its own value.
          child: _busy
              ? ExcludeSemantics(
                  child: PaymentSpinner(
                    color: foreground,
                    size: widget.size == PaymentSize.small
                        ? PaymentSize.small
                        : PaymentSize.medium,
                  ),
                )
              : SizedBox.square(dimension: metrics.icon),
        ),
      ],
    );
    final radius = theme.controlBorderRadius;
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final minimumSize = Size(
      widget.width == PaymentWidth.hug ? 112 : 48,
      metrics.height,
    );
    // The heading role carries the host font; a const style would not.
    final label = type.heading;
    final onPressed = enabled ? _handle : null;
    final button = switch (widget.variant) {
      PaymentButtonVariant.primary => FilledButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: onPressed,
        style: PaymentFocusRing.withoutFocusFill(
          FilledButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: theme.onAccent,
            disabledBackgroundColor: theme.surfaceMuted,
            disabledForegroundColor: theme.disabled,
            minimumSize: minimumSize,
            padding: metrics.padding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: shape,
            textStyle: label,
          ),
        ),
        child: child,
      ),
      // Same colors as the confirm button of a destructive
      // showPaymentConfirmDialog: surface on the danger foreground.
      PaymentButtonVariant.destructive => FilledButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: onPressed,
        style: PaymentFocusRing.withoutFocusFill(
          FilledButton.styleFrom(
            backgroundColor: theme.danger.foreground,
            foregroundColor: theme.surface,
            disabledBackgroundColor: theme.surfaceMuted,
            disabledForegroundColor: theme.disabled,
            minimumSize: minimumSize,
            padding: metrics.padding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: shape,
            textStyle: label,
          ),
        ),
        child: child,
      ),
      PaymentButtonVariant.secondary => OutlinedButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: onPressed,
        style: PaymentFocusRing.withoutFocusFill(
          OutlinedButton.styleFrom(
            foregroundColor: theme.accent,
            disabledBackgroundColor: theme.surfaceMuted,
            disabledForegroundColor: theme.disabled,
            minimumSize: minimumSize,
            padding: metrics.padding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: shape,
            textStyle: label,
          ).copyWith(
            side: WidgetStateBorderSide.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? theme.disabled
                    : theme.border,
              ),
            ),
          ),
        ),
        child: child,
      ),
      PaymentButtonVariant.quiet => TextButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: onPressed,
        style: PaymentFocusRing.withoutFocusFill(
          TextButton.styleFrom(
            foregroundColor: theme.accent,
            disabledForegroundColor: theme.disabled,
            minimumSize: minimumSize,
            padding: metrics.padding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: shape,
            textStyle: label,
          ),
        ),
        child: child,
      ),
    };
    // Press feedback is Material's pressed state layer darkening the fill.
    // The button is full width, and scaling a 320 dp slab moves its edges by
    // several pixels, which reads as a lurch rather than a press. Keyboard
    // focus is the neutral ring, not Material's fill.
    final ring = PaymentFocusRing(radius: radius, child: button);
    return Semantics(
      liveRegion: _busy,
      value: _busy ? (widget.busyLabel ?? l10n.working) : null,
      child: widget.width == PaymentWidth.fill
          ? SizedBox(
              width: double.infinity,
              child: MinTapTarget(child: ring),
            )
          : MinTapTarget(child: ring),
    );
  }
}

/// Indeterminate progress for a wait with no known length: a thin ring, or a
/// still hourglass when the platform or host asks for reduced motion.
///
/// Prefer a [LoadingSkeleton] where content is loading into a known shape,
/// and [PaymentButton]'s `busy` state for an action that is running; both
/// already show progress. Screen readers hear [semanticLabel], "Loading" by
/// default.
class PaymentSpinner extends StatefulWidget {
  const PaymentSpinner({
    super.key,
    this.size = PaymentSize.medium,
    this.delay = Duration.zero,
    this.color,
    this.semanticLabel,
  });

  /// Width and height. The ring's stroke is 12% of it.
  final PaymentSize size;
  final Duration delay;

  /// Defaults to [PaymentTheme.textSecondary]: waiting is not a brand moment.
  final Color? color;
  final String? semanticLabel;

  @override
  State<PaymentSpinner> createState() => _PaymentSpinnerState();
}

class _PaymentSpinnerState extends State<PaymentSpinner> {
  late bool _shown = widget.delay == Duration.zero;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    if (!_shown) {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final size = switch (widget.size) {
      PaymentSize.small => 16.0,
      PaymentSize.medium => 20.0,
      PaymentSize.large => 32.0,
    };
    if (!_shown) {
      return SizedBox.square(dimension: size);
    }
    final color = widget.color ?? theme.textSecondary;
    return Semantics(
      label: widget.semanticLabel ?? PaymentLocalizations.of(context).loading,
      child: ExcludeSemantics(
        child: PaymentMotion.of(context).reduced
            ? Icon(PaymentIcons.busy, size: size, color: color)
            : SizedBox.square(
                dimension: size,
                child: CircularProgressIndicator(
                  strokeWidth: size * 0.12,
                  color: color,
                ),
              ),
      ),
    );
  }
}

/// A 1 px hairline in [PaymentTheme.outline] that separates rows or groups.
/// Decorative: screen readers skip it.
///
/// Between rows of a list use the default [height] of 1, as
/// [PaymentList] does. Between sections use the `section` gap (24) so the rule
/// sits in the middle of a section gap.
class PaymentDivider extends StatelessWidget {
  const PaymentDivider({super.key, this.height = 1});

  /// Total height, with the rule centered in it.
  final double height;

  @override
  Widget build(BuildContext context) => Divider(
    height: height,
    thickness: 1,
    color: PaymentTheme.of(context).outline,
  );
}

/// Small tag showing a status with icon and text; color only supports the
/// label.
class PaymentBadge extends StatelessWidget {
  const PaymentBadge({
    super.key,
    required this.tone,
    required this.label,
    this.icon,
  }) : _urgent = false;

  const PaymentBadge.urgent({super.key, required this.label, this.icon})
    : tone = StatusTone.danger,
      _urgent = true;

  final StatusTone tone;
  final String label;
  final IconData? icon;
  final bool _urgent;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final colors = theme.tone(tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.space(PaymentSpace.related),
        vertical: theme.space(PaymentSpace.inline),
      ),
      decoration: BoxDecoration(
        color: _urgent ? colors.foreground : colors.container,
        borderRadius: theme.tagBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? toneIcon(tone),
            size: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6).scale(14),
            color: _urgent ? theme.surface : colors.foreground,
          ),
          SizedBox(width: theme.space(PaymentSpace.inline)),
          Flexible(
            child: Text(
              label,
              style: PaymentType.of(context).tag.copyWith(
                color: _urgent ? theme.surface : colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deprecated alias of [PaymentBadge].
@Deprecated('Use PaymentBadge. Removed in 0.2.0.')
typedef StatusBadge = PaymentBadge;

/// Inline message for errors, warnings and explanations.
class PaymentBanner extends StatefulWidget {
  const PaymentBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.icon,
    this.actions = const [],
    this.announce = false,
    this.onDismiss,
  });

  /// Semantic message tone.
  final StatusTone tone;

  /// Visible banner heading.
  final String title;

  /// Optional explanation.
  final String? message;

  /// Default trigger glyph.
  final IconData? icon;

  /// Inline links or hug secondary/quiet actions.
  final List<Widget> actions;

  /// Announces the banner to screen readers when it appears.
  final bool announce;

  /// Shows Hide banner; reports at most once. The host removes the banner.
  final VoidCallback? onDismiss;
  @override
  State<PaymentBanner> createState() => _PaymentBannerState();
}

class _PaymentBannerState extends State<PaymentBanner> {
  bool _reported = false;
  @override
  Widget build(BuildContext context) {
    assert(
      widget.actions.every(
        (w) =>
            w is PaymentLink ||
            w is PaymentButton &&
                w.width == PaymentWidth.hug &&
                (w.variant == PaymentButtonVariant.secondary ||
                    w.variant == PaymentButtonVariant.quiet),
      ),
      'PaymentBanner actions are links or hug secondary/quiet buttons.',
    );
    final theme = PaymentTheme.of(context);
    final colors = theme.tone(widget.tone);
    final type = PaymentType.of(context);
    // One line of the 15/20 heading title.
    final line = PaymentType.firstLineHeight(context);
    return Semantics(
      container: true,
      liveRegion: widget.announce,
      child: Container(
        width: double.infinity,
        padding: widget.onDismiss == null
            ? EdgeInsets.all(theme.space(PaymentSpace.block))
            : EdgeInsetsDirectional.only(
                start: theme.space(PaymentSpace.block),
                bottom: theme.space(PaymentSpace.block),
              ),
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: theme.controlBorderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The icon scales with the text up to 1.6× and centers on
                // the title's first line, however many lines it wraps to.
                Padding(
                  padding: EdgeInsets.only(
                    top: widget.onDismiss == null
                        ? 0
                        : theme.space(PaymentSpace.block),
                  ),
                  child: PaymentIcon.tone(widget.tone, icon: widget.icon),
                ),
                SizedBox(width: theme.space(PaymentSpace.block)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: widget.onDismiss == null
                          ? 0
                          : theme.space(PaymentSpace.block),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: type.heading.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                        if (widget.message != null) ...[
                          SizedBox(height: theme.space(PaymentSpace.inline)),
                          Text(widget.message!, style: type.bodyFor(context)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.onDismiss != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: math.max(
                        0,
                        theme.space(PaymentSpace.block) + line / 2 - 24,
                      ),
                    ),
                    child: PaymentIconButton(
                      icon: PaymentIcons.close,
                      tooltip:
                          '${PaymentLocalizations.of(context).hideBanner}: ${widget.title}',
                      onPressed: _reported
                          ? null
                          : () {
                              if (_reported) return;
                              setState(() => _reported = true);
                              widget.onDismiss!();
                            },
                    ),
                  ),
              ],
            ),
            if (widget.actions.isNotEmpty) ...[
              SizedBox(height: theme.space(PaymentSpace.related)),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: widget.onDismiss == null
                      ? 0
                      : theme.space(PaymentSpace.block),
                ),
                child: Wrap(
                  spacing: theme.space(PaymentSpace.related),
                  runSpacing: theme.space(PaymentSpace.inline),
                  children: widget.actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Deprecated alias of [PaymentBanner].
@Deprecated('Use PaymentBanner. Removed in 0.2.0.')
typedef NoticeBanner = PaymentBanner;

/// A titled group of content. Sections are flat: they sit on the page
/// surface and are separated by space, never boxed, so they nest inside a
/// host's own cards and sheets without stacking borders.
class PaymentSection extends StatelessWidget {
  const PaymentSection({
    super.key,
    this.title,
    this.trailing,
    required this.child,
  });

  final String? title;

  /// Optional action beside the title, such as an "Edit" button. Keeping a
  /// section's action in its header saves a row and ties it to the content.
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.space(PaymentSpace.related),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title!, style: PaymentType.of(context).heading),
                  ),
                ),
                ?trailing,
              ],
            ),
            SizedBox(
              height: trailing == null
                  ? theme.space(PaymentSpace.related) * 0.5
                  : 0,
            ),
          ],
          child,
        ],
      ),
    );
  }
}

/// The top of a status screen: a band, then an icon beside the state in
/// words. Band shape, tone, icon and words are four signals, so a hatched
/// band (the outcome is not known yet) never reads as a plain "pending".
///
/// The title scales with the text and may wrap. The icon scales up to 1.6×
/// and centers on the title's first line.
class StatusHeader extends StatelessWidget {
  const StatusHeader({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    this.hatched = false,
  });

  final StatusTone tone;
  final IconData icon;
  final String title;

  /// Marks an outcome that is not known yet.
  final bool hatched;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final colors = theme.tone(tone);
    // One line of a 15/20 title, so the icon box matches its first line.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBand(tone: tone, hatched: hatched),
        SizedBox(height: theme.space(PaymentSpace.block)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentIcon.tone(tone, icon: icon),
            SizedBox(width: theme.space(PaymentSpace.related)),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: PaymentType.of(
                    context,
                  ).heading.copyWith(color: colors.foreground),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Thin band above a status title. A solid band marks a settled or waiting
/// state; a hatched band marks an outcome that is not known yet, so the two
/// warning states differ in shape as well as in words, not only in color.
class StatusBand extends StatelessWidget {
  const StatusBand({super.key, required this.tone, this.hatched = false});

  final StatusTone tone;
  final bool hatched;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: CustomPaint(
            painter: _BandPainter(
              color: theme.tone(tone).foreground,
              background: theme.surface,
              hatched: hatched,
            ),
          ),
        ),
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  const _BandPainter({
    required this.color,
    required this.background,
    required this.hatched,
  });

  final Color color;
  final Color background;
  final bool hatched;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (!hatched) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    paintHatch(
      canvas,
      Offset.zero & size,
      color: color,
      background: background,
    );
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.color != color ||
      old.background != background ||
      old.hatched != hatched;
}

/// Covers sensitive content when [obscured] is true, for example while the
/// host app is in the app switcher. OS-level screenshot protection remains
/// the host's responsibility.
class PrivacyMask extends StatelessWidget {
  const PrivacyMask({super.key, required this.obscured, required this.child});

  final bool obscured;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Stack(
      children: [
        ExcludeSemantics(excluding: obscured, child: child),
        if (obscured)
          Positioned.fill(
            child: ColoredBox(
              color: theme.surface,
              child: Center(
                child: PaymentIcon(
                  Icons.lock_outline,
                  size: PaymentIconSize.xlarge,
                  color: PaymentTextColor.secondary,
                  semanticLabel: PaymentLocalizations.of(context).contentHidden,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Counts down to [expiresAt] using the host [clock]. Stops at zero and calls
/// [onElapsed] once; reaching zero is not proof of non-payment.
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.expiresAt,
    required this.clock,
    this.onElapsed,
    this.style,
  });

  final DateTime expiresAt;
  final DateTime Function() clock;
  final VoidCallback? onElapsed;
  final TextStyle? style;

  static Duration remaining(DateTime expiresAt, DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  bool _elapsedReported = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _elapsedReported = false;
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_left == Duration.zero) {
      _reportElapsed();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_left == Duration.zero) {
        _timer?.cancel();
        _reportElapsed();
      }
    });
  }

  void _reportElapsed() {
    if (_elapsedReported) return;
    _elapsedReported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onElapsed?.call();
    });
  }

  Duration get _left =>
      CountdownText.remaining(widget.expiresAt, widget.clock());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final left = _left;
    return Semantics(
      label: l10n.timeRemaining(CountdownText.formatDuration(left)),
      excludeSemantics: true,
      child: Text(
        CountdownText.formatDuration(left),
        style: type.tabular(type.label.merge(widget.style)),
      ),
    );
  }
}
