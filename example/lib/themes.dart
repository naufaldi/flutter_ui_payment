import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// Two independent brands applied from outside the package, without forking.
enum DemoBrand { ruangBayar, lumen }

ThemeData buildTheme(DemoBrand brand, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  switch (brand) {
    case DemoBrand.ruangBayar:
      // "Hairline": white page, navy-black ink, rules instead of cards.
      // Colors are contrast-checked in docs/design-research.md, section 0.
      final ink = dark ? const Color(0xFFECEDF0) : const Color(0xFF1A1F36);
      final surface = dark ? const Color(0xFF131417) : Colors.white;
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1F36),
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        primary: ink,
        onPrimary: surface,
        surface: surface,
        onSurface: ink,
      );
      final payment = PaymentTheme.fromColorScheme(scheme).copyWith(
        accent: ink,
        onAccent: surface,
        surface: surface,
        surfaceMuted: dark ? const Color(0xFF1C1E23) : const Color(0xFFF5F6F8),
        outline: dark ? const Color(0xFF2C2E35) : const Color(0xFFE3E6EC),
        textPrimary: ink,
        textSecondary: dark ? const Color(0xFFA2A8B5) : const Color(0xFF5E6678),
        // Control edge 3.37:1 light, 4.85:1 dark; disabled labels stay above
        // 2:1 on the muted fill.
        border: dark ? const Color(0xFF7E838E) : const Color(0xFF868C9A),
        disabled: dark ? const Color(0xFF62656E) : const Color(0xFFA6ABB5),
      );
      return _base(scheme, payment, background: surface);
    case DemoBrand.lumen:
      // "Contrast": pure black and white and heavier amounts, with the same
      // corners as Hairline (radius 8).
      final ink = dark ? Colors.white : Colors.black;
      final surface = dark ? const Color(0xFF0F0F0F) : Colors.white;
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        primary: ink,
        onPrimary: surface,
        surface: surface,
        onSurface: ink,
      );
      final payment = PaymentTheme.fromColorScheme(scheme).copyWith(
        accent: ink,
        onAccent: surface,
        surface: surface,
        surfaceMuted: dark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F3F3),
        outline: dark ? const Color(0xFF333333) : const Color(0xFFE8E8E8),
        textPrimary: ink,
        textSecondary: dark ? const Color(0xFFB3B3B3) : const Color(0xFF545454),
        radius: 8,
        amountWeight: FontWeight.w700,
      );
      return _base(scheme, payment, background: surface);
  }
}

ThemeData _base(
  ColorScheme scheme,
  PaymentTheme payment, {
  required Color background,
}) {
  final controlRadius = payment.controlBorderRadius;
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    extensions: [payment],
    dividerTheme: DividerThemeData(color: payment.outline, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: payment.textPrimary,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        height: 24 / 17,
        letterSpacing: 0,
        fontWeight: FontWeight.w600,
        color: payment.textPrimary,
      ),
      shape: Border(bottom: BorderSide(color: payment.outline)),
    ),
    // Demo/Scenarios/Gallery switcher: a plain bar with a hairline, the
    // selected destination in ink, no tonal pill.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? payment.textPrimary
              : payment.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? payment.textPrimary
              : payment.textSecondary,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: payment.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: payment.sheetBorderRadius),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: payment.surface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: payment.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: controlRadius,
        side: BorderSide(color: payment.outline),
      ),
    ),
    // Plain Material buttons in example screens match PaymentButton: 6 px
    // corners, ink outline, no pill.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: payment.textPrimary,
        side: BorderSide(color: payment.border),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: payment.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    ),
    // Chips in example screens (sheet filters, the scenario picker): small
    // corners, no check mark, selection shown by an ink outline.
    chipTheme: ChipThemeData(
      showCheckmark: false,
      backgroundColor: payment.surface,
      selectedColor: payment.surfaceMuted,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? payment.accent
              : payment.outline,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
      labelStyle: TextStyle(fontSize: 14, color: payment.textPrimary),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: payment.surface,
      border: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: payment.textSecondary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: payment.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: payment.accent, width: 2),
      ),
    ),
  );
}
