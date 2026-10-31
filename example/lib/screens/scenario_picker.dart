import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../demo_strings.dart';
import '../scenarios/catalog.dart';

/// Lists every deterministic scenario; Run resets the fake host with that
/// fixture and opens the demo where the behavior can be tried.
class ScenarioPicker extends StatefulWidget {
  const ScenarioPicker({
    super.key,
    required this.onRun,
    required this.activeId,
    required this.onOpenSettings,
  });

  final void Function(Scenario scenario, int variant) onRun;
  final String activeId;
  final VoidCallback onOpenSettings;

  @override
  State<ScenarioPicker> createState() => _ScenarioPickerState();
}

class _ScenarioPickerState extends State<ScenarioPicker> {
  final Map<String, int> _variant = {};

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final lang = s.languageCode;
    final theme = PaymentTheme.of(context);
    final text = Theme.of(context).textTheme;
    String group(String id) => switch (id[0]) {
      'A' => s.groupAccount,
      'H' => s.groupJourneys,
      'K' => s.groupKyc,
      'P' => s.groupPayment,
      _ => s.groupCross,
    };
    final children = <Widget>[
      Text(s.scenarioIntro, style: text.bodyMedium),
      const SizedBox(height: 8),
    ];
    String? lastGroup;
    for (final scenario in scenarios) {
      final g = group(scenario.id);
      if (g != lastGroup) {
        lastGroup = g;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Semantics(
              header: true,
              child: Text(
                g,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }
      final selected = _variant[scenario.id] ?? 0;
      final active = scenario.id == widget.activeId;
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PaymentSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active ? theme.accent : theme.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scenario.id,
                        style: text.labelLarge?.copyWith(
                          color: active ? theme.onAccent : theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        scenario.title.of(lang),
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scenario.expect.of(lang),
                  style: text.bodySmall?.copyWith(color: theme.textSecondary),
                ),
                if (scenario.variants.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final (i, v) in scenario.variants.indexed)
                        ChoiceChip(
                          key: Key('variant-${scenario.id}-$i'),
                          label: Text(v.label.of(lang)),
                          selected: i == selected,
                          onSelected: (_) =>
                              setState(() => _variant[scenario.id] = i),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: Key('run-${scenario.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: theme.accent,
                      foregroundColor: theme.onAccent,
                    ),
                    onPressed: () => widget.onRun(scenario, selected),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('${s.run} ${scenario.id}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabScenarios),
        actions: [
          IconButton(
            tooltip: s.settings,
            icon: const Icon(Icons.tune),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('scenario-list'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: children,
        ),
      ),
    );
  }
}
