import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';

class RecoveryCountdownScreen extends ConsumerStatefulWidget {
  const RecoveryCountdownScreen({super.key});

  @override
  ConsumerState<RecoveryCountdownScreen> createState() => _RecoveryCountdownScreenState();
}

class _RecoveryCountdownScreenState extends ConsumerState<RecoveryCountdownScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Re-build UI to update countdown
        // IMPORTANT: Let the provider check if the deadline actually passed
        ref.read(appStateProvider.notifier).verifyRecoveryState();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(recoveryRepositoryProvider);
    final startedAt = repo.getStartedAt();
    final availableAt = repo.getAvailableAt();
    
    if (startedAt == null || availableAt == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    Duration remaining = availableAt.difference(now);
    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    final String hours = remaining.inHours.toString().padLeft(2, '0');
    final String minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('APPBLOCK PIN RECOVERY'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.timer, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'Recovery is in progress.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'PIN available in:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                '${hours}h ${minutes}m ${seconds}s',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
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
                    Text(
                      'Started:\n${dateFormat.format(startedAt)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Available:\n${dateFormat.format(availableAt)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(appStateProvider.notifier).cancelRecovery();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Recovery'),
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
