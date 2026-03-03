import 'package:flutter/material.dart';

import 'students/students_list_screen.dart';
import 'companies/companies_list_screen.dart';
import 'alerts/red_alerts_screen.dart';
import 'dashboard/more_options_screen.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  // Ideally, these routes and indices would be managed by go_router.
  // For the standalone UI phase, we'll map the indices here mockingly.

  @override
  Widget build(BuildContext context) {
    // Current stand-in for full router: map index to screen widget
    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = widget.child; // The dashboard passed from main
        break;
      case 1:
        currentScreen = const StudentsListScreen();
        break;
      case 2:
        currentScreen = const CompaniesListScreen();
        break;
      case 3:
        currentScreen = const RedAlertsScreen();
        break;
      case 4:
        currentScreen = const MoreOptionsScreen();
        break;
      default:
        currentScreen = Scaffold(
          body: Center(
            child: Text('Screen $_currentIndex not built yet'),
          ),
        );
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            // In a real app with go_router, we would navigate based on index:
            // if (index == 0) context.go('/admin/dashboard');
            // ...
          });
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
