import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildProfileHeader(context, 'Jane', 'Software Engineer'),
        const SizedBox(height: 24),
        _buildSectionCard(
          context,
          title: 'About Me',
          child: const Text(
            'A passionate software engineer with a love for creating beautiful and functional mobile applications.',
          ),
        ),
        const SizedBox(height: 16),
        _buildSkillsSection(context, ['Flutter', 'Dart', 'Firebase', 'UI/UX Design']),
        const SizedBox(height: 16),
        _buildResumeSection(context),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String title) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/68.jpg'),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: const Text('Settings'),
          onPressed: () => context.go('/settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(height: 1.5, color: Colors.grey[700]),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context, List<String> skills) {
    return _buildSectionCard(
      context,
      title: 'Skills',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map((skill) => Chip(label: Text(skill))).toList(),
      ),
    );
  }

  Widget _buildResumeSection(BuildContext context) {
    final theme = Theme.of(context);
    return _buildSectionCard(
      context,
      title: 'Resume',
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'jane_doe_resume.pdf',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated: July 15, 2024',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {},
            tooltip: 'Download',
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}
