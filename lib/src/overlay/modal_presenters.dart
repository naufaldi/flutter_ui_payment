import 'package:flutter/material.dart';

import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';

/// Internal: the kit's modal bottom sheet, shared by [showPaymentSheet], the
/// phone confirm sheet (D45) and the phone menu sheet (D55). Not exported.
///
/// A flat surface with the sheet radius on the top corners only, sized to
/// its content up to the full height, or the full height when [fullHeight]
/// is true. Reduced motion opens and closes it without animation.
Future<T?> showKitBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  bool fullHeight = false,
}) {
  final motion = PaymentMotion.of(context);
  final theme = PaymentTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: fullHeight
        ? (context) => SizedBox(
            height: MediaQuery.sizeOf(context).height,
            child: _FullHeightScope(child: Builder(builder: builder)),
          )
        : builder,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: showDragHandle,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: theme.surface,
    // Flat sheet: the sheet radius on the top corners only, no tint; the
    // default handle is a small 32 x 4 bar.
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: theme.sheetBorderRadius.topLeft),
    ),
    sheetAnimationStyle: motion.reduced
        ? AnimationStyle.noAnimation
        : AnimationStyle(
            duration: motion.sheetEnter,
            reverseDuration: motion.sheetExit,
            curve: PaymentMotion.drawer,
          ),
  );
}

class _FullHeightScope extends InheritedWidget {
  const _FullHeightScope({required super.child});

  @override
  bool updateShouldNotify(_FullHeightScope oldWidget) => false;
}

/// Whether [context] is inside a `showKitBottomSheet(fullHeight: true)`
/// sheet, where a `PaymentSheet` fills the height and pins its footer.
bool inFullHeightSheet(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_FullHeightScope>() != null;

/// Internal: the pinned footer chrome shared by `PaymentSheet` and the kit's
/// full-height sheets: a hairline on top and 16 dp padding, or the bottom
/// safe-area inset when that is larger.
class KitSheetFooter extends StatelessWidget {
  const KitSheetFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.outline)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.all(theme.space(PaymentSpace.group)),
        child: child,
      ),
    );
  }
}

/// Internal: layout of the kit's full-height search and date sheets. A fixed
/// [header] and [top], a [body] that fills the rest (the caller supplies a
/// lazy scrollable), and a pinned [footer]. Moves above the keyboard.
class KitFullSheet extends StatelessWidget {
  const KitFullSheet({
    super.key,
    required this.header,
    this.top,
    required this.body,
    this.footer,
  });

  final Widget header;
  final Widget? top;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final gutter = theme.space(PaymentSpace.group);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (top != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: top,
            ),
          Expanded(child: body),
          if (footer != null)
            KitSheetFooter(child: footer!)
          else
            const SafeArea(top: false, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
