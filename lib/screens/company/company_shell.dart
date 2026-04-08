import 'package:flutter/material.dart';
import 'dashboard/company_dashboard_screen.dart';
import 'postings/manage_postings_screen.dart';
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
  final GlobalKey<State<CompanyDashboardScreen>> _dashboardKey =
      GlobalKey<State<CompanyDashboardScreen>>();
  final GlobalKey<State<CompanyProfileScreen>> _profileKey =
      GlobalKey<State<CompanyProfileScreen>>();

  void setIndex(int index) {
    setState(() => _currentIndex = index);
    _refreshForIndex(index);
  }

  void _refreshForIndex(int index) {
    if (index == 0) {
      final dynamic state = _dashboardKey.currentState;
      state?.refreshData();
    } else if (index == 2) {
      final dynamic state = _profileKey.currentState;
      state?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CompanyDashboardScreen(key: _dashboardKey),
      const ManagePostingsScreen(),
      CompanyProfileScreen(key: _profileKey),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: setIndex,
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
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
