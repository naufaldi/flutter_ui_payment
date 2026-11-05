import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'helpers/reduced_motion.dart';

/// Reports the motion its context sees on every build.
class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox();
  }
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => const SizedBox(height: 10);
}

/// Passes [parent] through and counts the listeners registered on it.
class _CountingAnimation extends Animation<double> {
  _CountingAnimation(this.parent);

  final Animation<double> parent;
  int listeners = 0;
  int statusListeners = 0;

  @override
  double get value => parent.value;

  @override
  AnimationStatus get status => parent.status;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    parent.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    parent.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners++;
    parent.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners--;
    parent.removeStatusListener(listener);
  }
}

Widget _app(Widget home) => MaterialApp(home: home);

const _a = ValueKey('a');
const _b = ValueKey('b');

/// A full-width swap between a 50 dp child [_a] and a 100 dp child [_b].
Widget _swap(bool showB) => _app(
  Align(
    alignment: Alignment.topCenter,
    child: Builder(
      builder: (context) => PaymentMotion.of(context).fullWidthSwap(
        showB
            ? const SizedBox(key: _b, height: 100, width: double.infinity)
            : const SizedBox(key: _a, height: 50, width: double.infinity),
      ),
    ),
  ),
);

void main() {
  testWidgets('fadeRise keeps leaving state when direction flips mid-swap', (
    t,
  ) async {
    var mounts = 0;
    var showB = false, back = false;
    late StateSetter rebuild;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) =>
                  PaymentMotion.fadeRise(c, a, back: back),
              child: showB
                  ? const SizedBox(key: _b)
                  : _MountProbe(key: _a, onMount: () => mounts++),
            );
          },
        ),
      ),
    );
    final state = t.state(find.byKey(_a));
    rebuild(() => showB = true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    rebuild(() => back = true);
    await t.pump();
    expect(mounts, 1);
    expect(t.state(find.byKey(_a)), same(state));
    await t.pumpAndSettle();
  });
  group('PaymentMotion.reduced (D65)', () {
    testWidgets('false by default', (tester) async {
      late bool reduced;
      await tester.pumpWidget(
        _app(_Probe((c) => reduced = PaymentMotion.of(c).reduced)),
      );
      expect(reduced, isFalse);
    });

    testWidgets('false when every platform flag is off', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      late bool reduced;
      await tester.pumpWidget(
        _app(_Probe((c) => reduced = PaymentMotion.of(c).reduced)),
      );
      expect(reduced, isFalse);
    });

    for (final setup in ReducedMotion.values) {
      testWidgets('true under ${setup.name}', (tester) async {
        late bool reduced;
        late Duration enter;
        late double scale;
        await tester.pumpWidget(
          setup.apply(
            tester,
            _app(
              _Probe((c) {
                final motion = PaymentMotion.of(c);
                reduced = motion.reduced;
                enter = motion.enter;
                scale = motion.pressedScale;
              }),
            ),
          ),
        );
        expect(reduced, isTrue);
        // D66: zero for both flags, no cross-fade variant.
        expect(enter, Duration.zero);
        expect(scale, 1);
      });
    }

    testWidgets('reads the iOS flag even under a MediaQuery that says no', (
      tester,
    ) async {
      // `a ?? false || b` would parse as `a ?? (false || b)` and never read
      // the platform flag while a MediaQuery is present.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      late bool reduced;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: _Probe((c) => reduced = PaymentMotion.of(c).reduced),
            ),
          ),
        ),
      );
      expect(reduced, isTrue);
    });

    testWidgets('a later Reduce Motion is seen on the next rebuild', (
      tester,
    ) async {
      late bool reduced;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _Probe((c) => reduced = PaymentMotion.of(c).reduced);
            },
          ),
        ),
      );
      expect(reduced, isFalse);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      rebuild(() {});
      await tester.pump();
      expect(reduced, isTrue);
    });

    testWidgets('Android disableAnimations rebuilds MediaQuery.fromView', (
      tester,
    ) async {
      // Decides whether the androidRemoveAnimations setup needs a MediaQuery
      // override as well: it doesn't, because MediaQuery.fromView listens.
      late bool mediaQuery;
      late bool reduced;
      await tester.pumpWidget(
        _app(
          _Probe((c) {
            mediaQuery = MediaQuery.disableAnimationsOf(c);
            reduced = PaymentMotion.of(c).reduced;
          }),
        ),
      );
      expect(mediaQuery, isFalse);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pump();
      expect(mediaQuery, isTrue);
      expect(reduced, isTrue);
    });
  });

  group('fadeRise (D70)', () {
    Future<Offset> topLeftAt(
      WidgetTester tester,
      double t,
      double height, {
      bool back = false,
    }) async {
      const child = ValueKey('child');
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: PaymentMotion.fadeRise(
            SizedBox(key: child, width: 100, height: height),
            AlwaysStoppedAnimation(t),
            back: back,
          ),
        ),
      );
      return tester.getTopLeft(find.byKey(child));
    }

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(find.byType(FadeTransition))
        .opacity
        .value;

    for (final height in [100.0, 800.0]) {
      testWidgets('rises exactly 8 dp for a $height dp child', (tester) async {
        expect(await topLeftAt(tester, 0, height), const Offset(0, 8));
        expect(opacity(tester), 0);
        expect(await topLeftAt(tester, 1, height), Offset.zero);
        expect(opacity(tester), 1);
      });
    }

    testWidgets('back mode fades with no rise', (tester) async {
      expect(await topLeftAt(tester, 0, 800, back: true), Offset.zero);
      expect(opacity(tester), 0);
      expect(await topLeftAt(tester, 0.5, 800, back: true), Offset.zero);
      expect(opacity(tester), inExclusiveRange(0, 1));
      expect(
        tester
            .widget<Transform>(find.byType(Transform))
            .transform
            .getTranslation()
            .y,
        0,
      );
    });

    test('still fits AnimatedSwitcher.transitionBuilder', () {
      // A compile-time check: the new named parameter is optional.
      const AnimatedSwitcherTransitionBuilder builder = PaymentMotion.fadeRise;
      expect(builder, isNotNull);
    });
  });

  group('transition builders (#116)', () {
    final builders = <String, AnimatedSwitcherTransitionBuilder>{
      'fadeScale': PaymentMotion.fadeScale,
      'fadeRise': PaymentMotion.fadeRise,
      'fadeRise back': (c, a) => PaymentMotion.fadeRise(c, a, back: true),
    };
    for (final MapEntry(key: name, value: builder) in builders.entries) {
      testWidgets('$name keeps a fixed listener count over rebuilds', (
        tester,
      ) async {
        // AnimatedSwitcher calls its transitionBuilder again with the same
        // entry animation on every child update during a swap.
        final controller = AnimationController(
          vsync: tester,
          duration: const Duration(milliseconds: 220),
        );
        addTearDown(controller.dispose);
        final animation = _CountingAnimation(controller);
        late StateSetter rebuild;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return builder(const SizedBox(), animation);
            },
          ),
        );
        unawaited(controller.forward());
        await tester.pump(const Duration(milliseconds: 50));
        final listeners = animation.listeners;
        final statusListeners = animation.statusListeners;
        for (var i = 0; i < 20; i++) {
          rebuild(() {});
          await tester.pump(const Duration(milliseconds: 5));
        }
        expect(animation.statusListeners, statusListeners);
        expect(animation.listeners, listeners);
        controller.stop();
        await tester.pumpWidget(const SizedBox());
        expect(animation.statusListeners, 0);
        expect(animation.listeners, 0);
      });
    }

    testWidgets('fadeScale keeps its easeOut fade and 0.95 scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        PaymentMotion.fadeScale(
          const SizedBox(),
          const AlwaysStoppedAnimation(0.5),
        ),
      );
      final eased = PaymentMotion.easeOut.transform(0.5);
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition))
            .opacity
            .value,
        eased,
      );
      expect(
        tester
            .widget<ScaleTransition>(find.byType(ScaleTransition))
            .scale
            .value,
        closeTo(0.95 + 0.05 * eased, 1e-12),
      );
    });
  });

  group('fullWidthSwap (D69)', () {
    Finder swapSize() => find.byType(AnimatedSize);

    testWidgets('fades only, full width, while the height eases', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_swap(false));
      expect(tester.getSize(swapSize()).height, 50);

      await tester.pumpWidget(_swap(true));
      await tester.pump(const Duration(milliseconds: 50));
      // Both children are on screen, full width, at the top, unscaled.
      for (final key in [_a, _b]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, 0);
        expect(rect.top, 0);
        expect(rect.width, 400);
      }
      expect(
        find.descendant(of: swapSize(), matching: find.byType(ScaleTransition)),
        findsNothing,
      );
      expect(
        find.descendant(of: swapSize(), matching: find.byType(SlideTransition)),
        findsNothing,
      );
      final fades = tester
          .widgetList<FadeTransition>(
            find.descendant(
              of: swapSize(),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value);
      expect(fades, everyElement(inExclusiveRange(0, 1)));
      // The height eases from 50 towards 100 instead of jumping.
      final early = tester.getSize(swapSize()).height;
      expect(early, inExclusiveRange(50, 100));

      await tester.pump(const Duration(milliseconds: 60));
      final middle = tester.getSize(swapSize()).height;
      expect(middle, inExclusiveRange(early, 100));

      await tester.pumpAndSettle();
      expect(tester.getSize(swapSize()).height, 100);
      expect(find.byKey(_a), findsNothing);
    });

    testWidgets('the leaving child takes no taps', (tester) async {
      await tester.pumpWidget(_swap(false));
      await tester.pumpWidget(_swap(true));
      await tester.pump(const Duration(milliseconds: 50));
      final leaving = tester.widget<IgnorePointer>(
        find
            .ancestor(of: find.byKey(_a), matching: find.byType(IgnorePointer))
            .first,
      );
      expect(leaving.ignoring, isTrue);
    });

    for (final setup in ReducedMotion.values) {
      testWidgets('is instant under ${setup.name}', (tester) async {
        await tester.pumpWidget(setup.apply(tester, _swap(false)));
        await expectStill(
          tester,
          () => tester.pumpWidget(setup.apply(tester, _swap(true))),
        );
        expect(find.byType(AnimatedSize), findsNothing);
        expect(tester.getSize(find.byKey(_b)).height, 100);
        expect(find.byKey(_a), findsNothing);
      });
    }

    // Two swaps side by side, each from a plain child to a stateful one,
    // under a MediaQuery that can turn reduced motion on.
    Widget twoSwaps({required bool showNew, required bool reduce}) => _app(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: Builder(
            builder: (context) {
              final motion = PaymentMotion.of(context);
              return Column(
                children: [
                  for (final id in ['one', 'two'])
                    motion.fullWidthSwap(
                      showNew
                          ? _Counter(key: ValueKey('$id-new'))
                          : SizedBox(key: ValueKey('$id-old'), height: 50),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );

    Future<void> startSwaps(WidgetTester tester) async {
      await tester.pumpWidget(twoSwaps(showNew: false, reduce: false));
      await tester.pumpWidget(twoSwaps(showNew: true, reduce: false));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      for (final id in ['one', 'two']) {
        tester.state<_CounterState>(find.byKey(ValueKey('$id-new'))).count = 3;
      }
    }

    void expectSwapsDone(WidgetTester tester) {
      for (final id in ['one', 'two']) {
        expect(find.byKey(ValueKey('$id-old')), findsNothing);
        final current = find.byKey(ValueKey('$id-new'));
        expect(tester.state<_CounterState>(current).count, 3);
        final fade = tester.widget<FadeTransition>(
          find
              .ancestor(of: current, matching: find.byType(FadeTransition))
              .first,
        );
        expect(fade.opacity.value, 1);
      }
    }

    testWidgets('ends a running swap when MediaQuery turns reduced on', (
      tester,
    ) async {
      await startSwaps(tester);
      await expectStill(
        tester,
        () => tester.pumpWidget(twoSwaps(showNew: true, reduce: true)),
      );
      expectSwapsDone(tester);

      // Turned back off, the next swap fades again.
      await tester.pumpWidget(twoSwaps(showNew: true, reduce: false));
      await tester.pumpWidget(twoSwaps(showNew: false, reduce: false));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.byKey(const ValueKey('one-new')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('one-new')), findsNothing);
    });

    testWidgets('ends a running swap when iOS Reduce Motion turns on', (
      tester,
    ) async {
      await startSwaps(tester);
      // Nothing above the swaps rebuilds: reduceMotion isn't in
      // MediaQueryData, so the swap has to notice the change itself.
      await expectStill(tester, () {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              reduceMotion: true,
              autoPlayVideos: true,
            );
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      });
      expectSwapsDone(tester);
    });

    testWidgets('keeps its content when reduced motion turns on', (
      tester,
    ) async {
      var reduce = false;
      late StateSetter set;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduce),
                child: Builder(
                  builder: (context) => PaymentMotion.of(
                    context,
                  ).fullWidthSwap(const _Counter(key: _a)),
                ),
              );
            },
          ),
        ),
      );
      tester.state<_CounterState>(find.byType(_Counter)).count = 3;
      set(() => reduce = true);
      await tester.pump();
      expect(find.byType(AnimatedSize), findsNothing);
      expect(tester.state<_CounterState>(find.byType(_Counter)).count, 3);
    });
  });
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required super.key, required this.onMount});
  final VoidCallback onMount;
  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 20);
}
