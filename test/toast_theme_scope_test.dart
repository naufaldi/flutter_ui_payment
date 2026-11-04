import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

void main() {
  // D103: a toast shown inside a feature-scoped theme paints that theme,
  // although the app's root ScaffoldMessenger renders it outside the scope.
  testWidgets('a toast from a scoped feature theme shows that theme', (
    tester,
  ) async {
    final app = PaymentTheme.fromColorScheme(
      ColorScheme.fromSeed(seedColor: const Color(0xFF3355AA)),
    );
    final feature = app.copyWith(
      textPrimary: const Color(0xFF1B3A2F),
      surface: const Color(0xFFF4FFF8),
      controlRadius: 20,
    );
    late BuildContext context;
    var undone = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        theme: ThemeData(extensions: [app]),
        home: Scaffold(
          body: Builder(
            builder: (outer) => Theme(
              data: Theme.of(outer).copyWith(
                extensions: [...Theme.of(outer).extensions.values, feature],
              ),
              child: Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );

    showPaymentToast(
      context,
      message: 'Card saved',
      tone: StatusTone.success,
      actionLabel: 'Undo',
      onAction: () => undone++,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The pill surface: the feature's ink fill and control corners.
    final pill = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Card saved'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(pill.color, feature.textPrimary);
    expect(
      (pill.shape! as RoundedRectangleBorder).borderRadius,
      feature.controlBorderRadius,
    );
    expect(pill.color, isNot(app.textPrimary));
    // The content: message, tone icon and action all use the feature surface.
    expect(
      DefaultTextStyle.of(tester.element(find.text('Card saved'))).style.color,
      feature.surface,
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
    );
    expect(icon.color, feature.surface);
    final action = tester.widget<TextButton>(find.byType(TextButton));
    expect(action.style!.foregroundColor!.resolve({}), feature.surface);

    // Lifetime is unchanged: the action still dismisses and reports once.
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(undone, 1);
    expect(find.byType(SnackBar), findsNothing);
  });
}
