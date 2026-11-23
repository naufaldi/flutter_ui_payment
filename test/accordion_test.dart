import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('mid-collapse retains Body and fades until exit', (tester) async {
    await tester.pumpWidget(
      host(
        const SingleChildScrollView(
          child: PaymentAccordionItem(
            title: 'Receipt',
            initiallyExpanded: true,
            child: SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(find.text('Body'), findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Body'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 75));
    await tester.pump(const Duration(microseconds: 1));
    expect(find.text('Body'), findsNothing);
  });
  testWidgets('re-tapping reverses collapse without a height jump', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: PaymentAccordionItem(
            title: 'Receipt',
            initiallyExpanded: true,
            child: _Body(key: key),
          ),
        ),
        1,
      ),
    );
    final item = find
        .descendant(
          of: find.byType(PaymentAccordionItem),
          matching: find.byType(Column),
        )
        .first;
    final full = tester.getSize(item).height;
    final state = key.currentState!;
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(key.currentState, same(state));
    await tester.pump(const Duration(milliseconds: 75));
    expect(key.currentState, same(state));
    final middle = tester.getSize(item).height;
    expect(middle, lessThan(full));
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(key.currentState, same(state));
    expect(tester.getSize(item).height, closeTo(middle, 0.01));
    for (var frame = 0; frame < 15; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(key.currentState, same(state));
      expect(find.text('Body'), findsOneWidget);
      // The turn keeps a little of the collapse's momentum, so the reveal
      // can dip a few pixels before it climbs; it must never jump.
      expect(tester.getSize(item).height, greaterThanOrEqualTo(middle - 4));
    }
    await tester.pumpAndSettle();
    expect(tester.getSize(item).height, full);
  });
  testWidgets('reopening mid-collapse turns the reveal without a speed snap', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SingleChildScrollView(
          child: PaymentAccordionItem(
            title: 'Receipt',
            child: SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );

    // The displayed progress: the heightFactor the reveal is painted with.
    double progress() {
      for (final align in tester.widgetList<Align>(
        find.descendant(
          of: find.byType(PaymentAccordionItem),
          matching: find.byType(Align),
        ),
      )) {
        if (align.heightFactor != null) return align.heightFactor!;
      }
      fail('no reveal Align found');
    }

    // Open part-way, collapse, then reopen before the collapse settles.
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    final collapse = <double>[];
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      collapse.add(progress());
    }
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    final atTurn = progress();
    expect(atTurn, closeTo(collapse.last, 0.0001));

    // Height and fade read the same value, so they cannot disagree mid-turn.
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Body'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, closeTo(atTurn, 0.0001));

    final reopen = <double>[];
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      reopen.add(progress());
    }
    // The collapse was still travelling when the tap landed, so the first
    // frame keeps a small step in the old direction; it cannot already be
    // moving at reopen speed. A restarted curve snaps here instead.
    final stepBefore = collapse.last - collapse[collapse.length - 2];
    final stepAfter = reopen.first - atTurn;
    expect(stepAfter.abs(), lessThan(stepBefore.abs() * 0.5));
    // It turns, arrives open and then stops ticking.
    expect(reopen.last, greaterThan(0.98));
    await tester.pumpAndSettle();
    expect(progress(), closeTo(1, 0.0001));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('Body'), findsOneWidget);
  });
  testWidgets('rapid taps keep the latest target', (tester) async {
    await tester.pumpWidget(
      host(
        const SingleChildScrollView(
          child: PaymentAccordionItem(
            title: 'Receipt',
            child: SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Collapse mid-open, reopen mid-collapse, collapse mid-reopen: three
    // reversals in a row, each retargeting the running spring.
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
  });
  testWidgets('collapsing content takes no taps', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentAccordionItem(
          title: 'Receipt',
          initiallyExpanded: true,
          child: GestureDetector(
            onTap: () => calls++,
            child: const SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );
    final point = tester.getCenter(find.text('Body'));
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Body'), findsOneWidget);
    await tester.tapAt(point);
    expect(calls, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('actions do not toggle; header controls its content', (
    tester,
  ) async {
    var edits = 0;
    final toggles = <bool>[];
    await tester.pumpWidget(
      host(
        PaymentAccordion(
          children: [
            PaymentAccordionItem(
              title: 'Receipt',
              onExpandedChanged: toggles.add,
              actions: [
                PaymentButton(
                  label: 'Edit',
                  size: PaymentSize.small,
                  width: PaymentWidth.hug,
                  variant: PaymentButtonVariant.secondary,
                  onPressed: () => edits++,
                ),
              ],
              child: const Text('Body'),
            ),
          ],
        ),
        1,
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(toggles, isEmpty);
    expect(find.text('Body'), findsNothing);
    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    expect(toggles, [true]);
    expect(find.text('Body'), findsOneWidget);
    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });
  testWidgets('controlled state stays host-owned and initial state works', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      host(
        PaymentAccordionItem(
          title: 'Controlled',
          expanded: false,
          onExpandedChanged: changes.add,
          child: const Text('Body'),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Controlled'));
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(find.text('Body'), findsNothing);
    await tester.pumpWidget(
      host(
        const PaymentAccordionItem(
          key: ValueKey('new'),
          title: 'Initial',
          initiallyExpanded: true,
          child: Text('Body'),
        ),
        1,
      ),
    );
    expect(find.text('Body'), findsOneWidget);
  });
  testWidgets('unsupported actions assert', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentAccordionItem(
          title: 'Receipt',
          actions: [PaymentButton(label: 'Edit', onPressed: () {})],
          child: const Text('Body'),
        ),
        1,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
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
