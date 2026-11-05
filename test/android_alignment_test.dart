import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'payment_path_footer_test.dart' as host;

void main() {
  for (final direction in TextDirection.values) {
    for (final width in [360.0, 640.0]) {
      testWidgets('document badge end: $width ${direction.name} (#145)', (
        t,
      ) async {
        t.view.physicalSize = Size(width, 800);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          host.screen(
            Directionality(
              textDirection: direction,
              child: DocumentUploadTile(
                requirement: const DocumentRequirement(
                  key: 'id',
                  label: 'ID',
                  acceptedTypes: {'image/jpeg'},
                  maxBytes: 1000,
                ),
                state: const DocumentSlotState.empty(),
                onPick: () {},
              ),
            ),
          ),
        );
        final title = t.getRect(find.text('ID'));
        final badge = t.getRect(find.byType(PaymentBadge));
        // The title and badge share the section's symmetric content gutters.
        final contentEnd = direction == TextDirection.ltr
            ? width - title.left
            : width - title.right;
        expect(
          direction == TextDirection.ltr ? badge.right : badge.left,
          closeTo(contentEnd, .5),
        );
        final target = t.getSize(find.byType(OutlinedButton));
        expect(target.width, greaterThanOrEqualTo(48));
        expect(target.height, greaterThanOrEqualTo(48));
        expect(t.takeException(), isNull);
      });

      testWidgets(
        'failed support text start: $width ${direction.name} (#145)',
        (t) async {
          t.view.physicalSize = Size(width, 800);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            host.screen(
              Directionality(
                textDirection: direction,
                child: PaymentStatusView(
                  attempt: PaymentAttempt(
                    attemptId: 'a',
                    quoteId: 'q',
                    quoteRevision: 1,
                    methodId: 'balance',
                    submission: SubmissionState.accepted,
                    observation: Observation.fresh,
                    snapshot: PaymentStatusSnapshot(
                      attemptId: 'a',
                      serverReference: 'REF',
                      status: PaymentStatus.failed,
                      revision: 1,
                      updatedAt: DateTime.utc(2026),
                      allowedActions: const {
                        PaymentAction.startNewAttempt,
                        PaymentAction.contactSupport,
                      },
                    ),
                  ),
                  onAction: (_) {},
                  secondaryAction: PaymentButton(
                    label: 'Done',
                    variant: PaymentButtonVariant.quiet,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          final l10n = PaymentLocalizations.of(
            t.element(find.byType(PaymentStatusView)),
          );
          final support = find.text(
            l10n.paymentActionLabel(PaymentAction.contactSupport),
          );
          final message = find.text(l10n.statusFailedMessage);
          final labelRect = t.getRect(support);
          final messageRect = t.getRect(message);
          expect(
            direction == TextDirection.ltr ? labelRect.left : labelRect.right,
            closeTo(
              direction == TextDirection.ltr
                  ? messageRect.left
                  : messageRect.right,
              .5,
            ),
          );
          final target = t.getSize(
            find.widgetWithText(
              PaymentButton,
              l10n.paymentActionLabel(PaymentAction.contactSupport),
            ),
          );
          expect(target.width, greaterThanOrEqualTo(48));
          expect(target.height, greaterThanOrEqualTo(48));
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
