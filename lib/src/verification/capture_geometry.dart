import 'package:flutter/painting.dart';
import 'capture_models.dart';

({Rect card, Rect? face}) captureFrameRects(CaptureKind kind, Size size) {
  final width = size.width * (kind == CaptureKind.idCard ? .86 : .44);
  final height = width * 54 / 85.6;
  if (kind == CaptureKind.idCard) {
    return (
      card: Rect.fromCenter(
        center: size.center(Offset.zero),
        width: width,
        height: height,
      ),
      face: null,
    );
  }
  final faceWidth = size.width * .46;
  final face = Rect.fromCenter(
    center: Offset(size.width / 2, size.height * .38),
    width: faceWidth,
    height: faceWidth * 1.3,
  );
  return (
    card: Rect.fromLTWH(
      (size.width - width) / 2,
      face.bottom + size.height * .025,
      width,
      height,
    ),
    face: face,
  );
}
