import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/internship.dart';
import '../../models/student_notification.dart';

class StudentPortalRepository {
  final SupabaseClient _client;

  StudentPortalRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<StudentProfileData> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final profile = await _client
        .from('students')
        .select(
          'name, college, department, semester, enrollment_id, '
          'contact_email, graduation_year, gpa, phone_number',
        )
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

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
      );
    }

    return StudentProfileData.fromMap(profile);
  }

  Future<List<StudentInternship>> fetchStudentInternships() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final student = await _client
        .from('students')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    if (student == null) {
      return const [];
    }

    final studentId = student['id'];

    final response = await _client
        .from('applications')
        .select(
          'id, status, progress, start_date, end_date, mentor_name, '
          'checkins, '
          'mentor_email, offer_letter_id, internships('
          'id, role, industry, location, stipend, duration, deadline, '
          'brand_color, logo_initial, about, status, companies(name))',
        )
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));

    return (response as List)
        .map((item) => _mapStudentInternship(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> applyForInternship(InternshipOpportunity opportunity) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final student = await _client
        .from('students')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    if (student == null) {
      throw Exception('Student profile not found');
    }

    final studentId = student['id'];

    final existing = await _client
        .from('applications')
        .select('id')
        .eq('student_id', studentId)
        .eq('internship_id', opportunity.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    if (existing != null) {
      return false;
    }

    await _client.from('applications').insert({
      'student_id': studentId,
      'internship_id': opportunity.id,
      'status': 'Applied',
      'progress': 0.0,
    }).timeout(const Duration(seconds: 15));

    return true;
  }

  Future<List<InternshipOpportunity>> fetchAvailableInternships() async {
    final user = _client.auth.currentUser;
    Set<String> appliedInternshipIds = {};

    if (user != null) {
      final student = await _client
          .from('students')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (student != null) {
        final appliedResponse = await _client
            .from('applications')
            .select('internship_id')
            .eq('student_id', student['id'])
            .timeout(const Duration(seconds: 15));

        appliedInternshipIds = (appliedResponse as List)
            .map((item) => item['internship_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      }
    }

    final response = await _client
        .from('internships')
        .select('id, role, industry, location, stipend, duration, deadline, '
            'brand_color, logo_initial, about, requirements, responsibilities, '
            'companies(name)')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));

    return (response as List)
        .map(
          (item) => _mapOpportunity(
            item as Map<String, dynamic>,
            appliedInternshipIds,
          ),
        )
        .toList();
  }

  Future<List<StudentNotification>> fetchStudentNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const [];
    }

    try {
      final response = await _client
          .from('student_notifications')
          .select('id, title, message, notification_type, is_read, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      return (response as List)
          .map((item) => _mapNotification(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Notification query failed: $e');
      return const [];
    } on TimeoutException catch (e) {
      debugPrint('Notification query timed out: $e');
      return const [];
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _client
        .from('student_notifications')
        .update({'is_read': true})
        .eq('id', id)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> markAllNotificationsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    await _client
        .from('student_notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false)
        .timeout(const Duration(seconds: 15));
  }

  Future<List<Map<String, dynamic>>> recordApplicationCheckin({
    required String applicationId,
    required bool isCheckout,
  }) async {
    final response = await _client
        .from('applications')
        .select('checkins')
        .eq('id', applicationId)
        .single()
        .timeout(const Duration(seconds: 15));

    final checkins = _jsonObjectList(response['checkins']);
    final today = DateTime.now();
    final todayLabel = DateFormat('yyyy-MM-dd').format(today);
    final nowIso = today.toUtc().toIso8601String();
    final index = checkins.indexWhere(
      (item) => item['checkin_date']?.toString() == todayLabel,
    );

    if (index >= 0) {
      final updated = Map<String, dynamic>.from(checkins[index]);
      updated['status'] = 'Present';
      if (isCheckout) {
        updated['check_out_at'] = nowIso;
      } else {
        updated['check_in_at'] = nowIso;
      }
      checkins[index] = updated;
    } else {
      checkins.add({
        'checkin_date': todayLabel,
        'status': 'Present',
        'check_in_at': isCheckout ? null : nowIso,
        'check_out_at': isCheckout ? nowIso : null,
        'notes': '',
      });
    }

    await _client
        .from('applications')
        .update({'checkins': checkins})
        .eq('id', applicationId)
        .timeout(const Duration(seconds: 15));

    return checkins;
  }

  Future<List<StudentDocumentItem>> fetchStudentDocuments() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final student = await _client
        .from('students')
        .select('id, resume_url, document_urls')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    if (student == null) {
      return const [];
    }

    final studentId = student['id']?.toString() ?? '';
    if (studentId.isEmpty) {
      return const [];
    }

    try {
      final response = await _client
          .from('student_documents')
          .select('id, title, public_url, source_type, mime_type, is_resume, created_at')
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      return (response as List)
          .map((item) => StudentDocumentItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Student documents query failed, falling back to legacy fields: $e');
      return _legacyDocumentsFromStudent(student);
    } on TimeoutException catch (e) {
      debugPrint('Student documents query timed out, falling back to legacy fields: $e');
      return _legacyDocumentsFromStudent(student);
    }
  }

  Future<void> addStudentDocument({
    required String title,
    required String publicUrl,
    required bool isResume,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final normalizedUrl = _normalizeDriveUrl(publicUrl);
    if (normalizedUrl == null) {
      throw Exception('Please enter a valid Google Drive link');
    }

    final student = await _client
        .from('students')
        .select('id, resume_url, document_urls')
        .eq('user_id', user.id)
        .single()
        .timeout(const Duration(seconds: 15));

    final studentId = student['id']?.toString() ?? '';
    if (studentId.isEmpty) {
      throw Exception('Student profile not found');
    }

    try {
      if (isResume) {
        await _client
            .from('student_documents')
            .delete()
            .eq('student_id', studentId)
            .eq('is_resume', true)
            .timeout(const Duration(seconds: 15));
      }

      await _client.from('student_documents').insert({
        'student_id': studentId,
        'title': title.trim(),
        'public_url': normalizedUrl,
        'source_type': 'google_drive',
        'is_resume': isResume,
      }).timeout(const Duration(seconds: 15));
    } on PostgrestException catch (e) {
      debugPrint('Student documents insert failed, using legacy fields only: $e');
    }

    final legacyDocs = _documentObjects(student['document_urls']);
    if (isResume) {
      await _client
          .from('students')
          .update({'resume_url': normalizedUrl})
          .eq('id', studentId)
          .timeout(const Duration(seconds: 15));
      return;
    }

    final alreadyExists = legacyDocs.any(
      (item) => item['url']?.toString() == normalizedUrl,
    );
    if (!alreadyExists) {
      legacyDocs.insert(0, {
        'name': title.trim(),
        'url': normalizedUrl,
        'sourceType': 'google_drive',
      });
    }

    await _client
        .from('students')
        .update({'document_urls': legacyDocs})
        .eq('id', studentId)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> renameStudentDocument({
    required String documentId,
    required String title,
  }) async {
    await _client
        .from('student_documents')
        .update({'title': title.trim(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', documentId)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> deleteStudentDocument(StudentDocumentItem document) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final student = await _client
        .from('students')
        .select('id, resume_url, document_urls')
        .eq('user_id', user.id)
        .single()
        .timeout(const Duration(seconds: 15));

    final studentId = student['id']?.toString() ?? '';
    if (studentId.isEmpty) {
      throw Exception('Student profile not found');
    }

    if (document.id.isNotEmpty) {
      try {
        await _client
            .from('student_documents')
            .delete()
            .eq('id', document.id)
            .timeout(const Duration(seconds: 15));
      } on PostgrestException catch (e) {
        debugPrint('Student documents delete failed, continuing legacy cleanup: $e');
      }
    }

    if (document.isResume) {
      final currentResume = student['resume_url']?.toString();
      if (currentResume == document.publicUrl) {
        await _client
            .from('students')
            .update({'resume_url': null})
            .eq('id', studentId)
            .timeout(const Duration(seconds: 15));
      }
      return;
    }

    final legacyDocs = _documentObjects(student['document_urls'])
      ..removeWhere((item) => item['url']?.toString() == document.publicUrl);

    await _client
        .from('students')
        .update({'document_urls': legacyDocs})
        .eq('id', studentId)
        .timeout(const Duration(seconds: 15));
  }

  StudentInternship _mapStudentInternship(Map<String, dynamic> item) {
    final internship = (item['internships'] as Map<String, dynamic>?) ?? {};
    final status = item['status']?.toString() ?? 'Applied';
    final startDate = item['start_date']?.toString();
    final endDate = _resolvedEndDateRaw(
      endDateRaw: item['end_date']?.toString(),
      startDateRaw: startDate,
      durationRaw: internship['duration'],
    );

    return StudentInternship(
      applicationId: item['id']?.toString() ?? '',
      id: internship['id']?.toString() ?? item['id'].toString(),
      company: internship['companies']?['name']?.toString() ?? 'Company',
      role: internship['role']?.toString() ?? 'Intern',
      department: internship['industry']?.toString() ?? 'General',
      location: internship['location']?.toString() ?? 'Not specified',
      startDate: _formatDate(startDate),
      endDate: _formatDate(endDate),
      deadline: _formatDate(internship['deadline']?.toString()),
      progress: _toDouble(item['progress']),
      daysLeft: _daysLeft(endDate),
      status: _mapApplicationStatus(status),
      internshipStatus: internship['status']?.toString() ?? '',
      brandColor: _parseColor(internship['brand_color']?.toString()),
      logoInitial: internship['logo_initial']?.toString() ??
          (internship['companies']?['name']?.toString().isNotEmpty == true
              ? internship['companies']['name'].toString()[0].toUpperCase()
              : 'I'),
      stipend: internship['stipend']?.toString() ?? 'Not specified',
      mentorName: item['mentor_name']?.toString() ?? 'Not assigned',
      mentorEmail: item['mentor_email']?.toString() ?? 'Not assigned',
      offerLetterId: item['offer_letter_id']?.toString() ?? 'Not issued',
      about: internship['about']?.toString() ?? 'No description available.',
      checkins: _jsonObjectList(item['checkins']),
    );
  }

  InternshipOpportunity _mapOpportunity(
    Map<String, dynamic> item,
    Set<String> appliedInternshipIds,
  ) {
    final internshipId = item['id']?.toString() ?? '';
    return InternshipOpportunity(
      id: internshipId,
      company: item['companies']?['name']?.toString() ?? 'Company',
      role: item['role']?.toString() ?? 'Intern',
      industry: item['industry']?.toString() ?? 'General',
      location: item['location']?.toString() ?? 'Not specified',
      stipend: item['stipend']?.toString() ?? 'Not specified',
      duration: item['duration']?.toString() ?? 'Not specified',
      deadline: _formatDate(item['deadline']?.toString()),
      brandColor: _parseColor(item['brand_color']?.toString()),
      logoInitial: item['logo_initial']?.toString() ??
          (item['companies']?['name']?.toString().isNotEmpty == true
              ? item['companies']['name'].toString()[0].toUpperCase()
              : 'I'),
      about: item['about']?.toString() ?? 'No description available.',
      isApplied: appliedInternshipIds.contains(internshipId),
      requirements: _stringList(item['requirements']),
      responsibilities: _stringList(item['responsibilities']),
    );
  }

  StudentNotification _mapNotification(Map<String, dynamic> item) {
    return StudentNotification(
      id: item['id']?.toString() ?? '',
      title: item['title']?.toString() ?? 'Notification',
      message: item['message']?.toString() ?? 'No message available.',
      timeLabel: _relativeTime(item['created_at']?.toString()),
      type: _mapNotificationType(item['notification_type']?.toString()),
      isRead: item['is_read'] == true,
    );
  }

  List<StudentDocumentItem> _legacyDocumentsFromStudent(
    Map<String, dynamic> student,
  ) {
    final documents = <StudentDocumentItem>[];
    final resumeUrl = _normalizeDriveUrl(student['resume_url']?.toString());
    if (resumeUrl != null) {
      documents.add(
        StudentDocumentItem(
          id: 'legacy-resume',
          title: 'Resume / CV',
          publicUrl: resumeUrl,
          sourceType: 'google_drive',
          isResume: true,
          createdAt: null,
        ),
      );
    }

    final docs = _documentObjects(student['document_urls']);
    for (var i = 0; i < docs.length; i++) {
      final entry = docs[i];
      final normalized = _normalizeDriveUrl(entry['url']?.toString());
      if (normalized == null) {
        continue;
      }
      documents.add(
        StudentDocumentItem(
          id: 'legacy-$i',
          title: entry['name']?.toString().trim().isNotEmpty == true
              ? entry['name'].toString().trim()
              : 'Supporting Document ${i + 1}',
          publicUrl: normalized,
          sourceType: entry['sourceType']?.toString() ?? 'google_drive',
          isResume: false,
          createdAt: null,
        ),
      );
    }
    return documents;
  }

  List<Map<String, dynamic>> _documentObjects(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue.map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        }
        if (item is Map) {
          return item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
        return <String, dynamic>{
          'name': 'Supporting Document',
          'url': item?.toString() ?? '',
          'sourceType': 'google_drive',
        };
      }).where((item) {
        final url = item['url']?.toString().trim() ?? '';
        return url.isNotEmpty;
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  String? _normalizeDriveUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('drive.google.com') && !host.contains('docs.google.com')) {
      return null;
    }

    final pathSegments = uri.pathSegments;
    final idFromFilePath = pathSegments.length >= 3 &&
            pathSegments[0] == 'file' &&
            pathSegments[1] == 'd'
        ? pathSegments[2]
        : null;
    final idFromDocPath = pathSegments.length >= 3 &&
            pathSegments[1] == 'd'
        ? pathSegments[2]
        : null;
    final idFromQuery = uri.queryParameters['id'];
    final fileId = idFromFilePath ?? idFromDocPath ?? idFromQuery;

    if (fileId == null || fileId.isEmpty) {
      return value;
    }

    if (host.contains('docs.google.com')) {
      final firstSegment = pathSegments.isNotEmpty ? pathSegments.first : 'document';
      return 'https://docs.google.com/$firstSegment/d/$fileId/edit?usp=sharing';
    }

    return 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not set';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  int _daysLeft(String? endDateRaw) {
    final parsed = DateTime.tryParse(endDateRaw ?? '');
    if (parsed == null) return 0;
    final diff = parsed.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String? _resolvedEndDateRaw({
    required String? endDateRaw,
    required String? startDateRaw,
    required dynamic durationRaw,
  }) {
    if (endDateRaw != null && endDateRaw.trim().isNotEmpty) {
      return endDateRaw;
    }

    final startDate = DateTime.tryParse(startDateRaw ?? '');
    if (startDate == null) {
      return null;
    }

    final durationMonths = _durationMonths(durationRaw);
    if (durationMonths <= 0) {
      return null;
    }

    final plannedEndDate = DateTime(
      startDate.year,
      startDate.month + durationMonths,
      startDate.day,
    );
    return plannedEndDate.toIso8601String();
  }

  int _durationMonths(dynamic rawDuration) {
    final text = rawDuration?.toString().trim() ?? '';
    final match = RegExp(r'(\d+)').firstMatch(text);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String _mapApplicationStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll('_', ' ');
    switch (normalized) {
      case 'applied':
      case 'Applied':
        return 'Applied';
      case 'active':
      case 'Active':
        return 'Active';
      case 'completed':
      case 'Completed':
        return 'Completed';
      case 'rejected':
      case 'Rejected':
        return 'Rejected';
      case 'removed':
      case 'Removed':
        return 'Removed';
      case 'under review':
        return 'Applied';
      case 'upcoming':
      case 'Upcoming':
        return 'Upcoming';
      default:
        return status.trim();
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _jsonObjectList(dynamic value) {
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        }
        if (item is Map) {
          return item.map(
            (key, val) => MapEntry(key.toString(), val),
          );
        }
        return <String, dynamic>{};
      }).where((item) => item.isNotEmpty).toList();
    }
    return <Map<String, dynamic>>[];
  }

  StudentNotificationType _mapNotificationType(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'academic':
        return StudentNotificationType.academic;
      case 'message':
        return StudentNotificationType.message;
      case 'announcement':
        return StudentNotificationType.announcement;
      case 'interview':
        return StudentNotificationType.interview;
      case 'security':
        return StudentNotificationType.security;
      default:
        return StudentNotificationType.general;
    }
  }

  String _relativeTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'Just now';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Just now';
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return DateFormat('dd MMM').format(parsed.toLocal());
  }
}

class StudentDocumentItem {
  final String id;
  final String title;
  final String publicUrl;
  final String sourceType;
  final bool isResume;
  final DateTime? createdAt;

  const StudentDocumentItem({
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
      title: map['title']?.toString() ?? 'Document',
      publicUrl: map['public_url']?.toString() ?? '',
      sourceType: map['source_type']?.toString() ?? 'google_drive',
      isResume: map['is_resume'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  String get typeLabel => isResume ? 'RESUME' : 'DRIVE LINK';

  String get timeLabel {
    if (createdAt == null) {
      return 'Saved from profile';
    }
    return DateFormat('dd MMM yyyy').format(createdAt!.toLocal());
  }
}

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
    );
  }

  String get initials {
    final parts =
        name.split(' ').where((part) => part.trim().isNotEmpty).take(2).toList();
    if (parts.isEmpty) return 'ST';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}
