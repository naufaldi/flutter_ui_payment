import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/verification/capture_geometry.dart';
import 'package:rakit_ui/src/foundation/view_frame.dart';

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
  Widget screen(
    KycCaptureGuide guide, {
    double scale = 1,
    String locale = 'en',
  }) => MaterialApp(
    locale: Locale(locale),
    supportedLocales: const [Locale('en'), Locale('id')],
    localizationsDelegates: const [
      PaymentLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(body: guide),
  );

  testWidgets('review photo is large enough to inspect at 360x640 (#139)', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      screen(
        KycCaptureGuide(
          kind: CaptureKind.idCard,
          photo: photo,
          onUsePhoto: () {},
          onRetake: () {},
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      t.getSize(find.byType(AspectRatio)).height,
      greaterThanOrEqualTo(200),
    );
    final usePhoto = find.widgetWithText(PaymentButton, 'Use photo');
    expect(usePhoto.hitTestable(), findsOneWidget);
    expect(t.getRect(usePhoto).bottom, lessThanOrEqualTo(640));
    expect(t.takeException(), isNull);
  });

  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(320, 569), 2.0),
    (const Size(1199, 720), 1.0),
  ]) {
    testWidgets('bounded capture fits and pins at $size, ${scale}x (#139)', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      for (final review in [false, true]) {
        await t.pumpWidget(
          screen(
            KycCaptureGuide(
              kind: CaptureKind.idCard,
              photo: review ? photo : null,
              onCapture: () {},
              onUsePhoto: () {},
              onRetake: () {},
            ),
            scale: scale,
          ),
        );
        await t.pumpAndSettle();
        final action = find.widgetWithText(
          PaymentButton,
          review ? 'Use photo' : 'Take photo',
        );
        expect(
          find.ancestor(of: action, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(action.hitTestable(), findsOneWidget);
        final preview = t.getRect(find.byType(AspectRatio));
        final footer = t.getRect(find.byType(PinnedFooter));
        expect(preview.top, greaterThanOrEqualTo(0));
        expect(preview.bottom, lessThanOrEqualTo(footer.top));
        expect(preview.width, lessThanOrEqualTo(640));
        expect(preview.left, greaterThanOrEqualTo(0));
        expect(preview.right, lessThanOrEqualTo(size.width));
        if (review && size.width != 360) {
          expect(t.getSize(action).width, lessThan(300));
        }
        expect(t.takeException(), isNull);
      }
    });
  }

  final compactStates = <String, DocumentSlotState>{
    'framing': const DocumentSlotState.empty(),
    'review': const DocumentSlotState.empty(),
    'uploading': const DocumentSlotState.uploading(
      file,
      requestId: '1',
      progress: .5,
    ),
    'uploaded': const DocumentSlotState.uploaded(file, requestId: '1'),
    'too large': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.tooLarge),
    ),
    'unsupported type': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.unsupportedType),
    ),
    'denied': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.permissionDenied),
    ),
    'permanently denied': const DocumentSlotState.failed(
      DocumentIssue(
        DocumentIssueKind.permissionPermanentlyDenied,
        canRetry: false,
        canOpenSettings: true,
      ),
    ),
    'interrupted': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.uploadInterrupted),
    ),
    'rejected': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.rejectedByHost),
    ),
    'rejected+update': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.rejectedByHost),
    ),
  };
  for (final size in [const Size(320, 569), const Size(320, 480)]) {
    for (final locale in ['en', 'id']) {
      for (final entry in compactStates.entries) {
        testWidgets(
          'compact default copy: ${entry.key} $locale at $size (#139)',
          (t) async {
            t.view.physicalSize = size;
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            await t.pumpWidget(
              screen(
                KycCaptureGuide(
                  kind: CaptureKind.idCard,
                  state: entry.value,
                  photo:
                      [
                        'framing',
                        'denied',
                        'permanently denied',
                      ].contains(entry.key)
                      ? null
                      : photo,
                  needsUpdate: entry.key == 'rejected+update',
                  onCapture: () {},
                  onRetake: () {},
                  onUsePhoto: () {},
                  onOpenSettings: () {},
                ),
                scale: 2,
                locale: locale,
              ),
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            expect(
              t.getSize(find.byType(AspectRatio)).height,
              greaterThanOrEqualTo(96),
            );
            final footer = t.getRect(find.byType(PinnedFooter));
            expect(
              t.getRect(find.byType(AspectRatio)).bottom,
              lessThanOrEqualTo(footer.top),
            );
            // FlutterTest's wide glyphs may require scrolling even where Roboto fits.
            for (final banner
                in find.byType(PaymentBanner).evaluate().toList()) {
              final texts = find.descendant(
                of: find.byWidget(banner.widget),
                matching: find.byType(Text),
              );
              for (final element in texts.evaluate().toList()) {
                final target = find.byWidget(element.widget);
                await Scrollable.ensureVisible(
                  t.element(target),
                  alignment: .5,
                );
                await t.pumpAndSettle();
                expect(target.hitTestable(), findsOneWidget);
              }
            }
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }

  // Short host-safe messages isolate layout from FlutterTest's one-em glyphs.
  // Device proof exercises the full localized messages with Roboto.
  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(320, 569), 2.0),
  ]) {
    for (final (name, state) in [
      (
        'uploading',
        const DocumentSlotState.uploading(file, requestId: '1', progress: .5),
      ),
      (
        'interrupted',
        const DocumentSlotState.failed(
          DocumentIssue(
            DocumentIssueKind.uploadInterrupted,
            safeMessage: 'Try again.',
          ),
        ),
      ),
      (
        'rejected',
        const DocumentSlotState.failed(
          DocumentIssue(
            DocumentIssueKind.rejectedByHost,
            safeMessage: 'Blurry photo.',
          ),
        ),
      ),
      (
        'permanently denied',
        const DocumentSlotState.failed(
          DocumentIssue(
            DocumentIssueKind.permissionPermanentlyDenied,
            safeMessage: 'Open Settings.',
            canRetry: false,
            canOpenSettings: true,
          ),
        ),
      ),
    ]) {
      testWidgets(
        'bounded status stays visible: $name at $size, ${scale}x (#139)',
        (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            screen(
              KycCaptureGuide(
                kind: CaptureKind.idCard,
                state: state,
                photo: name == 'permanently denied' ? null : photo,
                onRetake: () {},
                onUsePhoto: () {},
                onOpenSettings: () {},
              ),
              scale: scale,
            ),
          );
          await t.pumpAndSettle();
          final footer = t.getRect(find.byType(PinnedFooter));
          for (final finder in [
            find.byType(PaymentBadge),
            if (state.issue != null) find.byType(PaymentBanner),
            if (name == 'uploading') find.byType(LinearProgressIndicator),
          ]) {
            if (size.width == 360 ||
                !['interrupted', 'permanently denied'].contains(name)) {
              final rect = t.getRect(finder);
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.bottom, lessThanOrEqualTo(footer.top));
              expect(finder.hitTestable(), findsOneWidget);
            } else {
              await Scrollable.ensureVisible(t.element(finder), alignment: .5);
              await t.pumpAndSettle();
              expect(finder.hitTestable(), findsOneWidget);
            }
          }
          final preview = t.getRect(find.byType(AspectRatio));
          expect(preview.height, greaterThan(0));
          expect(preview.top, greaterThanOrEqualTo(0));
          expect(preview.bottom, lessThanOrEqualTo(footer.top));
          expect(preview.left, greaterThanOrEqualTo(0));
          expect(preview.right, lessThanOrEqualTo(size.width));
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('unbounded capture keeps its inline gallery layout (#139)', (
    t,
  ) async {
    await t.pumpWidget(
      host(KycCaptureGuide(kind: CaptureKind.idCard, photo: photo)),
    );
    await t.pumpAndSettle();
    expect(find.byType(PinnedFooter), findsNothing);
    expect(
      find.ancestor(of: find.text('Use photo'), matching: find.byType(Wrap)),
      findsOneWidget,
    );
    expect(t.getSize(find.byType(AspectRatio)), const Size(320, 320 * 4 / 3));
    expect(
      t
          .widget<PaymentButton>(find.widgetWithText(PaymentButton, 'Retake'))
          .variant,
      PaymentButtonVariant.secondary,
    );
  });

  final actionCases = [
    (
      'framing',
      const DocumentSlotState.empty(),
      false,
      ['Take photo'],
      <String>[],
    ),
    (
      'framing settings',
      const DocumentSlotState.failed(
        DocumentIssue(
          DocumentIssueKind.permissionDenied,
          canOpenSettings: true,
        ),
      ),
      false,
      ['Take photo'],
      ['Open settings'],
    ),
    (
      'review',
      const DocumentSlotState.empty(),
      true,
      ['Use photo'],
      ['Retake'],
    ),
    (
      'interrupted',
      const DocumentSlotState.failed(
        DocumentIssue(DocumentIssueKind.uploadInterrupted),
      ),
      true,
      ['Try again'],
      ['Retake'],
    ),
    (
      'uploading',
      const DocumentSlotState.uploading(file, requestId: '1', progress: .5),
      true,
      ['Retake'],
      <String>[],
    ),
    (
      'uploaded',
      const DocumentSlotState.uploaded(file, requestId: '1'),
      true,
      ['Retake'],
      <String>[],
    ),
    (
      'permanent denial',
      const DocumentSlotState.failed(
        DocumentIssue(
          DocumentIssueKind.permissionPermanentlyDenied,
          canRetry: false,
          canOpenSettings: true,
        ),
      ),
      false,
      ['Open settings'],
      <String>[],
    ),
    // #157: without a way to settings, a retryable denial still offers
    // the camera; with only settings left, settings is the primary.
    (
      'permanent denial, no settings',
      const DocumentSlotState.failed(
        DocumentIssue(DocumentIssueKind.permissionPermanentlyDenied),
      ),
      false,
      ['Take photo'],
      <String>[],
    ),
    (
      'framing, retry disallowed, settings',
      const DocumentSlotState.failed(
        DocumentIssue(
          DocumentIssueKind.permissionDenied,
          canRetry: false,
          canOpenSettings: true,
        ),
      ),
      false,
      ['Open settings'],
      <String>[],
    ),
    for (final kind in [
      DocumentIssueKind.tooLarge,
      DocumentIssueKind.unsupportedType,
      DocumentIssueKind.rejectedByHost,
    ])
      (
        kind.name,
        DocumentSlotState.failed(DocumentIssue(kind)),
        true,
        ['Retake'],
        <String>[],
      ),
    (
      'retry disallowed',
      const DocumentSlotState.failed(
        DocumentIssue(DocumentIssueKind.rejectedByHost, canRetry: false),
      ),
      true,
      <String>[],
      <String>[],
    ),
  ];
  for (final (name, state, hasPhoto, primary, quiet) in actionCases) {
    testWidgets('bounded footer mapping: $name (#139)', (t) async {
      var taken = 0, used = 0, retaken = 0, settings = 0;
      await t.pumpWidget(
        screen(
          KycCaptureGuide(
            kind: CaptureKind.idCard,
            state: state,
            photo: hasPhoto ? photo : null,
            onCapture: () => taken++,
            onUsePhoto: () => used++,
            onRetake: () => retaken++,
            onOpenSettings: () => settings++,
          ),
        ),
      );
      await t.pumpAndSettle();
      final buttons = t
          .widgetList<PaymentButton>(find.byType(PaymentButton))
          .toList();
      expect(
        buttons
            .where((b) => b.variant == PaymentButtonVariant.primary)
            .map((b) => b.label),
        primary,
      );
      expect(
        buttons
            .where((b) => b.variant == PaymentButtonVariant.quiet)
            .map((b) => b.label),
        quiet,
      );
      expect(buttons.length, primary.length + quiet.length);
      expect(buttons.length, lessThanOrEqualTo(2));
      for (final button in buttons) {
        final target = find.widgetWithText(PaymentButton, button.label);
        expect(
          find.ancestor(of: target, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(t.getSize(target).height, greaterThanOrEqualTo(48));
        await t.tap(target);
      }
      expect(taken, buttons.where((b) => b.label == 'Take photo').length);
      expect(
        used,
        buttons
            .where((b) => ['Use photo', 'Try again'].contains(b.label))
            .length,
      );
      expect(retaken, buttons.where((b) => b.label == 'Retake').length);
      expect(settings, buttons.where((b) => b.label == 'Open settings').length);
    });
  }

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

  testWidgets('needs update without a reason reads its title once (#166)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const KycCaptureGuide(kind: CaptureKind.idCard, needsUpdate: true)),
    );
    expect(find.text('Please update this item.'), findsOneWidget);
  });

  testWidgets('the picked file reads as one stop: name and size (#112)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DocumentUploadTile(
          requirement: requirement,
          state: const DocumentSlotState.uploaded(file, requestId: '1'),
          onPick: () {},
        ),
        scale: 2,
      ),
    );
    expect(find.semantics.byLabel('demo.jpg, 1 KB'), findsOneWidget);
    // The visual separator and the bare size are not spoken on their own.
    expect(find.semantics.byLabel(RegExp(r'^\s*·')), findsNothing);
    expect(find.semantics.byLabel('demo.jpg'), findsNothing);
    expect(tester.takeException(), isNull);
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
