# AppBlock PIN Vault - Security Architecture

## Philosophy
The AppBlock PIN Vault is designed to provide *behavioral friction* against impulsive access, rather than attempting to provide absolute protection against the device owner. It exists to protect you from yourself by enforcing a mandatory wait time before revealing a 8-digit PIN used for AppBlock.

## Security Model

### Strong protection
- Android Keystore-backed encryption
- AES-GCM encrypted PIN
- plaintext PIN not persistently stored
- persistent recovery workflow
- explicit reveal
- screenshot protection

### Behavioral protection
- recovery delay
- confirmation flow
- PIN rotation

### Limited protection
- clipboard lifetime
- local timestamps
- offline clock manipulation
- application lifecycle

### Outside application control
- rooted/debuggable devices
- OS modification
- device reset
- uninstall
- device-owner-level control

## Limitations
- **Offline local timing cannot provide absolute protection against a device owner who controls system time or the operating system.**
- **Device Owner Autonomy**: This app does not use Device Administrator privileges. The user can technically clear app data or uninstall the application. Doing so will securely destroy the AES key, permanently rendering the AppBlock PIN unrecoverable, which still fulfills the goal of preventing casual bypass.
- **Offline Only**: The app requires no internet access. Clock manipulation checks are strictly relative to local observations, not NTP, to honor the strict offline requirement.
