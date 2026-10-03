import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';
import 'package:appblock_pin_vault/core/state/app_lock_state.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    
    // Mock the native MethodChannel for tests
    const channel = MethodChannel('com.example.appblock_pin_vault/security');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'encryptAndStorePin') {
          return true;
        }
        if (methodCall.method == 'decryptPin') {
          return '12345678';
        }
        if (methodCall.method == 'getElapsedRealtime') {
          return 10000;
        }
        if (methodCall.method == 'setSecureMode') {
          return true;
        }
        return null;
      },
    );
  });

  test('AppStateNotifier completes setup and transitions to locked', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Initial state
    expect(container.read(appStateProvider), AppLockState.setupRequired);

    // Complete setup
    await container.read(appStateProvider.notifier).completeSetup('12345678');
    expect(container.read(appStateProvider), AppLockState.locked);
  });

  test('AppStateNotifier recovery state machine', () async {
    final prefs = await SharedPreferences.getInstance();
    // Simulate setup already complete
    prefs.setBool('is_setup_complete', true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Should initialize to locked
    expect(container.read(appStateProvider), AppLockState.locked);

    // Start recovery
    await container.read(appStateProvider.notifier).startRecovery(const Duration(milliseconds: 100));
    expect(container.read(appStateProvider), AppLockState.recoveryPending);

    // Verify state before deadline
    await container.read(appStateProvider.notifier).verifyRecoveryState();
    expect(container.read(appStateProvider), AppLockState.recoveryPending);

    // Wait for deadline to pass
    await Future.delayed(const Duration(milliseconds: 150));
    await container.read(appStateProvider.notifier).verifyRecoveryState();
    
    // Should transition to challengeReady
    expect(container.read(appStateProvider), AppLockState.challengeReady);

    // Complete challenge
    await container.read(appStateProvider.notifier).completeChallenge();
    expect(container.read(appStateProvider), AppLockState.revealReady);

    // Reveal PIN
    await container.read(appStateProvider.notifier).revealPin();
    expect(container.read(appStateProvider), AppLockState.pinRevealed);

    // Reset to locked
    await container.read(appStateProvider.notifier).resetToLocked();
    expect(container.read(appStateProvider), AppLockState.locked);
  });

  test('Cancellation resets state', () async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('is_setup_complete', true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appStateProvider.notifier).startRecovery(const Duration(hours: 1));
    expect(container.read(appStateProvider), AppLockState.recoveryPending);

    await container.read(appStateProvider.notifier).cancelRecovery();
    expect(container.read(appStateProvider), AppLockState.locked);
  });
}
