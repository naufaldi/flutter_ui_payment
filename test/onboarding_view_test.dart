import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  const tasks = [
    PaymentTaskListItem(title: 'Identity', status: PaymentTaskStatus.complete),
    PaymentTaskListItem(
      title: 'Documents',
      status: PaymentTaskStatus.inProgress,
    ),
    PaymentTaskListItem(title: 'Review'),
  ];
  testWidgets('phone puts current value before collapsed task list', (t) async {
    await setSurface(t, const Size(393, 1000));
    await t.pumpWidget(
      contentHost(
        const SizedBox(
          height: 700,
          child: PaymentOnboardingView(
            title: 'Setup',
            tasks: tasks,
            child: Text('Documents content'),
          ),
        ),
      ),
    );
    expect(find.text('Step 2 of 3: Documents'), findsOneWidget);
    expect(find.text('All steps'), findsOneWidget);
    expect(find.text('Review'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'completion calls host once per transition including initial true',
    (t) async {
      var calls = 0;
      Widget host(bool complete) => contentHost(
        SizedBox(
          height: 700,
          child: PaymentOnboardingView(
            title: 'Setup',
            tasks: tasks,
            completed: complete,
            onCompleted: () => calls++,
            child: const Text('Content'),
          ),
        ),
      );
      await t.pumpWidget(host(false));
      await t.pumpWidget(host(true));
      await t.pump();
      await t.pumpWidget(host(true));
      await t.pump();
      expect(calls, 1);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(host(true));
      await t.pump();
      expect(calls, 2);
    },
  );
  testWidgets('wide sidebar and pending content', (t) async {
    await setSurface(t, const Size(1024, 1000));
    await t.pumpWidget(
      contentHost(
        const SizedBox(
          height: 700,
          child: PaymentOnboardingView(
            title: 'Setup',
            tasks: tasks,
            pending: true,
            child: Text('Content'),
          ),
        ),
      ),
    );
    expect(find.byType(PaymentTaskList), findsOneWidget);
    expect(find.byType(PaymentAccordionItem), findsNothing);
    expect(find.text('Loading'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('phone gaps: spinner → text 12, content → accordion 16 (#66)', (
    t,
  ) async {
    await setSurface(t, const Size(393, 1000));
    await t.pumpWidget(
      contentHost(
        const SizedBox(
          height: 700,
          child: PaymentOnboardingView(
            title: 'Setup',
            tasks: tasks,
            pending: true,
            child: Text('Content'),
          ),
        ),
      ),
    );
    final spinner = t.getRect(find.byType(PaymentSpinner));
    final loading = t.getRect(find.text('Loading'));
    expect(loading.left - spinner.right, 12);
    final accordion = t.getRect(find.byType(PaymentAccordionItem));
    final row = t.getRect(
      find.ancestor(of: find.text('Loading'), matching: find.byType(Row)).first,
    );
    expect(accordion.top - row.bottom, 16);
  });
  testWidgets('a filled first field shows its whole floating label at rest '
      '(#228)', (t) async {
    await setSurface(t, const Size(360, 640));
    await t.pumpWidget(
      contentHost(
        const SizedBox(
          height: 640,
          child: PaymentOnboardingView(
            title: 'Your details',
            tasks: tasks,
            // A long form: the body scrolls, so its viewport clips.
            child: Column(
              children: [
                PaymentTextField(label: 'Full name', initialValue: 'Rina'),
                SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final label = t.renderObject<RenderBox>(find.text('Full name'));
    final rect = label.localToGlobal(Offset.zero) & label.size;
    // The label floats above the field's box, which starts the body.
    final field = t.getRect(find.byType(InputDecorator));
    expect(rect.top, lessThan(field.top));
    RenderObject child = label;
    for (var parent = label.parent; parent != null; parent = parent.parent) {
      final clip = parent.describeApproximatePaintClip(child);
      if (clip != null && parent is RenderBox) {
        final shown = clip.shift(parent.localToGlobal(Offset.zero));
        expect(
          shown.intersect(rect),
          rect,
          reason: 'clipped by ${parent.runtimeType}',
        );
      }
      child = parent;
    }
  });
}
