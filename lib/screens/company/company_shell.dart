import 'package:flutter/material.dart';
import 'dashboard/company_dashboard_screen.dart';
import 'postings/manage_postings_screen.dart';
import 'candidates/manage_candidates_screen.dart';
import 'profile/company_profile_screen.dart';

class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});

  @override
  State<CompanyShell> createState() => _CompanyShellState();

  static _CompanyShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<_CompanyShellState>();
}

class _CompanyShellState extends State<CompanyShell> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const CompanyDashboardScreen(),
    const ManagePostingsScreen(),
    const ManageCandidatesScreen(),
    const CompanyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.post_add_outlined),
            selectedIcon: Icon(Icons.post_add_rounded),
            label: 'Postings',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Candidates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
