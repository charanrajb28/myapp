import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_detail_screen.dart';
import 'add_student_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('*')
          .order('created_at');

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
        // Find user_id from students first
        final student = _students.firstWhere((s) => s['id'] == id);
        final userId = student['user_id'];
        
        await Supabase.instance.client.from('users').delete().eq('id', userId);
        _fetchStudents();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggleBlacklist(String id, bool currentStatus) async {
    try {
      await Supabase.instance.client.from('students').update({'is_blacklisted': !currentStatus}).eq('id', id);
      _fetchStudents();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStatus ? 'Student whitelisted' : 'Student blacklisted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              Expanded(child: _buildFilterButton()),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSortDropdown()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildExportButton()),
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
                          _buildFilterButton(),
                          const SizedBox(width: 12),
                          _buildSortDropdown(),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)), // Divider
                          const SizedBox(width: 12),
                          _buildExportButton(),
                          const SizedBox(width: 12),
                          _buildAddButton(context),
                        ],
                      ),
              ),

              // ── Interactive Horizontal Scroll Data Table ──
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
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
                            itemCount: _students.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final name = student['name'] ?? 'Unknown';
                              final department = student['department'] ?? 'Dept. Not Assigned';
                              final collegeId = student['college'] ?? 'ID-Not-Set';
                              
                              final email = department;
                                
                              // For MVP, we use dummy status since joining applications adds complexity
                              final status = 'Active'; 
                              final company = 'Unassigned';
                              
                              return _buildStudentDashboardTile(
                                name: name,
                                email: email,
                                collegeId: collegeId,
                                department: department,
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
                                    if (value == true) _fetchStudents();
                                  });
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
        decoration: InputDecoration(
          hintText: 'Search by name, ID, or email...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
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

  Widget _buildFilterButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF0F172A), size: 18),
        label: const Text('Filters', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
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
          value: 'Newest',
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
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {},
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
            _fetchStudents(); // Refresh the list
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
    required String status,
    required String company,
    required VoidCallback onTap,
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
                        collegeId,
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
                    if (value == 'blacklist') onBlacklist();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
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
                          const SizedBox(width: 8),
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
