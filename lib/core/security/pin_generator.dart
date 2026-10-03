import 'dart:math';

class PinGenerator {
  /// Generates a cryptographically secure random 8-digit PIN.
  /// The PIN can start with zero.
  static String generateSecurePin() {
    final secureRandom = Random.secure();
    final buffer = StringBuffer();
    
    // Generate exactly 8 random digits (0-9)
    for (var i = 0; i < 8; i++) {
      buffer.write(secureRandom.nextInt(10));
    }
    
    return buffer.toString();
  }
}
