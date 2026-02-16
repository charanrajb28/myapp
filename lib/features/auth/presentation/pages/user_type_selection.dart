import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/core/theme/theme.dart';

class UserTypeSelectionPage extends StatelessWidget {
  const UserTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.workspaces_outline,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Intern-Connect',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'Your future starts here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 60),
              _buildUserTypeButton(
                context,
                icon: Icons.person_outline,
                label: 'Student',
                userType: 'student',
              ),
              const SizedBox(height: 24),
              _buildUserTypeButton(
                context,
                icon: Icons.business_center_outlined,
                label: 'Company',
                userType: 'company',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(BuildContext context, {required IconData icon, required String label, required String userType}) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      onPressed: () => context.go('/login/$userType'),
      style: ElevatedButton.styleFrom(
        foregroundColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
      ),
    );
  }
}
