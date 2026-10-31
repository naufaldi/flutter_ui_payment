// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('accordion leading remains a compatible alias', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentAccordionItem(
          title: 'Legacy',
          leading: Icons.info_outline,
          child: Text('Details'),
        ),
        1,
      ),
    );
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
  testWidgets('feedback aliases preserve constructors and types', (
    tester,
  ) async {
    expect(StatusBadge, PaymentBadge);
    expect(NoticeBanner, PaymentBanner);
    await tester.pumpWidget(
      host(
        const StatusBadge(
          tone: StatusTone.warning,
          label: 'Pending',
          icon: Icons.schedule,
        ),
        1,
      ),
    );
    expect(find.byType(PaymentBadge), findsOneWidget);
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                controller = showPaymentSnackBar(context, message: 'Copied'),
            child: const Text('Show'),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    controller.close();
    await tester.pumpAndSettle();
    await controller.closed;
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('navigation aliases preserve old constructors', (tester) async {
    expect(ActionTileGroup, PaymentList);
    expect(ActionMenu, PaymentMenu);
    expect(ActionMenuEntry, PaymentMenuItem);
    expect(ExpandableSection, PaymentAccordionItem);
    void action() {}
    await tester.pumpWidget(
      host(ActionTile(title: 'Old', subtitle: 'Detail', onTap: action), 1),
    );
    final row = tester.widget<PaymentListItem>(find.byType(PaymentListItem));
    expect(row.secondaryTitle, 'Detail');
    expect(row.onPressed, same(action));
    await tester.pumpWidget(
      host(
        ActionMenu(
          entries: [ActionMenuEntry(label: 'Old action', onSelected: action)],
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Old action'), findsOneWidget);
    await tester.pumpWidget(
      host(
        const ExpandableSection(title: 'Old section', child: Text('Body')),
        1,
      ),
    );
    expect(find.byType(PaymentAccordionItem), findsOneWidget);
  });
  testWidgets('currency alias preserves the old constructor', (tester) async {
    expect(AmountInput, PaymentCurrencyField);
    await tester.pumpWidget(
      host(AmountInput(currency: 'IDR', onChanged: (_) {}), 1),
    );
    expect(find.byType(PaymentCurrencyField), findsOneWidget);
  });
}
