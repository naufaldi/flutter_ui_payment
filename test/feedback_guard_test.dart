import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'first_line_test.dart' show host;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('feedback geometry at $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(
                tone: StatusTone.warning,
                label: 'Pending',
                icon: Icons.schedule,
              ),
              NoticeBanner(
                tone: StatusTone.warning,
                title: 'Total changed',
                message: 'From Rp102.500 to Rp103.500.',
              ),
            ],
          ),
          scale,
        ),
      );
      expect(
        tester.getRect(find.byType(StatusBadge)),
        scale == 1
            ? const Rect.fromLTRB(0, 0, 118, 24)
            : const Rect.fromLTRB(0, 0, 202, 40),
      );
      expect(
        tester.getTopLeft(find.text('Total changed')).dx,
        scale == 1 ? 40 : 52,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
