import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

Widget contentHost(
  Widget child, {
  double scale = 1,
  bool dark = false,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: ThemeData(
    platform: TargetPlatform.iOS,
    brightness: dark ? Brightness.dark : Brightness.light,
  ),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);
Future<void> setSurface(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}
