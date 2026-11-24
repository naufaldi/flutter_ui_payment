import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('record body, trailing and footer are independent controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final actions = <String>[];
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.all(16),
          child: PaymentRecordCard(
            title: const Text('Settlement statement'),
            metadata: const Text('November 2026'),
            leading: Semantics(
              label: 'Document thumbnail',
              child: const SizedBox(width: 240, height: 96),
            ),
            onOpen: () => actions.add('open'),
            trailing: PaymentIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Remove statement',
              onPressed: () => actions.add('remove'),
            ),
            footer: PaymentLink(
              label: 'Download statement',
              onPressed: () => actions.add('download'),
            ),
          ),
        ),
        2,
      ),
    );
    final body = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp('Settlement statement.*November 2026', dotAll: true),
      ),
    );
    final remove = find.semantics
        .byPredicate(
          (node) => node.getSemanticsData().tooltip == 'Remove statement',
        )
        .evaluate()
        .single;
    final download = tester.getSemantics(
      find.bySemanticsLabel('Download statement'),
    );
    expect({body.id, remove.id, download.id}, hasLength(3));
    expect(body.flagsCollection.isButton, isTrue);
    expect(body.rect.height, greaterThanOrEqualTo(48));
    expect(remove.flagsCollection.isButton, isTrue);
    expect(find.bySemanticsLabel('Document thumbnail'), findsNothing);
    expect(
      tester.getSize(find.text('Settlement statement')).width,
      greaterThan(0),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(actions, ['open']);
    await tester.tap(find.byType(PaymentIconButton));
    await tester.tap(find.text('Download statement'));
    await tester.tap(find.text('Settlement statement'));
    expect(actions, ['open', 'remove', 'download', 'open']);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a narrow record keeps a separate 48 dp trailing tap target', (
    tester,
  ) async {
    final actions = <String>[];
    for (final width in [168.0, 48.0]) {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: width,
            child: PaymentRecordCard(
              title: const Text('PDF'),
              onOpen: () => actions.add('open'),
              trailing: PaymentIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Remove record',
                onPressed: () => actions.add('remove'),
              ),
            ),
          ),
          1,
        ),
      );
      final button = find.byType(IconButton);
      final target = tester.getRect(button);
      expect(
        target.width,
        greaterThanOrEqualTo(48),
        reason: 'card width $width',
      );
      expect(target.height, greaterThanOrEqualTo(48));
      await tester.tapAt(target.centerLeft + const Offset(1, 0));
    }
    expect(actions, ['remove', 'remove']);
  });

  testWidgets('resizing a record does not unlock a busy trailing action', (
    tester,
  ) async {
    final write = Completer<void>();
    var calls = 0;
    Widget card(double width) => host(
      SizedBox(
        width: width,
        child: PaymentRecordCard(
          title: const Text('PDF'),
          trailing: PaymentButton(
            label: 'Save',
            onPressed: () {
              calls++;
              return write.future;
            },
          ),
        ),
      ),
      1,
    );

    await tester.pumpWidget(card(240));
    final action = find.byType(PaymentButton);
    await tester.tap(action);
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(card(168));
    await tester.tap(action);
    expect(calls, 1);
    write.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'list dispatches ids, overrides handlers, and leaves values read-only',
    (tester) async {
      final ids = <String>[];
      var calls = 0;
      await tester.pumpWidget(
        host(
          PaymentList(
            onAction: ids.add,
            children: [
              const PaymentListItem(id: 'history', title: 'History'),
              PaymentListItem(
                id: 'pin',
                title: 'PIN',
                onPressed: () => calls++,
              ),
              const PaymentListItem(title: 'Balance', value: Text('Rp250.000')),
              const PaymentListItem(
                title: 'Disabled',
                disabledReason: 'Managed by your bank',
              ),
            ],
          ),
          1,
        ),
      );
      await tester.tap(find.text('History'));
      await tester.tap(find.text('PIN'));
      await tester.tap(find.text('Balance'));
      expect(ids, ['history']);
      expect(calls, 1);
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(find.byType(PaymentListItem).at(2))
            .flagsCollection
            .isButton,
        isFalse,
      );
      final disabled = tester.getSemantics(find.byType(PaymentListItem).at(3));
      expect(disabled.flagsCollection.isButton, isTrue);
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      expect(disabled.label, contains('Managed by your bank'));
      semantics.dispose();
    },
  );
  testWidgets('RTL uses one directional forward glyph', (tester) async {
    await tester.pumpWidget(
      host(
        Directionality(
          textDirection: TextDirection.rtl,
          child: PaymentListItem(title: 'History', onPressed: () {}),
        ),
        1,
      ),
    );
    expect(find.byIcon(PaymentIcons.forward), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });
  testWidgets('large targets and keyboard activation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentListItem(
          title: 'Bank',
          size: PaymentListItemSize.large,
          onPressed: () => calls++,
        ),
        1,
      ),
    );
    expect(
      tester.getSize(find.byType(PaymentListItem)).height,
      greaterThanOrEqualTo(64),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
  });
  testWidgets('value and trailing cannot be combined', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentListItem(
          title: 'Balance',
          value: Text('5'),
          trailing: Text('Change'),
        ),
        1,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
  testWidgets('large text keeps the amount at label size under the title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        const PaymentList(
          children: [
            PaymentListItem(
              title: 'Groceries at the corner shop',
              secondaryTitle: 'Paid 2 days ago',
              value: AmountText(Money(250000, 'IDR')),
            ),
          ],
        ),
        2,
      ),
    );
    final title = tester.getRect(find.text('Groceries at the corner shop'));
    final amount = tester.getRect(find.byType(AmountText));
    expect(tester.takeException(), isNull);
    expect(amount.height, greaterThanOrEqualTo(40));
    expect(amount.top, greaterThanOrEqualTo(title.bottom));
  });
  testWidgets('a 48 dp trailing control keeps its size beside a title', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PaymentListItem(
          title: 'Card ending 4242',
          trailing: PaymentButton(
            label: 'Change',
            variant: PaymentButtonVariant.quiet,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
            onPressed: () {},
          ),
        ),
        1,
      ),
    );
    final button = tester.getRect(find.byType(PaymentButton));
    final title = tester.getRect(find.text('Card ending 4242'));
    expect(button.height, greaterThanOrEqualTo(48));
    expect(button.center.dy, moreOrLessEquals(title.center.dy, epsilon: 0.5));
  });
}
