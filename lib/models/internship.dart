import 'package:flutter/material.dart';

class StudentInternship {
  final String applicationId;
  final String id;
  final String company;
  final String role;
  final String department;
  final String location;
  final String startDate;
  final String endDate;
  final String deadline;
  final double progress; // 0.0 – 1.0
  final int daysLeft;
  final String status; // 'Active' | 'Completed' | 'Upcoming'
  final String internshipStatus;
  final Color brandColor;
  final String logoInitial;
  final String stipend;
  final String mentorName;
  final String mentorEmail;
  final String offerLetterId;
  final String about;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> checkins;

  const StudentInternship({
    required this.applicationId,
    required this.id,
    required this.company,
    required this.role,
    required this.department,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.deadline,
    required this.progress,
    required this.daysLeft,
    required this.status,
    required this.internshipStatus,
    required this.brandColor,
    required this.logoInitial,
    required this.stipend,
    required this.mentorName,
    required this.mentorEmail,
    required this.offerLetterId,
    required this.about,
    this.alerts = const [],
    this.checkins = const [],
  });
}

class InternshipOpportunity {
  final String id;
  final String company;
  final String role;
  final String industry;
  final String location;
  final String stipend;
  final String duration;
  final String deadline;
  final Color brandColor;
  final String logoInitial;
  final String about;
  final List<String> requirements;
  final List<String> responsibilities;
  final bool? isApplied;

  const InternshipOpportunity({
    required this.id,
    required this.company,
    required this.role,
    required this.industry,
    required this.location,
    required this.stipend,
    this.duration = '3 Months',
    this.deadline = 'Oct 30, 2024',
    required this.brandColor,
    required this.logoInitial,
    required this.about,
    this.isApplied = false,
    this.requirements = const [
      'Currently pursuing B.Tech/B.E in CS or related fields',
      'Strong understanding of Data Structures and Algorithms',
      'Knowledge of Flutter/Dart is a plus',
      'Problem-solving mindset'
    ],
    this.responsibilities = const [
      'Collaborate with cross-functional teams to define and ship features',
      'Unit-test code for robustness, including edge cases and usability',
      'Work on bug fixing and improving application performance'
    ],
  });
}
