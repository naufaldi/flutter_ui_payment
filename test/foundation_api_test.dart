import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/token_resolvers.dart';

class NonlinearScaler extends TextScaler {
  const NonlinearScaler();
  @override
  double scale(double size) => size + size * size / 100;
  @override
  double get textScaleFactor => 1;
}

void main() {
  testWidgets('public roles, modifiers and token resolutions', (tester) async {
    for (final scaler in [
      const TextScaler.linear(1),
      const TextScaler.linear(1.3),
      const TextScaler.linear(2),
      const TextScaler.linear(3),
      const NonlinearScaler(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: Builder(
              builder: (context) {
                final type = PaymentType.of(context);
                final theme = PaymentTheme.of(context);
                expect(
                  PaymentType.firstLineHeight(context),
                  equals(scaler.scale(15) * 20 / 15),
                );
                if (scaler.scale(15) == 30) {
                  expect(PaymentType.firstLineHeight(context), 40.0);
                }
                expect(
                  type.tabular(const TextStyle(fontSize: 15)).fontFeatures,
                  const [FontFeature.tabularFigures()],
                );
                expect(
                  type.reference(type.label).fontFamily,
                  theme.referenceFontFamily,
                );
                expect(
                  type.reference(type.label).fontFamilyFallback,
                  theme.referenceFontFamilyFallback,
                );
                expect(theme.amountStyle(context), type.display);
                // ignore: deprecated_member_use_from_same_package
                final legacy = theme.amountStyle(context, large: false);
                expect(legacy.fontSize, 15);
                expect(legacy.height, 20 / 15);
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
                for (final role in PaymentTextRole.values) {
                  expect(role.resolve(context), styles[role.index]);
                }
                if (PaymentType.isLarge(context)) {
                  expect(type.bodyFor(context).height, 1.3);
                }
                expect(PaymentSpace.values.map(theme.space), [
                  0,
                  4,
                  8,
                  12,
                  16,
                  24,
                  32,
                ]);
                expect(
                  PaymentSpace.values.map(theme.copyWith(spacing: 10).space),
                  [0, 5, 10, 15, 20, 30, 40],
                );
                expect(PaymentRadius.values.map((r) => r.resolve(theme)), [
                  BorderRadius.zero,
                  theme.tagBorderRadius,
                  theme.controlBorderRadius,
                  theme.borderRadius,
                  theme.sheetBorderRadius,
                  BorderRadius.circular(999),
                ]);
                expect(PaymentTextColor.values.map((c) => c.resolve(theme)), [
                  theme.textPrimary,
                  theme.textSecondary,
                  theme.disabled,
                  theme.accent,
                  theme.info.foreground,
                  theme.success.foreground,
                  theme.warning.foreground,
                  theme.danger.foreground,
                ]);
                expect(PaymentFontWeight.values.map((w) => w.fontWeight), [
                  FontWeight.w400,
                  FontWeight.w600,
                  FontWeight.w700,
                ]);
                expect(PaymentIconSize.values.map((s) => s.resolve(context)), [
                  14,
                  16,
                  scaler.clamp(maxScaleFactor: 1.6).scale(20),
                  32,
                  48,
                ]);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }
    final branded = PaymentTheme.fromColorScheme(
      ColorScheme.fromSeed(seedColor: Colors.blue),
    ).copyWith(referenceFontFamily: 'JetBrains Mono');
    await tester.pumpWidget(
      MaterialApp(
        themeAnimationDuration: Duration.zero,
        theme: ThemeData(extensions: [branded]),
        home: Builder(
          builder: (context) {
            final type = PaymentType.of(context);
            expect(type.reference(type.label).fontFamily, 'JetBrains Mono');
            return const SizedBox();
          },
        ),
      ),
    );
  });
  test('closed sets and icon meanings', () {
    expect(PaymentTextRole.values.map((v) => v.name), [
      'display',
      'amountLarge',
      'title',
      'heading',
      'body',
      'label',
      'caption',
      'tag',
      'input',
    ]);
    expect(PaymentSize.values.map((v) => v.name), ['small', 'medium', 'large']);
    expect(PaymentWidth.values.map((v) => v.name), ['fill', 'hug']);
    expect(PaymentFieldPart.values.map((v) => v.name), [
      'label',
      'description',
      'error',
    ]);
    expect(
      [
        PaymentIcons.success,
        PaymentIcons.warning,
        PaymentIcons.danger,
        PaymentIcons.info,
        PaymentIcons.forward,
        PaymentIcons.externalLink,
        PaymentIcons.close,
        PaymentIcons.copy,
        PaymentIcons.copied,
        PaymentIcons.loadFailed,
        PaymentIcons.noMatches,
        PaymentIcons.busy,
        PaymentIcons.hidden,
      ],
      [
        Icons.check_circle_outline,
        Icons.warning_amber_outlined,
        Icons.error_outline,
        Icons.info_outline,
        Icons.chevron_right,
        Icons.open_in_new,
        Icons.close,
        Icons.copy_outlined,
        Icons.check,
        Icons.cloud_off_outlined,
        Icons.search_off,
        Icons.hourglass_top_outlined,
        Icons.lock_outline,
      ],
    );
    expect(PaymentIcons.forward.matchTextDirection, isTrue);
    expect(
      StatusTone.values.map(toneIcon),
      StatusTone.values.map(
        (tone) => switch (tone) {
          StatusTone.success => Icons.check_circle_outline,
          StatusTone.warning => Icons.warning_amber_outlined,
          StatusTone.danger => Icons.error_outline,
          StatusTone.info || StatusTone.neutral => Icons.info_outline,
        },
      ),
    );
  });
}
