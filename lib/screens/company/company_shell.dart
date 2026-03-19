import 'package:flutter/material.dart';
import 'dashboard/company_dashboard_screen.dart';

class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CompanyDashboardScreen(),
    const Scaffold(body: Center(child: Text('My Postings'))),
    const Scaffold(body: Center(child: Text('Candidate Management'))),
    const Scaffold(body: Center(child: Text('Settings'))),
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
