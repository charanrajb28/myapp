import 'package:flutter/material.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'In Review'),
              Tab(text: 'Interview'),
              Tab(text: 'Offered'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildApplicationList(context, 'All'),
              _buildApplicationList(context, 'In Review'),
              _buildApplicationList(context, 'Interview'),
              _buildApplicationList(context, 'Offered'),
              _buildApplicationList(context, 'Rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationList(BuildContext context, String status) {
    final allApplications = {
      'Software Engineer Intern': {'company': 'Google', 'status': 'In Review'},
      'Data Science Intern': {'company': 'Facebook', 'status': 'Interview'},
      'UX/UI Design Intern': {'company': 'Apple', 'status': 'Rejected'},
      'Product Manager Intern': {'company': 'Amazon', 'status': 'Offered'},
    };

    final filteredApplications = status == 'All'
        ? allApplications
        : Map.fromEntries(allApplications.entries.where((entry) => entry.value['status'] == status));

    if (filteredApplications.isEmpty) {
      return Center(
        child: Text(
          'No applications in this category.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredApplications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final title = filteredApplications.keys.elementAt(index);
        final details = filteredApplications.values.elementAt(index);
        return _buildApplicationCard(context, title, details['company']!, details['status']!);
      },
    );
  }

  Widget _buildApplicationCard(BuildContext context, String title, String company, String status) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    company.substring(0, 1),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(status),
                backgroundColor: _getStatusColor(status).withOpacity(0.1),
                labelStyle: theme.textTheme.bodySmall?.copyWith(color: _getStatusColor(status)),
                side: BorderSide.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Review':
        return Colors.blue.shade500;
      case 'Interview':
        return Colors.orange.shade500;
      case 'Offered':
        return Colors.green.shade500;
      case 'Rejected':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }
}
