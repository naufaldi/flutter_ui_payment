import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'payment_motion.dart';

/// The swap behind [PaymentMotion.fullWidthSwap] and the onboarding steps
/// (D94): [enter] in, [exit] out, on [PaymentMotion.topLayout], with
/// [transition] drawing each child's fade, and the height eased when
/// [easeSize] is set.
///
/// A switcher of its own rather than an AnimatedSwitcher: that one fixes
/// each fade's duration when the fade starts, so a swap already running when
/// reduced motion turns on would keep going. Here every running transition
/// ends at once under either flag, and the current child keeps its state.
///
/// Internal to the kit; it is not exported.
class MotionSwap extends StatefulWidget {
  const MotionSwap({
    super.key,
    required this.child,
    this.transition = fade,
    this.easeSize = true,
    this.onSettled,
  });

  /// The current child. Give each state its own key.
  final Widget child;

  /// Draws a child at an animation's value, 0 → 1 entering, 1 → 0 leaving.
  final Widget Function(Widget child, Animation<double> animation) transition;

  /// Whether the height eases over [enter] on [PaymentMotion.easeInOut].
  final bool easeSize;

  /// Called once a swap has fully come to rest: every fade done and the
  /// height no longer easing.
  final VoidCallback? onSettled;

  /// A fade only, on [PaymentMotion.easeOut].
  static Widget fade(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation.drive(CurveTween(curve: PaymentMotion.easeOut)),
        child: child,
      );

  @override
  State<MotionSwap> createState() => _MotionSwapState();
}

/// One child of the swap and the animation it owns.
class _SwapEntry {
  _SwapEntry(this.child, this.controller);

  Widget child;
  final AnimationController controller;
  late final Key key = ObjectKey(this);
}

class _MotionSwapState extends State<MotionSwap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Keeps the stack, and the state below it, when reduced motion is turned
  // on or off and the AnimatedSize around it comes or goes.
  final _stack = GlobalKey();
  final _size = GlobalKey();
  late _SwapEntry _current = _SwapEntry(
    widget.child,
    AnimationController(vsync: this, value: 1),
  );
  final _leaving = <_SwapEntry>[];
  bool _checkPending = false;

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
  void didUpdateWidget(MotionSwap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Widget.canUpdate(widget.child, _current.child)) {
      _current.child = widget.child;
      return;
    }
    final motion = PaymentMotion.of(context);
    final leaving = _current;
    _current =
        _SwapEntry(
            widget.child,
            AnimationController(vsync: this, duration: motion.enter),
          )
          ..controller.addStatusListener((status) {
            if (status.isCompleted) _checkSettled();
          })
          ..controller.forward();
    _leaving.add(leaving);
    leaving.controller
      ..reverseDuration = motion.exit
      ..addStatusListener((status) {
        if (status.isDismissed && mounted && _leaving.remove(leaving)) {
          setState(() {});
          leaving.controller.dispose();
          _checkSettled();
        }
      })
      ..reverse();
  }

  // Ends every running transition: the leaving children go and the current
  // one is fully shown, keeping its state.
  //
  // It always checks for rest: with the fades already done, reduced motion
  // can still cut a running height ease, and dropping the AnimatedSize drops
  // the onEnd that would have reported it (#200 R4).
  void _finish() {
    if (_leaving.isNotEmpty || !_current.controller.isCompleted) {
      for (final entry in _leaving) {
        entry.controller.dispose();
      }
      _leaving.clear();
      _current.controller.value = 1;
    }
    _checkSettled();
  }

  // After this frame's layout, so a removed child's height change has
  // already started the size ease.
  void _checkSettled() {
    if (widget.onSettled == null || _checkPending) return;
    _checkPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPending = false;
      if (!mounted || _leaving.isNotEmpty) return;
      if (_current.controller.isAnimating) return;
      final size = _size.currentContext?.findRenderObject();
      if (size is RenderAnimatedSize && size.isAnimating) return;
      widget.onSettled?.call();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final entry in [_current, ..._leaving]) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  Widget _drawn(_SwapEntry entry) => KeyedSubtree(
    key: entry.key,
    child: widget.transition(entry.child, entry.controller),
  );

  @override
  Widget build(BuildContext context) {
    final motion = PaymentMotion.of(context);
    if (motion.reduced) _finish();
    final stack = KeyedSubtree(
      key: _stack,
      child: PaymentMotion.topLayout(_drawn(_current), [
        for (final entry in _leaving) _drawn(entry),
      ]),
    );
    // AnimatedSize can't run at zero duration (it re-dirties its own layout),
    // so reduced motion leaves it out and the height changes at once.
    if (!widget.easeSize || motion.reduced) return stack;
    return AnimatedSize(
      key: _size,
      duration: motion.enter,
      curve: PaymentMotion.easeInOut,
      alignment: Alignment.topCenter,
      onEnd: _checkSettled,
      child: stack,
    );
  }
}
