import 'package:flutter/material.dart';

import 'dashboard/student_dashboard_screen.dart';
import 'internship/my_internship_screen.dart';
import 'checkins/checkins_screen.dart';
import 'reports/student_reports_screen.dart';
import 'profile/student_profile_screen.dart';


class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  static StudentShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<StudentShellState>();
  }

  @override
  State<StudentShell> createState() => StudentShellState();
}

class StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    StudentDashboardScreen(),
    MyInternshipScreen(),
    CheckinsScreen(),
    StudentReportsScreen(),
    StudentProfileScreen(),
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
        indicatorColor: const Color(0xFF0F172A).withValues(alpha: 0.08),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Internships',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'Reports',
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
