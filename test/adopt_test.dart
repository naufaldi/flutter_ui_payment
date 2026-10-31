import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/radio_mark.dart';
import 'widgets_test.dart' show host;
import 'kit_components_test.dart' show app, FakeVideo;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('consent alignment and gate $scale', (tester) async {
      var continued = 0;
      await tester.pumpWidget(
        host(
          VerificationIntro(
            requirements: const [
              DataRequirement(title: 'ID card', purpose: 'Match your name'),
            ],
            onContinue: () => continued++,
          ),
          textScale: scale,
        ),
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      final control = find.byType(PaymentCheckbox);
      expect(
        tester.getSemantics(control),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: PaymentLocalizations.of(tester.element(control)).consentLabel,
        ),
      );
      final slot = find.ancestor(
        of: find.byType(Checkbox),
        matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 20),
      );
      expect(
        tester.getTopLeft(slot).dx,
        tester.getTopLeft(find.byType(VerificationIntro)).dx,
      );
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      expect(continued, 1);
    });
  }
  testWidgets('method rings use disabled and selected roles', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentMethodPicker(
          methods: const [
            PaymentMethod(
              id: 'a',
              label: 'Balance',
              kind: PaymentMethodKind.balance,
            ),
            PaymentMethod(
              id: 'b',
              label: 'Card',
              kind: PaymentMethodKind.card,
              unavailableReason: 'Verify first',
            ),
          ],
          selectedId: 'a',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.byIcon(Icons.block), findsNothing);
    expect(find.textContaining('Verify first'), findsOneWidget);
    for (final e in find.byType(RadioMark).evaluate()) {
      final mark = e.widget as RadioMark;
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byWidget(mark),
          matching: find.byType(Container),
        ),
      );
      final border = (container.decoration as BoxDecoration).border! as Border;
      final theme = PaymentTheme.of(e);
      expect(border.top.width, mark.selected ? 6 : 1.5);
      expect(border.top.color, mark.enabled ? theme.accent : theme.disabled);
    }
  });
  testWidgets('video spinner announces only the video status', (tester) async {
    final video = FakeVideo()
      ..value = const VideoPlaybackValue(phase: VideoPhase.loading);
    addTearDown(video.dispose);
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PaymentVideoPlayer(controller: video, title: 'Demo'),
          ),
          reduceMotion: reduced,
        ),
      );
      final spinner = tester.widget<PaymentSpinner>(
        find.byType(PaymentSpinner),
      );
      expect(spinner.size, 32);
      expect(spinner.color, Colors.white);
      expect(find.bySemanticsLabel('Loading'), findsNothing);
      expect(find.text('Loading video'), findsOneWidget);
      if (reduced) {
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.widget<Icon>(find.byIcon(Icons.hourglass_top)).size, 32);
      } else {
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .strokeWidth,
          3.84,
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed photo retains review actions and illustrated fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KycCaptureGuide(
          kind: CaptureKind.idCard,
          photo: MemoryImage(Uint8List.fromList([0, 1, 2])),
          onUsePhoto: () {},
          onRetake: () {},
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(
      find.byWidgetPredicate((w) => w is CaptureFrameOverlay && !w.overPreview),
      findsOneWidget,
    );
    expect(find.text('Use photo'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reapproval is aligned, gated and disabled while busy', (
    tester,
  ) async {
    final quote = PaymentQuote(
      id: 'q',
      revision: 1,
      lines: const [QuoteLine(label: 'Item', amount: Money.idr(1000))],
      total: const Money.idr(1000),
      expiresAt: DateTime.utc(2030),
      methodId: 'a',
    );
    final changed = PaymentQuote(
      id: 'q',
      revision: 2,
      lines: const [QuoteLine(label: 'Item', amount: Money.idr(2000))],
      total: const Money.idr(2000),
      expiresAt: DateTime.utc(2030),
      methodId: 'a',
    );
    var calls = 0;
    for (final busy in [false, true]) {
      await tester.pumpWidget(
        host(
          PaymentConfirmation(
            key: ValueKey(busy),
            quote: changed,
            previousQuote: quote,
            method: const PaymentMethod(
              id: 'a',
              label: 'Balance',
              kind: PaymentMethodKind.balance,
            ),
            busy: busy,
            onConfirm: () async {
              calls++;
            },
          ),
        ),
      );
      final row = find.byType(PaymentCheckbox);
      expect(tester.widget<PaymentCheckbox>(row).onChanged == null, busy);
      final slot = find.ancestor(
        of: find.byType(Checkbox),
        matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 20),
      );
      expect(
        tester.getTopLeft(slot).dx,
        tester.getTopLeft(find.byType(PaymentConfirmation)).dx,
      );
      final pay = tester.widget<PaymentButton>(find.byType(PaymentButton));
      expect(pay.onPressed, isNull);
      if (!busy) {
        await tester.tap(row);
        await tester.pump();
        await tester.tap(find.byType(PaymentButton));
        await tester.pump();
        expect(calls, 1);
      }
      for (final e in find.byType(Divider).evaluate()) {
        expect(e.findAncestorWidgetOfExactType<PaymentDivider>(), isNotNull);
      }
    }
  });
}
