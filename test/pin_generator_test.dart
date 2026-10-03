import 'package:flutter_test/flutter_test.dart';
import 'package:appblock_pin_vault/core/security/pin_generator.dart';

void main() {
  group('PinGenerator', () {
    test('generates exactly 8 digits', () {
      final pin = PinGenerator.generateSecurePin();
      expect(pin.length, 8);
    });

    test('generates only numeric characters', () {
      final pin = PinGenerator.generateSecurePin();
      expect(int.tryParse(pin), isNotNull);
      // Ensure all characters are digits
      expect(RegExp(r'^[0-9]{8}$').hasMatch(pin), isTrue);
    });

    test('multiple generations produce different values', () {
      final pin1 = PinGenerator.generateSecurePin();
      final pin2 = PinGenerator.generateSecurePin();
      // While it is theoretically possible to generate the same 8-digit pin sequentially, 
      // the probability is 1 in 100,000,000, so this test should practically never fail.
      expect(pin1, isNot(equals(pin2)));
    });

    test('can generate leading zeros', () {
      // Run enough times to likely generate at least one PIN starting with 0
      // 10% chance per generation, so 100 generations is extremely likely to hit it
      bool foundLeadingZero = false;
      for (var i = 0; i < 200; i++) {
        final pin = PinGenerator.generateSecurePin();
        if (pin.startsWith('0')) {
          foundLeadingZero = true;
          break;
        }
      }
      expect(foundLeadingZero, isTrue);
    });
  });
}
