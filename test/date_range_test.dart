import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  test('localized compact ranges and value equality', () {
    final en = PaymentLocalizations('en'), id = PaymentLocalizations('id');
    expect(
      en.formatDateRange(DateTime(2026, 10), DateTime(2026, 10, 31)),
      '1–31 Oct 2026',
    );
    expect(
      id.formatDateRange(DateTime(2026, 10), DateTime(2026, 10, 31)),
      '1–31 Okt 2026',
    );
    expect(
      en.formatDateRange(DateTime(2026, 9, 28), DateTime(2026, 10, 3)),
      '28 Sep – 3 Oct 2026',
    );
    expect(
      en.formatDateRange(DateTime(2025, 12, 30), DateTime(2026, 1, 2)),
      '30 Dec 2025 – 2 Jan 2026',
    );
    final p = PaymentDatePreset(
      label: 'This month',
      start: DateTime(2026, 10),
      end: DateTime(2026, 10, 31),
    );
    expect(PaymentDateRange.fromPreset(p), PaymentDateRange.fromPreset(p));
  });
  testWidgets('preset selection and clearing report host changes', (
    tester,
  ) async {
    PaymentDateRange? result;
    final p = PaymentDatePreset(
      label: 'Last 30 days',
      start: DateTime(2026, 10, 2),
      end: DateTime(2026, 10, 31),
    );
    await tester.pumpWidget(
      host(
        PaymentDateRangePicker(
          label: 'Range',
          value: null,
          onChanged: (v) => result = v,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          presets: [p],
        ),
        1,
      ),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(result, PaymentDateRange.fromPreset(p));
  });
}
