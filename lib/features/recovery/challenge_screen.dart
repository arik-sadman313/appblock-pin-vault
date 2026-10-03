import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  String? _selectedReason;
  bool _acknowledged = false;

  final List<String> _reasons = [
    'I genuinely need access',
    'I want to disable AppBlock',
    'I need to reconfigure AppBlock',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RECOVERY READY'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'The waiting period has completed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text(
                'Why are you retrieving the PIN?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ..._reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                );
              }),
              const SizedBox(height: 32),
              if (_selectedReason != null) ...[
                const Text(
                  'I understand that retrieving this PIN gives me the ability to bypass my AppBlock restrictions.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('I understand'),
                  value: _acknowledged,
                  onChanged: (value) {
                    setState(() {
                      _acknowledged = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _acknowledged
                      ? () {
                          ref.read(appStateProvider.notifier).completeChallenge();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
