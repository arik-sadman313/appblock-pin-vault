import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/state/app_state_provider.dart';
import 'package:appblock_pin_vault/core/security/native_security_service.dart';
import 'package:appblock_pin_vault/core/security/pin_generator.dart';

class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key});

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen> with WidgetsBindingObserver {
  bool _revealed = false;
  String? _pin;
  bool _isLoading = false;
  Timer? _clipboardClearTimer;
  DateTime? _clipboardExpireTime;
  String? _lastCopiedPin;

  // Rotation State
  bool _isRotating = false;
  String? _newPin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeSecurityService.setSecureMode(true);
  }

  @override
  void dispose() {
    NativeSecurityService.setSecureMode(false);
    _clearClipboardIfSensitive();
    WidgetsBinding.instance.removeObserver(this);
    _clipboardClearTimer?.cancel();
    super.dispose();
  }

  Future<void> _clearClipboardIfSensitive() async {
    if (_lastCopiedPin != null) {
      final currentData = await Clipboard.getData(Clipboard.kTextPlain);
      if (currentData?.text == _lastCopiedPin) {
        Clipboard.setData(const ClipboardData(text: ''));
      }
      _lastCopiedPin = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_clipboardExpireTime != null && DateTime.now().isAfter(_clipboardExpireTime!)) {
        _clearClipboardIfSensitive();
      }
    }
  }

  Future<void> _revealPin() async {
    setState(() {
      _isLoading = true;
    });

    final pin = await NativeSecurityService.decryptPin();
    
    if (!mounted) return;

    if (pin != null) {
      setState(() {
        _pin = pin;
        _revealed = true;
        _isLoading = false;
      });
      ref.read(appStateProvider.notifier).revealPin(); // Update state to pinRevealed
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decrypt PIN. Data may be corrupted.')),
      );
    }
  }

  void _copyPin(String pinToCopy) {
    Clipboard.setData(ClipboardData(text: pinToCopy));
    _lastCopiedPin = pinToCopy;
    _clipboardExpireTime = DateTime.now().add(const Duration(seconds: 60));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN copied. Clipboard will clear in 60s.')),
    );

    // Auto-clear clipboard for security
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 60), () {
      _clearClipboardIfSensitive();
    });
  }

  void _done() {
    // Return to locked state
    ref.read(appStateProvider.notifier).resetToLocked();
  }

  void _startRotation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROTATE APPBLOCK PIN?'),
        content: const Text(
          'Generate a new PIN and replace the current vault PIN after you confirm that AppBlock has been updated.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isRotating = true;
                _newPin = PinGenerator.generateSecurePin();
              });
            },
            child: const Text('Generate New PIN'),
          ),
        ],
      ),
    );
  }

  void _confirmRotation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CONFIRM NEW PIN'),
        content: const Text('Make sure the new PIN works before replacing the stored PIN.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (_newPin == null) return;
              
              setState(() {
                _isLoading = true;
              });

              // Atomically encrypt and replace the stored PIN
              final success = await NativeSecurityService.encryptAndStorePin(_newPin!);
              
              if (!context.mounted) return;

              if (success) {
                // Clear plaintext references
                _pin = null;
                _newPin = null;
                
                // Return the vault to LOCKED
                ref.read(appStateProvider.notifier).resetToLocked();
              } else {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to securely store the new PIN. Old PIN remains intact.')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _cancelRotation() {
    setState(() {
      _isRotating = false;
      _newPin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRotating && _newPin != null) {
      return _buildRotationView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FINAL CONFIRMATION'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_revealed) ...[
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
                const SizedBox(height: 24),
                const Text(
                  'The AppBlock PIN is about to be revealed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This action is intentionally difficult to undo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _revealPin,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.visibility),
                  label: const Text('Reveal PIN'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ] else ...[
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
                    _pin ?? 'ERROR',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Warning: Copied PINs may be accessible to other apps on some Android versions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.amber),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyPin(_pin!),
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
                        onPressed: _done,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _startRotation,
                  child: const Text('Rotate AppBlock PIN'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRotationView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW PIN GENERATED'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NEW APPBLOCK PIN',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey),
                ),
                child: Text(
                  _newPin!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter this PIN into AppBlock before continuing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyPin(_newPin!),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy PIN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isLoading ? null : _confirmRotation,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("I've Updated AppBlock"),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _cancelRotation,
                child: const Text('Cancel Rotation', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
