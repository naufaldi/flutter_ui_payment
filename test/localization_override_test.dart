import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/charts/chart_geometry.dart';

class GermanPaymentLocalizations extends PaymentLocalizations {
  GermanPaymentLocalizations() : super('de');

  @override
  String formatNumber(num value, {bool grouping = true}) {
    final english = super.formatNumber(value, grouping: grouping);
    return english
        .replaceAll(',', '#')
        .replaceAll('.', ',')
        .replaceAll('#', '.');
  }

  @override
  String get save => 'Speichern';

  @override
  String get closeSheet => 'Schließen';

  @override
  String get continueLabel => 'Weiter';

  @override
  String paymentStatusShort(PaymentStatus? status) => 'Zahlungsstatus';
}

class GermanPaymentDelegate
    extends LocalizationsDelegate<PaymentLocalizations> {
  const GermanPaymentDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'de';

  @override
  Future<PaymentLocalizations> load(Locale locale) =>
      SynchronousFuture(GermanPaymentLocalizations());

  @override
  bool shouldReload(GermanPaymentDelegate old) => false;
}

void main() {
  testWidgets('a German host translates settings and the sheet close action', (
    tester,
  ) async {
    var saved = false;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: const [
          GermanPaymentDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final strings = PaymentLocalizations.of(context);
              expect(strings, isA<GermanPaymentLocalizations>());
              expect(strings.continueLabel, 'Weiter');
              expect(strings.paymentStatusShort(null), 'Zahlungsstatus');
              expect(strings.tryAgain, 'Try again');
              expect(strings.search, 'Search');
              expect(
                formatChartValue(strings, 1234.5, PaymentChartUnit.number),
                '1.234,5',
              );
              return PaymentSettingsView(
                title: 'Einstellungen',
                onSave: () async => saved = true,
                child: PaymentSheetHeader(
                  title: 'Details',
                  onClose: () => closed = true,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Speichern'), findsOneWidget);
    expect(find.byTooltip('Schließen'), findsOneWidget);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Schließen'));
    expect(saved, isTrue);
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
