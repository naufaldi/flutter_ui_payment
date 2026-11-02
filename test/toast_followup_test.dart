import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

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

  Finder pill() => find.descendant(
    of: find.byType(SnackBar),
    matching: find.byWidgetPredicate(
      (w) => w is Material && w.color == PaymentTheme.of(context).textPrimary,
    ),
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final action in [false, true]) {
        testWidgets(
          'themed close geometry dark=$dark scale=$scale action=$action',
          (tester) async {
            await mount(tester, dark: dark, scale: scale);
            // ignore: deprecated_member_use_from_same_package
            final controller = showPaymentSnackBar(
              context,
              message: 'Copied',
              actionLabel: action ? 'Undo' : null,
              onAction: action ? () {} : null,
            );
            await settle(tester);
            final icon = find.byIcon(Icons.close);
            // Measured with 1812ba1's interaction.dart at 320 x 640 dp.
            final top = scale == 1 ? 560.0 : (action ? 360.0 : 520.0);
            final iconX = action ? 259 + 1 / 3 : 250 + 2 / 3;
            final iconY = scale == 1 ? 580.0 : (action ? 480.0 : 560.0);
            expect(
              tester.getRect(pill().first),
              Rect.fromLTRB(16, top, 304, 624),
            );
            final rect = tester.getRect(icon);
            expect(rect.left, closeTo(iconX, 0.001));
            expect(rect.top, iconY);
            expect(rect.size, const Size(24, 24));
            final target = find.byKey(StandardComponentType.closeButton.key);
            expect(target, findsOneWidget);
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            final tooltip = MaterialLocalizations.of(
              context,
            ).closeButtonTooltip;
            expect(tester.widget<IconButton>(target).tooltip, tooltip);
            expect(
              tester.getSemantics(target).getSemanticsData().tooltip,
              tooltip,
            );
            await tester.tap(target);
            await settle(tester);
            expect(await controller.closed, SnackBarClosedReason.dismiss);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

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
    await mount(tester);
    showPaymentToast(context, message: 'Toast A', pending: true);
    await settle(tester);
    final height = tester.getSize(pill().first).height;
    showPaymentToast(context, message: 'Toast B', pending: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(boldText: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.text('Toast A'), findsOneWidget);
    expect(tester.getSize(pill().first).height, height);
    expect(find.byIcon(Icons.close), findsOneWidget);
    await settle(tester);
    await settle(tester);
  });
}
