import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TursoDatabaseService {
  static final TursoDatabaseService instance = TursoDatabaseService._internal();

  TursoDatabaseService._internal();

  String _baseUrl = '';
  String _authToken = '';
  bool _initialized = false;

  void configure({required String dbUrl, String? authToken}) {
    var url = dbUrl.trim();
    if (url.startsWith('libsql://')) {
      url = url.replaceFirst('libsql://', 'https://');
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    // Strip trailing slashes
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _baseUrl = url;
    _authToken = authToken ?? '';
    _initialized = true;
    debugPrint('⚡ [TursoDB] Configured endpoint: $_baseUrl');
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Map<String, dynamic> _formatArg(dynamic arg) {
    if (arg == null) {
      return {'type': 'null'};
    } else if (arg is int) {
      return {'type': 'integer', 'value': arg.toString()};
    } else if (arg is double || arg is num) {
      return {'type': 'float', 'value': arg};
    } else if (arg is bool) {
      return {'type': 'integer', 'value': arg ? '1' : '0'};
    } else if (arg is String) {
      return {'type': 'text', 'value': arg};
    } else if (arg is List || arg is Map) {
      return {'type': 'text', 'value': jsonEncode(arg)};
    } else {
      return {'type': 'text', 'value': arg.toString()};
    }
  }

  dynamic _parseCell(Map<String, dynamic> cell) {
    final type = cell['type'];
    final value = cell['value'];
    if (type == 'null' || value == null) {
      return null;
    }
    if (type == 'integer') {
      return int.tryParse(value.toString()) ?? value;
    }
    if (type == 'float') {
      return (value is num) ? value.toDouble() : (double.tryParse(value.toString()) ?? value);
    }
    if (type == 'text' && value is String) {
      final str = value.trim();
      if ((str.startsWith('[') && str.endsWith(']')) ||
          (str.startsWith('{') && str.endsWith('}'))) {
        try {
          return jsonDecode(str);
        } catch (_) {
          return value;
        }
      }
    }
    return value;
  }

  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    if (!_initialized) throw Exception('TursoDatabaseService is not configured');

    final pipelineUrl = Uri.parse('$_baseUrl/v2/pipeline');
    final payload = {
      'requests': [
        {
          'type': 'execute',
          'stmt': {
            'sql': sql,
            if (params != null && params.isNotEmpty)
              'args': params.map(_formatArg).toList(),
          }
        },
        {'type': 'close'}
      ]
    };

    final response = await http.post(
      pipelineUrl,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('TursoDB error [HTTP ${response.statusCode}]: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return [];

    final firstResult = results[0];
    if (firstResult['type'] == 'error') {
      throw Exception('TursoDB SQL error: ${firstResult['error']}');
    }

    final execRes = firstResult['response']?['result'];
    if (execRes == null) return [];

    final cols = (execRes['cols'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rows = (execRes['rows'] as List?) ?? [];

    final colNames = cols.map((c) => c['name'] as String).toList();
    final List<Map<String, dynamic>> output = [];

    for (final row in rows) {
      final rowCells = (row as List).cast<Map<String, dynamic>>();
      final Map<String, dynamic> map = {};
      for (int i = 0; i < colNames.length && i < rowCells.length; i++) {
        map[colNames[i]] = _parseCell(rowCells[i]);
      }
      output.add(map);
    }

    return output;
  }

  Future<Map<String, dynamic>?> querySingle(String sql, [List<dynamic>? params]) async {
    final rows = await query(sql, params);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> execute(String sql, [List<dynamic>? params]) async {
    if (!_initialized) throw Exception('TursoDatabaseService is not configured');

    final pipelineUrl = Uri.parse('$_baseUrl/v2/pipeline');
    final payload = {
      'requests': [
        {
          'type': 'execute',
          'stmt': {
            'sql': sql,
            if (params != null && params.isNotEmpty)
              'args': params.map(_formatArg).toList(),
          }
        },
        {'type': 'close'}
      ]
    };

    final response = await http.post(
      pipelineUrl,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('TursoDB error [HTTP ${response.statusCode}]: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return 0;

    final firstResult = results[0];
    if (firstResult['type'] == 'error') {
      throw Exception('TursoDB SQL error: ${firstResult['error']}');
    }

    final affected = firstResult['response']?['result']?['affected_row_count'];
    return (affected is int) ? affected : (int.tryParse(affected?.toString() ?? '0') ?? 0);
  }

  Future<void> batch(List<Map<String, dynamic>> requests) async {
    if (!_initialized) throw Exception('TursoDatabaseService is not configured');
    final pipelineUrl = Uri.parse('$_baseUrl/v2/pipeline');

    final formattedRequests = requests.map((req) {
      final sql = req['sql'] as String;
      final params = req['params'] as List<dynamic>?;
      return {
        'type': 'execute',
        'stmt': {
          'sql': sql,
          if (params != null && params.isNotEmpty)
            'args': params.map(_formatArg).toList(),
        }
      };
    }).toList();

    formattedRequests.add({'type': 'close'});

    final response = await http.post(
      pipelineUrl,
      headers: _headers,
      body: jsonEncode({'requests': formattedRequests}),
    );

    if (response.statusCode != 200) {
      throw Exception('TursoDB Batch Error [HTTP ${response.statusCode}]: ${response.body}');
    }
  }

  /// Initialize default tables & triggers if they do not exist
  Future<void> ensureSchema() async {
    const ddlStatements = [
      '''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL CHECK(role IN ('student', 'company', 'admin', 'sub_admin')),
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS students (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        enrollment_id TEXT,
        name TEXT,
        college TEXT DEFAULT 'Sheshadri Institute of Technology',
        department TEXT,
        semester TEXT,
        contact_email TEXT,
        phone_number TEXT,
        avatar_url TEXT,
        parent_contact TEXT,
        parent_email TEXT,
        resume_url TEXT,
        document_urls TEXT DEFAULT '[]',
        gpa REAL,
        graduation_year INTEGER,
        is_blacklisted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS companies (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        industry TEXT,
        location TEXT,
        website TEXT,
        phone TEXT,
        contact_email TEXT,
        description TEXT,
        logo_url TEXT,
        banner_url TEXT,
        mou_date TEXT,
        partner_since INTEGER,
        is_blacklisted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS internships (
        id TEXT PRIMARY KEY,
        company_id TEXT REFERENCES companies(id) ON DELETE CASCADE,
        role TEXT NOT NULL,
        industry TEXT,
        location TEXT NOT NULL,
        location_address TEXT,
        location_lat REAL,
        location_lng REAL,
        stipend TEXT,
        duration TEXT,
        deadline TEXT,
        brand_color TEXT,
        logo_initial TEXT,
        about TEXT,
        requirements TEXT DEFAULT '[]',
        responsibilities TEXT DEFAULT '[]',
        status TEXT DEFAULT 'UNDER_REVIEW',
        start_date TEXT,
        end_date TEXT,
        application_duration_days INTEGER DEFAULT 7,
        vacancies INTEGER DEFAULT 1,
        eligible_departments TEXT DEFAULT '[]',
        eligible_years TEXT DEFAULT '[]',
        active_days TEXT DEFAULT '[]',
        notes TEXT DEFAULT '',
        feedback_form_schema TEXT DEFAULT '[]',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS applications (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        internship_id TEXT NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
        status TEXT DEFAULT 'Applied' CHECK(status IN ('Applied', 'Accepted', 'Active', 'Completed', 'Upcoming', 'Rejected', 'Under Review', 'Removed')),
        applied_at TEXT DEFAULT CURRENT_TIMESTAMP,
        progress REAL DEFAULT 0.0,
        checkins TEXT DEFAULT '[]',
        feedback_data TEXT DEFAULT '{}',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS student_documents (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        type TEXT,
        size INTEGER,
        uploaded_at TEXT DEFAULT CURRENT_TIMESTAMP,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS user_device_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        device_token TEXT NOT NULL,
        device_info TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        logged_in_at TEXT DEFAULT CURRENT_TIMESTAMP,
        logged_out_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS student_notifications (
        id TEXT PRIMARY KEY,
        student_id TEXT,
        user_id TEXT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT,
        notification_type TEXT,
        is_read INTEGER DEFAULT 0,
        sender_name TEXT DEFAULT 'System Admin',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS feedbacks (
        id TEXT PRIMARY KEY,
        user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
        category TEXT,
        message TEXT NOT NULL,
        rating INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS sub_admins (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        created_by TEXT REFERENCES users(id) ON DELETE SET NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      ''',
    ];

    for (final stmt in ddlStatements) {
      try {
        await execute(stmt);
      } catch (e) {
        debugPrint('⚠️ Schema init warning: $e');
      }
    }

    final alterStatements = [
      'ALTER TABLE student_notifications ADD COLUMN user_id TEXT',
      'ALTER TABLE student_notifications ADD COLUMN notification_type TEXT',
      'ALTER TABLE student_notifications ADD COLUMN sender_name TEXT',
      'ALTER TABLE user_device_sessions ADD COLUMN fcm_token TEXT',
      'ALTER TABLE users ADD COLUMN fcm_token TEXT',
      'ALTER TABLE internships RENAME COLUMN title TO role',
      'ALTER TABLE internships RENAME COLUMN description TO about',
      'ALTER TABLE internships RENAME COLUMN is_active TO status',
      'ALTER TABLE internships ADD COLUMN industry TEXT',
      'ALTER TABLE internships ADD COLUMN deadline TEXT',
      'ALTER TABLE internships ADD COLUMN brand_color TEXT',
      'ALTER TABLE internships ADD COLUMN logo_initial TEXT',
      'ALTER TABLE internships ADD COLUMN requirements TEXT DEFAULT \'[]\'',
      'ALTER TABLE internships ADD COLUMN responsibilities TEXT DEFAULT \'[]\'',
      'ALTER TABLE internships ADD COLUMN application_duration_days INTEGER DEFAULT 7',
      'ALTER TABLE internships ADD COLUMN eligible_departments TEXT DEFAULT \'[]\'',
      'ALTER TABLE internships ADD COLUMN eligible_years TEXT DEFAULT \'[]\'',
      'ALTER TABLE feedbacks ADD COLUMN student_id TEXT',
      'ALTER TABLE feedbacks ADD COLUMN company_id TEXT',
      'ALTER TABLE feedbacks ADD COLUMN type TEXT',
      'ALTER TABLE feedbacks ADD COLUMN comment TEXT',
      'ALTER TABLE feedbacks ADD COLUMN form_responses TEXT DEFAULT \'{}\'',
    ];
    for (final stmt in alterStatements) {
      try {
        await execute(stmt);
      } catch (_) {}
    }
  }
}
