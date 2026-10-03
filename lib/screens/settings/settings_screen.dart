import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.brightness_6_rounded),
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    themeProvider.isSystemMode
                        ? 'Following system theme'
                        : themeProvider.isDarkMode
                        ? 'Dark theme enabled'
                        : 'Light theme enabled',
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.phone_android_rounded),
                  title: const Text(
                    'Use System Theme',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Radio<bool>(
                    value: true,
                    groupValue: themeProvider.isSystemMode,
                    onChanged: (_) {
                      themeProvider.useSystemTheme();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'App Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.info_outline_rounded),
                  ),
                  title: const Text(
                    'About SmartInterestX',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Personal money and transaction manager',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _showAbout(context);
                  },
                ),

                const Divider(height: 1),

                const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.storage_outlined)),
                  title: Text(
                    'Local Database',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Your transaction data is stored locally'),
                ),

                const Divider(height: 1),

                const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.verified_outlined)),
                  title: Text(
                    'Version',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('SmartInterestX • Version 1.0.0'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Support',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          Card(
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.help_outline_rounded),
              ),
              title: const Text(
                'Help & Support',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Get help using SmartInterestX'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showHelp(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SmartInterestX',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet_rounded,
        size: 40,
      ),
      children: const [
        Text(
          'SmartInterestX is a personal money and '
          'transaction management application designed '
          'to track people, transactions, payments, '
          'interest and pending amounts.',
        ),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'Use People to manage borrowers and lenders.\n\n'
            'Use Transactions to record money given or taken.\n\n'
            'Use Payments to record repayments.\n\n'
            'Use Analytics to view your financial summary.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
