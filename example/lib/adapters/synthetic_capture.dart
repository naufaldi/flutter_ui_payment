import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

class SyntheticIdCard extends StatelessWidget {
  const SyntheticIdCard({super.key, required this.obscured});
  final bool obscured;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 85.6 / 54,
    child: ColoredBox(
      color: const Color(0xffdce9ef),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CONTOH / SPECIMEN'),
            const Text('DEMO SARI WULANDARI (CONTOH)'),
            PrivacyMask(
              obscured: obscured,
              child: const Text('3100000000001234'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SyntheticCameraPreview extends StatelessWidget {
  const SyntheticCameraPreview({super.key, required this.kind});
  final CaptureKind kind;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SyntheticPainter(kind));
}

class _SyntheticPainter extends CustomPainter {
  _SyntheticPainter(this.kind, {this.blurry = false});
  final CaptureKind kind;
  final bool blurry;
  void text(
    Canvas canvas,
    String value,
    Offset at,
    double width, {
    double fontSize = 18,
  }) {
    (TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: const Color(0xff223747),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width)).paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (blurry) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      );
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff9baba8),
    );
    if (kind == CaptureKind.selfieWithIdCard) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .5, size.height * .35),
          width: size.width * .34,
          height: size.width * .44,
        ),
        Paint()..color = const Color(0xffc9a78f),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .5, size.height * .78),
          width: size.width * .85,
          height: size.width * .7,
        ),
        Paint()..color = const Color(0xff405c66),
      );
    }
    final width = size.width * (kind == CaptureKind.idCard ? .78 : .42);
    final card = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height * (kind == CaptureKind.idCard ? .5 : .7),
      ),
      width: width,
      height: width * 54 / 85.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(card, Radius.circular(width * .04)),
      Paint()..color = const Color(0xffdce9ef),
    );
    text(
      canvas,
      'DEMO SARI WULANDARI (CONTOH)',
      card.topLeft + Offset(width * .05, width * .08),
      width * .62,
      fontSize: width * .036,
    );
    text(
      canvas,
      'NIK •••• •••• •••• 1234',
      card.topLeft + Offset(width * .05, width * .25),
      width * .65,
      fontSize: width * .035,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        card.left + width * .73,
        card.top + width * .12,
        width * .2,
        width * .3,
      ),
      Paint()..color = const Color(0xff91aab7),
    );
    canvas.save();
    canvas.translate(card.center.dx, card.center.dy);
    canvas.rotate(-.25);
    text(
      canvas,
      'CONTOH / SPECIMEN',
      Offset(-width * .45, 0),
      width,
      fontSize: width * .08,
    );
    canvas.restore();
    if (blurry) canvas.restore();
  }

  @override
  bool shouldRepaint(_SyntheticPainter oldDelegate) =>
      kind != oldDelegate.kind || blurry != oldDelegate.blurry;
}

Future<ImageProvider> renderSyntheticPhoto(
  CaptureKind kind, {
  bool blurry = false,
}) async {
  final recorder = ui.PictureRecorder();
  _SyntheticPainter(
    kind,
    blurry: blurry,
  ).paint(Canvas(recorder), const Size(900, 1200));
  final picture = recorder.endRecording();
  final image = await picture.toImage(900, 1200);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return MemoryImage(bytes!.buffer.asUint8List());
}
