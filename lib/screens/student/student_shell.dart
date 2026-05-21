import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/student_notifications_provider.dart';
import '../../providers/student_internships_provider.dart';
import 'dashboard/student_dashboard_screen.dart';
import 'internship/my_internship_screen.dart';
import 'checkins/checkins_screen.dart';
import 'notifications/student_notifications_screen.dart';
import 'profile/student_profile_screen.dart';


class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  static StudentShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<StudentShellState>();
  }

  @override
  ConsumerState<StudentShell> createState() => StudentShellState();
}

class StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      ref.read(studentInternshipsProvider.notifier).loadInternships();
    } else if (index == 3) {
      ref.read(studentNotificationsProvider.notifier).loadNotifications();
    }
  }

  final List<Widget> _screens = const [
    StudentDashboardScreen(),
    MyInternshipScreen(),
    CheckinsScreen(),
    StudentNotificationsScreen(),
    StudentProfileScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(studentNotificationsProvider);
    final unreadCount = notificationState.notifications.where((n) => !n.isRead).length;

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
          setIndex(index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Internships',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: unreadCount > 0
                ? Badge(
                    label: Text('$unreadCount'),
                    backgroundColor: const Color(0xFFEF4444),
                    textColor: Colors.white,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: unreadCount > 0
                ? Badge(
                    label: Text('$unreadCount'),
                    backgroundColor: const Color(0xFFEF4444),
                    textColor: Colors.white,
                    child: const Icon(Icons.notifications_rounded),
                  )
                : const Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}
