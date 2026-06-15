import 'package:flutter_test/flutter_test.dart';
import 'package:desa_wisata/utils/price_helper.dart';

void main() {
  group('PriceHelper.toNumber', () {
    test('parses formatted Rupiah string', () {
      expect(PriceHelper.toNumber('Rp 450.000'), 450000.0);
    });

    test('parses string with dots and commas', () {
      expect(PriceHelper.toNumber('Rp 1.250.000'), 1250000.0);
    });

    test('parses plain number string', () {
      expect(PriceHelper.toNumber('100000'), 100000.0);
    });

    test('returns 0 for null', () {
      expect(PriceHelper.toNumber(null), 0.0);
    });

    test('returns 0 for empty string', () {
      expect(PriceHelper.toNumber(''), 0.0);
      expect(PriceHelper.toNumber('   '), 0.0);
    });

    test('handles num types directly', () {
      expect(PriceHelper.toNumber(450000), 450000.0);
      expect(PriceHelper.toNumber(450000.5), 450000.5);
    });

    test('returns 0 for non-parseable string', () {
      expect(PriceHelper.toNumber('gratis'), 0.0);
    });

    test('handles string with only Rp symbol', () {
      expect(PriceHelper.toNumber('Rp '), 0.0);
    });
  });

  group('PriceHelper.toInt', () {
    test('rounds correctly', () {
      expect(PriceHelper.toInt('Rp 450.500'), 450500);
      expect(PriceHelper.toInt(123.7), 124);
    });

    test('returns 0 for null', () {
      expect(PriceHelper.toInt(null), 0);
    });
  });

  group('PriceHelper.format', () {
    test('formats number to Indonesian currency', () {
      final formatted = PriceHelper.format(450000);
      expect(formatted, contains('450.000'));
    });

    test('formats zero', () {
      final formatted = PriceHelper.format(0);
      expect(formatted, contains('0'));
    });

    test('formats large numbers', () {
      final formatted = PriceHelper.format(1500000);
      expect(formatted, contains('1.500.000'));
    });
  });

  group('PriceHelper.formatAny', () {
    test('formats string price', () {
      final formatted = PriceHelper.formatAny('Rp 450.000');
      expect(formatted, contains('450.000'));
    });

    test('formats numeric price', () {
      final formatted = PriceHelper.formatAny(300000);
      expect(formatted, contains('300.000'));
    });

    test('formats null as zero', () {
      final formatted = PriceHelper.formatAny(null);
      expect(formatted, contains('0'));
    });
  });
}
