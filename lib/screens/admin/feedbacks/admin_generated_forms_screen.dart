import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_form_responses_screen.dart';

class AdminGeneratedFormsScreen extends StatefulWidget {
  const AdminGeneratedFormsScreen({super.key});

  @override
  State<AdminGeneratedFormsScreen> createState() => _AdminGeneratedFormsScreenState();
}

class _AdminGeneratedFormsScreenState extends State<AdminGeneratedFormsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _forms = [];

  @override
  void initState() {
    super.initState();
    _fetchForms();
  }

  Future<void> _fetchForms() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('internships')
          .select('id, role, company_id, feedback_form_schema, companies(name)')
          .not('feedback_form_schema', 'is', null)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _forms = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching generated forms: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading forms: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Generated Forms', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forms.isEmpty
              ? const Center(
                  child: Text('No feedback forms generated yet.', style: TextStyle(color: Color(0xFF64748B))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _forms.length,
                  itemBuilder: (context, index) {
                    final form = _forms[index];
                    final schema = form['feedback_form_schema'] as List?;
                    final numQuestions = schema?.length ?? 0;
                    final companyName = form['companies']?['name'] ?? 'Unknown Company';
                    final role = form['role'] ?? 'Unknown Role';

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text('$role @ $companyName', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        subtitle: Text('$numQuestions questions', style: const TextStyle(color: Color(0xFF64748B))),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminFormResponsesScreen(
                                internshipId: form['id'].toString(),
                                companyId: form['company_id'].toString(),
                                roleTitle: role,
                                companyName: companyName,
                                schema: schema ?? [],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
