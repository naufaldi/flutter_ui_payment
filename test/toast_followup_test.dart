import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'helpers/toast.dart';

void main() {
  setUp(() {
    final handle = TestWidgetsFlutterBinding.ensureInitialized()
        .ensureSemantics();
    addTearDown(handle.dispose);
  });
  late BuildContext context;
  Future<void> mount(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
    bool material3 = true,
    Color? closeColor,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: material3,
          brightness: dark ? Brightness.dark : Brightness.light,
          snackBarTheme: SnackBarThemeData(
            showCloseIcon: true,
            closeIconColor: closeColor,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets('legacy snack bar exposes Undo and reports a close tap', (
    tester,
  ) async {
    await mount(tester, scale: 2);
    // ignore: deprecated_member_use_from_same_package
    final controller = showPaymentSnackBar(
      context,
      message: 'Copied',
      actionLabel: 'Undo',
      onAction: () {},
    );
    await settle(tester);
    final close = find.byKey(StandardComponentType.closeButton.key);
    final bounds = tester.getRect(toastSurface(context));
    for (final content in [
      find.text('Copied'),
      find.widgetWithText(TextButton, 'Undo'),
      close,
    ]) {
      final rect = tester.getRect(content);
      expect(bounds.intersect(rect), rect);
    }
    final closeSize = tester.getSize(close);
    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(close).getSemanticsData().tooltip,
      MaterialLocalizations.of(context).closeButtonTooltip,
    );

    await tester.tap(close);
    await settle(tester);
    expect(await controller.closed, SnackBarClosedReason.dismiss);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final material3 in [false, true]) {
    for (final dark in [false, true]) {
      for (final override in [false, true]) {
        testWidgets('close color m3=$material3 dark=$dark override=$override', (
          tester,
        ) async {
          final color = override ? const Color(0xff123456) : null;
          await mount(
            tester,
            material3: material3,
            dark: dark,
            closeColor: color,
          );
          final theme = Theme.of(context);
          final controller = showPaymentToast(
            context,
            message: 'Copied',
            pending: true,
          );
          await settle(tester);
          final button = tester.widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.close),
          );
          expect(
            button.color,
            color ??
                (material3
                    ? theme.colorScheme.onInverseSurface
                    : theme.colorScheme.onSurface),
          );
          await tester.tap(find.byIcon(Icons.close));
          await settle(tester);
          await controller.closed;
        });
      }
    }
  }

  testWidgets('leaving toast survives accessibility rebuild', (tester) async {
    await mount(tester, scale: 2);
    showPaymentToast(context, message: 'Toast A', pending: true);
    await settle(tester);
    final surface = toastSurface(context);
    final bounds = tester.getRect(surface);
    final close = find.byKey(StandardComponentType.closeButton.key);
    for (final content in [find.text('Toast A'), close]) {
      final rect = tester.getRect(content);
      expect(bounds.intersect(rect), rect);
    }
    expect((Offset.zero & tester.view.physicalSize).intersect(bounds), bounds);
    final newest = showPaymentToast(context, message: 'Toast B', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(boldText: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.text('Toast A'), findsOneWidget);
    expect(tester.getSize(surface).height, bounds.height);
    expect(find.byIcon(Icons.close), findsOneWidget);
    await settle(tester);
    await settle(tester);
    expect(find.text('Toast B'), findsOneWidget);
    await tester.tap(close);
    await settle(tester);
    await newest.closed;
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
