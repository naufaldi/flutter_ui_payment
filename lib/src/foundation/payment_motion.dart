import 'package:flutter/widgets.dart';

/// Motion tokens shared by the kit.
///
/// Motion here is feedback only: a press was heard, a status changed, a step
/// moved forward. Durations stay under 300 ms, exits are faster than enters,
/// and everything collapses to [Duration.zero] when the platform or host asks
/// for reduced motion.
@immutable
class PaymentMotion {
  const PaymentMotion._(this.reduced);

  /// Reads reduced motion from both places it can come from:
  /// [MediaQueryData.disableAnimations] (a host override, or Android's
  /// "Remove animations") and [AccessibilityFeatures.reduceMotion], the only
  /// flag iOS sets for Reduce Motion. `MediaQueryData` doesn't carry the
  /// second one, so a widget sees an OS change on its next rebuild.
  factory PaymentMotion.of(BuildContext context) {
    final features = View.maybeOf(
      context,
    )?.platformDispatcher.accessibilityFeatures;
    // `??` binds looser than `||`, so both reads keep their parentheses.
    return PaymentMotion._(
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
          (features?.reduceMotion ?? false),
    );
  }

  /// True when animations should not play at all, under either flag.
  final bool reduced;

  /// Strong ease-out: movement starts immediately, so it reads as response.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// For elements already on screen that change size or position.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// iOS-like drawer curve for sheets and side panels that travel further.
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  Duration _d(int ms) => reduced ? Duration.zero : Duration(milliseconds: ms);

  /// Press feedback and color changes.
  Duration get press => _d(100);

  /// Selection, hover-like and color/border changes.
  Duration get quick => _d(150);

  /// A status or content swap entering.
  Duration get enter => _d(220);

  /// The matching exit, roughly 30% faster than [enter].
  Duration get exit => _d(150);

  /// Bottom sheets and side panels: larger surfaces get a little longer.
  Duration get sheetEnter => _d(280);

  /// The matching sheet exit.
  Duration get sheetExit => _d(200);

  /// Scale applied while a compact control is held down. Full-width buttons
  /// do not scale.
  double get pressedScale => reduced ? 1 : 0.96;

  /// Fade plus a slight scale-up from 0.95, never from nothing.
  static Widget fadeScale(Widget child, Animation<double> animation) {
    final curved = _eased(animation);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  // AnimatedSwitcher runs its transitionBuilder on every child update. A
  // CurvedAnimation would add a status listener to the parent each time
  // (#116); a driven CurveTween registers listeners only while they're used.
  static Animation<double> _eased(Animation<double> animation) =>
      animation.drive(CurveTween(curve: easeOut));

  /// Fade plus a fixed 8 dp rise, on every screen size, used when a flow
  /// moves to its next step. Pass `back: true` when the flow moves back: the
  /// content fades only, with no rise, so going back never looks like going
  /// forward.
  static Widget fadeRise(
    Widget child,
    Animation<double> animation, {
    bool back = false,
  }) {
    final curved = _eased(animation);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: back ? Offset.zero : Offset(0, _rise * (1 - curved.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }

  static const double _rise = 8;

  /// Swaps full-width content, such as a status header, with a fade only:
  /// [enter] in, [exit] out, and the height eased over [enter] on
  /// [easeInOut], so the content below glides instead of jumping. All of it
  /// is instant under reduced motion. Give each state's [child] its own key.
  ///
  /// It never scales: scaling a full-width slab moves its edges and reads as
  /// a lurch. Use [fadeScale] for compact elements only. The leaving child
  /// takes no taps ([topLayout]). Painting is clipped to the eased height
  /// only while it grows; at rest nothing is clipped, focus rings included.
  /// If reduced motion turns on mid-swap, the swap ends on the next frame.
  Widget fullWidthSwap(Widget child) => _FullWidthSwap(child);

  /// Layout for swaps: outgoing children keep painting while they fade but
  /// take no taps and are hidden from screen readers, so a leaving "Pay"
  /// button can never be pressed.
  static Widget topLayout(Widget? current, List<Widget> previous) => Stack(
    alignment: Alignment.topCenter,
    children: [
      for (final child in previous) _interactive(child, false),
      if (current != null) _interactive(current, true),
    ],
  );

  // Same wrapper type and key in both roles, so a child keeps its state
  // when it moves from current to previous.
  static Widget _interactive(Widget child, bool enabled) => IgnorePointer(
    key: child.key,
    ignoring: !enabled,
    child: ExcludeSemantics(excluding: !enabled, child: child),
  );
}

class _FullWidthSwap extends StatefulWidget {
  const _FullWidthSwap(this.child);

  final Widget child;

  @override
  State<_FullWidthSwap> createState() => _FullWidthSwapState();
}

/// One child of the swap and the fade it owns.
class _SwapEntry {
  _SwapEntry(this.child, this.controller)
    : opacity = CurvedAnimation(
        parent: controller,
        curve: PaymentMotion.easeOut,
      );

  Widget child;
  final AnimationController controller;
  final CurvedAnimation opacity;
  late final Key key = ObjectKey(this);

  void dispose() {
    opacity.dispose();
    controller.dispose();
  }
}

// A fade-only switcher of its own rather than an AnimatedSwitcher: that one
// fixes each fade's duration when the fade starts, so a swap already running
// when reduced motion turns on would keep going.
class _FullWidthSwapState extends State<_FullWidthSwap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Keeps the stack, and the state below it, when reduced motion is turned
  // on or off and the AnimatedSize around it comes or goes.
  final _stack = GlobalKey();
  late _SwapEntry _current = _SwapEntry(
    widget.child,
    AnimationController(vsync: this, value: 1),
  );
  final _leaving = <_SwapEntry>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // iOS Reduce Motion isn't part of MediaQueryData, so nothing above
  // rebuilds this when it turns on mid-swap.
  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void didUpdateWidget(_FullWidthSwap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Widget.canUpdate(widget.child, _current.child)) {
      _current.child = widget.child;
      return;
    }
    final motion = PaymentMotion.of(context);
    final leaving = _current;
    _current = _SwapEntry(
      widget.child,
      AnimationController(vsync: this, duration: motion.enter),
    )..controller.forward();
    _leaving.add(leaving);
    leaving.controller
      ..reverseDuration = motion.exit
      ..addStatusListener((status) {
        if (status.isDismissed && mounted) {
          setState(() => _leaving.remove(leaving));
          leaving.dispose();
        }
      })
      ..reverse();
  }

  // Ends every running fade: the leaving children go and the current one is
  // fully shown, keeping its state.
  void _finish() {
    for (final entry in _leaving) {
      entry.dispose();
    }
    _leaving.clear();
    _current.controller.value = 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final entry in [_current, ..._leaving]) {
      entry.dispose();
    }
    super.dispose();
  }

  Widget _faded(_SwapEntry entry) => KeyedSubtree(
    key: entry.key,
    child: FadeTransition(opacity: entry.opacity, child: entry.child),
  );

  @override
  Widget build(BuildContext context) {
    final motion = PaymentMotion.of(context);
    if (motion.reduced) _finish();
    final stack = KeyedSubtree(
      key: _stack,
      child: PaymentMotion.topLayout(_faded(_current), [
        for (final entry in _leaving) _faded(entry),
      ]),
    );
    // AnimatedSize can't run at zero duration (it re-dirties its own layout),
    // so reduced motion leaves it out and the height changes at once.
    if (motion.reduced) return stack;
    return AnimatedSize(
      duration: motion.enter,
      curve: PaymentMotion.easeInOut,
      alignment: Alignment.topCenter,
      child: stack,
    );
  }
}
