import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

Widget host(Widget child, double scale) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.iOS),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: Column(children: [child])),
  ),
);
