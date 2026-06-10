import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFormBuilderScreen extends StatefulWidget {
  final String internshipId;

  const AdminFormBuilderScreen({super.key, required this.internshipId});

  @override
  State<AdminFormBuilderScreen> createState() => _AdminFormBuilderScreenState();
}

class _AdminFormBuilderScreenState extends State<AdminFormBuilderScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadFormSchema();
  }

  Future<void> _loadFormSchema() async {
    try {
      final res = await Supabase.instance.client
          .from('internships')
          .select('feedback_form_schema')
          .eq('id', widget.internshipId)
          .single();

      final schema = res['feedback_form_schema'];
      if (schema != null && schema is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(schema);
        });
      }
    } catch (e) {
      debugPrint('Error loading form schema: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFormSchema() async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('internships')
          .update({'feedback_form_schema': _questions})
          .eq('id', widget.internshipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form schema saved successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving form: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'short_text', // short_text, long_text, multiple_choice
        'question': '',
        'options': <String>['Option 1'], // For multiple choice
        'required': true,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Configure Feedback Form',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveFormSchema,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Form', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined, size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      const Text('No Questions Added',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      const Text('Start building your feedback form.',
                          style: TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _questions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _questions.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 48.0),
                        child: OutlinedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Another Question'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                            foregroundColor: const Color(0xFF3B82F6),
                          ),
                        ),
                      );
                    }

                    final q = _questions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: const Center(
                              child: Icon(Icons.drag_indicator_rounded, size: 20, color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: q['question'],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                        decoration: InputDecoration(
                                          hintText: 'Question Title',
                                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        ),
                                        onChanged: (val) => q['question'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: DropdownButton<String>(
                                          value: q['type'],
                                          isExpanded: true,
                                          underline: const SizedBox(),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                          items: const [
                                            DropdownMenuItem(value: 'short_text', child: Text('Short Text')),
                                            DropdownMenuItem(value: 'long_text', child: Text('Long Text')),
                                            DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => q['type'] = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                if (q['type'] == 'multiple_choice') ...[
                                  ...List.generate((q['options'] as List).length, (optIndex) {
                                    final options = q['options'] as List<String>;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 22),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: options[optIndex],
                                              style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                                border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2)),
                                              ),
                                              onChanged: (val) => options[optIndex] = val,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                                            onPressed: () {
                                              setState(() {
                                                options.removeAt(optIndex);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  Row(
                                    children: [
                                      const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 22),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            (q['options'] as List<String>).add('Option ${(q['options'] as List).length + 1}');
                                          });
                                        },
                                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                                        child: const Text('Add option', style: TextStyle(fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      q['type'] == 'long_text' ? 'Long answer text' : 'Short answer text',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                const Divider(color: Color(0xFFF1F5F9), height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () => _removeQuestion(index),
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF64748B)),
                                      tooltip: 'Delete Question',
                                    ),
                                    const SizedBox(width: 12),
                                    Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                                    const SizedBox(width: 12),
                                    const Text('Required', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                    Switch.adaptive(
                                      value: q['required'] ?? true,
                                      onChanged: (val) {
                                        setState(() => q['required'] = val);
                                      },
                                      activeColor: const Color(0xFF3B82F6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
