import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// A GlobalKey can sit on one widget at a time. The phone menu sheet is its
// own route, so it can outlive the header that opened it: a resize can move a
// page link back to the title row while the sheet still shows the link's
// entry (#163). The open sheet keeps the key until its entry leaves the tree;
// the title row builds without it until then, and takes it back afterwards.

final _held = <GlobalKey>{};
final _released = ValueNotifier<int>(0);

/// Marks [heldKey] as held by an open menu sheet entry while [child] is
/// mounted. Other keys pass [child] through unchanged.
Widget holdMenuSheetKey(Key? heldKey, Widget child) => heldKey is GlobalKey
    ? _SheetKeyHold(heldKey: heldKey, child: child)
    : child;

/// Builds with [key], unless it is a [GlobalKey] an open menu sheet entry
/// still holds; then builds without it and rebuilds once the entry is gone.
Widget withMenuSheetKey(Key? key, Widget Function(Key? key) build) =>
    key is GlobalKey
    ? ListenableBuilder(
        listenable: _released,
        builder: (_, _) => build(_held.contains(key) ? null : key),
      )
    : build(key);

class _SheetKeyHold extends StatefulWidget {
  const _SheetKeyHold({required this.heldKey, required this.child});
  final GlobalKey heldKey;
  final Widget child;

  @override
  State<_SheetKeyHold> createState() => _SheetKeyHoldState();
}

class _SheetKeyHoldState extends State<_SheetKeyHold> {
  @override
  void initState() {
    super.initState();
    _held.add(widget.heldKey);
  }

  @override
  void didUpdateWidget(_SheetKeyHold old) {
    super.didUpdateWidget(old);
    if (old.heldKey != widget.heldKey) {
      _release(old.heldKey);
      _held.add(widget.heldKey);
    }
  }

  @override
  void dispose() {
    _release(widget.heldKey);
    super.dispose();
  }

  // Disposal runs while the tree is locked, so waiting widgets rebuild after
  // this frame, once the entry's element (and its key) is gone.
  void _release(GlobalKey key) {
    _held.remove(key);
    SchedulerBinding.instance.addPostFrameCallback((_) => _released.value++);
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
