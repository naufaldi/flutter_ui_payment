import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/main.dart';
import '../integration_test/record_card_flow_test.dart'
    show recordCardRecoveryTest;
import '../integration_test/support.dart';

void main() {
  recordCardRecoveryTest();

  testWidgets('tablet gallery shows detail modules side by side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.selectTab(2);
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavSidebar),
        matching: find.text('Views & pages'),
      ),
    );
    await settle(tester);
    final detail = find.byType(PaymentDetailPage);
    await revealGalleryTarget(tester, detail, step: 400);
    final primary = tester.getRect(
      find.descendant(
        of: detail,
        matching: find.byWidgetPredicate(
          (w) =>
              w is PaymentDetailPagePropertyList &&
              w.title == 'Payment details',
        ),
      ),
    );
    final secondary = tester.getRect(
      find.descendant(
        of: detail,
        matching: find.byWidgetPredicate(
          (w) => w is PaymentDetailPagePropertyList && w.title == 'Merchant',
        ),
      ),
    );
    expect(secondary.left, greaterThan(primary.right));
    expect(secondary.top, primary.top);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('captures can leave Kit components past its sidebar specimen '
      '(#189)', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    await openGalleryPage(tester, 'Kit components');
    // Bring the page's own NavSidebar specimen into the tree.
    final shellSpecimen = find.byKey(
      const ValueKey('specimen:AdaptiveNavShell · variants'),
    );
    await revealGalleryTarget(tester, shellSpecimen, step: 400);
    await openGalleryPage(tester, 'Charts');
    await revealGalleryTarget(tester, find.byType(PaymentSparkline));
    expect(find.byType(PaymentSparkline), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tablet captures navigate the permanent gallery sidebar without '
      'a menu button (#189)', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    expect(find.byTooltip('Open navigation'), findsNothing);
    await openGalleryPage(tester, 'Content');
    await revealGalleryTarget(
      tester,
      find.byKey(const ValueKey('specimen:PaymentDataTable · variants')),
      step: 400,
    );
    expect(find.byType(PaymentDataTable<int>), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('gallery keeps specimen state after scrolling away', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    await openGalleryPage(tester, 'Checkout');
    final scrollable = find
        .descendant(of: galleryList(), matching: find.byType(Scrollable))
        .first;
    final specimen = find.byKey(
      const ValueKey('specimen:PaymentSummary · PaymentConfirmation'),
    );
    Future<void> scanFromTop() async {
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.minScrollExtent);
      await tester.pump();
      for (
        var attempt = 0;
        specimen.evaluate().isEmpty && attempt < 100;
        attempt++
      ) {
        position.jumpTo(
          (position.pixels + 200).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
      expect(specimen, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(specimen));
      await settle(tester);
    }

    await scanFromTop();
    final quoteChanged = find.descendant(
      of: specimen,
      matching: find.text('quote changed'),
    );
    bool quoteChangedIsSelected() => tester
        .widgetList<Semantics>(
          find.ancestor(of: quoteChanged, matching: find.byType(Semantics)),
        )
        .any((semantics) => semantics.properties.selected ?? false);
    await tester.tap(quoteChanged);
    await settle(tester);
    expect(quoteChangedIsSelected(), isTrue);
    for (var i = 0; i < 4; i += 1) {
      await tester.drag(galleryList(), const Offset(0, -500));
      await settle(tester);
    }
    for (var i = 0; i < 4; i += 1) {
      await tester.drag(galleryList(), const Offset(0, 500));
      await settle(tester);
    }
    await scanFromTop();
    expect(quoteChangedIsSelected(), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('English gallery table formats every fee and its total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    await tester.tap(find.byTooltip('Open navigation'));
    await settle(tester);
    await tester.tap(find.text('Content'));
    await settle(tester);
    final table = find.byType(PaymentTable);
    await revealGalleryTarget(tester, table);
    for (final amount in ['Rp2,500', 'Rp0', 'Rp4,000', 'Rp1,500', 'Rp8,000']) {
      expect(
        find.descendant(of: table, matching: find.text(amount)),
        findsOneWidget,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('spacing roles show the resolved theme gaps', (tester) async {
    final app = await launch(tester);
    app.selectTab(2);
    await settle(tester);
    final specimen = find.byKey(
      const ValueKey('specimen:PaymentSpace · variants'),
    );
    await revealGalleryTarget(tester, specimen);
    final theme = PaymentTheme.of(tester.element(specimen));
    for (final role in PaymentSpace.values) {
      final before = tester.getRect(
        find.byKey(ValueKey('space:${role.name}:before')),
      );
      final after = tester.getRect(
        find.byKey(ValueKey('space:${role.name}:after')),
      );
      expect(after.left - before.right, theme.space(role), reason: role.name);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dark gallery logo letters use the theme onAccent color (#173)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.selectTab(2);
    await settle(tester);
    // Open in light, then switch: the tile must follow the new look.
    await tester.tap(find.byTooltip('Open navigation'));
    await settle(tester);
    await tester.tap(find.text('Layout'));
    await settle(tester);
    await revealGalleryTarget(
      tester,
      find.byKey(const ValueKey('specimen:PaymentImage · variants')),
    );
    // Start and await the native Picture.toImage work in the same real zone.
    await tester.runAsync(() async {
      app.updateSettings(
        const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
      );
      await settle(tester);
      await tester
          .widget<FutureBuilder<ImageProvider>>(
            find.byType(FutureBuilder<ImageProvider>),
          )
          .future!;
    });
    await settle(tester);
    final logo = find.byWidgetPredicate(
      (w) => w is PaymentImage && w.alt == 'Bank Contoh',
    );
    expect(logo, findsWidgets);
    final theme = PaymentTheme.of(tester.element(logo.first));
    final bytes =
        (tester.widget<PaymentImage>(logo.first).image as MemoryImage).bytes;
    final pixels = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData();
      frame.image.dispose();
      codec.dispose();
      return data!;
    });
    int count(Color color) {
      var n = 0;
      for (var i = 0; i < pixels!.lengthInBytes; i += 4) {
        if ((pixels.getUint8(i) - (color.r * 255).round()).abs() < 8 &&
            (pixels.getUint8(i + 1) - (color.g * 255).round()).abs() < 8 &&
            (pixels.getUint8(i + 2) - (color.b * 255).round()).abs() < 8) {
          n++;
        }
      }
      return n;
    }

    expect(theme.accent.computeLuminance(), greaterThan(0.5));
    // The letters are painted in the dark onAccent ink, not white.
    expect(count(theme.onAccent), greaterThan(100));
    expect(count(const Color(0xFFFFFFFF)), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
