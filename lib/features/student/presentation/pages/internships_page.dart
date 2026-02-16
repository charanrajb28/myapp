import 'package:flutter/material.dart';

class InternshipsPage extends StatefulWidget {
  const InternshipsPage({super.key});

  @override
  State<InternshipsPage> createState() => _InternshipsPageState();
}

class _InternshipsPageState extends State<InternshipsPage> {
  final List<String> _filters = ['All', 'Full-time', 'Part-time', 'Remote'];
  String _selectedFilter = 'All';

  // Mock data for internships
  final List<Map<String, String>> _internships = [
    {'title': 'Software Engineer Intern', 'company': 'Google', 'location': 'Mountain View, CA', 'type': 'Full-time'},
    {'title': 'Data Science Intern', 'company': 'Facebook', 'location': 'Menlo Park, CA', 'type': 'Full-time'},
    {'title': 'UX/UI Design Intern', 'company': 'Apple', 'location': 'Cupertino, CA', 'type': 'Remote'},
    {'title': 'Product Manager Intern', 'company': 'Amazon', 'location': 'Seattle, WA', 'type': 'Part-time'},
    {'title': 'Cloud Engineering Intern', 'company': 'Microsoft', 'location': 'Redmond, WA', 'type': 'Full-time'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        _buildFilterChips(context),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: _internships.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final internship = _internships[index];
              return _buildInternshipCard(
                context,
                internship['title']!,
                internship['company']!,
                internship['location']!,
                internship['type']!,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search for internships...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
                ),
              ),
              backgroundColor: theme.colorScheme.surface,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInternshipCard(BuildContext context, String title, String company, String location, String type) {
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
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const Spacer(),
                Chip(
                  label: Text(type),
                  labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
