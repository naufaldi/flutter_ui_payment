import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/kyc_capture_demo.dart';

import 'support/small_screen.dart';

/// A 1×1 transparent PNG standing in for the host camera's photo.
final testPhoto = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// Taps [text] that starts an upload. Its progress indicator animates for as
/// long as the host's answer is pending, so the wait is bounded.
Future<void> tapStartingUpload(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await pumpWhileUploading(tester);
}

Future<void> pumpWhileUploading(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Opens the source sheet and takes a photo with the camera.
Future<void> takePhoto(WidgetTester tester) async {
  await tapText(tester, 'Ambil foto');
  // The sheet's camera row repeats the label; it is the topmost one.
  await tapText(tester, 'Ambil foto');
}

DocumentSlotState slotOf(WidgetTester tester) =>
    tester.widget<KycCaptureGuide>(find.byType(KycCaptureGuide)).state;

void main() {
  testWidgets('an older upload answer cannot overwrite the retaken photo, and '
      'a finished upload is not a verification', (tester) async {
    final uploads = <String, Completer<DocumentIssue?>>{};
    await tester.pumpWidget(
      KycCaptureDemo(
        delay: Duration.zero,
        takePhoto: () async => testPhoto,
        upload: (id) => (uploads[id] = Completer<DocumentIssue?>()).future,
      ),
    );
    await tester.pumpAndSettle();
    await takePhoto(tester);
    await tapStartingUpload(tester, 'Pakai foto');
    expect(slotOf(tester).requestId, 'UPLOAD-DEMO-1');

    // The person retakes while the first upload is still running.
    await tapText(tester, 'Ulangi');
    await takePhoto(tester);
    await tapStartingUpload(tester, 'Pakai foto');
    expect(slotOf(tester).requestId, 'UPLOAD-DEMO-2');

    uploads['UPLOAD-DEMO-1']!.complete(
      const DocumentIssue(DocumentIssueKind.rejectedByHost),
    );
    await pumpWhileUploading(tester);
    expect(slotOf(tester).phase, DocumentSlotPhase.uploading);
    expect(slotOf(tester).requestId, 'UPLOAD-DEMO-2');

    uploads['UPLOAD-DEMO-2']!.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Foto KTP terunggah'), findsWidgets);
    expect(
      find.textContaining('belum berarti identitas terverifikasi'),
      findsOneWidget,
    );

    await tapText(tester, 'Kirim untuk verifikasi');
    expect(
      tester
          .widget<VerificationStatusView>(find.byType(VerificationStatusView))
          .snapshot
          .status,
      VerificationStatus.inReview,
    );
  });

  testWidgets('a denied camera explains why and offers settings; once '
      'allowed, the person can take the photo', (tester) async {
    await tester.pumpWidget(
      KycCaptureDemo(
        initialScenario: KycCaptureScenario.permissionDenied,
        delay: Duration.zero,
        takePhoto: () async => testPhoto,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Ambil foto');
    expect(slotOf(tester).issue!.kind, DocumentIssueKind.permissionDenied);

    await tapText(tester, PaymentLocalizations('id').openSettings);
    await tapText(tester, 'Simulasikan izin kamera');
    await takePhoto(tester);
    expect(find.text('Pakai foto'), findsOneWidget);
  });

  testWidgets('an interrupted upload retries the same photo; a blurry one '
      'asks for a retake', (tester) async {
    await tester.pumpWidget(
      KycCaptureDemo(
        initialScenario: KycCaptureScenario.interrupted,
        delay: Duration.zero,
        takePhoto: () async => testPhoto,
      ),
    );
    await tester.pumpAndSettle();
    await takePhoto(tester);
    await tapText(tester, 'Pakai foto');
    expect(slotOf(tester).issue!.kind, DocumentIssueKind.uploadInterrupted);
    await tapText(tester, PaymentLocalizations('id').tryAgain);
    expect(find.text('Foto KTP terunggah'), findsWidgets);

    await tester.pumpWidget(
      KycCaptureDemo(
        key: const ValueKey('blurry'),
        initialScenario: KycCaptureScenario.blurry,
        delay: Duration.zero,
        takePhoto: () async => testPhoto,
      ),
    );
    await tester.pumpAndSettle();
    await takePhoto(tester);
    await tapText(tester, 'Pakai foto');
    expect(slotOf(tester).issue!.kind, DocumentIssueKind.rejectedByHost);
    expect(enabled(tester, 'Ulangi'), isTrue);
  });

  testWidgets('320dp at 200% text in dark mode keeps the capture action '
      'reachable', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      KycCaptureDemo(
        initialDark: true,
        delay: Duration.zero,
        takePhoto: () async => testPhoto,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ambil foto').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
