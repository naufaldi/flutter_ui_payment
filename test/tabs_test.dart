import 'content_host.dart' as phase4;
import 'dart:ui' show SemanticsRole, Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets(
    'at 2x and 320 dp the selected last tab scrolls fully into view',
    (t) async {
      await phase4.setSurface(t, const Size(320, 800));
      var selected = 0;
      late StateSetter update;
      await t.pumpWidget(
        phase4.contentHost(
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return PaymentTabs(
                  tabs: const [
                    PaymentTab(label: 'All payments'),
                    PaymentTab(label: 'Succeeded'),
                    PaymentTab(label: 'Unsuccessful'),
                    PaymentTab(label: 'Refunded'),
                  ],
                  selectedIndex: selected,
                  onSelected: (i) => setState(() => selected = i),
                );
              },
            ),
          ),
          scale: 2,
        ),
      );
      await t.pumpAndSettle();
      final row = find.byType(PaymentTabs);
      expect(
        find.descendant(of: row, matching: find.byType(ShaderMask)),
        findsOneWidget,
      );
      final scroll = t.state<ScrollableState>(
        find.descendant(of: row, matching: find.byType(Scrollable)),
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      update(() => selected = 3);
      await t.pumpAndSettle();
      final viewport = t.getRect(row);
      final last = t.getRect(find.text('Refunded'));
      expect(last.left, greaterThanOrEqualTo(viewport.left));
      expect(last.right, lessThanOrEqualTo(viewport.right));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'fitted tabs retain equal widths when fitting and scroll at 200 percent',
    (t) async {
      await phase4.setSurface(t, const Size(800, 1000));
      Widget tabs() => PaymentTabs(
        tabs: const [
          PaymentTab(label: 'Card'),
          PaymentTab(label: 'Bank transfer'),
          PaymentTab(label: 'Wallet'),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
        fitted: true,
      );
      await t.pumpWidget(phase4.contentHost(tabs()));
      expect(
        t
            .widgetList<Scrollable>(find.byType(Scrollable))
            .any((s) => s.axisDirection == AxisDirection.right),
        isFalse,
      );
      await phase4.setSurface(t, const Size(320, 1000));
      await t.pumpWidget(phase4.contentHost(tabs(), scale: 2));
      expect(
        t
            .widgetList<Scrollable>(find.byType(Scrollable))
            .any((s) => s.axisDirection == AxisDirection.right),
        isTrue,
      );
      expect(t.takeException(), isNull);
    },
  );

  const tabs = [
    PaymentTab(label: 'Card'),
    PaymentTab(label: 'Bank', disabledReason: 'Unavailable'),
    PaymentTab(label: 'Wallet'),
  ];
  testWidgets('disabled tabs and manual keyboard activation', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      host(
        PaymentTabs(tabs: tabs, selectedIndex: 0, onSelected: selected.add),
        1,
      ),
    );
    final semantics = tester.ensureSemantics();
    await tester.pump();
    final bank = tester.getSemantics(find.text('Bank'));
    expect(bank.flagsCollection.isEnabled, Tristate.isFalse);
    expect(bank.hint, 'Unavailable');
    expect(bank.role, SemanticsRole.tab);
    semantics.dispose();
    await tester.tap(find.text('Bank'));
    expect(selected, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, [2]);
  });
  testWidgets('fitted tabs fall back to scrolling at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        PaymentTabs(
          tabs: const [
            PaymentTab(label: 'Card'),
            PaymentTab(label: 'Bank transfer'),
          ],
          selectedIndex: 0,
          fitted: true,
          onSelected: (_) {},
        ),
        2,
      ),
    );
    final wells = find.descendant(
      of: find.byType(PaymentTabs),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(wells.at(1)).width, greaterThan(160));
    expect(
      find.descendant(
        of: find.byType(PaymentTabs),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'panels build lazily, preserve state and size to visible content',
    (tester) async {
      var builds = 0;
      Widget panels(int selected) => host(
        PaymentTabPanels(
          selectedIndex: selected,
          children: [
            const SizedBox(height: 50, child: _Counter()),
            Builder(
              builder: (_) {
                builds++;
                return const SizedBox(height: 100, child: Text('Second'));
              },
            ),
          ],
        ),
        1,
      );
      await tester.pumpWidget(panels(0));
      expect(builds, 0);
      await tester.tap(find.text('Count 0'));
      await tester.pump();
      await tester.pumpWidget(panels(1));
      expect(builds, 1);
      expect(find.text('Count 1'), findsNothing);
      expect(tester.getSize(find.byType(PaymentTabPanels)).height, 100);
      await tester.pumpWidget(panels(0));
      expect(find.text('Count 1'), findsOneWidget);
      expect(tester.getSize(find.byType(PaymentTabPanels)).height, 50);
    },
  );
  testWidgets('visiting an earlier panel preserves the later panel state', (
    tester,
  ) async {
    Widget panels(int selected) => host(
      PaymentTabPanels(
        selectedIndex: selected,
        children: const [
          SizedBox(height: 50),
          SizedBox(height: 50, child: _Counter()),
        ],
      ),
      1,
    );
    await tester.pumpWidget(panels(1));
    await tester.tap(find.text('Count 0'));
    await tester.pump();
    await tester.pumpWidget(panels(0));
    await tester.pumpWidget(panels(1));
    expect(find.text('Count 1'), findsOneWidget);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => count++),
    child: Text('Count $count'),
  );
}
