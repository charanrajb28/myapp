import 'package:flutter/material.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  // Mock data for certificates
  final List<Map<String, String>> _certificates = const [
    {'title': 'Flutter Development Bootcamp', 'issuer': 'Udemy', 'date': 'June 2024'},
    {'title': 'Certified TensorFlow Developer', 'issuer': 'Google', 'date': 'May 2024'},
    {'title': 'Agile with Atlassian Jira', 'issuer': 'Coursera', 'date': 'April 2024'},
    {'title': 'Introduction to Cyber Security', 'issuer': 'Cisco', 'date': 'March 2024'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _certificates.length,
      itemBuilder: (context, index) {
        final cert = _certificates[index];
        return _buildCertificateCard(context, cert['title']!, cert['issuer']!, cert['date']!);
      },
    );
  }

  Widget _buildCertificateCard(BuildContext context, String title, String issuer, String date) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.school_outlined, size: 48, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issuer,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    'Issued: $date',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
