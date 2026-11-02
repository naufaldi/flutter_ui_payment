import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'helpers/reduced_motion.dart';

Widget motionHost(Widget child, ValueNotifier<bool> reduce) => MaterialApp(
  localizationsDelegates: const [PaymentLocalizations.delegate],
  builder: (context, child) => ValueListenableBuilder<bool>(
    valueListenable: reduce,
    builder: (context, on, _) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: on || MediaQuery.of(context).disableAnimations,
      ),
      child: child!,
    ),
  ),
  home: Scaffold(body: child),
);

void enable(
  WidgetTester tester,
  ReducedMotion setup,
  ValueNotifier<bool> reduce,
) {
  if (setup == ReducedMotion.mediaQuery) {
    reduce.value = true;
  } else {
    setup.apply(tester, const SizedBox());
  }
}

void main() {
  for (final setup in ReducedMotion.values) {
    for (final pending in [false, true]) {
      testWidgets(
        'next toast survives reduced-motion flip (${setup.name}, pending: $pending)',
        (tester) async {
          final reduce = ValueNotifier(false);
          addTearDown(reduce.dispose);
          late BuildContext context;
          await tester.pumpWidget(
            motionHost(
              Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
              reduce,
            ),
          );
          // Exercise the legacy controller's close reason too.
          // ignore: deprecated_member_use_from_same_package
          final first = showPaymentSnackBar(context, message: 'Toast A');
          await tester.pumpAndSettle();
          expect(find.text('Toast A'), findsOneWidget);
          enable(tester, setup, reduce);
          await tester.pump();
          final second = showPaymentToast(
            context,
            message: 'Toast B',
            pending: pending,
          );
          await tester.pump();
          await tester.pump();
          expect(find.text('Toast A'), findsNothing);
          expect(find.text('Toast B'), findsOneWidget);
          expect(await first.closed, SnackBarClosedReason.remove);
          if (pending) {
            await tester.pump(const Duration(seconds: 10));
            expect(find.text('Toast B'), findsOneWidget);
            second.dismiss();
          } else {
            await tester.pump(const Duration(milliseconds: 3999));
            expect(find.text('Toast B'), findsOneWidget);
            await tester.pump(const Duration(milliseconds: 1));
          }
          await tester.pumpAndSettle();
          expect(find.byType(SnackBar), findsNothing);
        },
      );
    }
    for (final kind in ['bottom sheet', 'side sheet', 'dialog', 'toast']) {
      testWidgets('$kind opens and closes still (${setup.name})', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final reduce = ValueNotifier(false);
        addTearDown(reduce.dispose);
        enable(tester, setup, reduce);
        late BuildContext context;
        await tester.pumpWidget(
          motionHost(
            Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
            reduce,
          ),
        );
        PaymentToastController? toast;
        await expectStill(tester, () {
          switch (kind) {
            case 'bottom sheet':
              showPaymentSheet<void>(
                context: context,
                builder: (_) => const Text('Panel'),
              );
            case 'side sheet':
              showPaymentSideSheet<void>(
                context: context,
                builder: (_) => const Text('Panel'),
              );
            case 'dialog':
              showPaymentConfirmDialog(
                context,
                title: 'Panel',
                message: 'Continue?',
                confirmLabel: 'Confirm',
              );
            case 'toast':
              toast = showPaymentToast(
                context,
                message: 'Panel',
                pending: true,
              );
          }
        });
        await tester.pump();
        expect(find.text('Panel'), findsOneWidget);
        if (kind == 'dialog') {
          final route = ModalRoute.of(tester.element(find.byType(Dialog)))!;
          expect(route.animation!.value, 1);
          final fades = tester.widgetList<FadeTransition>(
            find.ancestor(
              of: find.byType(Dialog),
              matching: find.byType(FadeTransition),
            ),
          );
          expect(fades.map((f) => f.opacity.value), everyElement(1.0));
        }
        if (toast != null) {
          await expectStill(
            tester,
            () => toast!.update('Updated', tone: StatusTone.success),
          );
          await tester.pump();
          expect(find.byType(PaymentSpinner), findsNothing);
          expect(find.byIcon(PaymentIcons.success), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(SnackBar),
              matching: find.byType(AnimatedSize),
            ),
            findsNothing,
          );
        }
        await expectStill(tester, () {
          if (toast != null) {
            toast!.dismiss();
          } else {
            Navigator.of(context).pop();
          }
        });
        await tester.pump(const Duration(microseconds: 1));
        expect(find.text('Panel'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      });
    }
    testWidgets(
      'controlled disclosure opens and closes still (${setup.name})',
      (tester) async {
        final reduce = ValueNotifier(false);
        final expanded = ValueNotifier(false);
        addTearDown(reduce.dispose);
        addTearDown(expanded.dispose);
        enable(tester, setup, reduce);
        await tester.pumpWidget(
          motionHost(
            ValueListenableBuilder<bool>(
              valueListenable: expanded,
              builder: (_, open, _) => PaymentAccordionItem(
                title: 'Receipt',
                expanded: open,
                child: const Text('Body'),
              ),
            ),
            reduce,
          ),
        );
        await expectStill(tester, () => expanded.value = true);
        expect(find.text('Body'), findsOneWidget);
        await expectStill(tester, () => expanded.value = false);
        expect(find.text('Body'), findsNothing);
      },
    );
    testWidgets(
      'toast reading timer works after instant entrance (${setup.name})',
      (tester) async {
        final reduce = ValueNotifier(false);
        addTearDown(reduce.dispose);
        enable(tester, setup, reduce);
        late BuildContext context;
        await tester.pumpWidget(
          motionHost(
            Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
            reduce,
          ),
        );
        await expectStill(tester, () {
          showPaymentToast(context, message: 'Copied');
        });
        await tester.pump(const Duration(milliseconds: 3999));
        expect(find.text('Copied'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
      },
    );
    for (final closing in [false, true]) {
      testWidgets(
        'disclosure flip mid-${closing ? 'collapse' : 'expand'} (${setup.name})',
        (tester) async {
          final reduce = ValueNotifier(false);
          final expanded = ValueNotifier(closing);
          addTearDown(reduce.dispose);
          addTearDown(expanded.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            motionHost(
              ValueListenableBuilder<bool>(
                valueListenable: expanded,
                builder: (_, open, _) => PaymentAccordionItem(
                  title: 'Receipt',
                  expanded: open,
                  child: _Body(key: key),
                ),
              ),
              reduce,
            ),
          );
          expanded.value = !closing;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.hasRunningAnimations, isTrue);
          final state = key.currentState;
          await expectStill(tester, () => enable(tester, setup, reduce));
          if (closing) {
            expect(find.text('Body'), findsNothing);
          } else {
            expect(key.currentState, same(state));
            final fade = tester.widget<FadeTransition>(
              find
                  .ancestor(
                    of: find.text('Body'),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            );
            expect(fade.opacity.value, 1);
          }
        },
      );
    }
    testWidgets('toast flip mid-update keeps Undo element (${setup.name})', (
      tester,
    ) async {
      final reduce = ValueNotifier(false);
      addTearDown(reduce.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        motionHost(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
          reduce,
        ),
      );
      final toast = showPaymentToast(
        context,
        message: 'Waiting',
        pending: true,
        actionLabel: 'Undo',
        onAction: () {},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final undo = tester.element(find.widgetWithText(TextButton, 'Undo'));
      toast.update(
        List.filled(40, 'Updated').join(' '),
        tone: StatusTone.success,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.byType(PaymentSpinner), findsOneWidget);
      await expectStill(tester, () => enable(tester, setup, reduce));
      expect(
        tester.element(find.widgetWithText(TextButton, 'Undo')),
        same(undo),
      );
      expect(find.byType(PaymentSpinner), findsNothing);
      expect(find.byIcon(PaymentIcons.success), findsOneWidget);
      toast.dismiss();
      await tester.pumpAndSettle();
    });
  }
}

class _Body extends StatefulWidget {
  const _Body({super.key});
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 100, child: Text('Body'));
}
