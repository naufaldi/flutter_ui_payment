import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

void main() {
  const id = MoneyFormat('id');
  const en = MoneyFormat('en');

  group('Money', () {
    test('adds integer minor units without floating point drift', () {
      expect(
        const Money.idr(100000) + const Money.idr(2500),
        const Money.idr(102500),
      );
      expect(
        const Money(10, 'USD') + const Money(20, 'USD'),
        const Money(30, 'USD'),
      );
    });

    test('refuses to mix currencies', () {
      expect(
        () => const Money.idr(1) + const Money(1, 'USD'),
        throwsArgumentError,
      );
    });
  });

  group('MoneyFormat.format', () {
    test('uses locale separators and currency digits', () {
      expect(id.format(const Money.idr(102500)), 'Rp102.500');
      expect(en.format(const Money.idr(102500)), 'Rp102,500');
      expect(id.format(const Money.idr(1250000000)), 'Rp1.250.000.000');
      expect(en.format(const Money(1999, 'USD')), r'$19.99');
      expect(id.format(const Money(1999, 'USD')), r'$19,99');
      expect(id.format(const Money.idr(-2500)), '−Rp2.500');
      expect(id.format(const Money.idr(0)), 'Rp0');
    });

    test('spoken form is digits plus currency code', () {
      expect(id.spoken(const Money.idr(102500)), '102500 IDR');
    });
  });

  group('MoneyFormat.parse', () {
    AmountParseResult p(MoneyFormat f, String s) => f.parse(s, 'IDR');

    test('accepts plain, grouped and pasted values', () {
      expect(p(id, '150000').money, const Money.idr(150000));
      expect(p(id, '150.000').money, const Money.idr(150000));
      expect(p(id, 'Rp 150.000').money, const Money.idr(150000));
      expect(p(id, ' IDR 150.000 ').money, const Money.idr(150000));
      expect(p(en, '150,000').money, const Money.idr(150000));
    });

    test('rejects ambiguous separators instead of guessing', () {
      expect(p(id, '150,000').issue, AmountIssue.ambiguous);
      expect(p(en, '150.000').issue, AmountIssue.ambiguous);
      expect(p(id, '15.00').issue, AmountIssue.ambiguous);
      expect(p(id, '1.5000').issue, AmountIssue.ambiguous);
    });

    test('reports empty, invalid and negative input', () {
      expect(p(id, '').issue, AmountIssue.empty);
      expect(p(id, 'Rp').issue, AmountIssue.empty);
      expect(p(id, '12a').issue, AmountIssue.invalidFormat);
      expect(p(id, '-5').issue, AmountIssue.negative);
    });

    test('parses decimals only for currencies that have them', () {
      expect(en.parse('19.99', 'USD').money, const Money(1999, 'USD'));
      expect(id.parse('19,9', 'USD').money, const Money(1990, 'USD'));
      expect(en.parse('19.999', 'USD').issue, AmountIssue.ambiguous);
    });

    test('applies host limits after parsing', () {
      const min = Money.idr(10000);
      const max = Money.idr(2000000);
      AmountParseResult limited(String s) =>
          p(id, s).withinLimits(minimum: min, maximum: max);
      expect(limited('0').issue, AmountIssue.zero);
      expect(limited('5000').issue, AmountIssue.belowMinimum);
      expect(limited('5000000').issue, AmountIssue.aboveMaximum);
      expect(limited('10.000').isValid, isTrue);
      expect(limited('-0').issue, AmountIssue.zero);
    });
  });
}
