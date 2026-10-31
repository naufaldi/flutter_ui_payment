import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/tooltip_geometry.dart';

void main() {
  const expected = [
    Offset(150, 362),
    Offset(180, 362),
    Offset(120, 362),
    Offset(150, 448),
    Offset(180, 448),
    Offset(120, 448),
    Offset(72, 405),
    Offset(72, 400),
    Offset(72, 410),
    Offset(228, 405),
    Offset(228, 400),
    Offset(228, 410),
  ];
  for (final p in PaymentTooltipPlacement.values) {
    test('placement $p', () {
      final result = placeTooltip(
        target: const Rect.fromLTWH(180, 400, 40, 40),
        size: const Size(100, 30),
        overlay: const Size(400, 800),
        placement: p,
        direction: TextDirection.ltr,
      );
      expect(result.offset, expected[p.index]);
      expect(result.placement, p);
    });
  }
  test('flip, clamp and RTL', () {
    final flipped = placeTooltip(
      target: const Rect.fromLTWH(0, 10, 40, 40),
      size: const Size(100, 30),
      overlay: const Size(400, 800),
      placement: PaymentTooltipPlacement.top,
      direction: TextDirection.ltr,
    );
    expect(flipped.placement, PaymentTooltipPlacement.bottom);
    expect(flipped.offset, const Offset(8, 58));
    final rtl = placeTooltip(
      target: const Rect.fromLTWH(180, 400, 40, 40),
      size: const Size(100, 30),
      overlay: const Size(400, 800),
      placement: PaymentTooltipPlacement.startTop,
      direction: TextDirection.rtl,
    );
    expect(rtl.offset, const Offset(228, 400));
  });
}
