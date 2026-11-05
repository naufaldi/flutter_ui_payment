import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/compositions/kyc_onboarding_block.dart';
import 'package:rakit_ui_example/kyc_onboarding_demo.dart';

import 'support/small_screen.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('consent starts unchecked and Continue waits for it', (
    tester,
  ) async {
    await tester.pumpWidget(const KycOnboardingDemo(delay: Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Nomor KTP (NIK)'), findsOneWidget);
    expect(enabled(tester, 'Lanjutkan'), isFalse);

    await tapText(
      tester,
      'Saya setuju data di atas diproses untuk verifikasi identitas.',
    );
    expect(enabled(tester, 'Lanjutkan'), isTrue);
    await tapText(tester, 'Lanjutkan');
    expect(find.byType(IdentityForm), findsOneWidget);
    // Identity only: the form never asks for a PIN, OTP or password.
    expect(find.textContaining('PIN'), findsNothing);
    expect(find.textContaining('OTP'), findsNothing);
  });

  testWidgets('the host rejects the ID number; the person corrects only that '
      'field and reviews it masked', (tester) async {
    await tester.pumpWidget(
      const KycOnboardingDemo(
        initialScenario: KycOnboardingScenario.hostRejectsId,
        initialStep: KycOnboardingStep.details,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Lanjutkan');
    expect(
      find.text('NIK ini tidak cocok dengan data kependudukan. Periksa lagi.'),
      findsOneWidget,
    );
    expect(find.text('Rina Contoh'), findsOneWidget);

    final idField = find.byType(EditableText).at(1);
    await tester.enterText(idField, '9999 0000 0000 3301');
    // Editing clears the host error under the field, which moves the layout.
    await tester.pump();
    await tapText(tester, 'Lanjutkan');
    expect(find.text('Tinjau data'), findsWidgets);
    expect(find.text('9999 0000 0000 3301'), findsNothing);
    expect(find.textContaining('3301'), findsOneWidget);
    expect(find.text('Rina Contoh'), findsOneWidget);
  });

  testWidgets('a failed save keeps the details; a confirmed save still says '
      'identity is not verified', (tester) async {
    await tester.pumpWidget(
      const KycOnboardingDemo(
        initialScenario: KycOnboardingScenario.saveFails,
        initialStep: KycOnboardingStep.review,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Simpan data');
    expect(find.text('Data belum tersimpan'), findsOneWidget);
    expect(find.text('Rina Contoh'), findsOneWidget);

    await tapText(tester, 'Simpan data');
    expect(find.text('Data diri tersimpan'), findsWidgets);
    expect(find.text('Identitas belum terverifikasi'), findsOneWidget);
  });

  testWidgets('320dp at 200% text in dark mode keeps consent and Continue '
      'reachable', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const KycOnboardingDemo(initialDark: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();
    await tapText(
      tester,
      'Saya setuju data di atas diproses untuk verifikasi identitas.',
    );
    expect(find.text('Lanjutkan').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
