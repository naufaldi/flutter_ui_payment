import 'package:flutter/widgets.dart';

/// Motion tokens shared by the kit.
///
/// Motion here is feedback only: a press was heard, a status changed, a step
/// moved forward. Durations stay under 300 ms, exits are faster than enters,
/// and everything collapses to [Duration.zero] when the platform or host asks
/// for reduced motion ([MediaQueryData.disableAnimations]).
@immutable
class PaymentMotion {
  const PaymentMotion._(this.reduced);

  factory PaymentMotion.of(BuildContext context) =>
      PaymentMotion._(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// True when animations should not play at all.
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
    final curved = CurvedAnimation(parent: animation, curve: easeOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  /// Fade plus an 8 px rise, used when a flow moves to its next step.
  static Widget fadeRise(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

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
