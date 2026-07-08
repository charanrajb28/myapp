import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/more_options_screen.dart'; // for Sub-Admins Management Dialog if needed

class AdminsListScreen extends StatefulWidget {
  const AdminsListScreen({super.key});

  @override
  State<AdminsListScreen> createState() => _AdminsListScreenState();
}

class _AdminsListScreenState extends State<AdminsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Newest';
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
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

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        // Dev Mode Mocking: Read from shared static list (only sub_admins)
        setState(() {
          _admins = SubAdminsManagementDialog.mockAdmins
              .where((admin) => admin['role'] == 'sub_admin')
              .toList();
          _isLoading = false;
        });
        return;
      }

      final res = await supabase
          .from('users')
          .select('*')
          .eq('role', 'sub_admin');
      
      if (mounted) {
        setState(() {
          _admins = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admins: $e');
      if (mounted) {
        setState(() {
          _admins = [
            {
              'name': 'System Admin',
              'email': 'admin@scholarbridge.com',
              'role': 'admin',
              'created_at': DateTime.now().toIso8601String(),
            }
          ];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _revokeSubAdmin(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Sub-Admin Access'),
        content: Text('Are you sure you want to revoke sub-admin access for $email? This will permanently disable their admin panel access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        // Dev Mode Mocking: remove from shared static list
        SubAdminsManagementDialog.mockAdmins.removeWhere((admin) => admin['email'] == email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sub-Admin access revoked successfully! (Dev Mode)'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _fetchAdmins();
        return;
      }

      // Delete from sub_admins table
      await supabase.from('sub_admins').delete().eq('user_id', userId);
      // Delete from users table
      await supabase.from('users').delete().eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sub-Admin access revoked successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _fetchAdmins();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke sub-admin: $e'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showEditAdminDialog(Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (ctx) => EditSubAdminDialog(
        admin: admin,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sub-Admin updated successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          _fetchAdmins();
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAndSortedAdmins() {
    List<Map<String, dynamic>> results = List.from(_admins);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((admin) {
        final name = (admin['name'] ?? '').toString().toLowerCase();
        final email = (admin['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // 2. Sorting logic
    if (_sortBy == 'Newest') {
      results.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    } else if (_sortBy == 'Oldest') {
      results.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
    } else if (_sortBy == 'A-Z') {
      results.sort((a, b) {
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
    }

    return results;
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SubAdminsManagementDialog(
        onSuccess: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          _fetchAdmins();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAdmins = _getFilteredAndSortedAdmins();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Directory',
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
          final isMobile = constraints.maxWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Search & Action Toolbar ──
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
                              Expanded(child: _buildSortDropdown()),
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
                          SizedBox(width: 140, child: _buildSortDropdown()),
                          const SizedBox(width: 12),
                          _buildAddButton(context),
                        ],
                      ),
              ),

              // ── Interactive Horizontal Scroll Data Table ──
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : activeAdmins.isEmpty
                        ? const Center(child: Text('No admins found.'))
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
                                        Expanded(flex: 3, child: _headerText('ADMIN INFO')),
                                        Expanded(flex: 2, child: _headerText('EMAIL ADDRESS')),
                                        Expanded(flex: 2, child: _headerText('ACCESS LEVEL')),
                                      ],
                                    ),
                                  ),
                                  // List Content
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      itemCount: activeAdmins.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final admin = activeAdmins[index];
                                        final name = admin['name'] ?? 'Unknown';
                                        final email = admin['email'] ?? '';
                                        final role = admin['role'] ?? 'admin';
                                        final isSubAdmin = role == 'sub_admin';

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.01),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: isSubAdmin
                                                  ? () => _showEditAdminDialog(admin)
                                                  : null,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  children: [
                                                    // Avatar
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor: isSubAdmin
                                                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                                          : const Color(0xFF0F172A).withValues(alpha: 0.1),
                                                      child: Icon(
                                                        isSubAdmin ? Icons.admin_panel_settings : Icons.shield_rounded,
                                                        color: isSubAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF0F172A),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Name & ID
                                                    Expanded(
                                                      flex: 3,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                                          const SizedBox(height: 2),
                                                          Text(isSubAdmin ? 'Sub-Admin Account' : 'Primary Super Admin', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                                        ],
                                                      ),
                                                    ),
                                                    // Email
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                                                    ),
                                                    // Access Level Badge
                                                    Expanded(
                                                      flex: 2,
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: isSubAdmin
                                                                ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                                                                : const Color(0xFF10B981).withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            isSubAdmin ? 'RESTRICTED' : 'FULL ACCESS',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: isSubAdmin ? const Color(0xFFD97706) : const Color(0xFF059669),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (isSubAdmin) ...[
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                                        tooltip: 'Edit Profile',
                                                        onPressed: () => _showEditAdminDialog(admin),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                                        tooltip: 'Revoke Access',
                                                        onPressed: () => _revokeSubAdmin(admin['id'] ?? admin['email'] ?? '', email),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
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
          hintText: 'Search admins by name or email...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
          items: const [
            DropdownMenuItem(value: 'Newest', child: Text('Newest')),
            DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
            DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _sortBy = val);
          },
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: _showAddAdminDialog,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('ADD SUB-ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
    );
  }
}

class EditSubAdminDialog extends StatefulWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onSuccess;

  const EditSubAdminDialog({required this.admin, required this.onSuccess, super.key});

  @override
  State<EditSubAdminDialog> createState() => _EditSubAdminDialogState();
}

class _EditSubAdminDialogState extends State<EditSubAdminDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin['name']?.toString());
    _emailController = TextEditingController(text: widget.admin['email']?.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateSubAdmin() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _updating = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = widget.admin['id'] ?? widget.admin['email'] ?? '';
      
      if (supabase.auth.currentUser == null) {
        // Dev Mode Mocking
        final index = SubAdminsManagementDialog.mockAdmins.indexWhere((a) => a['email'] == widget.admin['email']);
        if (index != -1) {
          SubAdminsManagementDialog.mockAdmins[index]['name'] = name;
        }
        widget.onSuccess();
        Navigator.pop(context);
        return;
      }

      await supabase.from('users').update({
        'name': name,
      }).eq('id', userId);

      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Sub-Admin Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UPDATE SUB-ADMIN DETAILS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Full Name',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Official Email ID',
              filled: true,
              fillColor: const Color(0xFFE2E8F0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: _updating ? null : _updateSubAdmin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: _updating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('SAVE CHANGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
