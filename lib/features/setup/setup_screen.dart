import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/security/pin_generator.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';
import 'package:flutter/services.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  String? _generatedPin;
  bool _pinConfirmed = false;
  bool _isSaving = false;

  void _generatePin() {
    setState(() {
      _generatedPin = PinGenerator.generateSecurePin();
      _pinConfirmed = false;
    });
  }

  void _copyPin() {
    if (_generatedPin != null) {
      Clipboard.setData(ClipboardData(text: _generatedPin!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN copied to clipboard')),
      );
    }
  }

  Future<void> _confirmAndLock() async {
    if (_generatedPin == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(appStateProvider.notifier).completeSetup(_generatedPin!);
      // State will change to 'locked' automatically, so the main router will navigate away
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PIN: $e')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    } finally {
      // Clear the PIN from memory
      _generatedPin = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APPBLOCK PIN VAULT'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_generatedPin == null) ...[
                const Icon(Icons.security, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 24),
                const Text(
                  'Generate a secure AppBlock PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _generatePin,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Generate PIN'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ] else if (!_pinConfirmed) ...[
                const Text(
                  'APPBLOCK PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _generatedPin!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyPin,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy PIN'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _pinConfirmed = true;
                          });
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
                const SizedBox(height: 24),
                const Text(
                  'Confirm that the PIN has been successfully configured in AppBlock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'If you continue without configuring AppBlock first, the vault may contain a PIN that you cannot conveniently recover.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _confirmAndLock,
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.lock),
                  label: const Text('PIN IS CONFIGURED'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isSaving ? null : () {
                    setState(() {
                      _pinConfirmed = false;
                    });
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
