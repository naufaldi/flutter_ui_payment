import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/themes.dart';

String hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
void main() {
  testWidgets('Hairline tokens match documentation snapshot', (tester) async {
    final colors = <String, Map<String, String>>{};
    final data = <String, Object>{'color': colors};
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          themeAnimationDuration: Duration.zero,
          theme: buildTheme(DemoBrand.ruangBayar, brightness),
          home: Builder(
            builder: (context) {
              final theme = PaymentTheme.of(context);
              final palette = <String, Color>{
                'surface': theme.surface,
                'surfaceMuted': theme.surfaceMuted,
                'outline': theme.outline,
                'border': theme.border,
                'textPrimary': theme.textPrimary,
                'textSecondary': theme.textSecondary,
                'disabled': theme.disabled,
                'accent': theme.accent,
                'onAccent': theme.onAccent,
                for (final tone in StatusTone.values) ...{
                  '${tone.name}.foreground': theme.tone(tone).foreground,
                  '${tone.name}.container': theme.tone(tone).container,
                },
              };
              for (final entry in palette.entries) {
                (colors[entry.key] ??= {})[brightness.name] = hex(entry.value);
              }
              final type = PaymentType.of(context);
              final styles = [
                type.display,
                type.amountLarge,
                type.title,
                type.heading,
                type.bodyFor(context),
                type.label,
                type.caption,
                type.tag,
                type.input,
              ];
              data['type'] = {
                for (final role in PaymentTextRole.values)
                  role.name: {
                    'size': styles[role.index].fontSize,
                    'line':
                        styles[role.index].fontSize! *
                        styles[role.index].height!,
                    'weight': styles[role.index].fontWeight!.value,
                    'tracking': styles[role.index].letterSpacing,
                  },
              };
              data['space'] = {
                for (final role in PaymentSpace.values)
                  role.name: theme.space(role),
              };
              data['radius'] = {
                'none': 0,
                'tag': theme.tagBorderRadius.topLeft.x,
                'control': theme.controlBorderRadius.topLeft.x,
                'box': theme.borderRadius.topLeft.x,
                'sheet': theme.sheetBorderRadius.topLeft.x,
                'circle': 'pill',
              };
              final motion = PaymentMotion.of(context);
              final curves = {
                'easeOut': PaymentMotion.easeOut,
                'easeInOut': PaymentMotion.easeInOut,
                'drawer': PaymentMotion.drawer,
              };
              data['motion'] = {
                'press': motion.press.inMilliseconds,
                'quick': motion.quick.inMilliseconds,
                'enter': motion.enter.inMilliseconds,
                'exit': motion.exit.inMilliseconds,
                'sheetEnter': motion.sheetEnter.inMilliseconds,
                'sheetExit': motion.sheetExit.inMilliseconds,
                'pressedScale': motion.pressedScale,
                for (final entry in curves.entries)
                  entry.key: [
                    (entry.value as Cubic).a,
                    (entry.value as Cubic).b,
                    (entry.value as Cubic).c,
                    (entry.value as Cubic).d,
                  ],
              };
              return const SizedBox();
            },
          ),
        ),
      );
    }
    final file = File('../website/src/data/tokens.json');
    final snapshot = '${const JsonEncoder.withIndent('  ').convert(data)}\n';
    if (const bool.fromEnvironment('UPDATE_TOKENS')) {
      file.writeAsStringSync(snapshot);
    } else {
      expect(
        file.readAsStringSync(),
        snapshot,
        reason: 'rerun with --dart-define=UPDATE_TOKENS=true',
      );
    }
  });
}
