import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

const oldIcons = {
  StatusTone.success: Icons.check_circle_outline,
  StatusTone.warning: Icons.warning_amber_rounded,
  StatusTone.danger: Icons.error_outline,
  StatusTone.info: Icons.info_outline,
  StatusTone.neutral: Icons.info_outline,
};
Widget host(Widget child, double scale) => MaterialApp(
  localizationsDelegates: const [PaymentLocalizations.delegate],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('first-line boxes retain geometry at $scale', (tester) async {
      final line = scale == 1 ? 20.0 : 40.0;
      final cases = <(Widget, IconData)>[
        (
          ActionTile(
            title: 'Title',
            subtitle: 'Subtitle',
            icon: Icons.receipt_long_outlined,
            onTap: () {},
          ),
          Icons.receipt_long_outlined,
        ),
        (
          const StateMessage(icon: Icons.search_off, title: 'Title'),
          Icons.search_off,
        ),
        (
          const NoticeBanner(tone: StatusTone.warning, title: 'Title'),
          Icons.warning_amber_rounded,
        ),
        (
          const StatusHeader(
            tone: StatusTone.info,
            icon: Icons.schedule,
            title: 'Title',
          ),
          Icons.schedule,
        ),
        (
          NavSidebar(
            sections: const [
              PaymentNavSection(
                items: [
                  PaymentNavItem(
                    id: 'a',
                    label: 'Title',
                    icon: Icons.home_outlined,
                  ),
                ],
              ),
            ],
            selectedId: null,
            onSelected: (_) {},
          ),
          Icons.home_outlined,
        ),
        (
          VerificationIntro(
            requirements: const [
              DataRequirement(title: 'ID card', purpose: 'To match your name'),
            ],
            onContinue: () {},
          ),
          Icons.check_circle_outline,
        ),
      ];
      for (final (widget, icon) in cases) {
        await tester.pumpWidget(host(widget, scale));
        final box = find
            .ancestor(of: find.byIcon(icon), matching: find.byType(SizedBox))
            .first;
        expect(
          tester.getSize(box).height,
          line,
          reason: widget.runtimeType.toString(),
        );
        if (widget is ActionTile) {
          expect(
            tester
                .getSize(
                  find
                      .ancestor(
                        of: find.byIcon(Icons.chevron_right),
                        matching: find.byType(SizedBox),
                      )
                      .first,
                )
                .height,
            line,
          );
        }
      }
      await tester.pumpWidget(
        host(
          PaymentCheckbox(value: true, onChanged: (_) {}, label: 'Agree'),
          scale,
        ),
      );
      expect(
        find.ancestor(
          of: find.byType(Checkbox),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == line,
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(
        host(const MerchantHeader(name: 'Toko Contoh'), scale),
      );
      expect(
        tester.getTopLeft(find.byType(ClipRRect)).dy -
            tester.getTopLeft(find.byType(MerchantHeader)).dy,
        scale == 1 ? 0 : 4,
      );
    });
  }
  for (final entry in oldIcons.entries) {
    testWidgets('banner and toast preserve ${entry.key} glyph', (tester) async {
      await tester.pumpWidget(
        host(NoticeBanner(tone: entry.key, title: 'Notice'), 1),
      );
      expect(find.byIcon(entry.value), findsOneWidget);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPaymentSnackBar(
                context,
                message: 'Saved',
                tone: entry.key,
              ),
              child: const Text('Show'),
            ),
          ),
          1,
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.byIcon(entry.value), findsOneWidget);
    });
  }
}
