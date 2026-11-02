import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support.dart';

void surface(WidgetTester t, Size physicalSize, {double dpr = 1}) {
  t.view.devicePixelRatio = dpr;
  t.view.physicalSize = physicalSize;
  t.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 32 * dpr);
  t.view.viewPadding = FakeViewPadding(top: 24 * dpr, bottom: 32 * dpr);
  addTearDown(t.view.reset);
}

Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('rail checkout keeps the amount visible above the keyboard', (
    t,
  ) async {
    surface(t, const Size(1280, 800));
    final app = await launch(t);
    await runScenario(t, app, 'P01');
    t.view.viewInsets = const FakeViewPadding(bottom: 376);
    await settle(t);

    final list = find.byKey(const ValueKey('flow-list-checkout'));
    final amount = find.byKey(const Key('amount'));
    final viewport = t.getRect(list);
    expect(viewport.height, greaterThan(200));
    expect(viewport.contains(t.getRect(amount).topLeft), isTrue);
    expect(viewport.contains(t.getRect(amount).bottomRight), isTrue);
    expect(amount.hitTestable(), findsOneWidget);
    await drain(t);
  });

  testWidgets('rail history keeps search visible above the keyboard', (
    t,
  ) async {
    surface(t, const Size(1280, 800));
    final app = await launch(t);
    final c = await runScenario(t, app, 'A01');
    await pumpUntil(t, () => !c.historyLoading);
    t.view.viewInsets = const FakeViewPadding(bottom: 376);
    await settle(t);

    final search = find.byType(EditableText);
    expect(search, findsOneWidget);
    final rect = t.getRect(search);
    expect(rect.top, greaterThanOrEqualTo(24));
    expect(rect.bottom, lessThanOrEqualTo(800 - 376));
    expect(search.hitTestable(), findsOneWidget);
    await drain(t);
  });

  testWidgets(
    'rail identity swap does not overflow while the keyboard closes',
    (t) async {
      surface(t, const Size(2560, 1600), dpr: 2);
      final app = await launch(t);
      final c = await runScenario(t, app, 'K02');
      t.view.viewInsets = const FakeViewPadding(bottom: 752);
      await settle(t);
      c.editDocuments();
      for (var frame = 1; frame <= 25; frame++) {
        t.view.viewInsets = FakeViewPadding(bottom: 752 * (1 - frame / 25));
        await t.pump(const Duration(milliseconds: 16));
        expect(t.takeException(), isNull, reason: 'IME closing frame $frame');
      }
      await drain(t);
    },
  );

  testWidgets('phone checkout keeps a nonempty viewport above the keyboard', (
    t,
  ) async {
    surface(t, const Size(360, 640));
    final app = await launch(t);
    await runScenario(t, app, 'P01');
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await settle(t);
    expect(
      t.getSize(find.byKey(const ValueKey('flow-list-checkout'))).height,
      greaterThan(0),
    );
    await drain(t);
  });
}
