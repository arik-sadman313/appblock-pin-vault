import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';
import 'package:appblock_pin_vault/core/state/settings_provider.dart';
import 'package:appblock_pin_vault/features/settings/settings_screen.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryDelay = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('APPBLOCK PIN VAULT'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'Status:\n🔒 PIN LOCKED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your AppBlock PIN is securely stored.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Recovery delay:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recoveryDelay.inHours} hours',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('RECOVER APPBLOCK PIN?'),
                      content: Text(
                        'The PIN will not be immediately available.\n\n'
                        'Recovery delay: ${recoveryDelay.inHours} hours\n\n'
                        'Once recovery begins, the waiting period cannot be shortened.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ref.read(appStateProvider.notifier).startRecovery(recoveryDelay);
                          },
                          child: const Text('Start Recovery'),
                        ),
                      ],
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Request PIN Recovery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
