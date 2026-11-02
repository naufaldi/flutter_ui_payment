import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/verification/capture_geometry.dart';

import 'helpers/reduced_motion.dart';

Widget host(
  Widget child, {
  String locale = 'en',
  double scale = 1,
  bool dark = false,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 320, child: child)),
    ),
  ),
);
final photo = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
  ),
);
const file = DocumentFile(
  name: 'demo.jpg',
  mimeType: 'image/jpeg',
  sizeBytes: 100,
);
const requirement = DocumentRequirement(
  key: 'id',
  label: 'ID card',
  acceptedTypes: {'image/jpeg'},
  maxBytes: 1000,
);

/// Like [host], but keeps the view's MediaQuery, so a reduced-motion setup
/// applied around it still reaches the kit.
Widget motionHost(Widget child, {double scale = 1}) => MaterialApp(
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: app!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 320, child: child)),
  ),
);

/// Both upload widgets, built without a photo so no image fade runs.
final uploads = <String, Widget Function(DocumentSlotState)>{
  'document slot': (state) =>
      DocumentUploadTile(requirement: requirement, state: state, onPick: () {}),
  'capture field': (state) =>
      KycCaptureGuide(kind: CaptureKind.idCard, state: state),
};
void main() {
  test('framing uses ID-1 ratio and separates face and card', () {
    for (final kind in CaptureKind.values) {
      final frames = captureFrameRects(kind, const Size(300, 400));
      expect(frames.card.width / frames.card.height, closeTo(85.6 / 54, .01));
      if (frames.face != null) {
        expect(frames.face!.bottom, lessThan(frames.card.top));
      }
    }
  });
  testWidgets('source sheet orders choices, reports selection and dismissal', (
    tester,
  ) async {
    CaptureSource? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showCaptureSourceSheet(
                context: context,
                sources: {CaptureSource.file, CaptureSource.camera},
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from gallery'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Take a photo')).dy,
      lessThan(tester.getTopLeft(find.text('Choose a file')).dy),
    );
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(result, CaptureSource.camera);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close panel'));
    await tester.pumpAndSettle();
    expect(result, null);
  });
  testWidgets('blocked source stays open and settings dismisses', (
    tester,
  ) async {
    var settings = 0;
    CaptureSource? result = CaptureSource.file;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showCaptureSourceSheet(
                context: context,
                unavailable: {CaptureSource.camera: 'Camera access is off'},
                onOpenSettings: () {
                  settings++;
                },
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Camera access is off'), findsOneWidget);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSheet), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(settings, 1);
    expect(result, null);
  });
  testWidgets('framing tips and preview pass-through', (tester) async {
    var captured = 0, tapped = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        KycCaptureGuide(
          kind: CaptureKind.idCard,
          preview: GestureDetector(
            key: const Key('host-preview'),
            onTap: () {
              tapped++;
            },
            child: const ColoredBox(color: Colors.grey),
          ),
          onCapture: () {
            captured++;
          },
        ),
      ),
    );
    expect(find.bySemanticsLabel('Frame for your ID card'), findsOneWidget);
    expect(find.text('Show all four corners'), findsOneWidget);
    expect(find.text('Don’t cover any text with your fingers'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byKey(const Key('host-preview'))));
    expect(tapped, 1);
    await tester.ensureVisible(find.text('Take photo'));
    await tester.tap(find.text('Take photo'));
    await tester.pump();
    expect(captured, 1);
    semantics.dispose();
  });
  testWidgets('review and host failures expose appropriate actions', (
    tester,
  ) async {
    var used = 0, retaken = 0;
    Future<void> show(DocumentSlotState state) async {
      await tester.pumpWidget(
        host(
          KycCaptureGuide(
            kind: CaptureKind.idCard,
            photo: photo,
            state: state,
            onUsePhoto: () {
              used++;
            },
            onRetake: () {
              retaken++;
            },
          ),
        ),
      );
      await tester.pump();
    }

    await show(const DocumentSlotState.empty());
    await tester.ensureVisible(find.text('Use photo'));
    await tester.tap(find.text('Use photo'));
    await tester.pump();
    expect(used, 1);
    await tester.tap(find.text('Retake'));
    await tester.pump();
    expect(retaken, 1);
    await show(const DocumentSlotState.uploading(file, requestId: '1'));
    expect(find.text('Uploading'), findsOneWidget);
    expect(find.text('Use photo'), findsNothing);
    expect(find.text('Retake'), findsOneWidget);
    await show(
      const DocumentSlotState.failed(
        DocumentIssue(
          DocumentIssueKind.rejectedByHost,
          safeMessage: 'Foto KTP buram. Ambil ulang di tempat terang.',
        ),
      ),
    );
    expect(
      find.text('Foto KTP buram. Ambil ulang di tempat terang.'),
      findsOneWidget,
    );
    expect(find.text('Use photo'), findsNothing);
    await show(
      const DocumentSlotState.failed(
        DocumentIssue(DocumentIssueKind.uploadInterrupted),
      ),
    );
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(used, 2);
  });
  testWidgets('permission and update states render without verdict copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KycCaptureGuide(
          kind: CaptureKind.idCard,
          state: const DocumentSlotState.failed(
            DocumentIssue(
              DocumentIssueKind.permissionPermanentlyDenied,
              canRetry: false,
              canOpenSettings: true,
            ),
          ),
          needsUpdate: true,
          updateReason: 'Host requests another photo',
          onOpenSettings: () {},
        ),
      ),
    );
    expect(find.text('Take photo'), findsNothing);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('Host requests another photo'), findsOneWidget);
    for (final kind in CaptureKind.values) {
      for (final locale in ['en', 'id']) {
        for (final state in [
          const DocumentSlotState.empty(),
          const DocumentSlotState.uploading(file, requestId: '1'),
          const DocumentSlotState.uploaded(file, requestId: '1'),
          const DocumentSlotState.failed(
            DocumentIssue(DocumentIssueKind.rejectedByHost),
          ),
        ]) {
          await tester.pumpWidget(
            host(
              KycCaptureGuide(kind: kind, state: state),
              locale: locale,
              scale: 2,
              dark: true,
            ),
          );
          expect(tester.takeException(), null);
          expect(
            find.textContaining(
              RegExp(
                r'verified|valid|detected|looks good|terverifikasi|jelas',
                caseSensitive: false,
              ),
            ),
            findsNothing,
          );
        }
      }
    }
  });

  // Upload progress (D76, #97): the badge owns the label and known value.
  for (final MapEntry(key: name, value: upload) in uploads.entries) {
    group('$name upload', () {
      const unknown = DocumentSlotState.uploading(file, requestId: '1');
      const known = DocumentSlotState.uploading(
        file,
        requestId: '1',
        progress: .42,
      );
      final bar = find.byType(LinearProgressIndicator);

      for (final setup in ReducedMotion.values) {
        testWidgets('unknown progress stands still (${setup.name})', (
          tester,
        ) async {
          await tester.pumpWidget(
            setup.apply(
              tester,
              motionHost(upload(const DocumentSlotState.empty())),
            ),
          );
          await expectStill(
            tester,
            () => tester.pumpWidget(
              setup.apply(tester, motionHost(upload(unknown))),
            ),
          );
          // No bar, so no value the kit doesn't know.
          expect(bar, findsNothing);
          expect(find.semantics.byValue(RegExp('%')), findsNothing);
          expect(find.semantics.byValue('42'), findsNothing);
          expect(
            find.semantics.byLabel('Uploading').evaluate().single.value,
            isEmpty,
          );
          expect(find.semantics.byLabel('Uploading'), findsOneWidget);
          // The still busy glyph sits beside "Uploading" in the badge.
          final glyph = find.descendant(
            of: find.byType(PaymentBadge),
            matching: find.byIcon(PaymentIcons.busy),
          );
          final label = find.descendant(
            of: find.byType(PaymentBadge),
            matching: find.text('Uploading'),
          );
          expect(glyph, findsOneWidget);
          expect(label, findsOneWidget);
          expect(
            tester.getCenter(glyph).dy,
            closeTo(tester.getCenter(label).dy, 1),
          );
          expect(
            tester.getTopRight(glyph).dx,
            lessThan(tester.getTopLeft(label).dx),
          );
        });

        testWidgets('known progress keeps its bar (${setup.name})', (
          tester,
        ) async {
          await tester.pumpWidget(
            setup.apply(tester, motionHost(upload(known))),
          );
          expect(tester.widget<LinearProgressIndicator>(bar).value, .42);
          expect(find.semantics.byValue('42%'), findsOneWidget);
          expect(
            find.semantics.byLabel('Uploading').evaluate().single,
            same(find.semantics.byValue('42%').evaluate().single),
          );
          expect(find.semantics.byValue('42'), findsNothing);
          expect(find.semantics.byLabel('Uploading'), findsOneWidget);
          expect(find.byIcon(PaymentIcons.busy), findsNothing);
          expect(tester.hasRunningAnimations, isFalse);
        });
      }

      testWidgets('with motion, unknown progress keeps the moving bar', (
        tester,
      ) async {
        await tester.pumpWidget(motionHost(upload(unknown)));
        expect(tester.widget<LinearProgressIndicator>(bar).value, isNull);
        expect(tester.hasRunningAnimations, isTrue);
        expect(find.semantics.byValue(RegExp('%')), findsNothing);
        expect(find.semantics.byValue('42'), findsNothing);
        expect(
          find.semantics.byLabel('Uploading').evaluate().single.value,
          isEmpty,
        );
        expect(find.semantics.byLabel('Uploading'), findsOneWidget);
        expect(find.byIcon(PaymentIcons.busy), findsNothing);
      });

      testWidgets('with motion, known progress shows its value', (
        tester,
      ) async {
        await tester.pumpWidget(motionHost(upload(known)));
        expect(tester.widget<LinearProgressIndicator>(bar).value, .42);
        expect(find.semantics.byValue('42%'), findsOneWidget);
        expect(
          find.semantics.byLabel('Uploading').evaluate().single,
          same(find.semantics.byValue('42%').evaluate().single),
        );
        expect(find.semantics.byValue('42'), findsNothing);
        expect(find.semantics.byLabel('Uploading'), findsOneWidget);
      });

      testWidgets('unknown progress at 200% text on 320 dp fits', (
        tester,
      ) async {
        await tester.pumpWidget(
          ReducedMotion.mediaQuery.apply(
            tester,
            motionHost(upload(unknown), scale: 2),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byIcon(PaymentIcons.busy), findsOneWidget);
      });
    });
  }
}
