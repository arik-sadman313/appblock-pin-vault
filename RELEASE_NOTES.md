# AppBlock PIN Vault v1.0.0

Initial stable release.

## Features

- Cryptographically secure 8-digit AppBlock PIN generation
- Android Keystore-backed AES-GCM encryption
- Offline local storage
- Delayed PIN recovery
- Recovery confirmation flow
- PIN reveal protection
- Screenshot protection with FLAG_SECURE
- Clipboard cleanup
- PIN rotation
- Configurable recovery delay
- Recovery persistence across app restarts
- Clock anomaly detection

## Security model

The application is designed to securely store the AppBlock PIN and introduce deliberate friction before retrieving it.

It is not intended to provide an unbreakable restriction against the owner of the Android device.

## APK

The release includes:

app-release.apk
