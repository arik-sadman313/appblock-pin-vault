import 'package:flutter/services.dart';

class NativeSecurityService {
  static const MethodChannel _channel = MethodChannel('com.example.appblock_pin_vault/security');

  /// Encrypts the provided [pin] using Android Keystore and stores it.
  /// Returns true if successful.
  static Future<bool> encryptAndStorePin(String pin) async {
    try {
      final bool result = await _channel.invokeMethod('encryptAndStorePin', {'pin': pin});
      return result;
    } on PlatformException {
      return false;
    }
  }

  /// Decrypts the stored PIN using Android Keystore.
  /// Returns the plaintext PIN, or null if decryption fails or no PIN exists.
  static Future<String?> decryptPin() async {
    try {
      final String? pin = await _channel.invokeMethod('decryptPin');
      return pin;
    } on PlatformException {
      return null;
    }
  }

  /// Deletes the stored PIN and its associated Keystore key.
  /// Returns true if successful.
  static Future<bool> deletePin() async {
    try {
      final bool result = await _channel.invokeMethod('deletePin');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> setSecureMode(bool secure) async {
    try {
      await _channel.invokeMethod('setSecureMode', {'secure': secure});
    } on PlatformException {
      // Ignore in tests or if unsupported
    }
  }

  static Future<int?> getElapsedRealtime() async {
    try {
      return await _channel.invokeMethod<int>('getElapsedRealtime');
    } on PlatformException {
      return null;
    }
  }
}
