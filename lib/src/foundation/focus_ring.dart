import 'package:flutter/material.dart';

import 'payment_motion.dart';
import 'payment_theme.dart';

/// Keyboard focus outline: 2 px wide, 2 px outside the control, in ink on
/// light and paper on dark, never the brand color.
///
/// It shows only when the platform is in keyboard (traditional) highlight
/// mode, Flutter's `:focus-visible`, so a tap never draws it. It is painted
/// over the control and outside its bounds, so it never moves the layout;
/// leave at least 4 px between the control and any clipping ancestor.
class PaymentFocusRing extends StatefulWidget {
  const PaymentFocusRing({
    super.key,
    required this.child,
    required this.radius,
    this.color,
  });

  final Widget child;

  /// The control's own corner radius; the ring follows it at +3.
  final BorderRadius radius;

  /// Overrides the ink color where the control sits on a picture. Keep it
  /// neutral (white), never the accent.
  final Color? color;

  /// [style] with Material's focus fill removed, since the ring replaces it.
  /// Pressed and hovered layers keep the colors [style] already gives them.
  static ButtonStyle withoutFocusFill(ButtonStyle style) {
    final base = style.overlayColor;
    return style.copyWith(
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) &&
                !states.contains(WidgetState.pressed) &&
                !states.contains(WidgetState.hovered)
            ? Colors.transparent
            : base?.resolve(states),
      ),
    );
  }

  @override
  State<PaymentFocusRing> createState() => _PaymentFocusRingState();
}

class _PaymentFocusRingState extends State<PaymentFocusRing> {
  bool _focused = false;
  late FocusHighlightMode _mode = FocusManager.instance.highlightMode;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    super.dispose();
  }

  void _onMode(FocusHighlightMode mode) {
    if (mounted && mode != _mode) setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final show = _focused && _mode == FocusHighlightMode.traditional;
    // The paint is always in the tree and only its painter toggles, so the
    // child is never remounted (and never loses focus) when the ring shows.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: CustomPaint(
        foregroundPainter: show
            ? FocusRingPainter(
                color: widget.color ?? PaymentTheme.of(context).textPrimary,
                radius: widget.radius.resolve(Directionality.of(context)),
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

/// Paints [PaymentFocusRing]'s outline.
class FocusRingPainter extends CustomPainter {
  const FocusRingPainter({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    // A 2 px stroke centered 3 px out: its inner edge sits 2 px outside the
    // control. Inflating the rounded rect grows its radii by 3 as well.
    canvas.drawRRect(
      radius.toRRect(Offset.zero & size).inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(FocusRingPainter old) =>
      old.color != color || old.radius != radius;
}

/// Press feedback for compact controls: the control shrinks to
/// [PaymentMotion.pressedScale] while held and springs back on release.
///
/// Only for small targets such as icon and link buttons. Full-width buttons
/// and rows keep Material's pressed layer instead, because scaling a wide
/// slab moves its edges by several pixels and reads as a lurch.
class PaymentPressScale extends StatefulWidget {
  const PaymentPressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;

  /// A disabled control does not react to a press.
  final bool enabled;

  @override
  State<PaymentPressScale> createState() => _PaymentPressScaleState();
}

class _PaymentPressScaleState extends State<PaymentPressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final motion = PaymentMotion.of(context);
    return Listener(
      onPointerDown: (_) => _set(widget.enabled),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? motion.pressedScale : 1,
        duration: motion.press,
        curve: PaymentMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
