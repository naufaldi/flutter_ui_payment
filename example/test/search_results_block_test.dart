import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/compositions/search_results_block.dart';
import 'package:rakit_ui_example/search_results_demo.dart';

const _first = (
  value: 2,
  title: 'Page 2',
  excerpt: 'A path through the garden.',
);
const _replacement = (
  value: 6,
  title: 'Page 6',
  excerpt: 'The lane continues uphill.',
);

Future<void> _mount(
  WidgetTester tester,
  SearchSource<int> search, {
  ValueChanged<int>? onOpen,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [PaymentLocalizations.delegate],
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: SearchResultsBlock<int>(
            queryLabel: 'Search text',
            search: search,
            onOpen: onOpen ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

Future<void> _submit(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(EditableText), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
}

void main() {
  testWidgets('editing hides partial results and ignores late old events', (
    tester,
  ) async {
    final old = StreamController<SearchUpdate<int>>();
    final current = StreamController<SearchUpdate<int>>();
    final opened = <int>[];
    await _mount(
      tester,
      (query) => switch (query) {
        'garden' => old.stream,
        'lane' => current.stream,
        _ => throw ArgumentError.value(query),
      },
      onOpen: opened.add,
    );
    await _submit(tester, ' garden ');
    old.add((matches: [_first], progress: .4));
    await tester.pump();
    expect(find.text(_first.excerpt), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'lane');
    await tester.pump();
    expect(find.text(_first.title), findsNothing);
    await _submit(tester, 'lane');
    current.add((matches: [_replacement], progress: 1));
    unawaited(current.close());
    await tester.pump();
    old.add((matches: [_first], progress: 1));
    old.addError(StateError('late failure'));
    unawaited(old.close());
    await tester.pump();
    expect(find.text(_first.title), findsNothing);
    expect(find.text('Search failed'), findsNothing);
    await tester.tap(find.widgetWithText(PaymentListItem, _replacement.title));
    expect(opened, [_replacement.value]);
  });

  testWidgets('cancel stops the host and discards late matches', (
    tester,
  ) async {
    var canceled = 0;
    final source = StreamController<SearchUpdate<int>>(
      onCancel: () => canceled++,
    );
    await _mount(tester, (_) => source.stream);
    await _submit(tester, 'garden');
    source.add((matches: [_first], progress: .4));
    await tester.pump();
    expect(find.bySemanticsLabel('Searching…'), findsOneWidget);
    final progress = tester.getSemantics(find.byType(LinearProgressIndicator));
    expect(progress.getSemanticsData().role, SemanticsRole.progressBar);
    expect(progress.value, '40');
    final cancel = find.widgetWithText(PaymentButton, 'Cancel');
    expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Cancel'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(cancel);
    await tester.pump();
    expect(canceled, 1);
    source.add((matches: [_first], progress: 1));
    unawaited(source.close());
    await tester.pump();
    expect(find.bySemanticsLabel('Search canceled'), findsOneWidget);
    expect(find.text(_first.title), findsNothing);
    expect(find.text('No results'), findsNothing);
    expect(find.text('garden'), findsOneWidget);
  });

  testWidgets('retry starts the same query and empty waits for completion', (
    tester,
  ) async {
    final first = StreamController<SearchUpdate<int>>();
    final retry = StreamController<SearchUpdate<int>>();
    final queries = <String>[];
    await _mount(tester, (query) {
      queries.add(query);
      return (queries.length == 1 ? first : retry).stream;
    });
    expect(find.text('No results'), findsNothing);
    await _submit(tester, ' garden ');
    first.addError(StateError('engine failure'));
    unawaited(first.close());
    await tester.pump();
    expect(find.text('Search failed'), findsOneWidget);
    expect(find.textContaining('engine failure'), findsNothing);
    await tester.tap(find.widgetWithText(PaymentButton, 'Retry'));
    await tester.pump();
    expect(queries, ['garden', 'garden']);
    retry.add((matches: [], progress: .9));
    await tester.pump();
    expect(find.text('No results'), findsNothing);
    unawaited(retry.close());
    await tester.pump();
    expect(find.bySemanticsLabel('No results'), findsOneWidget);
    expect(find.text('Searching…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an update cannot open a different match under a held tap', (
    tester,
  ) async {
    final source = StreamController<SearchUpdate<int>>();
    final opened = <int>[];
    await _mount(tester, (_) => source.stream, onOpen: opened.add);
    await _submit(tester, 'garden');
    source.add((matches: [_replacement], progress: .2));
    await tester.pump();
    final pressed = find.widgetWithText(PaymentListItem, _replacement.title);
    final gesture = await tester.startGesture(tester.getCenter(pressed));
    source.add((matches: [_first, _replacement], progress: .6));
    await tester.pump();
    await gesture.up();
    expect(opened, isNot(contains(_first.value)));
    unawaited(source.close());
    await tester.pump();
  });

  testWidgets('a tall keyboard leaves the Find input reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(body: SearchResultsDemo(embedded: true)),
      ),
    );
    await tester.tap(find.widgetWithText(PaymentButton, 'Find in document'));
    await tester.pumpAndSettle();
    final field = find.byType(EditableText);
    await tester.tap(field);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 248);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(field.hitTestable(), findsOneWidget);
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
    tester.testTextInput.enterText('garden');
    await tester.pumpAndSettle();
    final editor = tester.getRect(field);
    expect(editor.top, greaterThanOrEqualTo(24));
    expect(editor.bottom, lessThanOrEqualTo(72));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
    tester.view.resetViewInsets();
    for (var page = 0; page < 6; page++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
    final result = find.widgetWithText(PaymentListItem, 'Page 2');
    final viewport = find.descendant(
      of: find.byType(SearchResultsBlock<int>),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      result.hitTestable(),
      72,
      scrollable: viewport.first,
      maxScrolls: 6,
    );
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(field, findsNothing);
  });
}
