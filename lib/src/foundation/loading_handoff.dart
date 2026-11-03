import 'package:flutter/widgets.dart';

import 'motion_swap.dart';
import 'payment_motion.dart';

/// Hands a loading placeholder over to its content with
/// [PaymentMotion.fullWidthSwap] (D94): the content fades in and its height
/// eases, so whatever sits below glides instead of jumping.
///
/// Only the loading → ready step animates. The swap is in the tree while
/// [loading] and for the one handoff after it, until both fades and the
/// height ease have finished, then leaves, so later changes
/// to the ready content (a search, a filter, new data) stay instant, height
/// included. The ready content keeps its state when the swap leaves. Going
/// back to loading is instant too. A widget first built ready shows its
/// content at once.
///
/// Internal to the kit; it is not exported.
class LoadingHandoff extends StatefulWidget {
  const LoadingHandoff({super.key, required this.loading, required this.child});

  /// Whether [child] is the loading placeholder.
  final bool loading;

  /// The placeholder while [loading], the content after.
  final Widget child;

  @override
  State<LoadingHandoff> createState() => _LoadingHandoffState();
}

class _LoadingHandoffState extends State<LoadingHandoff> {
  // Keeps the ready content's state when the swap around it leaves.
  final _ready = GlobalKey();

  // True from the loading → ready step until the swap has come to rest:
  // both fades done and the height no longer easing. A ready result shorter
  // than its placeholder only starts shrinking once the placeholder has
  // faded out, so the swap stays until then.
  bool _handingOff = false;

  // A new swap mounts showing its child at once, with no fade.
  int _generation = 0;

  @override
  void didUpdateWidget(LoadingHandoff old) {
    super.didUpdateWidget(old);
    if (widget.loading == old.loading) return;
    if (widget.loading) {
      // Back to loading: a fresh swap shows the placeholder at once.
      _handingOff = false;
      _generation++;
      return;
    }
    // Under reduced motion the swap is instant, so it can leave now.
    _handingOff = !PaymentMotion.of(context).reduced;
  }

  void _settled() {
    if (_handingOff && mounted) setState(() => _handingOff = false);
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.loading
        ? null
        : KeyedSubtree(key: _ready, child: widget.child);
    if (ready != null && !_handingOff) return ready;
    return KeyedSubtree(
      key: ValueKey(_generation),
      child: MotionSwap(
        onSettled: _settled,
        // Filled, so the content keeps the column's start edge in the
        // swap's stack.
        child: SizedBox(
          key: ValueKey(widget.loading),
          width: double.infinity,
          child: ready ?? widget.child,
        ),
      ),
    );
  }
}
