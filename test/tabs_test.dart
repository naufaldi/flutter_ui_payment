import 'dart:ui' show SemanticsRole, Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
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
  testWidgets('fitted tabs divide width and large text wraps', (tester) async {
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
    expect(tester.getSize(wells.at(0)).width, 160);
    expect(tester.getSize(wells.at(1)).width, 160);
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
