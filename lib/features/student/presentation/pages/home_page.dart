import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, 'Jane', theme),
          const SizedBox(height: 24),
          _buildInternshipSummaryGrid(context, theme),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Ongoing Internship', theme),
          const SizedBox(height: 12),
          _buildOngoingInternshipCard(context, theme),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Upcoming Deadlines', theme),
          const SizedBox(height: 12),
          _buildDeadlineList(context, theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String name, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back,',
          style: theme.textTheme.displaySmall?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          name,
          style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInternshipSummaryGrid(BuildContext context, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSummaryCard(context, '3', 'Applied', theme, Icons.send_outlined, theme.colorScheme.primary),
        _buildSummaryCard(context, '1', 'Interview', theme, Icons.people_outline, Colors.orange),
        _buildSummaryCard(context, '0', 'Offered', theme, Icons.workspace_premium_outlined, Colors.green),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String count, String label, ThemeData theme, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge,
    );
  }

  Widget _buildOngoingInternshipCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.work_outline, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Software Engineer Intern',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Google',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineList(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildDeadlineTile(context, 'Facebook', '25th July 2024', theme),
        const SizedBox(height: 12),
        _buildDeadlineTile(context, 'Amazon', '30th July 2024', theme),
      ],
    );
  }

  Widget _buildDeadlineTile(BuildContext context, String company, String date, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                company.substring(0, 1),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$company Application',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Deadline: $date',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
