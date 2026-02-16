import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompanyProfilePage extends StatelessWidget {
  const CompanyProfilePage({super.key});

  // Dummy data
  static const companyProfile = {
    'name': 'Google',
    'website': 'https://www.google.com',
    'description':
        'A multinational technology company that specializes in Internet-related services and products.',
    'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(context,
              companyProfile['name']!,
              companyProfile['website']!,
              companyProfile['logoUrl']!),
          const SizedBox(height: 24),
          _buildAboutSection(context, companyProfile['description']!),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, String name, String website, String logoUrl) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: SvgPicture.network(
                logoUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          website,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Profile'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditCompanyProfilePage()),
            );
          },
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

  Widget _buildAboutSection(BuildContext context, String description) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Us',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditCompanyProfilePage extends StatefulWidget {
  const EditCompanyProfilePage({super.key});

  @override
  State<EditCompanyProfilePage> createState() => _EditCompanyProfilePageState();
}

class _EditCompanyProfilePageState extends State<EditCompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Google');
  final _websiteController = TextEditingController(text: 'https://www.google.com');
  final _descriptionController = TextEditingController(
      text:
          'A multinational technology company that specializes in Internet-related services and products.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'About Us'),
                maxLines: 6,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Update logic here
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
