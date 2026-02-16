import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/core/theme/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSettingsSection(context, 'Account', [
            _buildSettingsTile(context, 'Edit Profile', Icons.person_outline, theme),
            _buildSettingsTile(context, 'Change Password', Icons.lock_outline, theme),
          ], theme),
          _buildSettingsSection(context, 'Preferences', [
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
              title: Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              secondary: Icon(Icons.color_lens_outlined, color: theme.iconTheme.color),
            ),
          ], theme),
          _buildSettingsSection(context, 'Support', [
            _buildSettingsTile(context, 'Help Center', Icons.help_outline, theme),
            _buildSettingsTile(context, 'Contact Us', Icons.email_outlined, theme),
          ], theme),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> tiles, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
