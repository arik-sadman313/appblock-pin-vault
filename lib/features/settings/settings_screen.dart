import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appblock_pin_vault/core/state/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDelay = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final List<Duration> delays = [
      const Duration(hours: 1),
      const Duration(hours: 6),
      const Duration(hours: 12),
      const Duration(hours: 24),
      const Duration(hours: 48),
      const Duration(hours: 72),
      const Duration(days: 7),
    ];

    String formatDuration(Duration d) {
      if (d.inDays > 0 && d.inHours % 24 == 0) {
        return '${d.inDays} day${d.inDays > 1 ? 's' : ''}';
      }
      return '${d.inHours} hour${d.inHours > 1 ? 's' : ''}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'RECOVERY',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          ListTile(
            title: const Text('Recovery delay'),
            subtitle: const Text('Does not affect currently pending recoveries.'),
            trailing: DropdownButton<Duration>(
              value: currentDelay,
              onChanged: (Duration? newValue) {
                if (newValue != null) {
                  notifier.setRecoveryDelay(newValue);
                }
              },
              items: delays.map<DropdownMenuItem<Duration>>((Duration value) {
                return DropdownMenuItem<Duration>(
                  value: value,
                  child: Text(formatDuration(value)),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'PIN INFORMATION',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          const ListTile(
            title: Text('PIN length'),
            trailing: Text('8 digits', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          const ListTile(
            title: Text('PIN storage'),
            trailing: Text('Android Keystore', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          const ListTile(
            title: Text('Network requirement'),
            trailing: Text('None', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'SECURITY INFORMATION',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '• Your AppBlock PIN is encrypted using an Android Keystore-backed encryption key.\n\n'
              '• PIN recovery is intentionally delayed to make impulsive access more difficult.\n\n'
              '• The recovery delay is a behavioral protection, not an unbreakable security boundary.\n\n'
              '• Because this application runs locally on your Android device, the device owner may still be able to bypass application-level protections through device reset, debugging, modification, or other system-level mechanisms.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
