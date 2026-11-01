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
import '../foundation/token_resolvers.dart';

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

  /// Visible name identifying this value or control.
  final String label;

  /// Current value of this applied filter.
  final String? value;

  /// Multiple values summarized by this applied filter.
  final List<String>? values;

  /// Removes this applied value through the host.
  final VoidCallback? onClose;

  /// Opens host choices for this filter.
  final VoidCallback? onDropdown;

  /// Accepts this suggested filter through the host.
  final VoidCallback? onAddSuggestion;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _chip(context, box.maxWidth));

  // Width of the chip's content on one line: padding, icons, gaps, both
  // texts and the close target.
  double _oneLineWidth(BuildContext context, String? shown) {
    final t = PaymentTheme.of(context);
    final style = PaymentType.of(context).caption;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: scaler,
        textDirection: direction,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final icon = PaymentIconSize.small.resolve(context);
    final gap = t.space(PaymentSpace.inline);
    final parts = <double>[
      if (onAddSuggestion != null) icon,
      measure(label),
      if (shown != null) measure(shown),
      if (onDropdown != null) icon,
    ];
    return t.space(PaymentSpace.group) +
        parts.reduce((a, b) => a + b) +
        gap * (parts.length - 1) +
        (onClose == null ? t.space(PaymentSpace.group) : 48);
  }

  Widget _chip(BuildContext context, double maxWidth) {
    final t = PaymentTheme.of(context);
    final style = PaymentType.of(context).caption;
    final shown = value ?? (values == null ? null : joinLabels(values!));
    final action = onDropdown ?? onAddSuggestion;
    // A chip that wraps becomes a rounded rectangle, so text never runs
    // into the pill's curved ends (#48).
    final wraps = _oneLineWidth(context, shown) > maxWidth;
    final radius = wraps
        ? t.controlBorderRadius
        : const BorderRadius.all(Radius.circular(999));
    final shape = wraps
        ? RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: t.border),
          )
        : StadiumBorder(side: BorderSide(color: t.border));
    // Content centres in the 48 dp box; a wrapped chip keeps 12 above and
    // below so its lines clear the drawn border.
    Widget body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            t.space(PaymentSpace.group),
            t.space(PaymentSpace.block),
            onClose == null ? t.space(PaymentSpace.group) : 0,
            t.space(PaymentSpace.block),
          ),
          child: Wrap(
            spacing: t.space(PaymentSpace.inline),
            crossAxisAlignment: WrapCrossAlignment.center,
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
      ),
    );
    body = Semantics(
      button: action != null,
      label: shown == null ? label : '$label: $shown',
      child: ExcludeSemantics(child: body),
    );
    if (action != null) {
      body = PaymentFocusRing(
        radius: radius,
        child: InkWell(
          onTap: action,
          customBorder: wraps
              ? RoundedRectangleBorder(borderRadius: radius)
              : const StadiumBorder(),
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
                    ? CustomPaint(
                        painter: _DashedStadiumPainter(
                          t.border,
                          wraps ? t.controlBorderRadius.topLeft.x : null,
                        ),
                      )
                    : DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: shape,
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
  _DashedStadiumPainter(this.color, this.radius);

  /// Stroke color resolved from the theme.
  final Color color;

  /// Corner radius; null draws a pill.
  final double? radius;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius ?? size.height / 2),
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
  bool shouldRepaint(_DashedStadiumPainter old) =>
      old.color != color || old.radius != radius;
}

/// Related chips with arrow-key focus traversal.
class PaymentChipList extends StatelessWidget {
  const PaymentChipList({
    super.key,
    required this.children,
    this.reverse = false,
  });

  /// Chips in host reading order.
  final List<PaymentChip> children;

  /// Places the chip row in reverse reading order.
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
