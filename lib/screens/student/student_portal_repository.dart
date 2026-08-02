import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/internship.dart';
import '../../models/student_notification.dart';
import '../../services/auth_service.dart';
import '../../services/turso_database_service.dart';

class StudentProfileData {
  final String name;
  final String college;
  final String department;
  final String semester;
  final String enrollmentId;
  final String email;
  final String graduationYear;
  final String gpa;
  final String phone;
  final String avatarUrl;
  final String parentContact;
  final String parentEmail;

  const StudentProfileData({
    required this.name,
    required this.college,
    required this.department,
    required this.semester,
    required this.enrollmentId,
    required this.email,
    required this.graduationYear,
    required this.gpa,
    required this.phone,
    required this.avatarUrl,
    required this.parentContact,
    required this.parentEmail,
  });

  factory StudentProfileData.fromMap(Map<String, dynamic> map) {
    return StudentProfileData(
      name: map['name']?.toString() ?? 'Student',
      college: map['college']?.toString() ?? 'College not available',
      department: map['department']?.toString() ?? 'Department not available',
      semester: map['semester']?.toString() ?? 'Semester not available',
      enrollmentId: map['enrollment_id']?.toString() ?? 'Not assigned',
      email: map['contact_email']?.toString() ?? 'Email not available',
      graduationYear: map['graduation_year']?.toString() ?? 'Not set',
      gpa: map['gpa']?.toString() ?? 'Not set',
      phone: map['phone_number']?.toString() ?? 'Not set',
      avatarUrl: map['avatar_url']?.toString() ?? '',
      parentContact: map['parent_contact']?.toString() ?? 'Not set',
      parentEmail: map['parent_email']?.toString() ?? 'Not set',
    );
  }

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class StudentDocumentItem {
  final String id;
  final String title;
  final String publicUrl;
  final String sourceType;
  final bool isResume;
  final DateTime createdAt;

  StudentDocumentItem({
    required this.id,
    required this.title,
    required this.publicUrl,
    required this.sourceType,
    required this.isResume,
    required this.createdAt,
  });

  factory StudentDocumentItem.fromMap(Map<String, dynamic> map) {
    return StudentDocumentItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? map['name']?.toString() ?? 'Document',
      publicUrl: map['public_url']?.toString() ?? map['url']?.toString() ?? '',
      sourceType: map['source_type']?.toString() ?? map['sourceType']?.toString() ?? 'google_drive',
      isResume: (map['is_resume'] == true || map['is_resume'] == 1 || map['is_resume'] == '1'),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get typeLabel {
    switch (sourceType.toLowerCase()) {
      case 'resume':
      case 'pdf':
        return 'PDF Document';
      case 'google_drive':
        return 'Google Drive Link';
      default:
        return sourceType.toUpperCase();
    }
  }

  String get timeLabel {
    return DateFormat('MMM dd, yyyy').format(createdAt);
  }
}

class StudentPortalRepository {
  final TursoDatabaseService _db;
  final AuthService _auth;

  StudentPortalRepository({TursoDatabaseService? db, AuthService? auth})
      : _db = db ?? TursoDatabaseService.instance,
        _auth = auth ?? AuthService.instance;

  Future<StudentProfileData> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const StudentProfileData(
        name: 'Alex Guest (Dev Mode)',
        college: 'Stanford University',
        department: 'Computer Science',
        semester: '8th Semester',
        enrollmentId: 'SU-2022-8742',
        email: 'alex.guest@stanford.edu',
        graduationYear: '2026',
        gpa: '3.94 / 4.0',
        phone: '+1 (555) 019-2834',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
        parentContact: '+1 (555) 999-1234',
        parentEmail: 'parent@example.com',
      );
    }

    final profile = await _db.querySingle(
      '''
      SELECT name, college, department, semester, enrollment_id,
             contact_email, graduation_year, gpa, phone_number, avatar_url,
             parent_contact, parent_email
      FROM students WHERE user_id = ?
      ''',
      [user.uid],
    );

    if (profile == null) {
      return const StudentProfileData(
        name: 'Student',
        college: 'College not available',
        department: 'Department not available',
        semester: 'Semester not available',
        enrollmentId: 'Not assigned',
        email: 'Email not available',
        graduationYear: 'Not set',
        gpa: 'Not set',
        phone: 'Not set',
        avatarUrl: '',
        parentContact: 'Not set',
        parentEmail: 'Not set',
      );
    }

    return StudentProfileData.fromMap(profile);
  }

  Future<void> updateStudentProfile({
    required String name,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (avatarUrl != null) {
      await _db.execute(
        'UPDATE students SET name = ?, phone_number = ?, avatar_url = ? WHERE user_id = ?',
        [name.trim(), phone.trim(), avatarUrl.trim(), user.uid],
      );
    } else {
      await _db.execute(
        'UPDATE students SET name = ?, phone_number = ? WHERE user_id = ?',
        [name.trim(), phone.trim(), user.uid],
      );
    }

    await _db.execute('UPDATE users SET name = ? WHERE id = ?', [name.trim(), user.uid]);
  }

  Future<List<StudentInternship>> fetchStudentInternships() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [
        StudentInternship(
          applicationId: 'mock-app-1',
          id: 'mock-posting-1',
          company: 'TechCorp Solutions',
          role: 'Frontend Developer Intern',
          department: 'Engineering',
          location: 'San Francisco, CA (Hybrid)',
          startDate: '01 Jun 2026',
          endDate: '31 Aug 2026',
          deadline: '15 May 2026',
          progress: 0.65,
          daysLeft: 90,
          status: 'Active',
          internshipStatus: 'ONGOING',
          brandColor: const Color(0xFF6366F1),
          logoInitial: 'T',
          stipend: '\$4,500 / month',
          mentorName: 'Sarah Jenkins',
          mentorEmail: 'sarah.j@techcorp.com',
          offerLetterId: 'TC-2026-9921',
          about: 'Leading implementation of core UI components.',
          alerts: const [],
          checkins: const [],
        ),
      ];
    }

    final student = await _db.querySingle(
      'SELECT id FROM students WHERE user_id = ?',
      [user.uid],
    );

    if (student == null) {
      return const [];
    }

    final studentId = student['id'].toString();

    final rows = await _db.query(
      '''
      SELECT a.id as app_id, a.status as app_status, a.progress as app_progress,
             a.checkins as app_checkins,
             i.id as internship_id, i.role, i.industry, i.location, i.stipend,
             i.duration, i.deadline, i.start_date, i.end_date, i.about,
             i.is_active as internship_active, c.name as company_name
      FROM applications a
      JOIN internships i ON a.internship_id = i.id
      LEFT JOIN companies c ON i.company_id = c.id
      WHERE a.student_id = ?
      ORDER BY a.created_at DESC
      ''',
      [studentId],
    );

    return rows.map((r) {
      final checkinsRaw = r['app_checkins'];
      List<dynamic> checkinsList = [];
      if (checkinsRaw is String && checkinsRaw.isNotEmpty) {
        try {
          checkinsList = jsonDecode(checkinsRaw);
        } catch (_) {}
      }

      final progressVal = r['app_progress'];
      final double progress = (progressVal is num)
          ? progressVal.toDouble()
          : (double.tryParse(progressVal?.toString() ?? '0') ?? 0.0);

      return StudentInternship(
        applicationId: r['app_id'].toString(),
        id: r['internship_id'].toString(),
        company: r['company_name']?.toString() ?? 'Company',
        role: r['role']?.toString() ?? 'Intern',
        department: r['industry']?.toString() ?? 'Engineering',
        location: r['location']?.toString() ?? 'Remote',
        startDate: r['start_date']?.toString() ?? '',
        endDate: r['end_date']?.toString() ?? '',
        deadline: r['deadline']?.toString() ?? '',
        progress: progress,
        daysLeft: 90,
        status: r['app_status']?.toString() ?? 'Applied',
        internshipStatus: (r['internship_active'] == 1 || r['internship_active'] == '1') ? 'ONGOING' : 'COMPLETED',
        brandColor: const Color(0xFF6366F1),
        logoInitial: (r['company_name']?.toString().isNotEmpty == true) ? r['company_name'].toString()[0].toUpperCase() : 'C',
        stipend: (r['stipend'] != null) ? '\$${r['stipend']} / month' : 'Unpaid',
        mentorName: 'Mentor',
        mentorEmail: '',
        offerLetterId: 'OFFER-${r['app_id']}',
        about: r['about']?.toString() ?? '',
        alerts: const [],
        checkins: checkinsList.cast<Map<String, dynamic>>(),
      );
    }).toList();
  }

  Future<bool> applyForInternship(InternshipOpportunity opportunity) async {
    final user = _auth.currentUser;
    if (user == null) return true;

    final student = await _db.querySingle(
      'SELECT id FROM students WHERE user_id = ?',
      [user.uid],
    );

    if (student == null) {
      throw Exception('Student profile not found');
    }

    final studentId = student['id'].toString();

    final existing = await _db.querySingle(
      'SELECT id FROM applications WHERE student_id = ? AND internship_id = ?',
      [studentId, opportunity.id],
    );

    if (existing != null) {
      return false;
    }

    final appId = 'app_${DateTime.now().millisecondsSinceEpoch}';
    await _db.execute(
      '''
      INSERT INTO applications (id, student_id, internship_id, status, progress, checkins)
      VALUES (?, ?, ?, 'Applied', 0.0, '[]')
      ''',
      [appId, studentId, opportunity.id],
    );

    return true;
  }

  Future<List<InternshipOpportunity>> fetchAvailableInternships() async {
    final user = _auth.currentUser;
    Set<String> appliedInternshipIds = {};

    if (user != null) {
      final student = await _db.querySingle(
        'SELECT id FROM students WHERE user_id = ?',
        [user.uid],
      );

      if (student != null) {
        final applied = await _db.query(
          'SELECT internship_id FROM applications WHERE student_id = ?',
          [student['id'].toString()],
        );
        appliedInternshipIds = applied.map((a) => a['internship_id'].toString()).toSet();
      }
    }

    final rows = await _db.query(
      '''
      SELECT i.id, i.role, i.industry, i.location, i.stipend, i.duration, i.deadline,
             i.about, i.vacancies, i.is_active, c.name as company_name
      FROM internships i
      LEFT JOIN companies c ON i.company_id = c.id
      WHERE i.is_active = 1
      ORDER BY i.created_at DESC
      ''',
    );

    return rows.map((r) {
      final id = r['id'].toString();
      final isApplied = appliedInternshipIds.contains(id);

      return InternshipOpportunity(
        id: id,
        company: r['company_name']?.toString() ?? 'Company',
        role: r['role']?.toString() ?? 'Internship',
        industry: r['industry']?.toString() ?? 'General',
        location: r['location']?.toString() ?? 'Remote',
        stipend: (r['stipend'] != null) ? '\$${r['stipend']}/mo' : 'Unpaid',
        duration: r['duration']?.toString() ?? '3 Months',
        deadline: r['deadline']?.toString() ?? 'Open',
        brandColor: const Color(0xFF0F172A),
        logoInitial: (r['company_name']?.toString().isNotEmpty == true) ? r['company_name'].toString()[0].toUpperCase() : 'C',
        about: r['about']?.toString() ?? '',
        requirements: const [],
        responsibilities: const [],
        activeDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        eligibleDepartments: const [],
        notes: '',
        vacancies: (r['vacancies'] is int) ? r['vacancies'] : 1,
        applicationDurationDays: 30,
        isApplied: isApplied,
      );
    }).toList();
  }

  Future<List<StudentDocumentItem>> fetchStudentDocuments() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final student = await _db.querySingle(
      'SELECT id FROM students WHERE user_id = ?',
      [user.uid],
    );
    if (student == null) return [];

    final rows = await _db.query(
      '''
      SELECT id, name as title, url as public_url, type as source_type, created_at
      FROM student_documents
      WHERE student_id = ?
      ORDER BY created_at DESC
      ''',
      [student['id'].toString()],
    );

    return rows.map((r) => StudentDocumentItem.fromMap(r)).toList();
  }

  Future<void> addStudentDocument({
    required String title,
    required String publicUrl,
    required bool isResume,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final student = await _db.querySingle(
      'SELECT id FROM students WHERE user_id = ?',
      [user.uid],
    );
    if (student == null) return;

    final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    await _db.execute(
      '''
      INSERT INTO student_documents (id, student_id, name, url, type)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [docId, student['id'].toString(), title.trim(), publicUrl.trim(), isResume ? 'resume' : 'document'],
    );
  }

  Future<void> renameStudentDocument({
    required String documentId,
    required String title,
  }) async {
    await _db.execute(
      'UPDATE student_documents SET name = ? WHERE id = ?',
      [title.trim(), documentId],
    );
  }

  Future<void> deleteStudentDocument(StudentDocumentItem document) async {
    await _db.execute(
      'DELETE FROM student_documents WHERE id = ?',
      [document.id],
    );
  }

  Future<List<StudentNotification>> fetchStudentNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return const [];

    final student = await _db.querySingle(
      'SELECT id FROM students WHERE user_id = ?',
      [user.uid],
    );
    if (student == null) return const [];

    final rows = await _db.query(
      '''
      SELECT id, title, message, type, is_read, created_at
      FROM student_notifications
      WHERE student_id = ?
      ORDER BY created_at DESC
      ''',
      [student['id'].toString()],
    );

    return rows.map((r) {
      final typeStr = r['type']?.toString().toLowerCase() ?? '';
      StudentNotificationType type = StudentNotificationType.interview;
      if (typeStr.contains('academic')) type = StudentNotificationType.academic;
      if (typeStr.contains('security')) type = StudentNotificationType.security;

      return StudentNotification(
        id: r['id'].toString(),
        title: r['title']?.toString() ?? '',
        message: r['message']?.toString() ?? '',
        timeLabel: r['created_at']?.toString() ?? 'Recently',
        type: type,
        isRead: (r['is_read'] == 1 || r['is_read'] == '1'),
      );
    }).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.execute('UPDATE student_notifications SET is_read = 1 WHERE id = ?', [id]);
  }

  Future<void> markAllNotificationsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final student = await _db.querySingle('SELECT id FROM students WHERE user_id = ?', [user.uid]);
    if (student == null) return;

    await _db.execute(
      'UPDATE student_notifications SET is_read = 1 WHERE student_id = ?',
      [student['id'].toString()],
    );
  }

  Future<List<Map<String, dynamic>>> recordApplicationCheckin({
    required String applicationId,
    required bool isCheckout,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final app = await _db.querySingle(
      'SELECT checkins FROM applications WHERE id = ?',
      [applicationId],
    );
    if (app == null) return [];

    List<Map<String, dynamic>> checkins = [];
    final raw = app['checkins'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          checkins = decoded.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }

    final today = DateTime.now();
    final todayLabel = DateFormat('yyyy-MM-dd').format(today);
    final nowIso = today.toUtc().toIso8601String();

    final idx = checkins.indexWhere((c) => c['checkin_date']?.toString() == todayLabel);
    if (idx >= 0) {
      checkins[idx]['status'] = 'Present';
      if (isCheckout) {
        checkins[idx]['check_out_at'] = nowIso;
      } else {
        checkins[idx]['check_in_at'] = nowIso;
      }
    } else {
      checkins.add({
        'checkin_date': todayLabel,
        'status': 'Present',
        'check_in_at': isCheckout ? null : nowIso,
        'check_out_at': isCheckout ? null : nowIso,
        'notes': '',
      });
    }

    await _db.execute(
      'UPDATE applications SET checkins = ? WHERE id = ?',
      [jsonEncode(checkins), applicationId],
    );

    return checkins;
  }
}
