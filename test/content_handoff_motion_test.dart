import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'content_host.dart';
import 'helpers/reduced_motion.dart';

// Content handoffs (D94, #196–#199): onboarding steps arrive from below,
// loading hands off to content, task marks turn, and a kit-owned slot
// collapses, all after mount only. Leaving content takes no taps.

/// The lowest opacity any fade above [finder] paints it at.
double opacityOf(WidgetTester t, Finder finder) => t
    .widgetList<FadeTransition>(
      find.ancestor(of: finder, matching: find.byType(FadeTransition)),
    )
    .map((fade) => fade.opacity.value)
    .reduce((a, b) => a < b ? a : b);

const _tasks = [
  PaymentTaskListItem(title: 'Profile', status: PaymentTaskStatus.inProgress),
  PaymentTaskListItem(title: 'Bank account'),
];
const _next = [
  PaymentTaskListItem(title: 'Profile', status: PaymentTaskStatus.complete),
  PaymentTaskListItem(
    title: 'Bank account',
    status: PaymentTaskStatus.inProgress,
  ),
];
const _done = [
  PaymentTaskListItem(title: 'Profile', status: PaymentTaskStatus.complete),
  PaymentTaskListItem(
    title: 'Bank account',
    status: PaymentTaskStatus.complete,
  ),
];

Widget onboarding({
  required List<PaymentTaskListItem> tasks,
  required String step,
  VoidCallback? onTap,
  bool completed = false,
}) => contentHost(
  PaymentOnboardingView(
    title: 'Set up payouts',
    tasks: tasks,
    completed: completed,
    child: PaymentButton(label: step, onPressed: onTap ?? () {}),
  ),
);

TransactionRecord record(String id) => TransactionRecord(
  id: id,
  title: 'Order $id',
  amount: const Money.idr(25000),
  createdAt: DateTime.utc(2026, 11, 2, 9),
  status: PaymentStatus.succeeded,
);

Widget history({required bool loading, required List<TransactionRecord> rs}) =>
    contentHost(
      TransactionHistory(
        records: rs,
        query: '',
        filter: TransactionFilter.all,
        onQueryChanged: (_) {},
        onFilterChanged: (_) {},
        onOpen: (_) {},
        loading: loading,
      ),
    );

void main() {
  testWidgets('the next onboarding step arrives from below and the leaving '
      'one takes no taps; the done mark settles in', (t) async {
    var leavingTaps = 0;
    await t.pumpWidget(
      onboarding(
        tasks: _tasks,
        step: 'Save profile',
        onTap: () => leavingTaps++,
      ),
    );
    expect(t.hasRunningAnimations, isFalse, reason: 'no entrance on mount');

    await t.pumpWidget(onboarding(tasks: _next, step: 'Link bank'));
    await t.pump(const Duration(milliseconds: 60));
    final arriving = find.text('Link bank');
    expect(opacityOf(t, arriving), inExclusiveRange(0, 1));
    final rest = t.getTopLeft(arriving).dy;
    await t.tap(find.text('Save profile'), warnIfMissed: false);
    expect(leavingTaps, 0, reason: 'the leaving step takes no taps');

    await t.pumpAndSettle();
    expect(find.text('Save profile'), findsNothing);
    expect(t.getTopLeft(arriving).dy, lessThan(rest), reason: 'rose 8 dp');

    await t.pumpWidget(
      onboarding(tasks: _done, step: 'Link bank', completed: true),
    );
    await t.pump(const Duration(milliseconds: 60));
    final mark = find.byIcon(Icons.check_circle_outline);
    final scale = t
        .widget<ScaleTransition>(
          find.ancestor(of: mark, matching: find.byType(ScaleTransition)).first,
        )
        .scale
        .value;
    expect(scale, inExclusiveRange(0.95, 1), reason: 'compact fadeScale');
    await t.pumpAndSettle();
    expect(find.text('All steps complete'), findsOneWidget);
  });

  testWidgets('the list fades in after loading, then a new filter result '
      'swaps at once', (t) async {
    await t.pumpWidget(history(loading: true, rs: const []));
    expect(t.hasRunningAnimations, isFalse, reason: 'no entrance on mount');

    await t.pumpWidget(history(loading: false, rs: [record('1'), record('2')]));
    await t.pump(const Duration(milliseconds: 60));
    expect(opacityOf(t, find.text('Order 1')), inExclusiveRange(0, 1));
    expect(find.byType(LoadingSkeleton), findsOneWidget, reason: 'fading out');
    await t.pumpAndSettle();
    expect(find.byType(LoadingSkeleton), findsNothing);

    // Ready → ready (a search or filter result) is instant, height included.
    await t.pumpWidget(history(loading: false, rs: [record('2')]));
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
    expect(find.text('Order 1'), findsNothing);
  });

  testWidgets('a completed task mark turns into a check', (t) async {
    await t.pumpWidget(contentHost(const PaymentTaskList(items: _tasks)));
    expect(t.hasRunningAnimations, isFalse, reason: 'no entrance on mount');

    await t.pumpWidget(contentHost(const PaymentTaskList(items: _next)));
    await t.pump(const Duration(milliseconds: 50));
    expect(
      opacityOf(t, find.byIcon(Icons.check_circle)),
      inExclusiveRange(0, 1),
    );
    // Profile's half mark fades out while Bank account's arrives.
    expect(find.byIcon(Icons.contrast), findsNWidgets(2));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('a dismissed promo collapses and the content below glides up; '
      'the leaving card takes no taps', (t) async {
    const offer = PromoContent(
      id: 'p1',
      kind: PromoKind.promotion,
      title: 'Cashback 10%',
      ctaLabel: 'See offer',
    );
    var actions = 0;
    Widget slot(PromoSlotState state) => contentHost(
      Column(
        children: [
          PromoSlot(state: state, content: offer, onAction: (_) => actions++),
          const Text('Pay now'),
        ],
      ),
    );
    await t.pumpWidget(slot(PromoSlotState.ready));
    final top = t.getTopLeft(find.text('Pay now')).dy;

    await t.pumpWidget(slot(PromoSlotState.empty));
    await t.pump(const Duration(milliseconds: 80));
    await t.tap(find.text('See offer'), warnIfMissed: false);
    expect(actions, 0, reason: 'the leaving card takes no taps');
    // The card fades out (exit), then the slot's height eases to nothing.
    await t.pump(const Duration(milliseconds: 80));
    await t.pump(const Duration(milliseconds: 80));
    final mid = t.getTopLeft(find.text('Pay now')).dy;
    expect(mid, inExclusiveRange(0, top), reason: 'gliding, not jumping');

    await t.pumpAndSettle();
    expect(find.text('Cashback 10%'), findsNothing);
    expect(t.getTopLeft(find.text('Pay now')).dy, 0);
  });

  testWidgets('an onboarding step swap is instant under reduced motion', (
    t,
  ) async {
    final app = ReducedMotion.mediaQuery.apply(
      t,
      onboarding(tasks: _tasks, step: 'Save profile'),
    );
    await t.pumpWidget(app);
    await expectStill(
      t,
      () => t.pumpWidget(
        ReducedMotion.mediaQuery.apply(
          t,
          onboarding(tasks: _next, step: 'Link bank'),
        ),
      ),
    );
    expect(find.text('Save profile'), findsNothing);
  });
}
