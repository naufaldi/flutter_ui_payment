import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Internal: where each mounted [PinnedFooter] band sits, so a kit toast can
/// float above it instead of over its actions (D95).
///
/// A footer registers while it is mounted and records the route and
/// messenger it belongs to on every build. Nothing here calls the platform
/// (B11); it only reads layout the kit and its scaffolds already did.
class PinnedFooterRegistry {
  PinnedFooterRegistry._();

  static final _entries = <PinnedFooterEntry>{};

  static void add(PinnedFooterEntry entry) => _entries.add(entry);
  static void remove(PinnedFooterEntry entry) => _entries.remove(entry);

  /// How much higher than its resting edge a floating snack bar of
  /// [messenger] must sit for its bottom to clear the top of every visible
  /// footer, in logical pixels; 0 when no footer reaches below that edge.
  ///
  /// The resting edge is measured on the scaffold that shows the snack bar:
  /// the root of the footer's nested scaffolds under [messenger]. It is the
  /// same edge the scaffold uses, so a bottom navigation bar, a floating
  /// action button, the safe area and the keyboard already count, and a
  /// footer in the navigation bar slot needs no extra lift.
  static double lift(ScaffoldMessengerState messenger) {
    var lift = 0.0;
    for (final e in _entries) {
      if (e.messenger != messenger || !e.visible) continue;
      final box = e.context.findRenderObject();
      final rest = _restingEdge(e.context, messenger);
      if (rest == null || box is! RenderBox || !box.attached || !box.hasSize) {
        continue;
      }
      lift = math.max(lift, rest - box.localToGlobal(Offset.zero).dy);
    }
    return lift;
  }

  /// The global y where the bottom of a floating snack bar from [messenger]
  /// rests, with no margin, on the root scaffold above [context]. Mirrors
  /// the floating case of the scaffold's own layout.
  static double? _restingEdge(
    BuildContext context,
    ScaffoldMessengerState messenger,
  ) {
    var scaffold = Scaffold.maybeOf(context);
    if (scaffold == null) return null;
    while (true) {
      final parent = scaffold!.context.findAncestorStateOfType<ScaffoldState>();
      if (parent == null ||
          ScaffoldMessenger.maybeOf(parent.context) != messenger) {
        break;
      }
      scaffold = parent;
    }
    final frame = scaffold.context.findRenderObject();
    if (!scaffold.mounted ||
        frame is! RenderBox ||
        !frame.attached ||
        !frame.hasSize) {
      return null;
    }
    double? top(Widget? slot, String name) {
      final box = slot == null ? null : _slotBox(scaffold!, name);
      return box == null
          ? null
          : frame.globalToLocal(box.localToGlobal(Offset.zero)).dy;
    }

    final height = frame.size.height;
    final widget = scaffold.widget;
    final navTop = top(widget.bottomNavigationBar, 'bottomNavigationBar');
    final fabTop = _aboveFab(widget)
        ? top(widget.floatingActionButton, 'floatingActionButton')
        : null;
    final double base;
    if (fabTop != null) {
      base = navTop == null ? fabTop : math.min(navTop, fabTop);
    } else {
      final media = MediaQuery.of(scaffold.context);
      final resize = widget.resizeToAvoidBottomInset ?? true;
      final keyboard = resize ? media.viewInsets.bottom : 0.0;
      final contentBottom = math.max(
        0.0,
        height - math.max(keyboard, navTop == null ? 0.0 : height - navTop),
      );
      final safeBottom = resize && keyboard != 0
          ? 0.0
          : media.viewPadding.bottom;
      base = math.min(contentBottom, height - safeBottom);
    }
    return frame.localToGlobal(Offset(0, base)).dy;
  }

  /// The laid-out box of the scaffold's own [name] slot, such as
  /// `bottomNavigationBar`: the [LayoutId] child the scaffold positions in
  /// its multi-child layout. Only that layout's direct children are read, so
  /// the body (or a nested scaffold) can never stand in for a slot, even when
  /// it holds the same widget instance (#204 R3).
  static RenderBox? _slotBox(ScaffoldState scaffold, String name) {
    Element? layout;
    void find(Element e, int depth) {
      if (layout != null) return;
      if (e.widget is CustomMultiChildLayout) {
        layout = e;
        return;
      }
      if (depth == 0 || e.widget is Scaffold) return;
      e.visitChildren((c) => find(c, depth - 1));
    }

    (scaffold.context as Element).visitChildren((c) => find(c, 16));
    RenderBox? found;
    layout?.visitChildren((c) {
      final id = (c.widget is LayoutId) ? (c.widget as LayoutId).id : null;
      final box = c.renderObject;
      if (id is Enum &&
          id.name == name &&
          box is RenderBox &&
          box.attached &&
          box.hasSize) {
        found = box;
      }
    });
    return found;
  }

  /// Whether the scaffold rests a floating snack bar on top of its floating
  /// action button: every location except the top ones.
  static bool _aboveFab(Scaffold scaffold) =>
      switch (scaffold.floatingActionButtonLocation) {
        FloatingActionButtonLocation.startTop ||
        FloatingActionButtonLocation.centerTop ||
        FloatingActionButtonLocation.endTop ||
        FloatingActionButtonLocation.miniStartTop ||
        FloatingActionButtonLocation.miniCenterTop ||
        FloatingActionButtonLocation.miniEndTop => false,
        _ => true,
      };
}

/// Internal: one footer's registration, refreshed by its build.
class PinnedFooterEntry {
  PinnedFooterEntry(this.context);
  final BuildContext context;
  ScaffoldMessengerState? messenger;
  ModalRoute<Object?>? route;
  ValueListenable<TickerModeData>? ticker;

  bool get visible =>
      context.mounted &&
      (route?.isCurrent ?? true) &&
      (ticker?.value.enabled ?? true);

  /// Reads the footer's ancestors; call from its build.
  void update(BuildContext context) {
    messenger = ScaffoldMessenger.maybeOf(context);
    route = ModalRoute.of(context);
    ticker = TickerMode.getValuesNotifier(context);
  }
}
