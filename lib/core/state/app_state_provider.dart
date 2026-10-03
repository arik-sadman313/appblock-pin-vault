import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appblock_pin_vault/core/security/native_security_service.dart';
import 'app_lock_state.dart';
import 'recovery_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

final recoveryRepositoryProvider = Provider<RecoveryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecoveryRepository(prefs);
});

final appStateProvider = NotifierProvider<AppStateNotifier, AppLockState>(AppStateNotifier.new);

class AppStateNotifier extends Notifier<AppLockState> {
  static const String _isSetupKey = 'is_setup_complete';

  @override
  AppLockState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isSetup = prefs.getBool(_isSetupKey) ?? false;
    if (!isSetup) {
      return AppLockState.setupRequired;
    }

    final repo = ref.watch(recoveryRepositoryProvider);
    final savedState = repo.getSavedState();
    if (savedState == AppLockState.setupRequired) {
      repo.saveState(AppLockState.locked);
      return AppLockState.locked;
    }
    
    // Anti-tampering check
    final now = DateTime.now();
    final lastObserved = repo.getLastObservedTime();
    if (lastObserved != null && now.isBefore(lastObserved.subtract(const Duration(minutes: 5)))) {
      // Clock moved backwards significantly
      return AppLockState.timeAnomalyDetected;
    }
    repo.saveLastObservedTime(now);

    // Check deadline
    if (savedState == AppLockState.recoveryPending) {
      final availableAt = repo.getAvailableAt();
      if (availableAt != null && now.isAfter(availableAt)) {
        repo.saveState(AppLockState.challengeReady);
        return AppLockState.challengeReady;
      }
    }
    return savedState;
  }
  
  Future<void> verifyRecoveryState() async {
    final now = DateTime.now();
    final repo = ref.read(recoveryRepositoryProvider);
    
    final lastObserved = repo.getLastObservedTime();
    if (lastObserved != null && now.isBefore(lastObserved.subtract(const Duration(minutes: 5)))) {
      state = AppLockState.timeAnomalyDetected;
      repo.saveState(state);
      return;
    }
    repo.saveLastObservedTime(now);

    if (state == AppLockState.recoveryPending) {
      final availableAt = repo.getAvailableAt();
      final startedAt = repo.getStartedAt();
      
      if (availableAt != null && startedAt != null) {
        final elapsedStart = repo.getElapsedRealtimeStart();
        if (elapsedStart != null) {
          final currentElapsed = await NativeSecurityService.getElapsedRealtime();
          if (currentElapsed != null && currentElapsed >= elapsedStart) {
            final elapsedDuration = Duration(milliseconds: currentElapsed - elapsedStart);
            final wallDuration = now.difference(startedAt);
            
            if (wallDuration > elapsedDuration + const Duration(minutes: 5) || 
                wallDuration < elapsedDuration - const Duration(minutes: 5)) {
              state = AppLockState.timeAnomalyDetected;
              repo.saveState(state);
              return;
            }
          }
        }

        if (now.isAfter(availableAt)) {
          state = AppLockState.challengeReady;
          repo.saveState(state);
        }
      }
    }
  }

  Future<void> completeSetup(String pin) async {
    final success = await NativeSecurityService.encryptAndStorePin(pin);
    if (success) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_isSetupKey, true);
      state = AppLockState.locked;
      await ref.read(recoveryRepositoryProvider).saveState(state);
    } else {
      throw Exception('Failed to securely store the PIN');
    }
  }

  Future<void> startRecovery(Duration delay) async {
    final now = DateTime.now();
    final availableAt = now.add(delay);
    final repo = ref.read(recoveryRepositoryProvider);

    await repo.saveStartedAt(now);
    await repo.saveAvailableAt(availableAt);
    
    final elapsed = await NativeSecurityService.getElapsedRealtime();
    if (elapsed != null) {
      await repo.saveElapsedRealtimeStart(elapsed);
    }
    
    state = AppLockState.recoveryPending;
    await repo.saveState(state);
  }

  Future<void> cancelRecovery() async {
    final repo = ref.read(recoveryRepositoryProvider);
    await repo.clearRecovery();
    state = AppLockState.locked;
    await repo.saveState(state);
  }

  Future<void> completeChallenge() async {
    if (state == AppLockState.challengeReady) {
      state = AppLockState.revealReady;
      final repo = ref.read(recoveryRepositoryProvider);
      await repo.saveState(state);
    }
  }

  Future<void> revealPin() async {
    if (state == AppLockState.revealReady) {
      state = AppLockState.pinRevealed;
      final repo = ref.read(recoveryRepositoryProvider);
      await repo.saveState(state);
    }
  }

  Future<void> resetToLocked() async {
    final repo = ref.read(recoveryRepositoryProvider);
    await repo.clearRecovery();
    state = AppLockState.locked;
    await repo.saveState(state);
  }
}
