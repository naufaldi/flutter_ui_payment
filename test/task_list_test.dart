import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  testWidgets('host statuses, child count and task action are spoken', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    var calls = 0;
    await t.pumpWidget(
      contentHost(
        PaymentTaskList(
          items: [
            const PaymentTaskListItem(
              title: 'Identity',
              status: PaymentTaskStatus.complete,
            ),
            PaymentTaskListItem(
              title: 'Documents',
              status: PaymentTaskStatus.inProgress,
              onPressed: () {
                calls++;
              },
              subTasks: const [
                PaymentTaskListItem(
                  title: 'KTP',
                  status: PaymentTaskStatus.complete,
                ),
                PaymentTaskListItem(title: 'Selfie'),
              ],
            ),
            const PaymentTaskListItem(
              title: 'Review',
              status: PaymentTaskStatus.blocked,
            ),
          ],
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'Documents, In progress, 1 of 2 sub-tasks complete',
      ),
      findsOneWidget,
    );
    await t.tap(find.text('Documents'));
    expect(calls, 1);
    semantics.dispose();
  });
  testWidgets('complete hides children; narrow large text wraps', (t) async {
    await setSurface(t, const Size(320, 1000));
    for (final dark in [false, true]) {
      await t.pumpWidget(
        contentHost(
          const PaymentTaskList(
            items: [
              PaymentTaskListItem(
                title: 'A long completed identity check',
                status: PaymentTaskStatus.complete,
                subTasks: [PaymentTaskListItem(title: 'Hidden')],
              ),
            ],
          ),
          scale: 2,
          dark: dark,
        ),
      );
      expect(find.text('Hidden'), findsNothing);
      expect(t.takeException(), isNull);
    }
  });
}
