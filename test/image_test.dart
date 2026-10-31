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

class AsyncPendingImage extends PendingImage {
  const AsyncPendingImage();
  @override
  Future<PendingImage> obtainKey(ImageConfiguration configuration) async =>
      this;
}

void main() {
  testWidgets('pending tile in a wrap does not turn into an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            Wrap(
              children: [
                PaymentImage(
                  image: AsyncPendingImage(),
                  alt: 'Loading bank logo',
                  width: 96,
                  height: 64,
                ),
              ],
            ),
          ],
        ),
        1,
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });

  testWidgets('asynchronous pending provider stays loading after settlement', (
    tester,
  ) async {
    Object? failure;
    await tester.pumpWidget(
      host(
        Image(
          image: const AsyncPendingImage(),
          errorBuilder: (_, error, stack) {
            failure = error;
            return const SizedBox();
          },
        ),
        1,
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(failure, isNull);
  });

  testWidgets(
    'small error tile fits large text while retaining alt semantics',
    (tester) async {
      await tester.pumpWidget(
        host(
          PaymentImage(
            image: MemoryImage(Uint8List.fromList([0, 1, 2])),
            alt: 'Bank Contoh logo',
            width: 96,
            height: 64,
          ),
          2,
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('Bank Contoh logo, Image unavailable'),
        findsOneWidget,
      );
    },
  );

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
