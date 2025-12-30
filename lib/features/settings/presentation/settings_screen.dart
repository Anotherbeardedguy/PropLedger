import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/settings_notifier.dart';
import '../logic/biometric_settings_notifier.dart';
import '../logic/subscription_notifier.dart';
import '../../auth/logic/auth_notifier.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../data/remote/firebase_service.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data. The app will restart. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared (feature coming soon)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'App Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.money),
            title: const Text('Currency'),
            subtitle: Text(settings.currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyDialog(settings.currency, settingsNotifier),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date Format'),
            subtitle: Text(settings.dateFormat),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDateFormatDialog(settings.dateFormat, settingsNotifier),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(settings.themeMode.name.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(settings.themeMode, settingsNotifier),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data & Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Subscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final subscription = ref.watch(subscriptionNotifierProvider);
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      subscription.isActive ? Icons.workspace_premium : Icons.lock_outline,
                      color: subscription.isActive ? Colors.amber : Colors.grey,
                    ),
                    title: Text(subscription.isActive ? 'Premium Active' : 'Free Plan'),
                    subtitle: Text(subscription.statusText),
                    trailing: subscription.isActive
                        ? Chip(
                            label: Text('${subscription.remainingDays} days left'),
                            backgroundColor: subscription.remainingDays <= 7
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                          )
                        : null,
                  ),
                  if (!subscription.isActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(subscriptionNotifierProvider.notifier).activatePremium();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Premium activated for 30 days (Test Mode)'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text('Activate Premium (Test)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Cloud Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final subscription = ref.watch(subscriptionNotifierProvider);
              final authState = ref.watch(authNotifierProvider);
              final user = authState.value;
              
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.cloud_upload,
                      color: subscription.canAccessOnlineBackups ? Colors.blue : Colors.grey,
                    ),
                    title: const Text('Backup to Cloud'),
                    subtitle: Text(
                      subscription.canAccessOnlineBackups
                          ? 'Backup your data to Firebase'
                          : 'Premium subscription required',
                    ),
                    trailing: subscription.canAccessOnlineBackups
                        ? const Icon(Icons.chevron_right)
                        : Icon(Icons.lock, color: Colors.grey.shade400),
                    enabled: subscription.canAccessOnlineBackups && user != null,
                    onTap: subscription.canAccessOnlineBackups && user != null
                        ? () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Backup to Cloud'),
                                content: const Text(
                                  'This will upload all your data to Firebase. '
                                  'This may take a few moments depending on the amount of data.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Backup Now'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true && context.mounted) {
                              try {
                                final backupService = BackupService(
                                  firebaseService: FirebaseService(),
                                  subscriptionService: SubscriptionService(),
                                  database: null,
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Backing up data...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                
                                await backupService.backupToCloud(user.id);
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Backup completed successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Backup failed: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        : null,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.cloud_download,
                      color: subscription.canAccessOnlineBackups ? Colors.blue : Colors.grey,
                    ),
                    title: const Text('Restore from Cloud'),
                    subtitle: Text(
                      subscription.canAccessOnlineBackups
                          ? 'Restore your data from Firebase'
                          : 'Premium subscription required',
                    ),
                    trailing: subscription.canAccessOnlineBackups
                        ? const Icon(Icons.chevron_right)
                        : Icon(Icons.lock, color: Colors.grey.shade400),
                    enabled: subscription.canAccessOnlineBackups && user != null,
                    onTap: subscription.canAccessOnlineBackups && user != null
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Restore from cloud (Coming soon)'),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            onTap: _clearCache,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final biometricSettings = ref.watch(biometricSettingsProvider);
              return SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Biometric Authentication'),
                subtitle: Text(
                  biometricSettings.isSupported
                      ? (biometricSettings.isEnrolled
                          ? 'Lock app with ${biometricSettings.availableBiometrics}'
                          : 'No biometric credentials enrolled')
                      : 'Not supported on this device',
                ),
                value: biometricSettings.isEnabled,
                onChanged: biometricSettings.isSupported && biometricSettings.isEnrolled
                    ? (value) async {
                        try {
                          final success = await ref
                              .read(biometricSettingsProvider.notifier)
                              .toggleBiometric(value);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Authentication failed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            subtitle: const Text('Sign out of your account'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About PropLedger'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Version'),
            subtitle: const Text('1.1.0 (Local Mode)'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(String currentCurrency, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'USD',
            'EUR',
            'GBP',
            'ZAR',
            'AUD',
            'CAD',
          ].map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: currentCurrency,
              onChanged: (value) {
                if (value != null) {
                  notifier.setCurrency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDateFormatDialog(String currentFormat, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'MM/dd/yyyy',
            'dd/MM/yyyy',
            'yyyy-MM-dd',
          ].map((format) {
            return RadioListTile<String>(
              title: Text(format),
              value: format,
              groupValue: currentFormat,
              onChanged: (value) {
                if (value != null) {
                  notifier.setDateFormat(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(ThemeMode currentMode, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(mode.name.toUpperCase()),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  notifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
