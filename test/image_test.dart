import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

class PendingImage extends ImageProvider<PendingImage> {
  const PendingImage();
  @override
  Future<PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

void main() {
  testWidgets('Pending image retains alt and host placeholder', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentImage(
          image: PendingImage(),
          alt: 'Bank logo',
          width: 96,
          height: 64,
          placeholder: Text('Loading tile'),
        ),
        1,
      ),
    );
    expect(find.text('Loading tile'), findsOneWidget);
    expect(find.bySemanticsLabel('Bank logo'), findsOneWidget);
  });
  testWidgets('Failed provider uses fallback semantics', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentImage(
          image: MemoryImage(Uint8List.fromList([0, 1, 2])),
          alt: 'Photo',
          width: 96,
          height: 64,
          errorFallback: const Text('Frame for your ID card'),
        ),
        1,
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Frame for your ID card'), findsOneWidget);
    expect(find.bySemanticsLabel('Photo'), findsNothing);
  });
}
