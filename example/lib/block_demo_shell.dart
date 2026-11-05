import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'themes.dart';

/// Starts a block demo edge-to-edge, as the shipped checkout demo does.
void runBlockDemo(Widget app) {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(app);
}

/// The example host's clipboard effect. It reports the real outcome and never
/// claims a copy that did not happen. The kit itself never touches the
/// clipboard (B11).
Future<bool> copyToClipboard(String value) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    return true;
  } on PlatformException {
    return false;
  }
}

/// One developer scenario in the demo menu. Choosing it restarts the
/// synthetic session; it is never an end-user action.
typedef DemoScenario = ({String label, VoidCallback onSelected});

/// Ordinary phone host chrome shared by the block demos: app themes, Indonesian
/// localization, D85 system-bar styling, a light/dark switch and a developer
/// scenario menu. It is example scaffolding, not a block runtime: copy the
/// composition under `compositions/` and keep your own app shell.
class BlockDemoShell extends StatelessWidget {
  const BlockDemoShell({
    super.key,
    required this.title,
    required this.dark,
    required this.onToggleDark,
    required this.body,
    this.scenarios = const [],
  });

  final String title;
  final bool dark;
  final VoidCallback onToggleDark;
  final List<DemoScenario> scenarios;

  /// Built below the Scaffold, so sheets and toasts find their ancestors.
  final WidgetBuilder body;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(DemoBrand.ruangBayar, Brightness.light),
    darkTheme: buildTheme(DemoBrand.ruangBayar, Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: const [
      PaymentLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AnnotatedRegion<SystemUiOverlayStyle>(
      // D85: the host styles the system bars from its resolved theme.
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            PaymentIconButton(
              icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: dark ? 'Mode terang' : 'Mode gelap',
              onPressed: onToggleDark,
            ),
            if (scenarios.isNotEmpty)
              PopupMenuButton<int>(
                tooltip: 'Skenario demo',
                onSelected: (i) => scenarios[i].onSelected(),
                itemBuilder: (_) => [
                  for (final (i, s) in scenarios.indexed)
                    PopupMenuItem(value: i, child: Text(s.label)),
                ],
              ),
          ],
        ),
        body: SafeArea(top: false, child: Builder(builder: body)),
      ),
    ),
  );
}
