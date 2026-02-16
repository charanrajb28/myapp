import 'package:flutter/material.dart';

class InternshipListingsPage extends StatefulWidget {
  const InternshipListingsPage({super.key});

  @override
  State<InternshipListingsPage> createState() => _InternshipListingsPageState();
}

class _InternshipListingsPageState extends State<InternshipListingsPage> {
  final _searchController = TextEditingController();
  List<Internship> _internships = [];
  List<Internship> _filteredInternships = [];

  @override
  void initState() {
    super.initState();
    _internships = _getDummyInternships();
    _filteredInternships = _internships;
    _searchController.addListener(_filterInternships);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInternships() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredInternships = _internships.where((internship) {
        return internship.title.toLowerCase().contains(query) ||
            internship.companyName.toLowerCase().contains(query) ||
            internship.location.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Listings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search internships...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredInternships.isEmpty
                ? const Center(
                    child: Text('No internships found.'),
                  )
                : ListView.builder(
                    itemCount: _filteredInternships.length,
                    itemBuilder: (context, index) {
                      final internship = _filteredInternships[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            internship.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8.0),
                              Text('${internship.companyName} - ${internship.location}'),
                              const SizedBox(height: 8.0),
                              Text(
                                internship.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          onTap: () {
                            // TODO: Navigate to internship details page
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Internship> _getDummyInternships() {
    return [
      Internship(
        title: 'Software Engineer Intern',
        companyName: 'Google',
        location: 'Mountain View, CA',
        description: 'Work on challenging projects and gain valuable experience.',
      ),
      Internship(
        title: 'Product Manager Intern',
        companyName: 'Facebook',
        location: 'Menlo Park, CA',
        description: 'Define product strategy and work with cross-functional teams.',
      ),
      Internship(
        title: 'Data Scientist Intern',
        companyName: 'Netflix',
        location: 'Los Gatos, CA',
        description: 'Analyze data to drive business decisions.',
      ),
    ];
  }
}

class Internship {
  final String title;
  final String companyName;
  final String location;
  final String description;

  Internship({
    required this.title,
    required this.companyName,
    required this.location,
    required this.description,
  });
}
