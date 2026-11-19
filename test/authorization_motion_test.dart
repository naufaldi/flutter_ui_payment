import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'content_host.dart';
import 'helpers/reduced_motion.dart';

// AuthorizationPrompt phase handoff (#303, D125): the status slot fades
// between phases and eases its height while the actions update at once.
// The entering phase is readable on the first frame; the leaving one is
// already out of semantics, focus and taps. Reduced motion swaps at once,
// including a swap already running.

Widget prompt(AuthorizationPhase phase) => contentHost(
  AuthorizationPrompt(phase: phase, onStart: () {}, onBackToReview: () {}),
);

/// The lowest opacity any fade above [finder] paints it at.
double opacityOf(WidgetTester t, Finder finder) => t
    .widgetList<FadeTransition>(
      find.ancestor(of: finder, matching: find.byType(FadeTransition)),
    )
    .map((fade) => fade.opacity.value)
    .reduce((a, b) => a < b ? a : b);

/// What a screen reader's traversal can reach, as one string.
String spoken(WidgetTester t) => t.semantics
    .simulatedAccessibilityTraversal()
    .map((node) => node.getSemanticsData())
    .map((data) => '${data.label} ${data.value} ${data.hint}')
    .join(' | ');

void main() {
  testWidgets('the status fades between phases while the actions update '
      'at once', (t) async {
    await t.pumpWidget(prompt(AuthorizationPhase.ready));
    expect(t.hasRunningAnimations, isFalse, reason: 'no entrance on mount');
    final readyTitle = find.text('Confirm it’s you');

    await t.pumpWidget(prompt(AuthorizationPhase.inProgress));
    // Outside the swap: back is gone and the button is busy on the first
    // frame, not after the fade.
    expect(find.text('Back to review'), findsNothing);
    await t.pump(const Duration(milliseconds: 60));
    final waiting = find.text('Waiting for approval…');
    // Both phases paint mid-fade, entering still transparent, neither
    // scaled (D69).
    expect(readyTitle, findsOneWidget);
    expect(waiting, findsOneWidget);
    expect(opacityOf(t, waiting), inExclusiveRange(0, 1));
    expect(opacityOf(t, readyTitle), inExclusiveRange(0, 1));

    await t.pumpWidget(prompt(AuthorizationPhase.failed));
    // Back returns at once for the retryable phase; it is not part of the
    // swap.
    expect(find.text('Back to review'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 20));
    // The interrupted swap keeps the half-faded waiting status leaving
    // while the banner enters; all three phases are mid-fade.
    expect(waiting, findsOneWidget);
    expect(opacityOf(t, waiting), inExclusiveRange(0, 1));
    expect(find.byType(PaymentBanner), findsOneWidget);
    expect(find.text('Confirmation didn’t succeed'), findsOneWidget);
    expect(
      opacityOf(t, find.text('Confirmation didn’t succeed')),
      inExclusiveRange(0, 1),
    );

    await t.pumpAndSettle();
    expect(find.text('Confirm it’s you'), findsNothing);
    expect(find.text('Waiting for approval…'), findsNothing);
    expect(find.text('Confirmation didn’t succeed'), findsOneWidget);
  });

  testWidgets('the new phase is readable on the first frame and the old '
      'one is already gone', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(prompt(AuthorizationPhase.ready));

    // ready → failed: the banner's live region is there while it is still
    // transparent, and the ready text is already out.
    await t.pumpWidget(prompt(AuthorizationPhase.failed));
    expect(t.hasRunningAnimations, isTrue, reason: 'mid-swap');
    expect(spoken(t), contains('Confirmation didn’t succeed'));
    expect(spoken(t), isNot(contains('Confirm it’s you')));
    await t.pumpAndSettle();

    // failed → in progress (retry): the plain status's live region is
    // there on its first frame too.
    await t.pumpWidget(prompt(AuthorizationPhase.inProgress));
    expect(t.hasRunningAnimations, isTrue, reason: 'mid-swap');
    expect(spoken(t), contains('Waiting for approval'));
    expect(spoken(t), isNot(contains('Confirmation didn’t succeed')));
    // The busy button's spinner runs forever, so the swap settles by
    // frames rather than pumpAndSettle.
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Confirmation didn’t succeed'), findsNothing);
    expect(find.text('Waiting for approval…'), findsOneWidget);
    semantics.dispose();
  });

  for (final setup in ReducedMotion.values) {
    testWidgets('a phase swap is instant under reduced motion '
        '(${setup.name})', (t) async {
      await t.pumpWidget(setup.apply(t, prompt(AuthorizationPhase.ready)));
      await expectStill(
        t,
        () =>
            t.pumpWidget(setup.apply(t, prompt(AuthorizationPhase.inProgress))),
      );
      expect(find.text('Confirm it’s you'), findsNothing);
      expect(find.text('Waiting for approval…'), findsOneWidget);
    });
  }

  testWidgets('reduced motion turned on mid-swap ends it at once', (t) async {
    await t.pumpWidget(prompt(AuthorizationPhase.ready));
    await t.pumpWidget(prompt(AuthorizationPhase.failed));
    await t.pump(const Duration(milliseconds: 60));
    expect(find.text('Confirm it’s you'), findsOneWidget, reason: 'fading');

    ReducedMotion.iosReduceMotion.apply(t, const SizedBox());
    await t.pump();
    expect(find.text('Confirm it’s you'), findsNothing);
    expect(find.byType(PaymentBanner), findsOneWidget);
    expect(opacityOf(t, find.text('Confirmation didn’t succeed')), 1);
  });
}
