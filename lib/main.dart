import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/vault/vault_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/recovery/recovery_countdown_screen.dart';
import 'features/recovery/challenge_screen.dart';
import 'features/recovery/reveal_screen.dart';
import 'features/recovery/time_anomaly_screen.dart';
import 'core/state/app_lock_state.dart';
import 'core/state/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AppBlockPinVaultApp(),
    ),
  );
}

class AppBlockPinVaultApp extends ConsumerWidget {
  const AppBlockPinVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return MaterialApp(
      title: 'AppBlock PIN Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
        fontFamily: 'Roboto',
      ),
      home: _getScreenForState(appState),
    );
  }

  Widget _getScreenForState(AppLockState state) {
    switch (state) {
      case AppLockState.setupRequired:
        return const SetupScreen();
      case AppLockState.locked:
        return const VaultScreen();
      case AppLockState.recoveryPending:
        return const RecoveryCountdownScreen();
      case AppLockState.challengeReady:
        return const ChallengeScreen();
      case AppLockState.revealReady:
      case AppLockState.pinRevealed:
        return const RevealScreen();
      case AppLockState.timeAnomalyDetected:
        return const TimeAnomalyScreen();
    }
  }
}
