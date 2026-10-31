import '../foundation/payment_icons.dart';
import '../controls/actions.dart';
import 'package:flutter/material.dart';

import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';

/// Title row for a [PaymentSheet] with an optional close button.
///
/// "Close" only dismisses the panel. It never cancels a payment or any other
/// host operation; put such actions in the footer, behind a confirmation.
class PaymentSheetHeader extends StatelessWidget {
  const PaymentSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final String title;
  final String? subtitle;

  /// Null hides the close button (for example while a host call runs).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.spacing * 2,
        theme.spacing,
        theme.spacing,
        theme.spacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              // Centers the first line on the 48 dp close button.
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: type.title),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: theme.spacing * 0.5),
                    Text(subtitle!, style: type.caption),
                  ],
                ],
              ),
            ),
          ),
          if (onClose != null)
            PaymentIconButton(
              icon: PaymentIcons.close,
              tooltip: l10n.closeSheet,
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

/// Layout for bottom sheets and side panels: a fixed [header], a [body]
/// that scrolls when it is taller than the space, and a fixed [footer] for
/// actions. Respects the safe area and moves above the software keyboard.
///
/// Inside [showPaymentSideSheet] it fills the panel's height so the footer
/// sits at the bottom; in a bottom sheet it hugs its content.
class PaymentSheet extends StatelessWidget {
  const PaymentSheet({super.key, this.header, required this.body, this.footer});

  final Widget? header;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final fill = _SideSheetScope.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final scrollBody = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing * 2,
        0,
        theme.spacing * 2,
        theme.spacing * 2,
      ),
      child: body,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          if (fill)
            Expanded(child: scrollBody)
          else
            Flexible(child: scrollBody),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.outline)),
              ),
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.all(theme.spacing * 2),
                child: footer!,
              ),
            )
          else
            const SafeArea(top: false, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

/// Opens a modal bottom sheet sized to its content, up to the full height.
///
/// Swipe down, the scrim, Back and Escape dismiss it when [isDismissible]
/// is true; pass false while a host call that must finish is running.
Future<T?> showPaymentSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final motion = PaymentMotion.of(context);
  final theme = PaymentTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
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

/// Opens a panel from the end edge (right in left-to-right languages), for
/// filters or details on wide screens. The scrim, Back and Escape close it;
/// focus returns to whatever opened it.
Future<T?> showPaymentSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = 420,
}) {
  final motion = PaymentMotion.of(context);
  final l10n = PaymentLocalizations.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: l10n.closeSheet,
    barrierColor: Colors.black54,
    transitionDuration: motion.sheetEnter,
    pageBuilder: (context, _, _) {
      final theme = PaymentTheme.of(context);
      final width = MediaQuery.sizeOf(context).width;
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: width * 0.88 < maxWidth ? width * 0.88 : maxWidth,
          height: double.infinity,
          child: Material(
            color: theme.surface,
            surfaceTintColor: Colors.transparent,
            child: SafeArea(
              left: false,
              child: _SideSheetScope(child: Builder(builder: builder)),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      // Slides from the edge it lives on; the exit reverses the same path so
      // the panel goes back where it came from.
      final curved = CurvedAnimation(
        parent: animation,
        curve: PaymentMotion.drawer,
        reverseCurve: Curves.easeIn,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(rtl ? -1 : 1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class _SideSheetScope extends InheritedWidget {
  const _SideSheetScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SideSheetScope>() != null;

  @override
  bool updateShouldNotify(_SideSheetScope oldWidget) => false;
}
