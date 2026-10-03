import 'package:shared_preferences/shared_preferences.dart';
import 'app_lock_state.dart';

class RecoveryRepository {
  final SharedPreferences prefs;
  RecoveryRepository(this.prefs);

  static const String _stateKey = 'recovery_state';
  static const String _startedAtKey = 'recovery_started_at';
  static const String _availableAtKey = 'recovery_available_at';
  static const String _lastObservedKey = 'last_observed_time';

  AppLockState getSavedState() {
    final stateStr = prefs.getString(_stateKey);
    if (stateStr != null) {
      for (var value in AppLockState.values) {
        if (value.name == stateStr) return value;
      }
    }
    return AppLockState.setupRequired;
  }

  Future<void> saveState(AppLockState state) async {
    await prefs.setString(_stateKey, state.name);
  }

  DateTime? getStartedAt() {
    final millis = prefs.getInt(_startedAtKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> saveStartedAt(DateTime time) async {
    await prefs.setInt(_startedAtKey, time.millisecondsSinceEpoch);
  }

  DateTime? getAvailableAt() {
    final millis = prefs.getInt(_availableAtKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> saveAvailableAt(DateTime time) async {
    await prefs.setInt(_availableAtKey, time.millisecondsSinceEpoch);
  }

  DateTime? getLastObservedTime() {
    final millis = prefs.getInt(_lastObservedKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> saveLastObservedTime(DateTime time) async {
    await prefs.setInt(_lastObservedKey, time.millisecondsSinceEpoch);
  }

  int? getElapsedRealtimeStart() {
    return prefs.getInt('elapsed_realtime_start');
  }

  Future<void> saveElapsedRealtimeStart(int elapsed) async {
    await prefs.setInt('elapsed_realtime_start', elapsed);
  }

  Future<void> clearRecovery() async {
    await prefs.remove(_startedAtKey);
    await prefs.remove(_availableAtKey);
    await prefs.remove(_lastObservedKey);
    await prefs.remove('elapsed_realtime_start');
    // State is typically moved back to locked by the caller
  }
}
