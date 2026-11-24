import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/main.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  recordCardRecoveryTest();
}

void recordCardRecoveryTest() {
  testWidgets('Gallery checks an unconfirmed removal in the same prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = await launch(
      tester,
      settings: const DemoSettings(locale: Locale('en'), textScale: 2),
    );
    app.selectTab(2);
    await settle(tester);
    await openGalleryPage(tester, 'Interaction');
    final card = find.byType(PaymentRecordCard).last;
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find
          .descendant(of: galleryList(), matching: find.byType(Scrollable))
          .first,
    );
    final remove = find.descendant(
      of: card,
      matching: find.byTooltip('Remove statement'),
    );
    await tapVisible(tester, remove);
    await settle(tester);

    final title = find.text('Remove this statement?');
    final route = ModalRoute.of(tester.element(title));
    await tester.tap(find.text('Remove statement'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.semantics.byValue('Removing statement'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Check status'), findsOneWidget);
    expect(find.text('Remove statement'), findsNothing);
    expect(ModalRoute.of(tester.element(title)), same(route));

    await tester.tap(find.text('Check status'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.semantics.byValue('Checking status'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(title, findsNothing);
    expect(find.text('Statement removed (demo)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
