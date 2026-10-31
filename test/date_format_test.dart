import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

void main() {
  test('calendar dates retain host calendar and locale', () {
    final en = PaymentLocalizations('en');
    final id = PaymentLocalizations('id');
    expect(en.formatDate(DateTime(2026, 10, 30)), '30 Oct 2026');
    expect(id.formatDate(DateTime(2026, 10, 30)), '30 Okt 2026');
    for (final entry in {5: 'Mei', 8: 'Agu', 12: 'Des'}.entries) {
      expect(
        id.formatDate(DateTime(2026, entry.key, 1)),
        '1 ${entry.value} 2026',
      );
    }
    expect(en.formatDate(DateTime.utc(2026, 10, 30, 23, 30)), '30 Oct 2026');
    final timed = DateTime(2026, 10, 30, 14, 5);
    expect(en.formatDateTime(timed), startsWith(en.formatDate(timed)));
    expect(en.dateInputPattern, 'DD/MM/YYYY');
    expect(id.dateInputPattern, 'DD/MM/YYYY');
    for (final pattern in ['MM/DD/YYYY', 'YYYY-MM-DD', 'DD.MM.YYYY']) {
      expect(
        PaymentLocalizations('en', dateInputPattern: pattern).dateInputPattern,
        pattern,
      );
    }
    for (final pattern in ['DD/DD/YYYY', 'DD/MM-YYYY', 'D/M/YYYY']) {
      expect(
        () => PaymentLocalizations('en', dateInputPattern: pattern),
        throwsAssertionError,
      );
    }
  });
}
