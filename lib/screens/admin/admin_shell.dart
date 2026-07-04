import 'package:flutter/material.dart';

import 'students/students_list_screen.dart';
import 'companies/companies_list_screen.dart';
import 'alerts/red_alerts_screen.dart';
import 'dashboard/more_options_screen.dart';
import 'dashboard/admin_dashboard_screen.dart';
import '../../utils/device_session_helper.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  // Index constants for easy reference
  static const int indexOverview = 0;
  static const int indexStudents = 1;
  static const int indexCompanies = 2;
  static const int indexAlerts = 3;
  static const int indexMore = 4;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final SessionMonitor _sessionMonitor;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _sessionMonitor = SessionMonitor()..start(context);
  }

  @override
  void dispose() {
    _sessionMonitor.stop();
    _pageController.dispose();
    super.dispose();
  }

  void _setIndex(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToTab(int index) {
    _setIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.child is AdminDashboardScreen
        ? AdminDashboardScreen(onNavigateToTab: _navigateToTab)
        : widget.child;

    final screens = [
      dashboard,
      const StudentsListScreen(),
      const CompaniesListScreen(),
      const RedAlertsScreen(),
      const MoreOptionsScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _setIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _navigateToTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain),
            label: 'Companies',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
