import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Internal: where each mounted [PinnedFooter] band sits, so a kit toast can
/// float above it instead of over its actions (D95).
///
/// A footer registers while it is mounted and records the route, scaffold
/// and messenger it belongs to on every build. Nothing here calls the
/// platform (B11); it only reads layout the kit already did.
class PinnedFooterRegistry {
  PinnedFooterRegistry._();

  static final _entries = <PinnedFooterEntry>{};

  static void add(PinnedFooterEntry entry) => _entries.add(entry);
  static void remove(PinnedFooterEntry entry) => _entries.remove(entry);

  /// How far above the snack bar's resting edge the tallest visible footer
  /// of [messenger] reaches, in logical pixels; 0 when none is showing.
  ///
  /// A floating snack bar rests on the lower of the scaffold body's bottom
  /// and the safe-area bottom. A footer counts when it is on the current
  /// route, not under a disabled [TickerMode] (offstage tabs), laid out, and
  /// inside a [Scaffold] driven by [messenger].
  static double lift(ScaffoldMessengerState messenger) {
    var lift = 0.0;
    for (final e in _entries) {
      if (e.messenger != messenger || !e.visible) continue;
      final scaffold = e.scaffold;
      final box = e.context.findRenderObject();
      final frame = scaffold?.context.findRenderObject();
      if (scaffold == null ||
          !scaffold.mounted ||
          box is! RenderBox ||
          frame is! RenderBox ||
          !box.attached ||
          !frame.attached ||
          !box.hasSize ||
          !frame.hasSize) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      final frameBottom = frame.localToGlobal(Offset(0, frame.size.height)).dy;
      final rest = math.min(
        bottom,
        frameBottom - MediaQuery.viewPaddingOf(scaffold.context).bottom,
      );
      lift = math.max(lift, rest - top);
    }
    return lift;
  }
}

/// Internal: one footer's registration, refreshed by its build.
class PinnedFooterEntry {
  PinnedFooterEntry(this.context);
  final BuildContext context;
  ScaffoldMessengerState? messenger;
  ScaffoldState? scaffold;
  ModalRoute<Object?>? route;
  ValueListenable<TickerModeData>? ticker;

  bool get visible =>
      context.mounted &&
      (route?.isCurrent ?? true) &&
      (ticker?.value.enabled ?? true);

  /// Reads the footer's ancestors; call from its build.
  void update(BuildContext context) {
    messenger = ScaffoldMessenger.maybeOf(context);
    scaffold = Scaffold.maybeOf(context);
    route = ModalRoute.of(context);
    ticker = TickerMode.getValuesNotifier(context);
  }
}
