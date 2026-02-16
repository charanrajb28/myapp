import 'package:flutter/material.dart';

class PostInternshipPage extends StatefulWidget {
  const PostInternshipPage({super.key});

  @override
  State<PostInternshipPage> createState() => _PostInternshipPageState();
}

class _PostInternshipPageState extends State<PostInternshipPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _stipendController = TextEditingController();
  final _requirementsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Post a New Internship',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0),
            _buildSectionTitle(context, 'Internship Details'),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Internship Title'),
              validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Job Description'),
              maxLines: 5,
              validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (e.g., Remote, New York)'),
              validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _stipendController,
              decoration: const InputDecoration(labelText: 'Stipend (e.g., \$2000/month)'),
            ),
            const SizedBox(height: 24.0),
            _buildSectionTitle(context, 'Requirements'),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _requirementsController,
              decoration: const InputDecoration(labelText: 'List required skills, qualifications, etc.'),
              maxLines: 4,
              validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _postInternship,
              child: const Text('Post Internship'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  void _postInternship() {
    if (_formKey.currentState!.validate()) {
      // In a real app, this data would be sent to a backend service.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internship posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _stipendController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
}
