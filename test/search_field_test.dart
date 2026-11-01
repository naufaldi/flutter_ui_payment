import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/search_fold.dart';
import 'first_line_test.dart' show host;
import 'dialog_test.dart' show compact, wide, surface;

const _options = [
  PaymentSearchOption(value: 'aceh', label: 'Áceh'),
  PaymentSearchOption(value: 'barat', label: 'Jawa Barat'),
  PaymentSearchOption(value: 'timur', label: 'Jawa Timur'),
];

Finder get _sheetEditor => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.byType(EditableText),
);

void main() {
  test('local filter correctness over 1000 values', () {
    expect(
      List.generate(
        1000,
        (i) => 'Item $i',
      ).where((s) => matchesQuery(foldForSearch(s), 'Item 99')).length,
      11,
    );
  });
  testWidgets('filter, live count and keyboard selection', (tester) async {
    String? picked;
    await tester.pumpWidget(
      host(
        PaymentSearchField<String>(
          label: 'Province',
          options: const [
            PaymentSearchOption(value: 'aceh', label: 'Áceh'),
            PaymentSearchOption(value: 'barat', label: 'Jawa Barat'),
            PaymentSearchOption(value: 'timur', label: 'Jawa Timur'),
          ],
          selected: null,
          onSelected: (v) => picked = v,
        ),
        1,
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'jawa');
    await tester.pumpAndSettle();
    expect(find.text('Áceh'), findsNothing);
    expect(find.bySemanticsLabel('2 results'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, 'timur');
    expect(find.text('Jawa Timur'), findsOneWidget);
  });

  group('compact (D50)', () {
    testWidgets('tap opens a focused sheet; typing filters; a pick closes', (
      tester,
    ) async {
      surface(tester, compact);
      String? picked;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => PaymentSearchField<String>(
              label: 'Province',
              options: _options,
              selected: picked,
              onSelected: (v) => setState(() => picked = v),
            ),
          ),
          1,
        ),
      );
      // A trigger, not an inline editor.
      expect(find.byType(EditableText), findsNothing);
      await tester.tap(find.text('Province'));
      await tester.pumpAndSettle();
      expect(_sheetEditor, findsOneWidget);
      expect(
        tester.widget<EditableText>(_sheetEditor).focusNode.hasFocus,
        isTrue,
      );
      // Full height: the sheet reaches the top of the safe area.
      expect(tester.getSize(find.byType(BottomSheet)).height, compact.height);
      await tester.enterText(_sheetEditor, 'jawa');
      await tester.pumpAndSettle();
      expect(find.text('Áceh'), findsNothing);
      expect(find.bySemanticsLabel('2 results'), findsOneWidget);
      await tester.tap(find.text('Jawa Timur'));
      await tester.pumpAndSettle();
      expect(picked, 'timur');
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Jawa Timur'), findsOneWidget);
      // Focus returns to the trigger.
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<PaymentSearchField<String>>(),
        isNotNull,
      );
    });

    testWidgets('programmatic focus does not open the sheet', (tester) async {
      surface(tester, compact);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          PaymentSearchField<String>(
            label: 'Province',
            options: _options,
            selected: null,
            onSelected: (_) {},
            focusNode: focus,
          ),
          1,
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.byType(BottomSheet), findsNothing);
      // Enter on the focused trigger opens it.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('multiple: Done applies the draft, close discards it', (
      tester,
    ) async {
      surface(tester, compact);
      final reports = <Set<String>>[];
      await tester.pumpWidget(
        host(
          PaymentSearchField<String>.multiple(
            label: 'Banks',
            options: _options,
            selected: const {'aceh'},
            onSelectionChanged: reports.add,
          ),
          1,
        ),
      );
      await tester.tap(find.text('Banks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jawa Barat'));
      await tester.pumpAndSettle();
      // Still open, with the draft chip in the footer.
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(PaymentChip),
        ),
        findsNWidgets(2),
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(reports, [
        {'aceh', 'barat'},
      ]);
      await tester.tap(find.text('Banks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jawa Timur'));
      await tester.tap(find.byTooltip('Close panel'));
      await tester.pumpAndSettle();
      expect(reports, hasLength(1));
    });

    testWidgets('host results reach the open sheet', (tester) async {
      surface(tester, compact);
      var loading = true;
      var options = <PaymentSearchOption<String>>[];
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PaymentSearchField<String>(
                label: 'Remote',
                options: options,
                selected: null,
                onSelected: (_) {},
                onQueryChanged: (_) {},
                loading: loading,
              );
            },
          ),
          1,
        ),
      );
      await tester.tap(find.text('Remote'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Loading'),
        ),
        findsOneWidget,
      );
      update(() {
        loading = false;
        options = _options;
      });
      await tester.pumpAndSettle();
      expect(find.text('Jawa Barat'), findsOneWidget);
      expect(find.bySemanticsLabel('3 results'), findsOneWidget);
    });
  });

  group('wide (D50)', () {
    testWidgets('the list floats over the page and Escape closes it', (
      tester,
    ) async {
      surface(tester, wide);
      String? picked;
      const below = Key('below');
      await tester.pumpWidget(
        host(
          Column(
            children: [
              PaymentSearchField<String>(
                label: 'Province',
                options: _options,
                selected: null,
                onSelected: (v) => picked = v,
              ),
              const SizedBox(key: below, height: 10),
            ],
          ),
          1,
        ),
      );
      final before = tester.getTopLeft(find.byKey(below));
      final fieldSize = tester.getSize(find.byType(PaymentSearchField<String>));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final list = find.byType(ListView);
      expect(list, findsOneWidget);
      expect(tester.getTopLeft(find.byKey(below)), before);
      expect(
        tester.getSize(find.byType(PaymentSearchField<String>)),
        fieldSize,
      );
      // Elevated surface with the control edge.
      final panel = tester.widget<Material>(
        find.ancestor(of: list, matching: find.byType(Material)).first,
      );
      expect(panel.elevation, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      await tester.enterText(find.byType(EditableText), 'barat');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jawa Barat').last);
      await tester.pumpAndSettle();
      expect(picked, 'barat');
    });

    testWidgets('at 2× the list opens under the box, clear of the label', (
      tester,
    ) async {
      // The label sits above the box at large text (#73).
      surface(tester, wide);
      await tester.pumpWidget(
        host(
          PaymentSearchField<String>(
            label: 'Province',
            options: _options,
            selected: null,
            onSelected: (_) {},
          ),
          2,
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final list = tester.getRect(
        find
            .ancestor(
              of: find.byType(ListView),
              matching: find.byType(Material),
            )
            .first,
      );
      final label = tester.getRect(find.text('Province'));
      final box = tester.getRect(find.byType(InputDecorator));
      expect(label.bottom, lessThanOrEqualTo(box.top));
      expect(list.top, greaterThanOrEqualTo(box.bottom));
      expect(tester.takeException(), isNull);
    });
  });
}
