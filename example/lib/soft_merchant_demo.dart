import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'merchant_demo.dart';
import 'themes.dart';

/// The Merchant overview block in the Soft host preset: the same widgets and
/// fixture as `merchant_demo.dart`, other tokens, and a host inset panel.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MerchantDemo(brand: DemoBrand.soft));
}
