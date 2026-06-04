import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/students_provider.dart';
import 'student_detail_screen.dart';
import 'add_student_screen.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  // Controllers and active filter states
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Newest';
  final Set<String> _selectedDepartments = {};
  final Set<String> _selectedSemesters = {};
  bool? _filterBlacklisted; // null = All, false = Active, true = Blacklisted

  final List<String> _defaultDepartments = [
    'Computer Science',
    'Data Science',
    'Information Technology',
    'Electronics & Communication',
    'Mechanical Engineering',
    'Civil Engineering',
  ];

  final List<String> _defaultSemesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> _getAvailableDepartments(List<Map<String, dynamic>> rawStudents) {
    final depts = rawStudents
        .map((s) => (s['department'] ?? '').toString().trim())
        .where((d) => d.isNotEmpty)
        .toSet();
    return depts.isEmpty ? _defaultDepartments.toSet() : depts;
  }

  Set<String> _getAvailableSemesters(List<Map<String, dynamic>> rawStudents) {
    final sems = rawStudents
        .map((s) => (s['semester'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    return sems.isEmpty ? _defaultSemesters.toSet() : sems;
  }

  int get _activeFiltersCount {
    int count = 0;
    count += _selectedDepartments.length;
    count += _selectedSemesters.length;
    if (_filterBlacklisted != null) count += 1;
    return count;
  }

  void _refreshStudents() {
    ref.read(studentsProvider.notifier).loadStudents();
  }

  List<Map<String, dynamic>> _getFilteredAndSortedStudents(List<Map<String, dynamic>> rawStudents) {
    List<Map<String, dynamic>> results = List.from(rawStudents);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((student) {
        final name = (student['name'] ?? '').toString().toLowerCase();
        final enrollmentId = (student['enrollment_id'] ?? '').toString().toLowerCase();
        final email = (student['contact_email'] ?? '').toString().toLowerCase();
        return name.contains(query) || enrollmentId.contains(query) || email.contains(query);
      }).toList();
    }

    // 2. Department filter
    if (_selectedDepartments.isNotEmpty) {
      results = results.where((student) {
        final dept = (student['department'] ?? 'Dept. Not Assigned').toString();
        return _selectedDepartments.contains(dept);
      }).toList();
    }

    // 3. Semester filter
    if (_selectedSemesters.isNotEmpty) {
      results = results.where((student) {
        final sem = (student['semester'] ?? 'N/A').toString();
        return _selectedSemesters.contains(sem);
      }).toList();
    }

    // 4. Blacklist filter
    if (_filterBlacklisted != null) {
      results = results.where((student) {
        final isBlacklisted = student['is_blacklisted'] ?? false;
        return isBlacklisted == _filterBlacklisted;
      }).toList();
    }

    // 5. Sorting logic
    if (_sortBy == 'Newest') {
      results.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // newest first
      });
    } else if (_sortBy == 'Oldest') {
      results.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime); // oldest first
      });
    } else if (_sortBy == 'A-Z') {
      results.sort((a, b) {
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
    } else if (_sortBy == 'Status') {
      results.sort((a, b) {
        final aBlack = a['is_blacklisted'] ?? false;
        final bBlack = b['is_blacklisted'] ?? false;
        if (aBlack == bBlack) {
          final aName = (a['name'] ?? '').toString().toLowerCase();
          final bName = (b['name'] ?? '').toString().toLowerCase();
          return aName.compareTo(bName);
        }
        return aBlack ? -1 : 1; // Blacklisted first
      });
    }

    return results;
  }

  Future<void> _exportToExcel(List<Map<String, dynamic>> activeStudents) async {
    try {
      final headers = [
        'ID',
        'Enrollment ID',
        'Name',
        'Department',
        'Semester',
        'Contact Email',
        'Phone Number',
        'College',
        'Blacklisted',
        'Created At'
      ];
      
      final rows = activeStudents.map((s) {
        return [
          s['id']?.toString() ?? '',
          s['enrollment_id']?.toString() ?? '',
          s['name']?.toString() ?? '',
          s['department']?.toString() ?? '',
          s['semester']?.toString() ?? '',
          s['contact_email']?.toString() ?? '',
          s['phone_number']?.toString() ?? '',
          s['college']?.toString() ?? '',
          (s['is_blacklisted'] ?? false) ? 'Yes' : 'No',
          s['created_at']?.toString() ?? '',
        ];
      }).toList();

      // Convert rows to CSV string with Excel compatibility
      String csv = '\uFEFF'; // UTF-8 BOM for Excel compatibility
      csv += '${headers.map((h) => '"${h.replaceAll('"', '""')}"').join(',')}\r\n';
      
      for (final row in rows) {
        csv += '${row.map((field) => '"${field.replaceAll('"', '""')}"').join(',')}\r\n';
      }

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final base64Csv = base64Encode(bytes);
        final url = 'data:text/csv;base64,$base64Csv';
        final uri = Uri.parse(url);
        
        await launchUrl(uri);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Student directory exported successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: 'student_directory_${DateTime.now().millisecondsSinceEpoch}.csv',
        );

        if (result == null) return;

        final file = io.File(result.path);
        await file.writeAsString(csv, encoding: utf8);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Records saved to: ${result.path}'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showFilterDialog(List<Map<String, dynamic>> rawStudents) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final depts = _getAvailableDepartments(rawStudents).toList()..sort();
            final sems = _getAvailableSemesters(rawStudents).toList()..sort();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Students',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // ── Department Filter ──
                      const Text(
                        'Departments',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: depts.map((dept) {
                          final isSelected = _selectedDepartments.contains(dept);
                          return FilterChip(
                            label: Text(dept),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  _selectedDepartments.add(dept);
                                } else {
                                  _selectedDepartments.remove(dept);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF0F172A).withValues(alpha: 0.1),
                            checkmarkColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Semester Filter ──
                      const Text(
                        'Semesters',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sems.map((sem) {
                          final isSelected = _selectedSemesters.contains(sem);
                          return FilterChip(
                            label: Text(sem),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  _selectedSemesters.add(sem);
                                } else {
                                  _selectedSemesters.remove(sem);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF0F172A).withValues(alpha: 0.1),
                            checkmarkColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Blacklist Filter ──
                      const Text(
                        'Blacklist Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('All'),
                              selected: _filterBlacklisted == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => _filterBlacklisted = null);
                                }
                              },
                              selectedColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: _filterBlacklisted == null ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Active'),
                              selected: _filterBlacklisted == false,
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => _filterBlacklisted = false);
                                }
                              },
                              selectedColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: _filterBlacklisted == false ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Blacklisted'),
                              selected: _filterBlacklisted == true,
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => _filterBlacklisted = true);
                                }
                              },
                              selectedColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: _filterBlacklisted == true ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Dialog Actions ──
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  _selectedDepartments.clear();
                                  _selectedSemesters.clear();
                                  _filterBlacklisted = null;
                                });
                              },
                              child: const Text('Reset', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteStudent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to permanently delete this student profile and their associated user account? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(studentsProvider.notifier).deleteStudent(id);
        
        final isDevMode = Supabase.instance.client.auth.currentUser == null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDevMode ? 'Student deleted successfully (Dev Mode)' : 'Student deleted successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleBlacklist(String id, bool currentStatus) async {
    try {
      await ref.read(studentsProvider.notifier).toggleBlacklist(id, currentStatus);
      
      final isDevMode = Supabase.instance.client.auth.currentUser == null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? (isDevMode ? 'Student whitelisted (Dev Mode)' : 'Student whitelisted') : (isDevMode ? 'Student blacklisted (Dev Mode)' : 'Student blacklisted')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsProvider);
    final rawStudents = studentsState.students;
    final isLoading = studentsState.isLoading;
    final activeStudents = _getFilteredAndSortedStudents(rawStudents);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Student Directory',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            )),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800; // Increased breakpoint slightly for toolbar

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Search, Filter & Action Toolbar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildFilterButton(rawStudents)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSortDropdown()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildExportButton(activeStudents)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildAddButton(context)),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: _buildSearchField()),
                          const SizedBox(width: 12),
                          _buildFilterButton(rawStudents),
                          const SizedBox(width: 12),
                          SizedBox(width: 140, child: _buildSortDropdown()),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)), // Divider
                          const SizedBox(width: 12),
                          _buildExportButton(activeStudents),
                          const SizedBox(width: 12),
                          _buildAddButton(context),
                        ],
                      ),
              ),

              // ── Interactive Horizontal Scroll Data Table ──
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : activeStudents.isEmpty
                    ? const Center(child: Text('No students found.'))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: isMobile ? 850 : constraints.maxWidth - 40,
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 56), // Avatar spacer
                              Expanded(flex: 3, child: _headerText('STUDENT INFO')),
                              Expanded(flex: 2, child: _headerText('DEPARTMENT')),
                              Expanded(flex: 2, child: _headerText('INTERNSHIP STATUS')),
                              const SizedBox(width: 40), // Action icon spacer
                            ],
                          ),
                        ),
                        // List Content
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: activeStudents.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final student = activeStudents[index];
                              final name = student['name'] ?? 'Unknown';
                              final department = student['department'] ?? 'Dept. Not Assigned';
                              final collegeId = student['college'] ?? 'ID-Not-Set';
                              final semester = student['semester'] ?? 'N/A';
                              
                              final email = student['contact_email'] ?? student['email'] ?? department;
                                
                              // For MVP, we use dummy status since joining applications adds complexity
                              final status = 'Active'; 
                              final company = 'Unassigned';
                              
                              return _buildStudentDashboardTile(
                                name: name,
                                email: email,
                                collegeId: collegeId,
                                department: department,
                                semester: semester,
                                status: status,
                                company: company,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => StudentDetailScreen(
                                        studentId: student['id'].toString(),
                                        studentName: name,
                                        collegeId: collegeId,
                                        status: status,
                                        department: department,
                                        company: company,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == true) _refreshStudents();
                                  });
                                },
                                onEdit: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AddStudentScreen(student: student)),
                                  );
                                  if (result == true) _refreshStudents();
                                },
                                onBlacklist: () => _toggleBlacklist(student['id'], student['is_blacklisted'] ?? false),
                                onDelete: () => _deleteStudent(student['id']),
                                isBlacklisted: student['is_blacklisted'] ?? false,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, ID, or email...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(List<Map<String, dynamic>> rawStudents) {
    final count = _activeFiltersCount;
    final hasFilters = count > 0;
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: hasFilters ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasFilters ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          width: hasFilters ? 1.5 : 1.0,
        ),
      ),
      child: TextButton.icon(
        onPressed: () => _showFilterDialog(rawStudents),
        icon: Badge(
          isLabelVisible: hasFilters,
          label: Text('$count'),
          backgroundColor: const Color(0xFF0F172A),
          child: Icon(
            Icons.filter_list_rounded,
            color: hasFilters ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            size: 18,
          ),
        ),
        label: Text(
          'Filters',
          style: TextStyle(
            color: hasFilters ? const Color(0xFF0F172A) : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
          alignment: AlignmentDirectional.center,
          isExpanded: true,
          items: <String>['Newest', 'Oldest', 'A-Z', 'Status'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text('Sort: $value'),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _sortBy = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildExportButton(List<Map<String, dynamic>> activeStudents) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _exportToExcel(activeStudents),
        icon: const Icon(Icons.download_rounded, size: 18),
        label: const Text('Export', style: TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
          
          if (result == true) {
            _refreshStudents();
          }
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Student', style: TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _headerText(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStudentDashboardTile({
    required String name,
    required String email,
    required String collegeId,
    required String department,
    required String semester,
    required String status,
    required String company,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onBlacklist,
    required VoidCallback onDelete,
    bool isBlacklisted = false,
  }) {
    final isAlert = status == 'Red Alert';
    final isUnassigned = status == 'Unassigned';
    
    return Container(
      decoration: BoxDecoration(
        color: isBlacklisted ? const Color(0xFFFEF2F2).withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlacklisted 
              ? const Color(0xFFFCA5A5) 
              : (isAlert ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)), 
          width: (isBlacklisted || isAlert) ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: (isBlacklisted || isAlert) ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                  foregroundColor: (isBlacklisted || isAlert) ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                  radius: 20,
                  child: Text(name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                
                // Student Info (Flex 3)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBlacklisted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('BLACKLISTED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Department (Flex 2)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        semester,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Status / Company (Flex 2)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(status),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(isUnassigned ? Icons.help_outline_rounded : Icons.domain_rounded, size: 12, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded, 
                    color: isBlacklisted ? Colors.red : const Color(0xFF94A3B8), 
                    size: 20
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'blacklist') onBlacklist();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Edit Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'blacklist',
                      child: Row(
                        children: [
                          Icon(isBlacklisted ? Icons.check_circle_outline : Icons.block_rounded, size: 18, color: isBlacklisted ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Text(isBlacklisted ? 'Whitelist Student' : 'Blacklist Student'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Red Alert') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Text('RED ALERT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
      );
    } else if (status == 'Unassigned') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('UNASSIGNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
      );
    }
  }
}
