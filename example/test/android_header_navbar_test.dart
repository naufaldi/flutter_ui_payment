import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/main.dart';
import '../integration_test/support.dart';

void main() {
  testWidgets('history first row starts above the tab bar at 200 percent', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(t.view.reset);
    final app = await launch(
      t,
      settings: const DemoSettings(locale: Locale('en'), textScale: 2),
    );
    final c = await runScenario(t, app, 'A01');
    await pumpUntil(t, () => !c.historyLoading);
    final row = find.byType(TransactionListItem).first;
    final margin =
        t.getRect(find.byType(NavigationBar)).top - t.getRect(row).top;
    debugPrint('History first-row top clearance: $margin dp');
    expect(margin, greaterThan(0));
    final header = find.byWidgetPredicate(
      (w) => w is PaymentFullPageView && w.title == 'Transactions',
    );
    expect(
      find.descendant(of: header, matching: find.byType(PaymentMenu)),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('navigation bar follows the resolved app theme', (t) async {
    final app = await launch(
      t,
      settings: const DemoSettings(themeMode: ThemeMode.dark),
    );
    await settle(t);
    SystemUiOverlayStyle rootStyle() => t
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
        )
        .value;
    final dark = rootStyle();
    expect(dark.systemNavigationBarContrastEnforced, isFalse);
    expect(dark.systemNavigationBarColor, Colors.transparent);
    expect(dark.systemNavigationBarDividerColor, Colors.transparent);
    expect(dark.systemNavigationBarIconBrightness, Brightness.light);
    expect(dark.statusBarColor, isNull);
    expect(dark.statusBarBrightness, isNull);
    expect(dark.statusBarIconBrightness, isNull);
    app.updateSettings(app.settings.copyWith(themeMode: ThemeMode.light));
    await settle(t);
    expect(rootStyle().systemNavigationBarIconBrightness, Brightness.dark);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
