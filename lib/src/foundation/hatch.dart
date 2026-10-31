import 'package:flutter/painting.dart';

void paintHatch(
  Canvas canvas,
  Rect rect, {
  required Color color,
  required Color background,
  double pitch = 10,
  double stripe = 6,
}) {
  canvas.save();
  canvas.clipRect(rect);
  canvas.translate(rect.left, rect.top);
  canvas.drawRect(Offset.zero & rect.size, Paint()..color = background);
  final h = rect.height;
  for (var x = -h; x < rect.width + h; x += pitch) {
    final path = Path()
      ..moveTo(x, h)
      ..lineTo(x + stripe, h)
      ..lineTo(x + stripe + h, 0)
      ..lineTo(x + h, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
  canvas.restore();
}
