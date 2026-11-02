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
  for (final setup in ReducedMotion.values) {
    for (final custom in [true, false]) {
      testWidgets('loading placeholder under ${setup.name}, custom=$custom', (
        t,
      ) async {
        final result = Completer<ImageInfo>();
        await t.pumpWidget(
          setup.apply(
            t,
            host(
              PaymentImage(
                image: ControlledImage(result.future),
                alt: 'Bank logo',
                width: 96,
                height: 64,
                placeholder: custom ? const SizedBox(key: Key('ph')) : null,
              ),
              1,
            ),
          ),
        );
        final placeholder = custom
            ? find.byKey(const Key('ph'))
            : find.descendant(
                of: find.byType(PaymentImage),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is ColoredBox &&
                      w.color ==
                          PaymentTheme.of(
                            t.element(find.byType(PaymentImage)),
                          ).surfaceMuted,
                ),
              );
        expect(placeholder, findsOneWidget);
        await completeImage(t, result);
        await expectStill(t, () {});
        expect(placeholder, findsNothing);
      });
    }
    testWidgets('turning ${setup.name} off before load allows fade', (t) async {
      final result = Completer<ImageInfo>();
      final provider = ControlledImage(result.future);
      final reduced = ValueNotifier(true);
      addTearDown(reduced.dispose);
      final app = host(
        ValueListenableBuilder<bool>(
          valueListenable: reduced,
          builder: (context, value, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: setup == ReducedMotion.mediaQuery && value,
            ),
            child: child!,
          ),
          child: PaymentImage(
            image: provider,
            alt: 'Bank logo',
            width: 96,
            height: 64,
            placeholder: const SizedBox(key: Key('ph')),
          ),
        ),
        1,
      );
      await t.pumpWidget(
        setup == ReducedMotion.mediaQuery ? app : setup.apply(t, app),
      );
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      reduced.value = false;
      await t.pump();
      await completeImage(t, result);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(imageFade(t).opacity.value, allOf(greaterThan(0), lessThan(1)));
      expect(find.byKey(const Key('ph')), findsOneWidget);
      await t.pumpAndSettle();
    });
  }
  testWidgets('provider swap fades again after loading', (t) async {
    final first = Completer<ImageInfo>();
    final second = Completer<ImageInfo>();
    await t.pumpWidget(imageHost(ControlledImage(first.future)));
    await completeImage(t, first);
    await t.pumpAndSettle();
    await t.pumpWidget(imageHost(ControlledImage(second.future)));
    expect(find.byKey(const Key('ph')), findsOneWidget);
    await completeImage(t, second);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(imageFade(t).opacity.value, allOf(greaterThan(0), lessThan(1)));
    expect(find.byKey(const Key('ph')), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ph')), findsNothing);
  });
  testWidgets('host placeholder keeps State through load and fade', (t) async {
    final key = GlobalKey<_PlaceholderState>();
    final result = Completer<ImageInfo>();
    await t.pumpWidget(
      host(
        PaymentImage(
          image: ControlledImage(result.future),
          alt: '',
          width: 96,
          height: 64,
          placeholder: _Placeholder(
            key: const ValueKey('host-ph'),
            child: _Placeholder(key: key),
          ),
        ),
        1,
      ),
    );
    final state = key.currentState;
    final hostState = t.state(find.byKey(const ValueKey('host-ph')));
    expect(state, isNotNull);
    await completeImage(t, result);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(key.currentState, same(state));
    expect(t.state(find.byKey(const ValueKey('host-ph'))), same(hostState));
    await t.pumpAndSettle();
    expect(key.currentState, isNull);
  });
  for (final fixed in [true, false]) {
    for (final fit in BoxFit.values) {
      testWidgets('main layout parity fixed=$fixed fit=$fit', (t) async {
        final result = Completer<ImageInfo>();
        final referenceResult = Completer<ImageInfo>();
        const actualKey = Key('actual');
        const referenceKey = Key('reference');
        final width = fixed ? 96.0 : null;
        final height = fixed ? 64.0 : null;
        const placeholder = SizedBox(width: 37, height: 23);
        await t.pumpWidget(
          host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentImage(
                  key: actualKey,
                  image: ControlledImage(result.future),
                  alt: '',
                  width: width,
                  height: height,
                  fit: fit,
                  placeholder: placeholder,
                ),
                SizedBox(
                  key: referenceKey,
                  width: width,
                  height: height,
                  child: Image(
                    image: ControlledImage(referenceResult.future),
                    width: width,
                    height: height,
                    fit: fit,
                    frameBuilder: (_, child, frame, sync) =>
                        frame == null ? placeholder : child,
                  ),
                ),
              ],
            ),
            1,
          ),
        );
        expect(
          t.getSize(find.byKey(actualKey)),
          t.getSize(find.byKey(referenceKey)),
        );
        expect(
          t.getSize(find.byKey(actualKey)),
          fixed ? const Size(96, 64) : const Size(37, 23),
        );
        await completeImage(t, result);
        await completeImage(t, referenceResult);
        await t.pump();
        expect(
          t.getSize(find.byKey(actualKey)),
          t.getSize(find.byKey(referenceKey)),
        );
        expect(
          t.getSize(find.byKey(actualKey)),
          fixed ? const Size(96, 64) : const Size(10, 10),
        );
        await t.pumpAndSettle();
        expect(
          t.getSize(find.byKey(actualKey)),
          t.getSize(find.byKey(referenceKey)),
        );
      });
    }
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
  await t.pump();
}

FadeTransition imageFade(WidgetTester t) => t.widget<FadeTransition>(
  find.descendant(
    of: find.byType(PaymentImage),
    matching: find.byType(FadeTransition),
  ),
);

class _Placeholder extends StatefulWidget {
  const _Placeholder({super.key, this.child});
  final Widget? child;
  @override
  State<_Placeholder> createState() => _PlaceholderState();
}

class _PlaceholderState extends State<_Placeholder> {
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 37, height: 23, child: widget.child);
}
