import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentsState {
  final List<Map<String, dynamic>> students;
  final bool isLoading;
  final String? errorMessage;

  StudentsState({
    required this.students,
    required this.isLoading,
    this.errorMessage,
  });

  StudentsState copyWith({
    List<Map<String, dynamic>>? students,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentsState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class StudentsNotifier extends Notifier<StudentsState> {
  @override
  StudentsState build() {
    // Fetch students asynchronously upon initialization
    Future.microtask(() => loadStudents());
    return StudentsState(students: [], isLoading: false);
  }

  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        // Dev Mode Mock Data
        final mockStudents = [
          {
            'id': 'stu-1',
            'name': 'Alex Guest',
            'department': 'Computer Science',
            'college': 'Stanford University',
            'semester': '8th Semester',
            'contact_email': 'alex.guest@stanford.edu',
            'phone_number': '+1-555-0199',
            'is_blacklisted': false,
            'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          },
          {
            'id': 'stu-2',
            'name': 'Sarah Chen',
            'department': 'Data Science',
            'college': 'UC Berkeley',
            'semester': '6th Semester',
            'contact_email': 'schen@berkeley.edu',
            'phone_number': '+1-555-0142',
            'is_blacklisted': false,
            'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          },
          {
            'id': 'stu-3',
            'name': 'Michael Vance',
            'department': 'Information Technology',
            'college': 'MIT',
            'semester': '7th Semester',
            'contact_email': 'mvance@mit.edu',
            'phone_number': '+1-555-0188',
            'is_blacklisted': false,
            'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
          },
          {
            'id': 'stu-4',
            'name': 'Emily Watson',
            'department': 'Data Science',
            'college': 'Stanford University',
            'semester': '8th Semester',
            'contact_email': 'ewatson@stanford.edu',
            'phone_number': '+1-555-0123',
            'is_blacklisted': false,
            'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          },
          {
            'id': 'stu-5',
            'name': 'James Miller',
            'department': 'Computer Science',
            'college': 'MIT',
            'semester': '6th Semester',
            'contact_email': 'jmiller@mit.edu',
            'phone_number': '+1-555-0155',
            'is_blacklisted': true,
            'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
          }
        ];
        state = state.copyWith(students: mockStudents, isLoading: false);
        return;
      }

      final res = await client
          .from('students')
          .select('*')
          .order('created_at');

      state = state.copyWith(
        students: List<Map<String, dynamic>>.from(res),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        // Dev Mode: in-memory delete
        final updated = state.students.where((s) => s['id'] != id).toList();
        state = state.copyWith(students: updated);
        return;
      }

      // Find the student's auth user_id
      final student = state.students.firstWhere((s) => s['id'] == id);
      final userId = student['user_id'];

      if (userId != null) {
        // Call SECURITY DEFINER RPC — deletes auth.users row which cascades to
        // public.users → students, applications, documents, notifications, etc.
        await client.rpc('admin_delete_user', params: {'target_user_id': userId});
      } else {
        // Fallback: no user_id, delete the student profile row directly
        await client.from('students').delete().eq('id', id);
      }

      // Reload the list from DB
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleBlacklist(String id, bool currentStatus) async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        // Dev Mode Mock Toggle
        final updated = state.students.map((s) {
          if (s['id'] == id) {
            return {...s, 'is_blacklisted': !currentStatus};
          }
          return s;
        }).toList();
        state = state.copyWith(students: updated);
        return;
      }

      await client.from('students').update({'is_blacklisted': !currentStatus}).eq('id', id);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }
}

final studentsProvider = NotifierProvider<StudentsNotifier, StudentsState>(() {
  return StudentsNotifier();
});
