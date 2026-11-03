import 'package:flutter/widgets.dart';

import 'payment_motion.dart';

/// Hands a loading placeholder over to its content with
/// [PaymentMotion.fullWidthSwap] (D94): the content fades in and its height
/// eases, so whatever sits below glides instead of jumping.
///
/// Only the loading → ready step animates. The swap is in the tree while
/// [loading] and for the one handoff after it, then leaves, so later changes
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

class _LoadingHandoffState extends State<LoadingHandoff>
    with SingleTickerProviderStateMixin {
  // Keeps the ready content's state when the swap around it leaves.
  final _ready = GlobalKey();

  // Runs for the length of one handoff; the swap stays while it runs.
  late final AnimationController _handoff;

  @override
  void initState() {
    super.initState();
    _handoff = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status.isCompleted && mounted) setState(() {});
      });
  }

  // A new swap mounts showing its child at once, with no fade.
  int _generation = 0;

  @override
  void didUpdateWidget(LoadingHandoff old) {
    super.didUpdateWidget(old);
    if (widget.loading == old.loading) return;
    if (widget.loading) {
      // Back to loading: a fresh swap shows the placeholder at once.
      _handoff.stop();
      _generation++;
      return;
    }
    final motion = PaymentMotion.of(context);
    // Under reduced motion the swap is instant, so it can leave now.
    if (motion.reduced) return;
    _handoff
      ..duration = motion.enter
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _handoff.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.loading
        ? null
        : KeyedSubtree(key: _ready, child: widget.child);
    if (ready != null && !_handoff.isAnimating) return ready;
    return KeyedSubtree(
      key: ValueKey(_generation),
      child: PaymentMotion.of(context).fullWidthSwap(
        // Filled, so the content keeps the column's start edge in the
        // swap's stack.
        SizedBox(
          key: ValueKey(widget.loading),
          width: double.infinity,
          child: ready ?? widget.child,
        ),
      ),
    );
  }
}
