import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'adapters/fake_host.dart';
import 'coordinator/demo_coordinator.dart';
import 'demo_strings.dart';
import 'scenarios/catalog.dart';
import 'screens/flow_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/scenario_picker.dart';
import 'themes.dart';

void main() => runApp(const DemoApp());

/// Display preferences chosen in the demo shell.
class DemoSettings {
  const DemoSettings({
    this.brand = DemoBrand.ruangBayar,
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('id'),
    this.textScale,
    this.reduceMotion = false,
  });

  final DemoBrand brand;
  final ThemeMode themeMode;
  final Locale locale;

  /// Null follows the device setting.
  final double? textScale;
  final bool reduceMotion;

  DemoSettings copyWith({
    DemoBrand? brand,
    ThemeMode? themeMode,
    Locale? locale,
    double? Function()? textScale,
    bool? reduceMotion,
  }) => DemoSettings(
    brand: brand ?? this.brand,
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
    textScale: textScale == null ? this.textScale : textScale(),
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key, this.initialSettings = const DemoSettings()});

  final DemoSettings initialSettings;

  @override
  State<DemoApp> createState() => DemoAppState();
}

class DemoAppState extends State<DemoApp> {
  late DemoSettings settings = widget.initialSettings;
  int tab = 0;
  Scenario activeScenario = scenarios.first;
  int activeVariant = 0;
  late DemoHost host;
  late DemoCoordinator coordinator;

  /// Changes on every simulated restart so all widget state is rebuilt.
  int launch = 0;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _boot(activeScenario.variants.first);
    _lifecycle = AppLifecycleListener(
      onInactive: () => coordinator.setObscured(true),
      onHide: () => coordinator.setObscured(true),
      onResume: () => coordinator.onResumed(),
    );
  }

  void _boot(ScenarioVariant variant) {
    host = DemoHost(variant.config)
      ..languageCode = settings.locale.languageCode;
    coordinator = DemoCoordinator(host);
    unawaited(_startAt(variant.start));
  }

  Future<void> _startAt(FlowStep start) async {
    await coordinator.start();
    await coordinator.setUpScenario(start);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    coordinator.dispose();
    host.dispose();
    super.dispose();
  }

  void selectTab(int index) => setState(() => tab = index);

  void updateSettings(DemoSettings next) {
    setState(() => settings = next);
    host.languageCode = next.locale.languageCode;
  }

  /// Resets the simulated host and opens the scenario in the demo tab.
  void runScenario(Scenario scenario, int variantIndex) {
    final variant = scenario.variants[variantIndex];
    coordinator.dispose();
    host.dispose();
    setState(() {
      activeScenario = scenario;
      activeVariant = variantIndex;
      settings = settings.copyWith(
        textScale: () => variant.textScale ?? settings.textScale,
        themeMode: variant.dark == null
            ? null
            : (variant.dark! ? ThemeMode.dark : ThemeMode.light),
        reduceMotion: variant.reduceMotion,
      );
      _boot(variant);
      launch++;
      tab = 0;
    });
  }

  /// Process restart: in-memory state is lost; the host keeps its server data
  /// and the opaque recovery reference.
  void simulateRestart() {
    final account = coordinator.account;
    coordinator.dispose();
    host.record('— App restarted (in-memory state discarded) —');
    setState(() {
      coordinator = DemoCoordinator(host, account: account);
      unawaited(coordinator.start());
      launch++;
    });
  }

  Future<void> simulateBackground() async {
    coordinator.setObscured(true);
    host.record('App moved to background (simulated)');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    coordinator.onResumed();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruang Bayar',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(settings.brand, Brightness.light),
      darkTheme: buildTheme(settings.brand, Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        PaymentLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: settings.textScale == null
                ? media.textScaler
                : TextScaler.linear(settings.textScale!),
            disableAnimations: media.disableAnimations || settings.reduceMotion,
          ),
          child: child!,
        );
      },
      home: _Shell(app: this),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.app});

  final DemoAppState app;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final pages = [
      FlowScreen(
        key: ValueKey('flow-${app.launch}'),
        coordinator: app.coordinator,
        scenarioLabel: app.activeScenario.id,
        onRestart: app.simulateRestart,
        onBackground: app.simulateBackground,
        onOpenSettings: () => showSettingsSheet(context, app),
      ),
      ScenarioPicker(
        onRun: app.runScenario,
        activeId: app.activeScenario.id,
        onOpenSettings: () => showSettingsSheet(context, app),
      ),
      GalleryScreen(onOpenSettings: () => showSettingsSheet(context, app)),
    ];
    final destinations = [
      (Icons.shopping_bag_outlined, Icons.shopping_bag, s.tabDemo),
      (Icons.rule_folder_outlined, Icons.rule_folder, s.tabScenarios),
      (Icons.widgets_outlined, Icons.widgets, s.tabGallery),
    ];
    final body = IndexedStack(index: app.tab, children: pages);
    // Phones get a bottom bar; tablets, desktops and wide browser windows get
    // a side rail so the content keeps a readable width.
    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: app.tab,
                onDestinationSelected: app.selectTab,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final (icon, selected, label) in destinations)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(selected),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tab,
        onDestinationSelected: app.selectTab,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}

Future<void> showSettingsSheet(BuildContext context, DemoAppState app) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final s = DemoStrings.of(context);
        final settings = app.settings;
        void update(DemoSettings next) {
          app.updateSettings(next);
          setSheet(() {});
        }

        Widget group<T>(
          String title,
          T value,
          List<(T, String)> options,
          ValueChanged<T> onChanged,
        ) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (v, label) in options)
                    ChoiceChip(
                      label: Text(label),
                      selected: v == value,
                      onSelected: (_) => onChanged(v),
                    ),
                ],
              ),
            ],
          ),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    s.settings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                group(s.brand, settings.brand, const [
                  (DemoBrand.ruangBayar, 'Ruang Bayar'),
                  (DemoBrand.lumen, 'Lumen'),
                ], (v) => update(settings.copyWith(brand: v))),
                group(
                  s.appearance,
                  settings.themeMode,
                  [
                    (ThemeMode.light, s.light),
                    (ThemeMode.dark, s.darkLabel),
                    (ThemeMode.system, s.system),
                  ],
                  (v) => update(settings.copyWith(themeMode: v)),
                ),
                group(
                  s.language,
                  settings.locale.languageCode,
                  const [('id', 'Bahasa Indonesia'), ('en', 'English')],
                  (v) => update(settings.copyWith(locale: Locale(v))),
                ),
                group<double?>(
                  s.textSize,
                  settings.textScale,
                  [
                    (null, s.system),
                    (1.0, '100%'),
                    (1.3, '130%'),
                    (2.0, '200%'),
                  ],
                  (v) => update(settings.copyWith(textScale: () => v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.reduceMotion),
                  value: settings.reduceMotion,
                  onChanged: (v) => update(settings.copyWith(reduceMotion: v)),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
