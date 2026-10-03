import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';

class TimeAnomalyScreen extends ConsumerWidget {
  const TimeAnomalyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SECURITY WARNING'),
        centerTitle: true,
        backgroundColor: Colors.red.shade900,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning, size: 80, color: Colors.redAccent),
              const SizedBox(height: 32),
              const Text(
                'CLOCK MANIPULATION DETECTED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The device system time appears to have been moved backwards significantly. '
                'To prevent tampering, the vault recovery process has been suspended.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              const Text(
                'Please restore your device time to automatic (network provided) time. '
                'You may need to cancel and restart the recovery request.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () {
                  // Allow canceling the suspended recovery
                  ref.read(appStateProvider.notifier).cancelRecovery();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Recovery Request'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
