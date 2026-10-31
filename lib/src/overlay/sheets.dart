import '../foundation/primitives.dart';
import '../foundation/view_frame.dart';
import '../interaction/interaction.dart';
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
  return _showSheet(
    context: context,
    builder: builder,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    showDragHandle: true,
  );
}

Future<T?> _showSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool isDismissible,
  required bool enableDrag,
  required bool showDragHandle,
}) {
  /// Paymentmotion.of(context) supplied by the host.
  final motion = PaymentMotion.of(context);

  /// Paymenttheme.of(context) supplied by the host.
  final theme = PaymentTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
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

/// Opens a panel from the end edge (right in left-to-right languages), for
/// filters or details on wide screens. The scrim, Back and Escape close it;
/// focus returns to whatever opened it.
Future<T?> showPaymentSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = 420,
}) {
  /// Paymentmotion.of(context) supplied by the host.
  final motion = PaymentMotion.of(context);

  /// Paymentlocalizations.of(context) supplied by the host.
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

/// Focus task size on phone and wide panels.
enum PaymentFocusViewSize {
  /// Content-height phone sheet or 420 dp side panel.
  small,

  /// Full-height phone sheet or 720 dp side panel.
  large,
}

/// Copy for protecting unsaved work on close.
@immutable
class PaymentConfirmClose {
  const PaymentConfirmClose({
    required this.title,
    required this.message,
    required this.exitLabel,
    this.cancelLabel,
  });

  /// Title supplied by the host.
  final String title;

  /// Message supplied by the host.
  final String message;

  /// Exitlabel supplied by the host.
  final String exitLabel;

  /// Cancellabel supplied by the host.
  final String? cancelLabel;
}

/// Presents a focused task through the existing sheet surfaces.
Future<T?> showPaymentFocusView<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  PaymentFocusViewSize size = PaymentFocusViewSize.small,
}) {
  Widget scoped(BuildContext c) => _FocusScope(
    size: size,
    child: Builder(builder: builder),
  );
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showPaymentSideSheet<T>(
      context: context,
      maxWidth: size == PaymentFocusViewSize.small ? 420 : 720,
      builder: scoped,
    );
  }
  return _showSheet<T>(
    context: context,
    builder: scoped,
    isDismissible: true,
    enableDrag: false,
    showDragHandle: false,
  );
}

class _FocusScope extends InheritedWidget {
  const _FocusScope({required this.size, required super.child});

  /// Size supplied by the host.
  final PaymentFocusViewSize size;
  @override
  bool updateShouldNotify(_FocusScope oldWidget) => size != oldWidget.size;
}

/// A focused task body; only its presentation function opens a sheet.
class PaymentFocusView extends StatefulWidget {
  const PaymentFocusView({
    super.key,
    required this.title,
    required this.child,
    this.primaryAction,
    this.secondaryAction,
    this.footer,
    this.confirmClose,
  });

  /// Title supplied by the host.
  final String title;

  /// Child supplied by the host.
  final Widget child;

  /// Primaryaction supplied by the host.
  final PaymentButton? primaryAction;

  /// Secondaryaction supplied by the host.
  final PaymentButton? secondaryAction;

  /// Footer supplied by the host.
  final Widget? footer;

  /// Confirmclose supplied by the host.
  final PaymentConfirmClose? confirmClose;
  @override
  State<PaymentFocusView> createState() => _PaymentFocusViewState();
}

class _PaymentFocusViewState extends State<PaymentFocusView> {
  bool _asking = false;
  @override
  Widget build(BuildContext context) {
    final w = widget;

    final scope = context.dependOnInheritedWidgetOfExactType<_FocusScope>();
    Widget sheet = PaymentSheet(
      header: PaymentSheetHeader(
        title: w.title,
        onClose: scope == null ? null : () => Navigator.maybePop(context),
      ),
      body: w.child,
      footer:
          w.footer == null &&
              w.primaryAction == null &&
              w.secondaryAction == null
          ? null
          : ViewFooter(
              footer: w.footer,
              primaryAction: w.primaryAction,
              secondaryAction: w.secondaryAction,
            ),
    );
    if (scope == null) return sheet;
    if (scope.size == PaymentFocusViewSize.large) {
      sheet = _SideSheetScope(child: sheet);
    }
    return PopScope<Object?>(
      canPop: w.confirmClose == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _asking || w.confirmClose == null) return;
        _asking = true;

        final c = w.confirmClose!;

        final leave = await showPaymentConfirmDialog(
          context,
          title: c.title,
          message: c.message,
          confirmLabel: c.exitLabel,
          cancelLabel: c.cancelLabel,
          destructive: true,
        );
        _asking = false;
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: sheet,
    );
  }
}
