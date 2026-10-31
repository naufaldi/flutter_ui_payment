import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controls/actions.dart';
import '../foundation/field_trigger.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/focus_ring.dart';

/// Compact value or filter; callbacks select removable, edit or suggested kind.
class PaymentChip extends StatelessWidget {
  const PaymentChip({
    super.key,
    required this.label,
    this.value,
    this.values,
    this.onClose,
    this.onDropdown,
    this.onAddSuggestion,
  }) : assert(value == null || values == null),
       assert(
         onAddSuggestion == null ||
             (value == null &&
                 values == null &&
                 onClose == null &&
                 onDropdown == null),
       );

  /// label for this component.
  final String label;

  /// value for this component.
  final String? value;

  /// values for this component.
  final List<String>? values;

  /// onClose for this component.
  final VoidCallback? onClose;

  /// onDropdown for this component.
  final VoidCallback? onDropdown;

  /// onAddSuggestion for this component.
  final VoidCallback? onAddSuggestion;
  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final style = PaymentType.of(context).caption;
    final shown = value ?? (values == null ? null : joinLabels(values!));
    final action = onDropdown ?? onAddSuggestion;
    Widget body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          t.space(PaymentSpace.block),
          t.space(PaymentSpace.block),
          onClose == null ? t.space(PaymentSpace.block) : 0,
          t.space(PaymentSpace.block),
        ),
        child: Wrap(
          spacing: t.space(PaymentSpace.inline),
          children: [
            if (onAddSuggestion != null)
              const PaymentIcon(
                Icons.add,
                size: PaymentIconSize.small,
                color: PaymentTextColor.secondary,
              ),
            Text(label, style: style),
            if (shown != null)
              Text(shown, style: style.copyWith(color: t.textPrimary)),
            if (onDropdown != null)
              const PaymentIcon(
                Icons.expand_more,
                size: PaymentIconSize.small,
                color: PaymentTextColor.secondary,
              ),
          ],
        ),
      ),
    );
    body = Semantics(
      button: action != null,
      label: shown == null ? label : '$label: $shown',
      child: ExcludeSemantics(child: body),
    );
    if (action != null) {
      body = PaymentFocusRing(
        radius: BorderRadius.circular(999),
        child: InkWell(
          onTap: action,
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: body,
        ),
      );
    }
    return PaymentPressScale(
      enabled: action != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: t.space(PaymentSpace.related),
                ),
                child: onAddSuggestion != null
                    ? CustomPaint(painter: _DashedStadiumPainter(t.border))
                    : DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: StadiumBorder(
                            side: BorderSide(color: t.border),
                          ),
                          color: t.surface,
                        ),
                      ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(fit: FlexFit.loose, child: body),
                if (onClose != null)
                  PaymentIconButton(
                    icon: PaymentIcons.close,
                    tooltip: PaymentLocalizations.of(context).removeItem(label),
                    onPressed: onClose,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  _DashedStadiumPainter(this.color);

  /// color for this component.
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var x = 0.0; x < metric.length; x += 7) {
        canvas.drawPath(
          metric.extractPath(x, (x + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadiumPainter old) => old.color != color;
}

/// Related chips with arrow-key focus traversal.
class PaymentChipList extends StatelessWidget {
  const PaymentChipList({
    super.key,
    required this.children,
    this.reverse = false,
  });

  /// children for this component.
  final List<PaymentChip> children;

  /// reverse for this component.
  final bool reverse;
  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousFocusIntent(),
      },
      child: Wrap(
        spacing: PaymentTheme.of(context).space(PaymentSpace.related),
        textDirection: reverse
            ? (Directionality.of(context) == TextDirection.ltr
                  ? TextDirection.rtl
                  : TextDirection.ltr)
            : null,
        children: children,
      ),
    ),
  );
}
