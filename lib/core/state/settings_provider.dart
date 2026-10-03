import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, Duration>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Duration> {
  static const String _delayKey = 'recovery_delay_hours';

  @override
  Duration build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final hours = prefs.getInt(_delayKey) ?? 24;
    return Duration(hours: hours);
  }

  Future<void> setRecoveryDelay(Duration delay) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_delayKey, delay.inHours);
    state = delay;
  }
}
