import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/supabase_compat.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import '../../../services/turso_database_service.dart';

class VerifyStudentsScreen extends StatefulWidget {
  const VerifyStudentsScreen({super.key});

  @override
  State<VerifyStudentsScreen> createState() => _VerifyStudentsScreenState();
}

class _UploadProgressState {
  final int totalRows;
  final int currentUploaded;
  final int totalToUpload;
  final int skippedCount;
  final String status;

  _UploadProgressState({
    required this.totalRows,
    required this.currentUploaded,
    required this.totalToUpload,
    required this.skippedCount,
    required this.status,
  });

  double get progress {
    if (totalToUpload <= 0) return 0.0;
    return (currentUploaded / totalToUpload).clamp(0.0, 1.0);
  }
}

class _VerifyStudentsScreenState extends State<VerifyStudentsScreen> {
  String _userRole = 'sub_admin';
  bool _isLoading = true;
  bool _isUploading = false;
  int _uploadCurrent = 0;
  int _uploadTotalRows = 0;
  int _uploadToUploadTotal = 0;
  int _uploadSkippedCount = 0;
  String _uploadStatusMessage = '';
  List<Map<String, dynamic>> _pendingStudents = [];
  String _searchQuery = '';
  
  int _currentPage = 1;
  final int _limit = 20;
  int _totalRows = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _loadPendingStudents();
  }

  Future<void> _fetchUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final res = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() {
            _userRole = res['role']?.toString() ?? 'sub_admin';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
  }

  Future<void> _loadPendingStudents() async {
    setState(() => _isLoading = true);
    try {
      int offset = (_currentPage - 1) * _limit;
      final countResult = await TursoDatabaseService.instance.query('SELECT COUNT(*) as count FROM pending_students_verification');
      int totalRows = 0;
      if (countResult.isNotEmpty) {
        totalRows = int.tryParse(countResult.first['count']?.toString() ?? '0') ?? 0;
      }

      final result = await TursoDatabaseService.instance.query('SELECT * FROM pending_students_verification ORDER BY uploaded_at DESC LIMIT $_limit OFFSET $offset');
      if (mounted) {
        setState(() {
          _totalRows = totalRows;
          _pendingStudents = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractCellValue(dynamic cell) {
    if (cell == null) return '';
    final val = cell.value;
    if (val == null) return '';
    try {
      final inner = (val as dynamic).value;
      if (inner != null) return inner.toString().trim();
    } catch (_) {}
    return val.toString().trim();
  }

  List<String> _parseCsvLine(String line) {
    List<String> result = [];
    StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  static Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showUploadSummaryDialog({
    required int totalRows,
    required int uploaded,
    required int skipped,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Upload Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Excel student data processing complete:', style: TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            _buildSummaryRow(Icons.list_alt_rounded, 'Total rows in file:', '$totalRows', Colors.blueGrey),
            const SizedBox(height: 8),
            _buildSummaryRow(Icons.cloud_done_rounded, 'Successfully uploaded:', '$uploaded', const Color(0xFF16A34A)),
            const SizedBox(height: 8),
            _buildSummaryRow(Icons.person_off_rounded, 'Skipped (already exists):', '$skipped', const Color(0xFFD97706)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadExcel() async {
    bool dialogDismissed = false;

    void closeProgressDialog() {
      if (!dialogDismissed && mounted) {
        dialogDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'excel',
        extensions: <String>['xlsx', 'xls', 'csv'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      if (file == null) return;
      if (!mounted) return;

      final progressNotifier = ValueNotifier<_UploadProgressState>(
        _UploadProgressState(
          totalRows: 0,
          currentUploaded: 0,
          totalToUpload: 0,
          skippedCount: 0,
          status: 'Reading and parsing file...',
        ),
      );

      setState(() {
        _isLoading = true;
        _isUploading = true;
        _uploadTotalRows = 0;
        _uploadCurrent = 0;
        _uploadToUploadTotal = 0;
        _uploadSkippedCount = 0;
        _uploadStatusMessage = 'Reading file...';
      });

      // Show live progress modal dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return PopScope(
            canPop: false,
            child: ValueListenableBuilder<_UploadProgressState>(
              valueListenable: progressNotifier,
              builder: (context, state, _) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF6366F1), size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Uploading Students',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.status,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: state.totalToUpload > 0 ? state.progress : null,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.totalToUpload > 0
                                  ? 'Uploading: ${state.currentUploaded} of ${state.totalToUpload}'
                                  : (state.totalRows > 0 ? 'Total rows: ${state.totalRows}' : 'Counting rows...'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              state.totalToUpload > 0
                                  ? '${(state.progress * 100).toInt()}%'
                                  : '...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniMetric('Total Rows', '${state.totalRows}', Colors.blueGrey),
                              Container(width: 1, height: 26, color: Colors.grey.shade300),
                              _buildMiniMetric('Uploaded', '${state.currentUploaded}', const Color(0xFF16A34A)),
                              Container(width: 1, height: 26, color: Colors.grey.shade300),
                              _buildMiniMetric('Skipped', '${state.skippedCount}', const Color(0xFFD97706)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ).then((_) => dialogDismissed = true);

      // Read file and decode
      final bytes = await file.readAsBytes();
      final isCsv = file.name.toLowerCase().endsWith('.csv');
      List<List<String>> extractedRows = [];

      if (isCsv) {
        final content = utf8.decode(bytes, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          extractedRows.add(_parseCsvLine(line));
        }
      } else {
        var excel = Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]?.rows ?? [];
          for (var r in rows) {
            extractedRows.add(r.map((c) => _extractCellValue(c)).toList());
          }
        }
      }

      if (extractedRows.isEmpty) {
        closeProgressDialog();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file is empty')),
          );
        }
        return;
      }

      // Check header row (index 0)
      int startIndex = 0;
      final headerStr = extractedRows[0].join(' ').toLowerCase();
      if (headerStr.contains('usn') ||
          headerStr.contains('seat') ||
          headerStr.contains('roll') ||
          headerStr.contains('name') ||
          headerStr.contains('sl') ||
          headerStr.contains('student')) {
        startIndex = 1;
      }

      List<Map<String, String>> studentRowsToProcess = [];
      for (int i = startIndex; i < extractedRows.length; i++) {
        final row = extractedRows[i];
        if (row.isEmpty) continue;
        final usn = row.isNotEmpty ? row[0].trim() : '';
        final name = row.length > 1 ? row[1].trim() : '';
        final dept = row.length > 2 ? row[2].trim() : '';
        final sem = row.length > 3 ? row[3].trim() : '';

        if (usn.isNotEmpty) {
          studentRowsToProcess.add({
            'usn': usn,
            'name': name.isEmpty ? 'Student' : name,
            'department': dept.isEmpty ? 'General' : dept,
            'semester': sem.isEmpty ? '1st Semester' : sem,
          });
        }
      }

      final totalFoundRows = studentRowsToProcess.length;
      if (totalFoundRows == 0) {
        closeProgressDialog();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No student records found in file')),
          );
        }
        return;
      }

      progressNotifier.value = _UploadProgressState(
        totalRows: totalFoundRows,
        currentUploaded: 0,
        totalToUpload: 0,
        skippedCount: 0,
        status: 'Checking for existing students...',
      );

      if (mounted) {
        setState(() {
          _uploadTotalRows = totalFoundRows;
          _uploadStatusMessage = 'Checking for existing students...';
        });
      }

      // Query existing students in database (both registered students and pending verification)
      final registeredStudents = await TursoDatabaseService.instance.query(
        'SELECT LOWER(enrollment_id) as usn FROM students WHERE enrollment_id IS NOT NULL',
      );
      final existingPending = await TursoDatabaseService.instance.query(
        'SELECT LOWER(usn) as usn FROM pending_students_verification WHERE usn IS NOT NULL',
      );

      final Set<String> existingUsnSet = {};
      for (var r in registeredStudents) {
        final u = r['usn']?.toString().toLowerCase().trim();
        if (u != null && u.isNotEmpty) existingUsnSet.add(u);
      }
      for (var r in existingPending) {
        final u = r['usn']?.toString().toLowerCase().trim();
        if (u != null && u.isNotEmpty) existingUsnSet.add(u);
      }

      // Skip students that already exist before uploading
      List<Map<String, String>> toUpload = [];
      int skippedCount = 0;

      for (var s in studentRowsToProcess) {
        final normUsn = s['usn']!.toLowerCase();
        if (existingUsnSet.contains(normUsn)) {
          skippedCount++;
        } else {
          toUpload.add(s);
          existingUsnSet.add(normUsn); // Avoid duplicates within same file
        }
      }

      // If all students already exist, finish early and display summary
      if (toUpload.isEmpty) {
        progressNotifier.value = _UploadProgressState(
          totalRows: totalFoundRows,
          currentUploaded: 0,
          totalToUpload: 0,
          skippedCount: skippedCount,
          status: 'All $totalFoundRows students already exist!',
        );
        await Future.delayed(const Duration(milliseconds: 600));
        closeProgressDialog();

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          _showUploadSummaryDialog(
            totalRows: totalFoundRows,
            uploaded: 0,
            skipped: skippedCount,
          );
        }
        return;
      }

      final totalToUpload = toUpload.length;
      int currentUploaded = 0;

      if (mounted) {
        setState(() {
          _uploadToUploadTotal = totalToUpload;
          _uploadSkippedCount = skippedCount;
        });
      }

      // Upload in chunks with real-time numeric progress updates
      final int batchSize = totalToUpload <= 10 ? 1 : 10;
      for (int i = 0; i < totalToUpload; i += batchSize) {
        final end = (i + batchSize < totalToUpload) ? i + batchSize : totalToUpload;
        final currentBatch = toUpload.sublist(i, end);

        final batchRequests = currentBatch.map((s) => {
          'sql': 'INSERT INTO pending_students_verification (usn, name, department, semester) VALUES (?, ?, ?, ?) ON CONFLICT(usn) DO UPDATE SET name=excluded.name, department=excluded.department, semester=excluded.semester',
          'params': [s['usn'], s['name'], s['department'], s['semester']],
        }).toList();

        await TursoDatabaseService.instance.batch(batchRequests);
        currentUploaded = end;

        progressNotifier.value = _UploadProgressState(
          totalRows: totalFoundRows,
          currentUploaded: currentUploaded,
          totalToUpload: totalToUpload,
          skippedCount: skippedCount,
          status: 'Uploading $currentUploaded of $totalToUpload students...',
        );

        if (mounted) {
          setState(() {
            _uploadCurrent = currentUploaded;
          });
        }

        // Small pause for smooth visual counter update
        await Future.delayed(const Duration(milliseconds: 40));
      }

      await Future.delayed(const Duration(milliseconds: 350));
      closeProgressDialog();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showUploadSummaryDialog(
          totalRows: totalFoundRows,
          uploaded: currentUploaded,
          skipped: skippedCount,
        );
      }

      _currentPage = 1;
      await _loadPendingStudents();
    } catch (e) {
      closeProgressDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _clearTable() async {
    final confirmCtrl = TextEditingController();
    bool canDelete = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Clear Verification Table?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This will delete all pending students. Are you sure?'),
                const SizedBox(height: 14),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(text: 'Type '),
                      TextSpan(text: '"delete"', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      TextSpan(text: ' to confirm clearing:'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Type "delete" here',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      canDelete = val.trim().toLowerCase() == 'delete';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: canDelete ? () => Navigator.pop(ctx, true) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Clear Table'),
              ),
            ],
          );
        },
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await TursoDatabaseService.instance.execute('DELETE FROM pending_students_verification');
        _currentPage = 1;
        await _loadPendingStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification table cleared')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing table: $e')));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteStudent(String usn, String name) async {
    final confirmCtrl = TextEditingController();
    bool canDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Delete Student'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "$name" ($usn)?'),
                const SizedBox(height: 14),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(text: 'Type '),
                      TextSpan(text: '"delete"', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      TextSpan(text: ' to confirm deletion:'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Type "delete" here',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      canDelete = val.trim().toLowerCase() == 'delete';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canDelete ? () => Navigator.pop(ctx, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await TursoDatabaseService.instance.execute(
          'DELETE FROM pending_students_verification WHERE usn = ?',
          [usn],
        );
        await _loadPendingStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting student: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<dynamic> _buildPaginationItems(int totalPages, int currentPage) {
    if (totalPages <= 5) {
      return List.generate(totalPages, (i) => i + 1);
    }

    if (currentPage <= 3) {
      return [1, 2, 3, '...', totalPages];
    } else if (currentPage >= totalPages - 2) {
      return [1, '...', totalPages - 2, totalPages - 1, totalPages];
    } else {
      return [1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages];
    }
  }

  void _showEditStudentDialog(Map<String, dynamic>? student) {
    final usnCtrl = TextEditingController(text: student?['usn']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: student?['name']?.toString() ?? '');
    final deptCtrl = TextEditingController(text: student?['department']?.toString() ?? '');
    final semCtrl = TextEditingController(text: student?['semester']?.toString() ?? '');
    final bool isEdit = student != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Correct Student Data' : 'Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usnCtrl, decoration: const InputDecoration(labelText: 'University Seat No.'), enabled: !isEdit),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: semCtrl, decoration: const InputDecoration(labelText: 'Semester')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (usnCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await TursoDatabaseService.instance.execute(
                  'INSERT INTO pending_students_verification (usn, name, department, semester) VALUES (?, ?, ?, ?) ON CONFLICT(usn) DO UPDATE SET name=excluded.name, department=excluded.department, semester=excluded.semester',
                  [usnCtrl.text, nameCtrl.text, deptCtrl.text, semCtrl.text],
                );
                await _loadPendingStudents();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving student: $e')));
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _pendingStudents.where((s) {
      final q = _searchQuery.toLowerCase();
      final usn = s['usn'].toString().toLowerCase();
      final name = s['name'].toString().toLowerCase();
      return usn.contains(q) || name.contains(q);
    }).toList();

    final totalPages = (_totalRows / _limit).ceil() < 1 ? 1 : (_totalRows / _limit).ceil();
    final paginationItems = _buildPaginationItems(totalPages, _currentPage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Students'),
        actions: [
          if (_userRole == 'admin' || _userRole == 'sub_admin')
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Clear Verification Table',
              onPressed: _clearTable,
            ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (_isUploading && _uploadTotalRows > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    _uploadToUploadTotal > 0
                        ? 'Uploading $_uploadCurrent of $_uploadToUploadTotal students...'
                        : 'Processing $_uploadTotalRows rows...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_uploadSkippedCount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Skipped $_uploadSkippedCount existing students',
                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (_uploadStatusMessage.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _uploadStatusMessage,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ],
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 650;

                    final searchField = TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by University Seat No. or Name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    );

                    final uploadBtn = ElevatedButton.icon(
                      onPressed: _uploadExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    );

                    final addBtn = ElevatedButton.icon(
                      onPressed: () => _showEditStudentDialog(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    );

                    if (isSmall) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: uploadBtn),
                              const SizedBox(width: 10),
                              Expanded(child: addBtn),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 10),
                          uploadBtn,
                          const SizedBox(width: 10),
                          addBtn,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: filteredList.isEmpty
                    ? const Center(child: Text('No pending students found.'))
                    : Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // Sticky Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 2, child: Text('University Seat No.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                                      Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                                      SizedBox(width: 48), // Space for action menu icon
                                    ],
                                  ),
                                ),
                                // Scrollable Body with padding at the bottom
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 90), // Prevents overlap with floating pagination
                                    itemCount: filteredList.length,
                                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                                    itemBuilder: (context, index) {
                                      final s = filteredList[index];
                                      return InkWell(
                                        onTap: () => _showEditStudentDialog(s),
                                        hoverColor: Colors.blue.withValues(alpha: 0.05),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              Expanded(flex: 2, child: Text(s['usn']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                                              Expanded(flex: 3, child: Text(s['name']?.toString() ?? '')),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.blueGrey),
                                                tooltip: 'Actions',
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showEditStudentDialog(s);
                                                  } else if (value == 'delete') {
                                                    _deleteStudent(s['usn']?.toString() ?? '', s['name']?.toString() ?? '');
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                                        SizedBox(width: 10),
                                                        Text('Edit Student'),
                                                      ],
                                                    ),
                                                  ),
                                                  if (_userRole == 'admin' || _userRole == 'sub_admin')
                                                    const PopupMenuItem<String>(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                                          SizedBox(width: 10),
                                                          Text('Delete Student', style: TextStyle(color: Colors.red)),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _currentPage > 1 ? () {
                                        setState(() => _currentPage--);
                                        _loadPendingStudents();
                                      } : null,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: paginationItems.map((item) {
                                        if (item is String) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }
                                        final p = item as int;
                                        final isSelected = _currentPage == p;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2),
                                          child: InkWell(
                                            onTap: () {
                                              if (!isSelected) {
                                                setState(() => _currentPage = p);
                                                _loadPendingStudents();
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.blueAccent : Colors.transparent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '$p',
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.black87,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: _currentPage < totalPages ? () {
                                        setState(() => _currentPage++);
                                        _loadPendingStudents();
                                      } : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
    );
  }
}
