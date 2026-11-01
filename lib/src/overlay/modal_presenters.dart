import 'package:flutter/material.dart';

import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';

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
            child: builder(context),
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
