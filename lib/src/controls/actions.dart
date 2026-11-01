import 'dart:async';
import 'package:flutter/material.dart';
import '../foundation/focus_ring.dart';
import '../foundation/token_resolvers.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/tap_target.dart';

/// Semantic icon colors. Nothing else exists.
enum PaymentIconButtonVariant {
  /// Secondary text for ordinary controls.
  neutral,

  /// Accent for the main value affordance.
  accent,
}

/// A 48 dp action with a spoken tooltip, circular focus ring and press feedback.
class PaymentIconButton extends StatelessWidget {
  /// Creates an icon action; null onPressed disables it.
  const PaymentIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = PaymentIconButtonVariant.neutral,
    this.focusNode,
  }) : assert(tooltip != ''),
       _danger = false;

  // The copy button's failure glyph, in the danger tone.
  const PaymentIconButton._danger({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : variant = PaymentIconButtonVariant.neutral,
       focusNode = null,
       _danger = true;

  final bool _danger;

  /// Semantic glyph.
  final IconData icon;

  /// Nonempty spoken action label.
  final String tooltip;

  /// Host action; null disables interaction.
  final VoidCallback? onPressed;

  /// Semantic icon color.
  final PaymentIconButtonVariant variant;

  /// Host focus node for focus return.
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final color = onPressed == null
        ? theme.disabled
        : _danger
        ? theme.danger.foreground
        : switch (variant) {
            PaymentIconButtonVariant.neutral => theme.textSecondary,
            PaymentIconButtonVariant.accent => theme.accent,
          };
    return TooltipTheme(
      data: TooltipTheme.of(context).copyWith(
        decoration: BoxDecoration(
          color: theme.textPrimary,
          borderRadius: theme.controlBorderRadius,
        ),
        textStyle: type.caption.copyWith(color: theme.surface),
        padding: EdgeInsets.symmetric(
          horizontal: theme.space(PaymentSpace.related),
          vertical: theme.space(PaymentSpace.inline),
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      child: PaymentFocusRing(
        radius: BorderRadius.circular(24),
        child: PaymentPressScale(
          enabled: onPressed != null,
          child: IconButton(
            focusNode: focusNode,
            tooltip: tooltip,
            onPressed: onPressed,
            visualDensity: VisualDensity.standard,
            style: PaymentFocusRing.withoutFocusFill(
              IconButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
            icon: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

/// Inline text hierarchy. Nothing else exists.
enum PaymentLinkVariant {
  /// Heading-weight accent action.
  primary,

  /// Underlined secondary caption.
  secondary,
}

/// Inline text action; the host opens any destination.
class PaymentLink extends StatelessWidget {
  /// Creates a text action with a 48 dp target.
  const PaymentLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.external = false,
    this.variant = PaymentLinkVariant.primary,
    this.semanticLabel,
  });

  /// Visible action label.
  final String label;

  /// Host action; null disables interaction.
  final VoidCallback? onPressed;

  /// Adds an external glyph, link role and destination hint.
  final bool external;

  /// Visual text hierarchy.
  final PaymentLinkVariant variant;

  /// Spoken replacement, such as Edit: Your details.
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final primary = switch (variant) {
      PaymentLinkVariant.primary => true,
      PaymentLinkVariant.secondary => false,
    };
    final style = primary
        ? type.heading
        : type.caption.copyWith(decoration: TextDecoration.underline);
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: !external,
      link: external,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      hint: external ? PaymentLocalizations.of(context).opensExternally : null,
      onTap: onPressed,
      child: MinTapTarget(
        child: PaymentFocusRing(
          radius: theme.controlBorderRadius,
          child: PaymentPressScale(
            enabled: onPressed != null,
            child: TextButton(
              onPressed: onPressed,
              style: PaymentFocusRing.withoutFocusFill(
                TextButton.styleFrom(
                  foregroundColor: primary ? theme.accent : theme.textSecondary,
                  disabledForegroundColor: theme.disabled,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.controlBorderRadius,
                  ),
                  textStyle: style,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: Text(label)),
                  if (external) ...[
                    SizedBox(width: theme.space(PaymentSpace.inline)),
                    SizedBox(
                      height:
                          MediaQuery.textScalerOf(
                            context,
                          ).scale(style.fontSize!) *
                          style.height!,
                      child: Center(
                        child: Icon(
                          PaymentIcons.externalLink,
                          size:
                              (primary
                                      ? PaymentIconSize.medium
                                      : PaymentIconSize.small)
                                  .resolve(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Host-owned copying with a temporary check and persistent inline failure.
class PaymentCopyButton extends StatefulWidget {
  /// Creates a copy action; the host returns whether copying worked.
  const PaymentCopyButton({
    super.key,
    required this.value,
    required this.onCopy,
    this.tooltip,
  });

  /// Synthetic or host-supplied value to copy.
  final String value;

  /// Host copy implementation; exceptions are reported as failure.
  final Future<bool> Function(String value) onCopy;

  /// Spoken label; defaults to the localized copy action.
  final String? tooltip;
  @override
  State<PaymentCopyButton> createState() => _PaymentCopyButtonState();
}

enum _CopyState { idle, pending, copied, failed }

class _PaymentCopyButtonState extends State<PaymentCopyButton> {
  _CopyState _state = _CopyState.idle;
  Timer? _revert;
  int _generation = 0;
  final _failure = OverlayPortalController();
  final _link = LayerLink();
  Future<void> _press() async {
    if (_state == _CopyState.pending) return;
    _revert?.cancel();
    _failure.hide();
    final generation = ++_generation;
    setState(() => _state = _CopyState.pending);
    bool ok;
    try {
      ok = await widget.onCopy(widget.value);
    } catch (_) {
      ok = false;
    }
    if (!mounted || generation != _generation) return;
    setState(() => _state = ok ? _CopyState.copied : _CopyState.failed);
    if (ok) {
      _revert = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _state = _CopyState.idle);
      });
    } else {
      _failure.show();
    }
  }

  @override
  void didUpdateWidget(PaymentCopyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _generation++;
      _revert?.cancel();
      _state = _CopyState.idle;
      _failure.hide();
    }
  }

  @override
  void dispose() {
    _generation++;
    _revert?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final failed = _state == _CopyState.failed;
    final copied = _state == _CopyState.copied;
    final tooltip = widget.tooltip ?? l10n.copy;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The button keeps its 48 dp box in every state; failure swaps the
    // glyph and hangs a persistent label under the button's end edge, over
    // the content below, so nothing moves (#46).
    return OverlayPortal(
      controller: _failure,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _link,
        targetAnchor: rtl ? Alignment.bottomLeft : Alignment.bottomRight,
        followerAnchor: rtl ? Alignment.topLeft : Alignment.topRight,
        child: Align(
          alignment: rtl ? Alignment.topLeft : Alignment.topRight,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Text(
                l10n.copyFailed,
                style: PaymentType.of(
                  context,
                ).tag.copyWith(color: theme.danger.foreground),
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Semantics(
          container: true,
          liveRegion: copied || failed,
          value: copied
              ? l10n.copied
              : failed
              ? l10n.copyFailed
              : null,
          child: failed
              ? PaymentIconButton._danger(
                  icon: PaymentIcons.danger,
                  tooltip: tooltip,
                  onPressed: _press,
                )
              : PaymentIconButton(
                  icon: copied ? PaymentIcons.copied : PaymentIcons.copy,
                  tooltip: tooltip,
                  variant: PaymentIconButtonVariant.accent,
                  onPressed: _press,
                ),
        ),
      ),
    );
  }
}
