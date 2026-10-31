import 'package:flutter/widgets.dart';
import '../controls/controls.dart' show PaymentTooltipPlacement;

/// Positions the bubble, flipping its side before clamping to the viewport.
({Offset offset, PaymentTooltipPlacement placement}) placeTooltip({
  required Rect target,
  required Size size,
  required Size overlay,
  required PaymentTooltipPlacement placement,
  required TextDirection direction,
  double gap = 8,
  double margin = 8,
}) {
  final rtl = direction == TextDirection.rtl;
  Offset position(PaymentTooltipPlacement p) {
    final vertical = p.index < 6;
    if (vertical) {
      final top = p.index < 3;
      final align = p.index % 3;
      final x = switch (align) {
        0 => target.center.dx - size.width / 2,
        1 => rtl ? target.right - size.width : target.left,
        _ => rtl ? target.left : target.right - size.width,
      };
      return Offset(
        x,
        top ? target.top - gap - size.height : target.bottom + gap,
      );
    }
    final start = p.index < 9;
    final left = start != rtl;
    final y = switch (p.index % 3) {
      0 => target.center.dy - size.height / 2,
      1 => target.top,
      _ => target.bottom - size.height,
    };
    return Offset(
      left ? target.left - gap - size.width : target.right + gap,
      y,
    );
  }

  bool fits(Offset o) => placement.index < 6
      ? o.dy >= margin && o.dy + size.height <= overlay.height - margin
      : o.dx >= margin && o.dx + size.width <= overlay.width - margin;
  final opposite = switch (placement) {
    PaymentTooltipPlacement.top => PaymentTooltipPlacement.bottom,
    PaymentTooltipPlacement.topStart => PaymentTooltipPlacement.bottomStart,
    PaymentTooltipPlacement.topEnd => PaymentTooltipPlacement.bottomEnd,
    PaymentTooltipPlacement.bottom => PaymentTooltipPlacement.top,
    PaymentTooltipPlacement.bottomStart => PaymentTooltipPlacement.topStart,
    PaymentTooltipPlacement.bottomEnd => PaymentTooltipPlacement.topEnd,
    PaymentTooltipPlacement.start => PaymentTooltipPlacement.end,
    PaymentTooltipPlacement.startTop => PaymentTooltipPlacement.endTop,
    PaymentTooltipPlacement.startBottom => PaymentTooltipPlacement.endBottom,
    PaymentTooltipPlacement.end => PaymentTooltipPlacement.start,
    PaymentTooltipPlacement.endTop => PaymentTooltipPlacement.startTop,
    PaymentTooltipPlacement.endBottom => PaymentTooltipPlacement.startBottom,
  };
  var used = placement;
  var offset = position(used);
  if (!fits(offset) && fits(position(opposite))) {
    used = opposite;
    offset = position(used);
  }
  final maxX = (overlay.width - margin - size.width).clamp(
    margin,
    double.infinity,
  );
  final maxY = (overlay.height - margin - size.height).clamp(
    margin,
    double.infinity,
  );
  return (
    offset: Offset(
      offset.dx.clamp(margin, maxX),
      offset.dy.clamp(margin, maxY),
    ),
    placement: used,
  );
}
