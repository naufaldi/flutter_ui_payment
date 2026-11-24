import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui_example/collection_block_demo.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('collection demo retries, appends and keeps earlier documents', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CollectionBlockDemo(
        initialScenario: CollectionDemoScenario.laterError,
        fixtureDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();

    final scroll = find.byType(Scrollable).first;
    final load = find.text('Load more');
    await tester.scrollUntilVisible(load, 100, scrollable: scroll);
    await Scrollable.ensureVisible(tester.element(load), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(load.hitTestable());
    await tester.pumpAndSettle();

    final retry = find.text('Retry');
    expect(retry.hitTestable(), findsOneWidget);
    expect(
      find.textContaining('Your earlier items are still here.'),
      findsOneWidget,
    );
    expect(find.text('Field guide'), findsOneWidget);
    await tester.tap(retry.hitTestable());
    await tester.pumpAndSettle();

    final appended = find.text('Site sketches');
    await tester.scrollUntilVisible(appended, 100, scrollable: scroll);
    await tester.pumpAndSettle();
    expect(appended.hitTestable(), findsOneWidget);
    expect(retry, findsNothing);
    expect(load, findsNothing);
    final earlier = find.text('Workshop notes');
    await tester.scrollUntilVisible(earlier, -100, scrollable: scroll);
    await tester.pumpAndSettle();
    expect(earlier.hitTestable(), findsOneWidget);
  });
}
