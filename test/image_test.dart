import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;
import 'helpers/reduced_motion.dart';

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
  testWidgets('loaded image fades over placeholder then removes it', (t) async {
    final result = Completer<ImageInfo>();
    final semantics = t.ensureSemantics();
    await t.pumpWidget(imageHost(ControlledImage(result.future)));
    expect(find.byKey(const Key('ph')), findsOneWidget);
    await completeImage(t, result);
    await t.pump();
    await t.pump(const Duration(milliseconds: 75));
    expect(find.byKey(const Key('ph')), findsOneWidget);
    final fade = t.widget<FadeTransition>(
      find.descendant(
        of: find.byType(PaymentImage),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, allOf(greaterThan(0), lessThan(1)));
    expect(find.bySemanticsLabel('Bank logo'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('ph')), findsNothing);
    semantics.dispose();
  });
  for (final setup in ReducedMotion.values) {
    testWidgets('loaded image is instant under ${setup.name}', (t) async {
      final result = Completer<ImageInfo>();
      await t.pumpWidget(
        setup.apply(t, imageHost(ControlledImage(result.future))),
      );
      await completeImage(t, result);
      await expectStill(t, () {});
      expect(find.byKey(const Key('ph')), findsNothing);
    });
  }
  testWidgets('iOS reduced motion finishes image fade mid-flight', (t) async {
    final result = Completer<ImageInfo>();
    await t.pumpWidget(imageHost(ControlledImage(result.future)));
    await completeImage(t, result);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(t.hasRunningAnimations, isTrue);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await expectStill(t, () {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
    });
    expect(find.byKey(const Key('ph')), findsNothing);
  });
  testWidgets('synchronously cached image does not fade', (t) async {
    final result = Completer<ImageInfo>();
    final provider = ControlledImage(result.future);
    await t.pumpWidget(imageHost(provider));
    await completeImage(t, result);
    await t.pumpAndSettle();
    await t.pumpWidget(host(const SizedBox(), 1));
    await t.pumpWidget(imageHost(provider));
    expect(find.byKey(const Key('ph')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(PaymentImage),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(t.hasRunningAnimations, isFalse);
  });
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

class ControlledImage extends ImageProvider<ControlledImage> {
  ControlledImage(this.result);
  final Future<ImageInfo> result;
  @override
  Future<ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    ControlledImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(result);
}

Widget imageHost(ImageProvider provider) => host(
  PaymentImage(
    image: provider,
    alt: 'Bank logo',
    width: 96,
    height: 64,
    placeholder: const SizedBox(key: Key('ph')),
  ),
  1,
);

Future<void> completeImage(WidgetTester t, Completer<ImageInfo> result) async {
  await t.runAsync(() async {
    result.complete(
      ImageInfo(image: await createTestImage(width: 10, height: 10)),
    );
    await Future<void>.delayed(Duration.zero);
  });
}
