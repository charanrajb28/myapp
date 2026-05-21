import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/internship.dart';
import '../screens/student/student_portal_repository.dart';
import 'student_notifications_provider.dart';

class StudentInternshipsState {
  final List<InternshipOpportunity> availableInternships;
  final List<StudentInternship> studentInternships;
  final bool isLoading;
  final String? errorMessage;

  StudentInternshipsState({
    required this.availableInternships,
    required this.studentInternships,
    required this.isLoading,
    this.errorMessage,
  });

  StudentInternshipsState copyWith({
    List<InternshipOpportunity>? availableInternships,
    List<StudentInternship>? studentInternships,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentInternshipsState(
      availableInternships: availableInternships ?? this.availableInternships,
      studentInternships: studentInternships ?? this.studentInternships,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class StudentInternshipsNotifier extends Notifier<StudentInternshipsState> {
  late final StudentPortalRepository _repository;

  @override
  StudentInternshipsState build() {
    _repository = ref.watch(studentPortalRepositoryProvider);
    // Fetch available internships and student internships asynchronously on initialization
    Future.microtask(() => loadInternships());

    // Polling: Auto-refresh internships every 30 seconds
    final timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadInternships();
    });
    ref.onDispose(() {
      timer.cancel();
    });

    return StudentInternshipsState(
      availableInternships: [],
      studentInternships: [],
      isLoading: false,
    );
  }

  Future<void> loadInternships() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final available = await _repository.fetchAvailableInternships();
      final student = await _repository.fetchStudentInternships();
      state = state.copyWith(
        availableInternships: available,
        studentInternships: student,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final studentInternshipsProvider =
    NotifierProvider.autoDispose<StudentInternshipsNotifier, StudentInternshipsState>(() {
  return StudentInternshipsNotifier();
});
