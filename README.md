# AppBlock PIN Vault

A local Android security vault designed specifically to store an 8-digit PIN for AppBlock. 

## Purpose
The primary purpose of this app is to generate a secure PIN for AppBlock and deliberately lock it away. By enforcing a configurable wait time (from 1 hour up to 7 days), the app prevents casual or impulsive bypassing of your AppBlock restrictions.

## Features
- **Offline First**: Absolutely no network requests, accounts, or cloud synchronization. Your PIN never leaves your device.
- **Android Keystore**: Utilizes the native Android hardware Keystore to securely encrypt the PIN using AES-GCM.
- **Time-Delayed Recovery**: Enforces a strict, persistent waiting period before the PIN can be revealed.
- **Anti-Tampering**: Detects obvious clock manipulation attempts within a single boot session and suspends the recovery process.
- **Secure PIN Rotation**: Allows generating a new PIN and atomically replacing the old one only after you confirm AppBlock has been successfully updated.

## Build Instructions
Requirements: Flutter SDK, Android SDK.

1. Clone or download the repository.
2. Run `flutter pub get` to fetch dependencies.
3. Run tests with `flutter test`.
4. Build the release APK:
```bash
flutter build apk --release
```
The resulting APK can be installed directly on your Android device.

## Recovery Behavior
1. **Request**: Initiating a recovery records an absolute timestamp.
2. **Wait**: The app will count down the configured delay. You can close the app or reboot the device; the delay is tracked persistently.
3. **Challenge**: Once the time expires, you must acknowledge the consequences of revealing the PIN.
4. **Reveal**: The PIN is decrypted and displayed. You can copy it, and the clipboard will automatically clear after 60 seconds.

## Known Limitations
Please see [SECURITY.md](SECURITY.md) for a detailed breakdown of the security model and its inherent limitations regarding local-only time enforcement.
