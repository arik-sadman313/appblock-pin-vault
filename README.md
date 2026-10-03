# AppBlock PIN Vault

A local Android vault designed to securely store an AppBlock PIN and make retrieving it deliberately difficult.

The application generates a cryptographically random 8-digit PIN, encrypts it using an Android Keystore-backed key, stores only the encrypted form locally, and places PIN retrieval behind a configurable waiting period and confirmation process.

The application is completely offline and does not require an account, server, cloud service, or another person to control recovery.

---

# Purpose

AppBlock PIN Vault was created to solve a simple problem:

**How can someone use AppBlock to enforce their own app and website restrictions without keeping the AppBlock PIN readily accessible to themselves?**

AppBlock uses a PIN to protect its blocking configuration. If the user knows that PIN, they can disable or modify their restrictions whenever they feel like bypassing them.

This application creates a separate vault for that PIN.

Instead of choosing and memorizing an easy PIN, the user can:

1. Generate a random 8-digit PIN.
2. Configure AppBlock with that PIN.
3. Store the PIN securely inside the vault.
4. Lock the vault.
5. Continue using AppBlock without knowing the PIN.
6. If access to the PIN is genuinely necessary, initiate recovery.
7. Wait through a deliberate recovery period.
8. Complete the recovery confirmation.
9. Explicitly reveal the PIN.
10. Optionally generate and configure a new PIN afterward.

The purpose is **not to make the Android device impossible for its owner to bypass**. That is not a realistic security boundary for an application running on a device the owner controls.

The purpose is to introduce a deliberate separation between:

```text
Wanting to bypass a restriction
             ↓
      Immediate access
             ✗
             │
             ▼
       Recovery request
             ↓
        Waiting period
             ↓
      Deliberate confirmation
             ↓
        Explicit reveal
```

This makes the decision to retrieve the AppBlock PIN **intentional rather than instantaneous**.

The application is therefore best understood as a **self-control utility built around secure credential storage and delayed recovery**, rather than as a replacement for AppBlock itself.

---

# Core Concept

The basic workflow is:

```text
Generate random PIN
        ↓
Configure AppBlock
        ↓
Encrypt PIN
        ↓
Lock vault
        ↓
PIN becomes inaccessible normally
        ↓
Request recovery
        ↓
Wait for configured delay
        ↓
Complete confirmation challenge
        ↓
Explicitly reveal PIN
        ↓
Optionally rotate PIN
```

The system is intentionally designed around **delay and friction**, rather than claiming that the Android device owner can be permanently prevented from bypassing their own device.

---

# How It Works

## 1. PIN Generation

During initial setup, the application generates an 8-digit numeric PIN using a cryptographically secure random number generator.

Example:

```text
73918426
```

The PIN may contain leading zeros.

The user enters this PIN into AppBlock.

The vault then securely stores the PIN.

---

## 2. Encryption

The plaintext PIN is encrypted using:

```text
Android Keystore
       ↓
AES-GCM encryption
       ↓
Encrypted PIN + IV
       ↓
Local storage
```

The encryption key is generated and protected by Android Keystore.

The key itself is not stored in SharedPreferences.

The plaintext PIN is not intentionally stored in persistent application storage.

---

## 3. Normal Locked State

After setup, the vault displays only:

```text
🔒 PIN LOCKED
```

The PIN itself is not shown.

The user cannot simply open the application and press "Show PIN."

Instead, PIN retrieval requires the recovery process.

---

## 4. Recovery Request

When the user requests the PIN, the application does not immediately decrypt it.

Instead:

```text
Request Recovery
        ↓
Confirmation
        ↓
Recovery Timer
```

The recovery delay can be configured.

Available options include:

- 1 hour
- 6 hours
- 12 hours
- 24 hours
- 48 hours
- 72 hours
- 7 days

The default is 24 hours.

---

## 5. Persistent Recovery Timer

The recovery deadline is stored as an absolute timestamp.

Conceptually:

```text
recoveryStartedAt
recoveryAvailableAt
```

The countdown shown in the UI is only a visual representation.

The application determines whether recovery is available by comparing the current time with the persisted deadline.

Therefore:

```text
Close application
        ↓
Reopen application
        ↓
Recovery continues
```

and:

```text
Reboot phone
        ↓
Open vault
        ↓
Recovery state remains
```

The recovery timer is not reset simply because the application was closed.

---

## 6. Recovery Challenge

When the waiting period expires, the PIN is still not automatically displayed.

The user must explicitly acknowledge that retrieving the PIN will provide access to the AppBlock credential.

The challenge is intentionally designed as **behavioral friction**.

It should not be interpreted as a cryptographic security mechanism.

---

## 7. PIN Reveal

Only after the recovery process is completed can the user explicitly choose:

```text
Reveal PIN
```

At this point:

```text
Encrypted PIN
      ↓
Android Keystore
      ↓
AES-GCM decryption
      ↓
Plaintext PIN
      ↓
Temporary display
```

The PIN is not automatically copied to the clipboard.

The reveal screen uses Android's secure-window mechanism to prevent sensitive content from appearing in screenshots and recent-task previews.

---

## 8. Clipboard Protection

The user must explicitly choose:

```text
Copy PIN
```

if they want the PIN copied.

The application attempts to clear the clipboard after the configured timeout and also performs cleanup when leaving the sensitive reveal state.

Clipboard protection is not considered absolute because Android clipboard behavior depends on the operating-system version and system environment.

---

## 9. PIN Rotation

After recovering the PIN, the user can generate a new one.

The important part is that the old PIN is not immediately replaced.

The process is:

```text
Generate new PIN
        ↓
User updates AppBlock
        ↓
User confirms
        ↓
New PIN encrypted
        ↓
Stored PIN replaced
        ↓
Old PIN discarded
        ↓
Vault locked again
```

If the application fails before confirmation, the old PIN remains intact.

This prevents accidental loss of the currently working AppBlock credential.

---

## 10. Security Architecture

```text
┌──────────────────────────────┐
│          Flutter UI          │
├──────────────────────────────┤
│        Riverpod State        │
├──────────────────────────────┤
│ Recovery / Vault Services    │
├──────────────────────────────┤
│ Flutter ↔ Kotlin Channel     │
├──────────────────────────────┤
│ Native Android Security      │
│                              │
│      Android Keystore        │
│             ↓                │
│          AES-GCM              │
├──────────────────────────────┤
│ Local encrypted storage      │
└──────────────────────────────┘
```

---

# Technology Stack

- Flutter
- Dart
- Riverpod
- Kotlin
- Android Keystore
- AES-GCM
- SharedPreferences for non-secret/local metadata and encrypted ciphertext
- Material 3

No backend is required.

No internet connection is required for core functionality.

---

# Privacy

The application is intentionally local.

It does not require:

- account creation
- email
- phone number
- cloud synchronization
- analytics
- advertisements
- external authentication
- another person to hold a recovery credential

The core application can operate completely offline.

---

# Threat Model

The application is designed primarily against:

- impulsive PIN retrieval
- casual inspection of the vault
- accidental exposure of the PIN
- application restarts resetting recovery
- simple recovery-flow bypasses

It is NOT designed to provide absolute protection against a determined device owner with system-level control.

A sufficiently privileged user may potentially:

- uninstall the application
- clear application data
- modify the Android operating system
- use debugging/root access
- reset the device
- manipulate system-level state

This limitation is inherent to an application running on a device controlled by its owner.

---

# Recovery Philosophy

The vault intentionally combines:

```text
Cryptographic protection
        +
Persistent state
        +
Time delay
        +
Behavioral friction
```

The cryptography protects the stored credential.

The delay and confirmation process make impulsive retrieval inconvenient.

These are separate security mechanisms and should not be confused with one another.

---

# Project Structure

```text
lib/
├── core/
│   ├── security/
│   ├── storage/
│   ├── time/
│   ├── errors/
│   └── constants/
│
├── features/
│   ├── setup/
│   ├── vault/
│   ├── recovery/
│   └── settings/
│
└── shared/
    ├── widgets/
    └── theme/

android/
└── app/
    └── native security implementation
```

---

# Installation

Download the latest APK from the GitHub Releases section.

Install it on an Android device.

During setup:

1. Launch the vault.
2. Generate a PIN.
3. Configure AppBlock with the generated PIN.
4. Confirm the AppBlock configuration.
5. Lock the vault.

Do not delete the vault's application data after setup unless you understand that doing so may make the stored credential unavailable.

---

# Building From Source

Requirements:

- Flutter SDK
- Android SDK
- Java/JDK compatible with the Flutter/Android project

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The generated APK will be located under:

```text
build/app/outputs/flutter-apk/
```

---

# Testing

The project includes automated tests covering:

- PIN generation
- state-machine transitions
- recovery deadlines
- cancellation
- recovery persistence

Run:

```bash
flutter test
```

---

# Release

Current stable release:

**v1.0.0**

The release includes a downloadable Android APK.

---

# Security Documentation

Additional technical information is available in:

- `SECURITY.md`
- `SECURITY_AUDIT.md`
- `FINAL_ACCEPTANCE_REPORT.md`

---

# Disclaimer

This project is a personal self-control/security utility.

It does not guarantee that the owner of an Android device can never bypass the application.

Its purpose is to make access to the stored AppBlock PIN deliberate, inconvenient, and resistant to casual or impulsive retrieval.

---

# License

Currently, this repository does not have an explicit open-source license.
