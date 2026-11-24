import '../foundation/primitives.dart';
import '../foundation/view_frame.dart';
import '../interaction/interaction.dart';
import '../foundation/payment_icons.dart';
import '../controls/actions.dart';
import 'package:flutter/material.dart';

import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/first_line.dart';
import 'modal_presenters.dart';

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
        theme.space(PaymentSpace.group),
        theme.space(PaymentSpace.related),
        theme.space(PaymentSpace.related),
        theme.space(PaymentSpace.related),
      ),
      // The title's first line centres on the 48 dp close button at every
      // text scale (#61-7). The band stays 48 without the button, so hiding
      // it during a host call does not move the title.
      child: FirstLineRow(
        line: lineHeightOf(context, type.title),
        trailingExtent: 48,
        text: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(title, style: type.title)),
            if (subtitle != null) ...[
              SizedBox(height: theme.space(PaymentSpace.inline)),
              Text(subtitle!, style: type.caption),
            ],
          ],
        ),
        trailing: onClose == null
            ? null
            : PaymentIconButton(
                icon: PaymentIcons.close,
                tooltip: l10n.closeSheet,
                onPressed: onClose,
              ),
      ),
    );
  }
}

/// Layout for bottom sheets and side panels: a fixed [header], a [body]
/// that scrolls when it is taller than the space, and a fixed [footer] for
/// actions. Respects the safe area and moves above the software keyboard.
///
/// As the direct body of [showPaymentSideSheet], it fills the panel. In a
/// bottom sheet the default constructor hugs its content unless [height] is
/// set. [PaymentSheet.scrollable] gives a caller-owned scrollable the
/// remaining space directly.
class PaymentSheet extends StatelessWidget {
  /// Wraps [body] in a scroll view with the sheet's standard gutters.
  const PaymentSheet({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.height,
  }) : _ownsScroll = true,
       assert(height == null || (height > 0 && height < double.infinity));

  /// Gives [body] a finite viewport without wrapping it in a scroll view or
  /// adding gutters. Pass a [ListView] or [CustomScrollView] and set its padding
  /// as needed. Without [height], the parent must bound the height. When a
  /// keyboard leaves a short, wide viewport, the header and footer move beside
  /// the body to leave room for editing.
  const PaymentSheet.scrollable({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.height,
  }) : _ownsScroll = false,
       assert(height == null || (height > 0 && height < double.infinity));

  /// Optional fixed content above the scrolling body.
  final Widget? header;

  /// The content to scroll, or the scrollable itself in [PaymentSheet.scrollable].
  final Widget body;

  /// Optional fixed actions below the scrolling body.
  final Widget? footer;

  /// Requested height in logical pixels, excluding the keyboard inset and
  /// route drag handle. Must be finite and positive, with room for the header
  /// and footer. Parent constraints can limit it or require the sheet to fill
  /// the panel.
  final double? height;

  final bool _ownsScroll;

  @override
  Widget build(BuildContext context) {
    final fill =
        height != null ||
        _SideSheetScope.of(context) ||
        inFullHeightSheet(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final gutter = PaymentTheme.of(context).space(PaymentSpace.group);
    final scrollBody = _ownsScroll
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
            child: body,
          )
        : body;
    // The sheet's body has no column cap, so neither has its footer.
    final bottom = footer != null
        ? PinnedFooter(maxContentWidth: null, child: footer!)
        : const SafeArea(top: false, child: SizedBox.shrink());
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: _ownsScroll
            ? Column(
                mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?header,
                  if (fill)
                    Expanded(child: scrollBody)
                  else
                    Flexible(child: scrollBody),
                  bottom,
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Leave a touch target's worth of height after the padded
                  // header and footer, or trade width for that height.
                  final beside =
                      keyboard > 0 &&
                      constraints.maxHeight < 4 * kMinInteractiveDimension &&
                      constraints.maxWidth >= 480;
                  Widget rail(Widget child, {required int flex}) => Flexible(
                    flex: flex,
                    child: Center(
                      child: SingleChildScrollView(
                        primary: false,
                        child: child,
                      ),
                    ),
                  );
                  return Flex(
                    direction: beside ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null)
                        beside ? rail(header!, flex: 3) : header!,
                      // Keep this slot in place so the editor retains focus.
                      Expanded(
                        key: const ValueKey('sheet-body'),
                        flex: beside ? 3 : 1,
                        child: scrollBody,
                      ),
                      if (footer != null)
                        // Resize the same footer; remounting it resets any
                        // pending action lock in its buttons.
                        Flexible(
                          key: const ValueKey('sheet-footer'),
                          flex: beside ? 2 : 0,
                          child: Center(
                            heightFactor: 1,
                            child: SingleChildScrollView(
                              primary: false,
                              child: SizedBox(
                                width: double.infinity,
                                child: PinnedFooter(
                                  maxContentWidth: null,
                                  besideBody: beside,
                                  padding: beside
                                      ? EdgeInsets.symmetric(horizontal: gutter)
                                      : null,
                                  child: footer!,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        bottom,
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Opens a modal bottom sheet sized to its content, up to the full height.
/// Use [PaymentSheet.height] to request a shorter panel.
///
/// Swipe down, the scrim, Back and Escape dismiss it when [isDismissible]
/// is true; pass false while a host call that must finish is running.
Future<T?> showPaymentSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showKitBottomSheet(
    context: context,
    builder: builder,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
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
  final navigator = Navigator.of(context, rootNavigator: true);
  // The root navigator sits above any feature-scoped Theme, so the caller's
  // themes are captured once here and wrap the whole panel, chrome included.
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push(
    _SideSheetRoute<T>(
      motion: motion,
      barrierDismissible: barrierDismissible,
      barrierLabel: l10n.closeSheet,
      pageBuilder: (_, _, _) => themes.wrap(
        Builder(
          builder: (context) {
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
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Slides from the edge it lives on; the exit plays the same curve
        // backwards, so the panel goes back the way it came.
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: Offset(rtl ? -1 : 1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: PaymentMotion.drawer)),
          ),
          child: child,
        );
      },
    ),
  );
}

// showGeneralDialog's route reuses the enter duration for the exit and
// fades the scrim on its own curve. This one exits at sheetExit, and the
// scrim follows the panel on the drawer curve. Both are zero under reduced
// motion.
class _SideSheetRoute<T> extends RawDialogRoute<T> {
  _SideSheetRoute({
    required PaymentMotion motion,
    required super.pageBuilder,
    required super.transitionBuilder,
    super.barrierDismissible,
    super.barrierLabel,
  }) : _exit = motion.sheetExit,
       super(
         barrierColor: Colors.black54,
         transitionDuration: motion.sheetEnter,
       );

  final Duration _exit;

  @override
  Duration get reverseTransitionDuration => _exit;

  @override
  Curve get barrierCurve => PaymentMotion.drawer;
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

  /// Heading displayed above the content.
  final String title;

  /// Explanation of the consequence before confirmation.
  final String message;

  /// Action label naming the consequence of leaving.
  final String exitLabel;

  /// Label for keeping the current task open.
  final String? cancelLabel;
}

/// Presents a focused task through the existing sheet surfaces: a bottom
/// sheet on phones (window shortest side under 600 dp, so also in landscape;
/// D92) and a side sheet on tablets.
Future<T?> showPaymentFocusView<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  PaymentFocusViewSize size = PaymentFocusViewSize.small,
}) {
  Widget scoped(BuildContext c) => _FocusScope(
    size: size,
    child: Builder(builder: builder),
  );
  if (!isCompact(context)) {
    return showPaymentSideSheet<T>(
      context: context,
      maxWidth: size == PaymentFocusViewSize.small ? 420 : 720,
      builder: scoped,
    );
  }
  return showKitBottomSheet<T>(
    context: context,
    builder: scoped,
    enableDrag: false,
    showDragHandle: false,
  );
}

class _FocusScope extends InheritedWidget {
  const _FocusScope({required this.size, required super.child});

  /// Width of the focused task presentation.
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

  /// Heading displayed above the content.
  final String title;

  /// Content rendered inside this layout body.
  final Widget child;

  /// The single main action in the task footer.
  final PaymentButton? primaryAction;

  /// Supporting or dismiss action in the task footer.
  final PaymentButton? secondaryAction;

  /// Supporting footer content alongside task actions.
  final Widget? footer;

  /// Dirty-draft confirmation; null allows immediate close.
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
