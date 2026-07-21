import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manage_postings_screen.dart';

class CreatePostingScreen extends StatefulWidget {
  const CreatePostingScreen({super.key});

  @override
  State<CreatePostingScreen> createState() => _CreatePostingScreenState();
}

class _CreatePostingScreenState extends State<CreatePostingScreen> {
  final roleController         = TextEditingController(text: 'Sales & HR Operations Intern');
  final descController         = TextEditingController(text: 'We are seeking an enthusiastic intern to manage outbound sales outreach and coordinate recruiter/HR activities. This opportunity is ideal for B.Com, BBA, and MBA graduates looking to build a career in sales, recruitment, or business operations.');
  final stipendController      = TextEditingController(text: '15000');
  final durationController     = TextEditingController(text: '3');
  final notesController        = TextEditingController(text: 'Candidate must have excellent communication, basic Excel skills, and a laptop.');
  final _taskInputController   = TextEditingController();
  final activeDurationController = TextEditingController(text: '7');
  final vacanciesController    = TextEditingController(text: '1');
  final _locationSearchController = TextEditingController();

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  DateTime _expectedStartDate = DateTime.now().add(const Duration(days: 15));
  String _durationUnit = 'Months';
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

  // Tasks list
  final List<String> _tasks = [
    'Identify and research potential leads for corporate sales',
    'Screen resume applications and schedule interviews for the HR team',
    'Assist in onboarding new recruits and maintaining student records',
    'Prepare weekly reports on sales pipelines and recruitment status'
  ];

  String _selectedIndustry = 'Marketing & Sales';
  final _customIndustryController = TextEditingController();
  List<String> _industriesList = [
    'E-Commerce',
    'Retail & Wholesale',
    'Logistics & Supply Chain',
    'Marketing & Sales',
    'Fintech & Finance',
    'E-Commerce Operations',
    'Digital Marketing',
    'Business Analytics',
    'Customer Support',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadDynamicIndustries();
  }

  Future<void> _loadDynamicIndustries() async {
    try {
      final response = await Supabase.instance.client
          .from('internships')
          .select('industry');
      if (response != null && response is List) {
        final dbIndustries = response
            .map((item) => item['industry']?.toString().trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
        
        setState(() {
          _industriesList.remove('Other');
          for (final ind in dbIndustries) {
            if (!_industriesList.contains(ind)) {
              _industriesList.add(ind);
            }
          }
          _industriesList.add('Other');
        });
      }
    } catch (e) {
      debugPrint('Error loading dynamic industries: $e');
    }
  }

  // Eligible departments state
  static const List<String> _allDepartments = [
    'B.Com LSCM',
    'B.Com A&F',
    'B.Com (Regular)',
    'BCA',
    'BBA',
  ];
  final Set<String> _eligibleDepartments = {
    'B.Com LSCM',
    'B.Com A&F',
    'B.Com (Regular)',
    'BCA',
    'BBA',
  };

  // Eligible years state
  static const List<String> _allYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
  ];
  final Set<String> _eligibleYears = {
    '1st Year',
    '2nd Year',
    '3rd Year',
  };

  // Days of the week state
  static const List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _activeDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

  @override
  void dispose() {
    roleController.dispose();
    descController.dispose();
    stipendController.dispose();
    durationController.dispose();
    notesController.dispose();
    _taskInputController.dispose();
    activeDurationController.dispose();
    vacanciesController.dispose();
    _locationSearchController.dispose();
    _locationSearchFocus.dispose();
    _locationDebounce?.cancel();
    _customIndustryController.dispose();
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

  void _removeTask(int index) {
    setState(() => _tasks.removeAt(index));
  }

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

  static const List<Map<String, dynamic>> _fallbackLocations = [
    {'short_name': 'Bengaluru, Karnataka', 'display_name': 'Bengaluru, Karnataka, India', 'lat': 12.9716, 'lng': 77.5946},
    {'short_name': 'Mumbai, Maharashtra', 'display_name': 'Mumbai, Maharashtra, India', 'lat': 19.0760, 'lng': 72.8777},
    {'short_name': 'Delhi, NCR', 'display_name': 'Delhi, National Capital Region, India', 'lat': 28.7041, 'lng': 77.1025},
    {'short_name': 'Hyderabad, Telangana', 'display_name': 'Hyderabad, Telangana, India', 'lat': 17.3850, 'lng': 78.4867},
    {'short_name': 'Pune, Maharashtra', 'display_name': 'Pune, Maharashtra, India', 'lat': 18.5204, 'lng': 73.8567},
    {'short_name': 'Chennai, Tamil Nadu', 'display_name': 'Chennai, Tamil Nadu, India', 'lat': 13.0827, 'lng': 80.2707},
    {'short_name': 'Gurugram, Haryana', 'display_name': 'Gurugram, Haryana, India', 'lat': 28.4595, 'lng': 77.0266},
    {'short_name': 'Noida, Uttar Pradesh', 'display_name': 'Noida, Uttar Pradesh, India', 'lat': 28.5355, 'lng': 77.3910},
    {'short_name': 'San Francisco, CA', 'display_name': 'San Francisco, California, United States', 'lat': 37.7749, 'lng': -122.4194},
    {'short_name': 'New York, NY', 'display_name': 'New York City, New York, United States', 'lat': 40.7128, 'lng': -74.0060},
    {'short_name': 'London, UK', 'display_name': 'London, Greater London, United Kingdom', 'lat': 51.5074, 'lng': -0.1278},
    {'short_name': 'Seattle, WA', 'display_name': 'Seattle, Washington, United States', 'lat': 47.6062, 'lng': -122.3321},
    {'short_name': 'Boston, MA', 'display_name': 'Boston, Massachusetts, United States', 'lat': 42.3601, 'lng': -71.0589},
  ];

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
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept-Language': 'en',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
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
          return;
        }
      }
      _useFallbackSuggestions(query);
    } catch (_) {
      if (mounted) {
        _useFallbackSuggestions(query);
      }
    }
  }

  void _useFallbackSuggestions(String query) {
    final filtered = _fallbackLocations
        .where((loc) =>
            loc['short_name']!.toLowerCase().contains(query.toLowerCase()) ||
            loc['display_name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      _locationSuggestions = filtered;
      _searchingLocation = false;
    });
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

  // ── Publish ──────────────────────────────────────────────────────────────────

  Future<void> _publishPosting() async {
    if (roleController.text.isEmpty || descController.text.isEmpty) {
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
    if (_eligibleDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one target department.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user     = supabase.auth.currentUser;
      if (user == null) return;

      final companyRes = await supabase
          .from('companies')
          .select('id, name')
          .eq('user_id', user.id)
          .single();

      final companyId   = companyRes['id'];
      final colors      = ['#6366F1', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444'];
      final randomColor = colors[DateTime.now().millisecond % colors.length];
      final sortedDays  = _allDays.where((d) => _activeDays.contains(d)).toList();
      final sortedDepts = _allDepartments.where((d) => _eligibleDepartments.contains(d)).toList();
      final sortedYears = _allYears.where((y) => _eligibleYears.contains(y)).toList();

      final finalIndustry = _selectedIndustry == 'Other'
          ? (_customIndustryController.text.trim().isNotEmpty ? _customIndustryController.text.trim() : 'Other')
          : _selectedIndustry;

      await supabase.from('internships').insert({
        'company_id'  : companyId,
        'role'        : roleController.text.trim(),
        'about'       : descController.text.trim(),
        'stipend'     : stipendController.text.trim(),
        'duration'    : '${durationController.text.trim()} $_durationUnit',
        'industry'    : finalIndustry,
        'location'    : isRemote ? 'Remote' : 'On-site',
        'location_address': isRemote ? null : _selectedLocationAddress,
        'location_lat': isRemote ? null : _selectedLat,
        'location_lng': isRemote ? null : _selectedLng,
        'brand_color' : randomColor,
        'status'      : 'UNDER_REVIEW',
        'logo_initial': (companyRes['name'] as String).isNotEmpty
            ? (companyRes['name'] as String)[0].toUpperCase()
            : 'C',
        'responsibilities': _tasks,
        'notes'       : notesController.text.trim(),
        'active_days' : sortedDays,
        'eligible_departments': sortedDepts,
        'eligible_years': sortedYears,
        'application_duration_days': int.tryParse(activeDurationController.text.trim()) ?? 7,
        'vacancies'   : int.tryParse(vacanciesController.text.trim()) ?? 1,
        'deadline'    : DateTime(
          _selectedDeadline.year,
          _selectedDeadline.month,
          _selectedDeadline.day,
        ).toIso8601String(),
        'start_date'  : DateTime(
          _expectedStartDate.year,
          _expectedStartDate.month,
          _expectedStartDate.day,
        ).toIso8601String().split('T')[0],
        'end_date'    : _calculateEndDate(
          _expectedStartDate,
          durationController.text,
          _durationUnit,
          _activeDays,
        ).toIso8601String().split('T')[0],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error publishing posting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('CREATE NEW JOB POST',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
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
                _sectionLabel('JOB DETAILS'),
                const SizedBox(height: 24),
                _industrialField('JOB TITLE', roleController,
                    hint: 'e.g. Mobile Developer'),
                const SizedBox(height: 20),
                _industrialField('JOB DESCRIPTION', descController,
                    maxLines: 4, hint: 'What will the intern do?'),
                const SizedBox(height: 20),
                _categoryDropdownField(),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                      child: _industrialField('STIPEND (INR)', stipendController,
                          isNumeric: true, hint: 'e.g. 15000')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _durationField()),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _deadlineField()),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _industrialField('APP ACTIVE DURATION (DAYS)', activeDurationController,
                          isNumeric: true, hint: 'e.g. 7')),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _industrialField('VACANCIES AVAILABLE', vacanciesController,
                          isNumeric: true, hint: 'e.g. 5')),
                  const SizedBox(width: 16),
                  Expanded(child: _expectedStartDateField()),
                ]),
                const SizedBox(height: 32),

                // ── Target Departments ─────────────────────────────────────
                _sectionLabel('TARGET DEPARTMENTS / COURSES'),
                const SizedBox(height: 8),
                const Text('Select which student departments are eligible for this posting',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _departmentPickerSection(),
                const SizedBox(height: 32),

                // ── Target Years of Study ──────────────────────────────────
                _sectionLabel('TARGET YEARS OF STUDY'),
                const SizedBox(height: 8),
                const Text('Select which student years of study are eligible for this posting',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _yearPickerSection(),
                const SizedBox(height: 32),

                // ── Work Location ──────────────────────────────────────────
                _sectionLabel('WORK LOCATION'),
                const SizedBox(height: 16),
                _locationOption(),
                const SizedBox(height: 32),

                // ── Days Active ────────────────────────────────────────────
                _sectionLabel('DAYS ACTIVE IN THE WEEK'),
                const SizedBox(height: 8),
                const Text('Select which days interns are expected to be active',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _dayPickerSection(),
                const SizedBox(height: 32),

                // ── Task List ──────────────────────────────────────────────
                _sectionLabel('TASK LIST'),
                const SizedBox(height: 8),
                const Text('Add individual tasks the intern will be responsible for',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _taskListSection(),
                const SizedBox(height: 32),

                // ── Notes ──────────────────────────────────────────────────
                _sectionLabel('NOTES'),
                const SizedBox(height: 8),
                const Text('Internal notes, special requirements, or any extra info',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _notesField(),
                const SizedBox(height: 48),

                _publishBtn(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.white60,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1));

  Widget _locationOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Remote / On-site toggle
        Row(children: [
          _locBtn('Work from Home', isRemote,
              () => setState(() { isRemote = true; _clearLocation(); })),
          const SizedBox(width: 12),
          _locBtn('On-site Office', !isRemote,
              () => setState(() => isRemote = false)),
        ]),

        // On-site location search (shown only when On-site is selected)
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

        // Selected location chip (shown when a location is picked)
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
          // Search input
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

          // Suggestions dropdown
          if (_locationSearchController.text.trim().isNotEmpty) ...[
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      _selectLocation({
                        'short_name': _locationSearchController.text.trim(),
                        'display_name': _locationSearchController.text.trim(),
                        'lat': 0.0,
                        'lng': 0.0,
                      });
                    },
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.add_location_alt_rounded, color: Color(0xFF6366F1), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Use entered custom address',
                                  style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _locationSearchController.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_locationSuggestions.isNotEmpty) ...[
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListView.separated(
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
                  ],
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE2E8F0),
                width: 1.5),
            boxShadow: active
                ? [BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == 'Work from Home'
                    ? Icons.home_work_rounded
                    : Icons.location_city_rounded,
                color: active ? Colors.white : const Color(0xFF94A3B8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
            ],
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
          // Task items
          if (_tasks.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                return _taskItem(index);
              },
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
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              hintText:
                  'Any special requirements, work culture info, tools used, etc.',
              hintStyle: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w400),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _departmentPickerSection() {
    final allSelected = _eligibleDepartments.length == _allDepartments.length;
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
            children: [
              const Text('Quick Select:',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (allSelected) {
                      _eligibleDepartments.clear();
                    } else {
                      _eligibleDepartments.addAll(_allDepartments);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allSelected ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: allSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                      color: allSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _allDepartments.map((dept) {
              final isSelected = _eligibleDepartments.contains(dept);
              return FilterChip(
                label: Text(dept),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _eligibleDepartments.add(dept);
                    } else {
                      _eligibleDepartments.remove(dept);
                    }
                  });
                },
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFFF8FAFC),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_eligibleDepartments.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.school_rounded, size: 13, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    allSelected
                        ? 'All departments are eligible for this internship'
                        : '${_eligibleDepartments.length} of ${_allDepartments.length} departments selected (${_eligibleDepartments.join(', ')})',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _yearPickerSection() {
    final allSelected = _eligibleYears.length == _allYears.length;
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
            children: [
              const Text('Quick Select:',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (allSelected) {
                      _eligibleYears.clear();
                    } else {
                      _eligibleYears.addAll(_allYears);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allSelected ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: allSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                      color: allSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _allYears.map((yr) {
              final isSelected = _eligibleYears.contains(yr);
              return FilterChip(
                label: Text(yr),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _eligibleYears.add(yr);
                    } else {
                      _eligibleYears.remove(yr);
                    }
                  });
                },
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFFF8FAFC),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_eligibleYears.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.school_rounded, size: 13, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    allSelected
                        ? 'All years are eligible for this internship'
                        : '${_eligibleYears.length} of ${_allYears.length} years selected (${_eligibleYears.join(', ')})',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
            children:
                _allDays.map((day) => Expanded(child: _dayChip(day))).toList(),
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
            day.substring(0, 1),
            style: TextStyle(
                color:
                    isSelected ? Colors.white : const Color(0xFF94A3B8),
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

  Widget _industrialField(String label, TextEditingController controller,
      {int maxLines = 1, bool isNumeric = false, String? hint}) {
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
          keyboardType: isNumeric
              ? TextInputType.number
              : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500),
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
        const Text('SELECTION DEADLINE',
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

  Widget _expectedStartDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EXPECTED START DATE',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickExpectedStartDate,
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
                const Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_expectedStartDate),
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

  Future<void> _pickExpectedStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expectedStartDate.isBefore(now) ? now : _expectedStartDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF10B981),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _expectedStartDate = picked);
  }

  DateTime _calculateEndDate(DateTime startDate, String durationStr, String unit, Set<String> activeDays) {
    final value = int.tryParse(durationStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 3;
    if (unit.toLowerCase().contains('month')) {
      return DateTime(startDate.year, startDate.month + value, startDate.day);
    } else if (unit.toLowerCase().contains('week')) {
      return startDate.add(Duration(days: value * 7));
    } else {
      // Days
      DateTime current = startDate;
      int added = 0;
      final activeSet = activeDays.map((d) => d.substring(0, 3).toLowerCase()).toSet();
      if (activeSet.isEmpty) {
        return startDate.add(Duration(days: value));
      }
      const weekdayMap = {
        1: 'mon',
        2: 'tue',
        3: 'wed',
        4: 'thu',
        5: 'fri',
        6: 'sat',
        7: 'sun',
      };
      while (added < value) {
        final weekdayStr = weekdayMap[current.weekday];
        if (activeSet.contains(weekdayStr)) {
          added++;
        }
        if (added < value) {
          current = current.add(const Duration(days: 1));
        }
      }
      return current;
    }
  }

  Widget _durationField() {
    final calculatedEnd = _calculateEndDate(_expectedStartDate, durationController.text, _durationUnit, _activeDays);
    final endDateStr = DateFormat('dd MMM yyyy').format(calculatedEnd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DURATION',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. 3',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _durationUnit,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'Days', child: Text('Days')),
                      DropdownMenuItem(value: 'Weeks', child: Text('Weeks')),
                      DropdownMenuItem(value: 'Months', child: Text('Months')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _durationUnit = val);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Expected End Date: $endDateStr',
          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _publishBtn(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _publishPosting,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('PUBLISH JOB POST',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('JOB CATEGORY / INDUSTRY',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _industriesList.contains(_selectedIndustry) ? _selectedIndustry : 'Other',
          items: _industriesList.map((ind) {
            return DropdownMenuItem<String>(
              value: ind,
              child: Text(ind, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedIndustry = val;
                if (val != 'Other') {
                  _customIndustryController.clear();
                }
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
          ),
        ),
        if (_selectedIndustry == 'Other') ...[
          const SizedBox(height: 12),
          _industrialField('CUSTOM CATEGORY / INDUSTRY', _customIndustryController,
              hint: 'e.g. Data Science, Logistics'),
        ],
      ],
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
