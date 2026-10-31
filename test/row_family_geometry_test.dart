import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

const expected = <String, List<Rect>>{
  '1.0 rtl 0': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(253.0, 12.0, 328.0, 32.0),
    Rect.fromLTRB(250.0, 32.0, 328.0, 50.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
  ],
  '1.0 rtl 1': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(253.0, 12.0, 328.0, 32.0),
    Rect.fromLTRB(250.0, 32.0, 328.0, 50.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
  ],
  '1.0 rtl 2': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 72.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 72.0),
    Rect.fromLTRB(285.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(282.0, 32.0, 360.0, 50.0),
  ],
  '1.0 rtl 3': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(253.0, 12.0, 328.0, 32.0),
    Rect.fromLTRB(250.0, 32.0, 328.0, 50.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
  ],
  '1.0 rtl 4': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(253.0, 12.0, 328.0, 32.0),
    Rect.fromLTRB(250.0, 32.0, 328.0, 50.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
  ],
  '1.0 rtl 5': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 64.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 64.0),
    Rect.fromLTRB(285.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(282.0, 32.0, 360.0, 50.0),
  ],
  '1.0 rtl 6': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 66.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 66.0),
    Rect.fromLTRB(121.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(0.0, 12.0, 105.0, 32.0),
    Rect.fromLTRB(139.0, 36.0, 360.0, 54.0),
  ],
  '1.0 rtl 7': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 98.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 98.0),
    Rect.fromLTRB(121.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(0.0, 12.0, 105.0, 32.0),
    Rect.fromLTRB(139.0, 36.0, 360.0, 54.0),
    Rect.fromLTRB(262.0, 66.0, 334.0, 82.0),
    Rect.fromLTRB(124.0, 66.0, 220.0, 82.0),
  ],
  '1.0 ltr 0': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(32.0, 12.0, 107.0, 32.0),
    Rect.fromLTRB(32.0, 32.0, 110.0, 50.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 32.0),
  ],
  '1.0 ltr 1': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(32.0, 12.0, 107.0, 32.0),
    Rect.fromLTRB(32.0, 32.0, 110.0, 50.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
  ],
  '1.0 ltr 2': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 72.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 72.0),
    Rect.fromLTRB(0.0, 12.0, 75.0, 32.0),
    Rect.fromLTRB(0.0, 32.0, 78.0, 50.0),
  ],
  '1.0 ltr 3': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(32.0, 12.0, 107.0, 32.0),
    Rect.fromLTRB(32.0, 32.0, 110.0, 50.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
  ],
  '1.0 ltr 4': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 62.0),
    Rect.fromLTRB(32.0, 12.0, 107.0, 32.0),
    Rect.fromLTRB(32.0, 32.0, 110.0, 50.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 32.0),
  ],
  '1.0 ltr 5': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 64.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 64.0),
    Rect.fromLTRB(0.0, 12.0, 75.0, 32.0),
    Rect.fromLTRB(0.0, 32.0, 78.0, 50.0),
  ],
  '1.0 ltr 6': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 66.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 66.0),
    Rect.fromLTRB(0.0, 12.0, 239.0, 32.0),
    Rect.fromLTRB(255.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(0.0, 36.0, 221.0, 54.0),
  ],
  '1.0 ltr 7': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 98.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 98.0),
    Rect.fromLTRB(0.0, 12.0, 239.0, 32.0),
    Rect.fromLTRB(255.0, 12.0, 360.0, 32.0),
    Rect.fromLTRB(0.0, 36.0, 221.0, 54.0),
    Rect.fromLTRB(26.0, 66.0, 98.0, 82.0),
    Rect.fromLTRB(140.0, 66.0, 236.0, 82.0),
  ],
  '2.0 rtl 0': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(166.0, 12.0, 316.0, 52.0),
    Rect.fromLTRB(160.0, 52.0, 316.0, 88.0),
    Rect.fromLTRB(328.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(328.0, 16.0, 360.0, 48.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 52.0),
    Rect.fromLTRB(0.0, 22.0, 20.0, 42.0),
  ],
  '2.0 rtl 1': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(166.0, 12.0, 316.0, 52.0),
    Rect.fromLTRB(160.0, 52.0, 316.0, 88.0),
    Rect.fromLTRB(328.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(328.0, 16.0, 360.0, 48.0),
  ],
  '2.0 rtl 2': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(210.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(204.0, 52.0, 360.0, 88.0),
  ],
  '2.0 rtl 3': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(178.0, 12.0, 328.0, 52.0),
    Rect.fromLTRB(172.0, 52.0, 328.0, 88.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 52.0),
  ],
  '2.0 rtl 4': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(178.0, 12.0, 328.0, 52.0),
    Rect.fromLTRB(172.0, 52.0, 328.0, 88.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 52.0),
  ],
  '2.0 rtl 5': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(210.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(204.0, 52.0, 360.0, 88.0),
  ],
  '2.0 rtl 6': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 180.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 180.0),
    Rect.fromLTRB(210.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(150.0, 52.0, 360.0, 92.0),
    Rect.fromLTRB(0.0, 96.0, 360.0, 168.0),
  ],
  '2.0 rtl 7': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 272.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 272.0),
    Rect.fromLTRB(210.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(150.0, 52.0, 360.0, 92.0),
    Rect.fromLTRB(0.0, 96.0, 360.0, 168.0),
    Rect.fromLTRB(190.0, 180.0, 334.0, 212.0),
    Rect.fromLTRB(142.0, 224.0, 334.0, 256.0),
  ],
  '2.0 ltr 0': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(44.0, 12.0, 194.0, 52.0),
    Rect.fromLTRB(44.0, 52.0, 200.0, 88.0),
    Rect.fromLTRB(0.0, 12.0, 32.0, 52.0),
    Rect.fromLTRB(0.0, 16.0, 32.0, 48.0),
    Rect.fromLTRB(340.0, 12.0, 360.0, 52.0),
    Rect.fromLTRB(340.0, 22.0, 360.0, 42.0),
  ],
  '2.0 ltr 1': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(44.0, 12.0, 194.0, 52.0),
    Rect.fromLTRB(44.0, 52.0, 200.0, 88.0),
    Rect.fromLTRB(0.0, 12.0, 32.0, 52.0),
    Rect.fromLTRB(0.0, 16.0, 32.0, 48.0),
  ],
  '2.0 ltr 2': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 12.0, 150.0, 52.0),
    Rect.fromLTRB(0.0, 52.0, 156.0, 88.0),
  ],
  '2.0 ltr 3': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(32.0, 12.0, 182.0, 52.0),
    Rect.fromLTRB(32.0, 52.0, 188.0, 88.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 52.0),
  ],
  '2.0 ltr 4': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(32.0, 12.0, 182.0, 52.0),
    Rect.fromLTRB(32.0, 52.0, 188.0, 88.0),
    Rect.fromLTRB(0.0, 12.0, 20.0, 52.0),
  ],
  '2.0 ltr 5': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 100.0),
    Rect.fromLTRB(0.0, 12.0, 150.0, 52.0),
    Rect.fromLTRB(0.0, 52.0, 156.0, 88.0),
  ],
  '2.0 ltr 6': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 180.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 180.0),
    Rect.fromLTRB(0.0, 12.0, 150.0, 52.0),
    Rect.fromLTRB(0.0, 52.0, 210.0, 92.0),
    Rect.fromLTRB(0.0, 96.0, 360.0, 168.0),
  ],
  '2.0 ltr 7': [
    Rect.fromLTRB(0.0, 0.0, 360.0, 272.0),
    Rect.fromLTRB(0.0, 0.0, 360.0, 272.0),
    Rect.fromLTRB(0.0, 12.0, 150.0, 52.0),
    Rect.fromLTRB(0.0, 52.0, 210.0, 92.0),
    Rect.fromLTRB(0.0, 96.0, 360.0, 168.0),
    Rect.fromLTRB(26.0, 180.0, 170.0, 212.0),
    Rect.fromLTRB(26.0, 224.0, 218.0, 256.0),
  ],
};

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('row geometry $scale $direction', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cases = <Widget>[
          ActionTile(
            title: 'Title',
            subtitle: 'Detail',
            icon: Icons.receipt_long_outlined,
            onTap: () {},
          ),
          const ActionTile(
            title: 'Title',
            icon: Icons.receipt_long_outlined,
            disabledReason: 'Detail',
          ),
          ActionTile(
            title: 'Title',
            subtitle: 'Detail',
            trailing: Switch(value: true, onChanged: (_) {}),
            onTap: () {},
          ),
          PaymentCheckbox(
            value: false,
            onChanged: (_) {},
            label: 'Title',
            description: 'Detail',
          ),
          PaymentRadio(
            value: 1,
            groupValue: 1,
            onChanged: (_) {},
            label: 'Title',
            description: 'Detail',
          ),
          PaymentSwitch(
            value: true,
            onChanged: (_) {},
            label: 'Title',
            description: 'Detail',
          ),
          for (final status in [PaymentStatus.succeeded, PaymentStatus.failed])
            TransactionListItem(
              record: TransactionRecord(
                id: '1',
                title: 'Title',
                amount: const Money.idr(1000),
                createdAt: DateTime.utc(2026),
                status: status,
                refund: RefundInfo(
                  status: status == PaymentStatus.failed
                      ? RefundStatus.refunded
                      : RefundStatus.none,
                ),
              ),
              onTap: () {},
            ),
        ];
        for (var i = 0; i < cases.length; i++) {
          final widget = cases[i];
          await tester.pumpWidget(
            host(
              Directionality(
                textDirection: direction,
                child: Column(children: [widget]),
              ),
              scale,
            ),
          );
          final root = find.byWidget(widget);
          final targets = <Finder>[
            root,
            find.descendant(of: root, matching: find.byType(InkWell)).first,
            find.text('Title'),
            ...find
                .descendant(of: root, matching: find.byType(Text))
                .evaluate()
                .where((e) => (e.widget as Text).data != 'Title')
                .map((e) => find.byWidget(e.widget)),
          ];
          targets.addAll(
            find
                .descendant(
                  of: root,
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is SizedBox &&
                        (w.width == 20 ||
                            w.width == 32 ||
                            w.height == 20 ||
                            w.height == 40),
                  ),
                )
                .evaluate()
                .map((e) => find.byWidget(e.widget)),
          );
          final rects = targets.map(tester.getRect).toList();
          expect(rects, expected['$scale ${direction.name} $i']);
        }
      });
    }
  }
}
