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

class _VerifyStudentsScreenState extends State<VerifyStudentsScreen> {
  String _userRole = 'sub_admin';
  bool _isLoading = true;
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

  Future<void> _uploadExcel() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'excel',
        extensions: <String>['xlsx', 'xls', 'csv'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file != null) {
        setState(() => _isLoading = true);
        var bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        
        List<Map<String, dynamic>> newStudents = [];
        
        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]?.rows ?? [];
          // Skip header row usually index 0
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 4) {
              String usn = row[0]?.value?.toString() ?? '';
              String name = row[1]?.value?.toString() ?? '';
              String department = row[2]?.value?.toString() ?? '';
              String semester = row[3]?.value?.toString() ?? '';
              
              if (usn.isNotEmpty) {
                newStudents.add({
                  'usn': usn,
                  'name': name,
                  'department': department,
                  'semester': semester,
                });
              }
            }
          }
        }

        // Insert into database
        for (var s in newStudents) {
          await TursoDatabaseService.instance.execute(
            'INSERT INTO pending_students_verification (usn, name, department, semester) VALUES (?, ?, ?, ?) ON CONFLICT(usn) DO UPDATE SET name=excluded.name, department=excluded.department, semester=excluded.semester',
            [s['usn'], s['name'], s['department'], s['semester']],
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful')));
        }
        _currentPage = 1;
        await _loadPendingStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
        setState(() => _isLoading = false);
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
        ? const Center(child: CircularProgressIndicator())
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
