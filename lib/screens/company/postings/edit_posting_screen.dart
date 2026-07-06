import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPostingScreen extends StatefulWidget {
  final Map<String, dynamic> posting;
  const EditPostingScreen({super.key, required this.posting});

  @override
  State<EditPostingScreen> createState() => _EditPostingScreenState();
}

class _EditPostingScreenState extends State<EditPostingScreen> {
  late TextEditingController roleController;
  late TextEditingController descController;
  late TextEditingController stipendController;
  late TextEditingController durationController;
  late TextEditingController notesController;

  final TextEditingController _taskInputController = TextEditingController();
  late TextEditingController activeDurationController;
  final TextEditingController _locationSearchController = TextEditingController();

  late DateTime _selectedDeadline;
  bool isRemote  = true;
  bool _isSaving = false;

  // Location search state
  String? _selectedLocationAddress;
  double? _selectedLat;
  double? _selectedLng;
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _searchingLocation = false;
  Timer? _locationDebounce;
  final _locationSearchFocus = FocusNode();

  // Tasks list (loaded from responsibilities[])
  late List<String> _tasks;

  // Days of the week state
  static const List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late Set<String> _activeDays;

  @override
  void initState() {
    super.initState();
    roleController     = TextEditingController(text: widget.posting['role']?.toString() ?? '');
    descController     = TextEditingController(text: widget.posting['about']?.toString() ?? '');
    stipendController  = TextEditingController(text: widget.posting['stipend']?.toString() ?? '');
    durationController = TextEditingController(text: widget.posting['duration']?.toString() ?? '');
    notesController    = TextEditingController(text: widget.posting['notes']?.toString() ?? '');
    activeDurationController = TextEditingController(
        text: widget.posting['application_duration_days']?.toString() ?? '7');

    // Pre-populate tasks from responsibilities array
    final rawTasks = widget.posting['responsibilities'];
    _tasks = rawTasks is List
        ? rawTasks.map((t) => t.toString()).where((t) => t.isNotEmpty).toList()
        : [];

    // Location
    isRemote = (widget.posting['location']?.toString().toLowerCase() ?? 'remote') == 'remote';
    if (!isRemote) {
      _selectedLocationAddress = widget.posting['location_address']?.toString();
      _selectedLat = double.tryParse(widget.posting['location_lat']?.toString() ?? '');
      _selectedLng = double.tryParse(widget.posting['location_lng']?.toString() ?? '');
      if (_selectedLocationAddress != null) {
        _locationSearchController.text = _selectedLocationAddress!;
      }
    }

    final parsedDeadline = DateTime.tryParse(widget.posting['deadline']?.toString() ?? '');
    _selectedDeadline = parsedDeadline ?? DateTime.now().add(const Duration(days: 30));

    // Pre-populate active days (default Mon–Fri if absent)
    final rawDays = widget.posting['active_days'];
    _activeDays = (rawDays is List && rawDays.isNotEmpty)
        ? rawDays.map((d) => d.toString()).toSet()
        : {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  }

  @override
  void dispose() {
    roleController.dispose();
    descController.dispose();
    stipendController.dispose();
    durationController.dispose();
    notesController.dispose();
    _taskInputController.dispose();
    activeDurationController.dispose();
    _locationSearchController.dispose();
    _locationSearchFocus.dispose();
    _locationDebounce?.cancel();
    super.dispose();
  }

  void _addTask() {
    final text = _taskInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(text);
      _taskInputController.clear();
    });
  }

  void _removeTask(int index) => setState(() => _tasks.removeAt(index));

  // ── Location Search (OpenStreetMap Nominatim) ────────────────────────────────

  void _onLocationQueryChanged(String query) {
    _locationDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _locationSuggestions = []);
      return;
    }
    _locationDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchLocationSuggestions(query.trim());
    });
  }

  Future<void> _fetchLocationSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _searchingLocation = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&addressdetails=1&limit=6',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'InternshipApp/1.0 (internship.app@example.com)',
        'Accept-Language': 'en',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _locationSuggestions = data
              .map((item) => {
                    'display_name': item['display_name']?.toString() ?? '',
                    'short_name': _buildShortName(item),
                    'lat': double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
                    'lng': double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
                  })
              .toList();
          _searchingLocation = false;
        });
      } else {
        setState(() { _locationSuggestions = []; _searchingLocation = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _locationSuggestions = []; _searchingLocation = false; });
    }
  }

  String _buildShortName(dynamic item) {
    final addr = item['address'];
    if (addr == null) return item['display_name']?.toString() ?? '';
    final parts = <String>[];
    for (final key in ['amenity', 'building', 'road', 'neighbourhood', 'suburb',
        'city', 'town', 'village', 'county', 'state', 'country']) {
      final v = addr[key]?.toString();
      if (v != null && v.isNotEmpty && !parts.contains(v)) parts.add(v);
      if (parts.length >= 3) break;
    }
    return parts.isEmpty ? item['display_name']?.toString() ?? '' : parts.join(', ');
  }

  void _selectLocation(Map<String, dynamic> suggestion) {
    setState(() {
      _selectedLocationAddress = suggestion['short_name'];
      _selectedLat = suggestion['lat'];
      _selectedLng = suggestion['lng'];
      _locationSearchController.text = suggestion['short_name'];
      _locationSuggestions = [];
    });
    _locationSearchFocus.unfocus();
  }

  void _clearLocation() {
    setState(() {
      _selectedLocationAddress = null;
      _selectedLat = null;
      _selectedLng = null;
      _locationSearchController.clear();
      _locationSuggestions = [];
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _savePosting() async {
    if (roleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required job details.')));
      return;
    }
    if (!isRemote && (_selectedLocationAddress == null || _selectedLocationAddress!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an on-site location.')));
      return;
    }
    if (_activeDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one active day.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sortedDays = _allDays.where((d) => _activeDays.contains(d)).toList();

      await Supabase.instance.client.from('internships').update({
        'role'            : roleController.text.trim(),
        'about'           : descController.text.trim(),
        'stipend'         : stipendController.text.trim(),
        'duration'        : durationController.text.trim(),
        'location'        : isRemote ? 'Remote' : 'On-site',
        'location_address': isRemote ? null : _selectedLocationAddress,
        'location_lat'    : isRemote ? null : _selectedLat,
        'location_lng'    : isRemote ? null : _selectedLng,
        'responsibilities': _tasks,
        'notes'           : notesController.text.trim(),
        'active_days'     : sortedDays,
        'application_duration_days': int.tryParse(activeDurationController.text.trim()) ?? 7,
        'deadline'        : DateTime(
          _selectedDeadline.year,
          _selectedDeadline.month,
          _selectedDeadline.day,
        ).toIso8601String(),
      }).eq('id', widget.posting['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posting updated successfully!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update posting: $e')));
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline.isBefore(now) ? now : _selectedDeadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDeadline = picked);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('EDIT_POSTING_CONSOLE',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('> METADATA_TERMINAL'),
                const SizedBox(height: 24),
                _field('ROLE_TITLE_LABEL', roleController),
                const SizedBox(height: 20),
                _field('MISSION_DESCRIPTION_LOG', descController, maxLines: 4),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(child: _field('STIPEND (INR)', stipendController, isNumeric: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _field('DURATION (MO)', durationController, isNumeric: true)),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _deadlineField()),
                  const SizedBox(width: 16),
                  Expanded(child: _field('APP ACTIVE DURATION (DAYS)', activeDurationController, isNumeric: true)),
                ]),
                const SizedBox(height: 32),

                // ── Location ──────────────────────────────────────────────
                _label('> LOCATION_SELECT_TERMINAL'),
                const SizedBox(height: 16),
                _locationOption(),
                const SizedBox(height: 32),

                // ── Days Active ───────────────────────────────────────────
                _label('> ACTIVE_DAYS_SCHEDULE'),
                const SizedBox(height: 8),
                const Text('Select which days interns are expected to be active',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _dayPickerSection(),
                const SizedBox(height: 32),

                // ── Task List ─────────────────────────────────────────────
                _label('> TASK_LIST'),
                const SizedBox(height: 8),
                const Text('Add individual tasks the intern will be responsible for',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _taskListSection(),
                const SizedBox(height: 32),

                // ── Notes ─────────────────────────────────────────────────
                _label('> NOTES_LOG'),
                const SizedBox(height: 8),
                const Text('Internal notes, special requirements, or any extra info',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _notesField(),
                const SizedBox(height: 48),

                _commitBtn(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSaving)
            Container(
                color: Colors.white60,
                child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 2));

  Widget _locationOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _locBtn('REMOTE_IN', isRemote, () => setState(() { isRemote = true; _clearLocation(); })),
          const SizedBox(width: 12),
          _locBtn('ONSITE_HQ', !isRemote, () => setState(() => isRemote = false)),
        ]),
        if (!isRemote) ...[
          const SizedBox(height: 16),
          _locationSearchField(),
        ],
      ],
    );
  }

  Widget _locationSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OFFICE LOCATION',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),

        if (_selectedLocationAddress != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedLocationAddress!,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _clearLocation,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _clearLocation,
            child: const Text(
              'Change location',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          TextField(
            controller: _locationSearchController,
            focusNode: _locationSearchFocus,
            onChanged: _onLocationQueryChanged,
            style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search city, area or office address…',
              hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF6366F1))))
                  : (_locationSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF94A3B8), size: 18),
                          onPressed: () {
                            _locationSearchController.clear();
                            setState(() => _locationSuggestions = []);
                          })
                      : null),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),

          if (_locationSuggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _locationSuggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, i) {
                  final s = _locationSuggestions[i];
                  return InkWell(
                    onTap: () => _selectLocation(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Color(0xFF6366F1), size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['short_name'],
                                  style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                if (s['display_name'] != s['short_name']) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    s['display_name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (!_searchingLocation &&
              _locationSearchController.text.length >= 3 &&
              _locationSuggestions.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 16),
                  SizedBox(width: 10),
                  Text('No locations found. Try a different search.',
                      style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _locBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                width: 1.5),
            boxShadow: active
                ? [BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _taskListSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskInputController,
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Write unit tests for the API',
                      hintStyle: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addTask(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTask,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 5),
                        Text('ADD TASK',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_tasks.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) => _taskItem(index),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 16),
              child: Text('No tasks added yet',
                  style: TextStyle(
                      color: const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _taskItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 9,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_tasks[index],
                style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () => _removeTask(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFEF4444), size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: notesController,
        maxLines: 5,
        style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.6),
        decoration: const InputDecoration(
          hintText: 'Any special requirements, work culture info, tools used, etc.',
          hintStyle:
              TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w400),
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dayPickerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: _allDays
                .map((day) => Expanded(child: _dayChip(day)))
                .toList(),
          ),
          if (_activeDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_buildActiveDaySummary(),
                      style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayChip(String day) {
    final isSelected = _activeDays.contains(day);
    final isWeekend  = day == 'Sat' || day == 'Sun';
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _activeDays.remove(day);
        } else {
          _activeDays.add(day);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            day.substring(0, isWeekend ? 3 : 1),
            style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  String _buildActiveDaySummary() {
    final sorted = _allDays.where((d) => _activeDays.contains(d)).toList();
    if (sorted.length == 7) return 'All days — 7 days/week';
    if (sorted.length == 5 &&
        !_activeDays.contains('Sat') &&
        !_activeDays.contains('Sun')) return 'Monday to Friday — 5 days/week';
    return '${sorted.join(', ')} — ${sorted.length} day${sorted.length == 1 ? '' : 's'}/week';
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType:
              isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _deadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('> SELECTION_DEADLINE',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDeadline),
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: Color(0xFF94A3B8), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _commitBtn(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _savePosting,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('COMMIT_CHANGES',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background decorations ────────────────────────────────────────────────────

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
        child: CustomPaint(painter: _DotPainter()),
      );
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
