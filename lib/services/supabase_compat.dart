import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'turso_database_service.dart';

class AuthException implements Exception {
  final String message;
  final String? statusCode;
  AuthException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class PostgrestException implements Exception {
  final String message;
  final String? code;
  PostgrestException(this.message, {this.code});
  @override
  String toString() => message;
}

enum AuthFlowType { implicit, pkce }

class AuthClientOptions {
  final AuthFlowType? authFlowType;
  const AuthClientOptions({this.authFlowType});
}

enum CountOption { exact, planned, estimated }

class RealtimeChannel {
  RealtimeChannel onPostgresChanges({
    required dynamic event,
    required dynamic schema,
    required dynamic table,
    dynamic filter,
    required Function(dynamic payload) callback,
  }) =>
      this;
  RealtimeChannel subscribe() => this;
  Future<void> unsubscribe() async {}
}

enum PostgresChangeEvent { all, insert, update, delete }
enum PostgresChangeFilterType { eq }

class PostgresChangeFilter {
  final PostgresChangeFilterType type;
  final String column;
  final dynamic value;
  PostgresChangeFilter({required this.type, required this.column, required this.value});
}

/// Compatibility layer allowing existing codebase calling `Supabase.instance.client`
/// to operate seamlessly on top of TursoDB (SQLite) and Firebase Auth.
class Supabase {
  static final Supabase instance = Supabase._internal();
  Supabase._internal();

  final SupabaseClient client = SupabaseClient();

  static Future<void> initialize({required String url, required String anonKey}) async {
    // No-op for Firebase/Turso initialization handled in main.dart
  }
}

class SupabaseClient {
  final SupabaseAuthAdapter auth = SupabaseAuthAdapter();

  SupabaseClient([String? url, String? anonKey, AuthClientOptions? authOptions]);

  SupabaseQueryBuilder from(String table) {
    return SupabaseQueryBuilder(table);
  }

  RealtimeChannel channel(String name) => RealtimeChannel();

  Future<dynamic> rpc(String functionName, {Map<String, dynamic>? params}) async {
    debugPrint('ℹ️ RPC $functionName called with params: $params');
    if (functionName == 'create_password_reset_otp' || functionName == 'verify_password_reset_otp') {
      return null;
    }
    return null;
  }
}

class SupabaseAuthUser {
  final fb_auth.User _fbUser;
  SupabaseAuthUser(this._fbUser);

  String get id => _fbUser.uid;
  String? get email => _fbUser.email;
  Map<String, dynamic> get userMetadata => {'name': _fbUser.displayName ?? ''};
  String? get createdAt => _fbUser.metadata.creationTime?.toIso8601String();
  String? get lastSignInAt => _fbUser.metadata.lastSignInTime?.toIso8601String();
}

class AuthState {
  final SupabaseAuthUser? user;
  AuthState(this.user);
}

class AuthResponse {
  final SupabaseAuthUser? user;
  AuthResponse(this.user);
}

class SupabaseAuthAdapter {
  SupabaseAuthUser? get currentUser {
    final fbUser = AuthService.instance.currentUser;
    return fbUser != null ? SupabaseAuthUser(fbUser) : null;
  }

  Stream<AuthState> get onAuthStateChange {
    return AuthService.instance.authStateChanges.map(
      (fbUser) => AuthState(fbUser != null ? SupabaseAuthUser(fbUser) : null),
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cred = await AuthService.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AuthResponse(cred.user != null ? SupabaseAuthUser(cred.user!) : null);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final name = data?['name']?.toString() ?? 'User';
    final role = data?['role']?.toString() ?? 'student';

    fb_auth.UserCredential cred;
    if (role == 'company') {
      cred = await AuthService.instance.createCompanyAccount(
        email: email,
        password: password,
        name: name,
      );
    } else {
      cred = await AuthService.instance.createStudentAccount(
        email: email,
        password: password,
        name: name,
      );
    }
    return AuthResponse(cred.user != null ? SupabaseAuthUser(cred.user!) : null);
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await AuthService.instance.sendPasswordResetEmail(email);
  }

  Future<void> updateUser(dynamic attributes) async {
    final user = AuthService.instance.currentUser;
    if (user != null && attributes != null) {
      if (attributes is Map && attributes.containsKey('password')) {
        await user.updatePassword(attributes['password'].toString());
      }
    }
  }
}

class SupabaseQueryBuilder implements Future<dynamic> {
  final String table;
  String _selectCols = '*';
  final List<String> _whereClauses = [];
  final List<dynamic> _params = [];
  String? _orderBy;
  bool _ascending = true;
  int? _limit;
  bool _isSingle = false;
  bool _isMaybeSingle = false;

  Map<String, dynamic>? _insertData;
  List<Map<String, dynamic>>? _insertBatch;
  Map<String, dynamic>? _updateData;
  bool _isDelete = false;
  bool _isUpsert = false;
  String? _onConflictCol;

  SupabaseQueryBuilder(this.table);

  SupabaseQueryBuilder select([String columns = '*']) {
    _selectCols = columns;
    return this;
  }

  SupabaseQueryBuilder eq(String column, dynamic value) {
    _whereClauses.add('$column = ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder neq(String column, dynamic value) {
    _whereClauses.add('$column != ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder lt(String column, dynamic value) {
    _whereClauses.add('$column < ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder gt(String column, dynamic value) {
    _whereClauses.add('$column > ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder gte(String column, dynamic value) {
    _whereClauses.add('$column >= ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder lte(String column, dynamic value) {
    _whereClauses.add('$column <= ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder not(String column, String operator, dynamic value) {
    if (operator == 'eq') {
      _whereClauses.add('$column != ?');
      _params.add(value);
    } else if (operator == 'is') {
      _whereClauses.add('$column IS NOT ?');
      _params.add(value);
    } else {
      _whereClauses.add('NOT ($column $operator ?)');
      _params.add(value);
    }
    return this;
  }

  SupabaseQueryBuilder count([CountOption? option]) {
    return this;
  }

  SupabaseQueryBuilder filter(String column, String operator, dynamic value) {
    if (operator == 'eq') return eq(column, value);
    if (operator == 'neq') return neq(column, value);
    _whereClauses.add('$column $operator ?');
    _params.add(value);
    return this;
  }

  SupabaseQueryBuilder inFilter(String column, List<dynamic> values) {
    if (values.isEmpty) {
      _whereClauses.add('1 = 0');
      return this;
    }
    final placeholders = List.filled(values.length, '?').join(', ');
    _whereClauses.add('$column IN ($placeholders)');
    _params.addAll(values);
    return this;
  }

  SupabaseQueryBuilder order(String column, {bool ascending = true}) {
    _orderBy = column;
    _ascending = ascending;
    return this;
  }

  SupabaseQueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  SupabaseQueryBuilder single() {
    _isSingle = true;
    return this;
  }

  SupabaseQueryBuilder maybeSingle() {
    _isMaybeSingle = true;
    return this;
  }

  SupabaseQueryBuilder insert(dynamic data) {
    if (data is Map<String, dynamic>) {
      _insertData = data;
    } else if (data is List) {
      _insertBatch = List<Map<String, dynamic>>.from(data);
    }
    return this;
  }

  SupabaseQueryBuilder upsert(dynamic data, {String? onConflict, bool? ignoreDuplicates}) {
    _isUpsert = true;
    _onConflictCol = onConflict;
    return insert(data);
  }

  SupabaseQueryBuilder update(Map<String, dynamic> data) {
    _updateData = data;
    return this;
  }

  SupabaseQueryBuilder delete() {
    _isDelete = true;
    return this;
  }

  Future<dynamic> _execute() async {
    final db = TursoDatabaseService.instance;

    // Handle INSERT / UPSERT
    if (_insertData != null) {
      if (_isUpsert) {
        final conflictCol = _onConflictCol ?? (_insertData!.containsKey('user_id') ? 'user_id' : 'id');
        final conflictVal = _insertData![conflictCol];

        if (conflictVal != null) {
          final existing = await db.querySingle(
            'SELECT id FROM $table WHERE $conflictCol = ?',
            [conflictVal],
          );

          if (existing != null) {
            final updateFields = Map<String, dynamic>.from(_insertData!)..remove(conflictCol);
            if (updateFields.isNotEmpty) {
              final setClauses = updateFields.keys.map((k) => '$k = ?').join(', ');
              final updateParams = [...updateFields.values, conflictVal];
              final sql = 'UPDATE $table SET $setClauses WHERE $conflictCol = ?';
              await db.execute(sql, updateParams);
            }
            return _insertData;
          }
        }
      }

      if (!_insertData!.containsKey('id') || _insertData!['id'] == null) {
        _insertData = Map<String, dynamic>.from(_insertData!);
        final prefix = table.length >= 3 ? table.substring(0, 3) : table;
        _insertData!['id'] = '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 1000)}';
      }

      if (table == 'student_notifications') {
        _insertData = Map<String, dynamic>.from(_insertData!);
        if (_insertData!['student_id'] == null || _insertData!['student_id'].toString().isEmpty) {
          _insertData!['student_id'] = _insertData!['user_id'] ?? _insertData!['id'];
        }
        if (_insertData!['user_id'] == null || _insertData!['user_id'].toString().isEmpty) {
          _insertData!['user_id'] = _insertData!['student_id'] ?? _insertData!['id'];
        }
      }

      final keys = _insertData!.keys.toList();
      final values = _insertData!.values.toList();
      final placeholders = List.filled(keys.length, '?').join(', ');
      final sql = 'INSERT INTO $table (${keys.join(', ')}) VALUES ($placeholders)';
      await db.execute(sql, values);
      return _insertData;
    }

    if (_insertBatch != null && _insertBatch!.isNotEmpty) {
      int idx = 0;
      final List<Map<String, dynamic>> requests = [];
      for (final item in _insertBatch!) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        if (!itemMap.containsKey('id') || itemMap['id'] == null) {
          final prefix = table.length >= 3 ? table.substring(0, 3) : table;
          itemMap['id'] = '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${idx++}';
        }

        if (table == 'student_notifications') {
          if (itemMap['student_id'] == null || itemMap['student_id'].toString().isEmpty) {
            itemMap['student_id'] = itemMap['user_id'] ?? itemMap['id'];
          }
          if (itemMap['user_id'] == null || itemMap['user_id'].toString().isEmpty) {
            itemMap['user_id'] = itemMap['student_id'] ?? itemMap['id'];
          }
        }

        final keys = itemMap.keys.toList();
        final values = itemMap.values.toList();
        final placeholders = List.filled(keys.length, '?').join(', ');
        final sql = 'INSERT INTO $table (${keys.join(', ')}) VALUES ($placeholders)';
        requests.add({'sql': sql, 'params': values});
      }
      await db.batch(requests);
      return _insertBatch;
    }

    // Handle UPDATE
    if (_updateData != null) {
      final setClauses = _updateData!.keys.map((k) => '$k = ?').join(', ');
      final updateParams = [..._updateData!.values];
      var sql = 'UPDATE $table SET $setClauses';
      if (_whereClauses.isNotEmpty) {
        sql += ' WHERE ${_whereClauses.join(' AND ')}';
        updateParams.addAll(_params);
      }
      await db.execute(sql, updateParams);
      return _updateData;
    }

    // Handle DELETE
    if (_isDelete) {
      var sql = 'DELETE FROM $table';
      if (_whereClauses.isNotEmpty) {
        sql += ' WHERE ${_whereClauses.join(' AND ')}';
      }
      await db.execute(sql, _params);
      return null;
    }

    // Handle SELECT
    final parsedItems = _getTopLevelItems(_selectCols).map(ParsedSelectItem.parse).toList();
    final plainCols = parsedItems.where((item) => !item.isRelation).map((item) => item.raw).toList();

    String baseCols;
    if (plainCols.isEmpty) {
      baseCols = '*';
    } else {
      baseCols = plainCols.join(', ');
    }
    
    var sql = 'SELECT $baseCols FROM $table';
    if (_whereClauses.isNotEmpty) {
      sql += ' WHERE ${_whereClauses.join(' AND ')}';
    }
    if (_orderBy != null) {
      sql += ' ORDER BY $_orderBy ${_ascending ? 'ASC' : 'DESC'}';
    }
    if (_limit != null) {
      sql += ' LIMIT $_limit';
    }

    final rows = await db.query(sql, _params);

    final relationItems = parsedItems.where((item) => item.isRelation).toList();
    if (rows.isNotEmpty && relationItems.isNotEmpty) {
      await _populateRelations(db, table, rows, relationItems);
    }

    if (_isSingle) {
      if (rows.isEmpty) throw Exception('No row found for single() query on $table');
      return rows.first;
    }
    if (_isMaybeSingle) {
      if (rows.isEmpty) return null;
      return rows.first;
    }

    return rows;
  }

  @override
  Stream<dynamic> asStream() => _execute().asStream();

  @override
  Future<dynamic> catchError(Function onError, {bool Function(Object error)? test}) {
    return _execute().catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue, {Function? onError}) {
    return _execute().then(onValue, onError: onError);
  }

  @override
  Future<dynamic> timeout(Duration timeLimit, {FutureOr<dynamic> Function()? onTimeout}) {
    return _execute().timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _execute().whenComplete(action);
  }
}

class ParsedSelectItem {
  final String raw;
  final bool isRelation;
  final String? relationName;
  final String? subSelect;

  ParsedSelectItem._({
    required this.raw,
    required this.isRelation,
    this.relationName,
    this.subSelect,
  });

  factory ParsedSelectItem.parse(String item) {
    item = item.trim();
    final firstParen = item.indexOf('(');
    if (firstParen > 0 && item.endsWith(')')) {
      final relName = item.substring(0, firstParen).trim();
      final sub = item.substring(firstParen + 1, item.length - 1).trim();
      return ParsedSelectItem._(
        raw: item,
        isRelation: true,
        relationName: relName,
        subSelect: sub,
      );
    }
    return ParsedSelectItem._(raw: item, isRelation: false);
  }
}

class RelationInfo {
  final String localCol;
  final String foreignCol;
  final bool isList;
  RelationInfo({required this.localCol, required this.foreignCol, required this.isList});
}

List<String> _getTopLevelItems(String selectString) {
  final items = <String>[];
  int depth = 0;
  int start = 0;
  for (int i = 0; i < selectString.length; i++) {
    final char = selectString[i];
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
    } else if (char == ',' && depth == 0) {
      items.add(selectString.substring(start, i).trim());
      start = i + 1;
    }
  }
  if (start < selectString.length) {
    final tail = selectString.substring(start).trim();
    if (tail.isNotEmpty) {
      items.add(tail);
    }
  }
  return items;
}

String _singular(String name) {
  if (name.endsWith('ies')) return '${name.substring(0, name.length - 3)}y';
  if (name.endsWith('s')) return name.substring(0, name.length - 1);
  return name;
}

RelationInfo? _getRelationInfo(String baseTable, String relationTable) {
  if (baseTable == 'internships' && relationTable == 'companies') {
    return RelationInfo(localCol: 'company_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'internships' && relationTable == 'applications') {
    return RelationInfo(localCol: 'id', foreignCol: 'internship_id', isList: true);
  }
  if (baseTable == 'applications' && relationTable == 'students') {
    return RelationInfo(localCol: 'student_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'applications' && relationTable == 'internships') {
    return RelationInfo(localCol: 'internship_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'companies' && relationTable == 'internships') {
    return RelationInfo(localCol: 'id', foreignCol: 'company_id', isList: true);
  }
  if (baseTable == 'companies' && relationTable == 'users') {
    return RelationInfo(localCol: 'user_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'students' && relationTable == 'users') {
    return RelationInfo(localCol: 'user_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'students' && relationTable == 'applications') {
    return RelationInfo(localCol: 'id', foreignCol: 'student_id', isList: true);
  }
  if (baseTable == 'students' && relationTable == 'student_documents') {
    return RelationInfo(localCol: 'id', foreignCol: 'student_id', isList: true);
  }
  if (baseTable == 'feedbacks' && relationTable == 'students') {
    return RelationInfo(localCol: 'student_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'feedbacks' && relationTable == 'companies') {
    return RelationInfo(localCol: 'company_id', foreignCol: 'id', isList: false);
  }
  if (baseTable == 'feedbacks' && relationTable == 'users') {
    return RelationInfo(localCol: 'user_id', foreignCol: 'id', isList: false);
  }

  final relSingular = _singular(relationTable);

  return RelationInfo(
    localCol: '${relSingular}_id',
    foreignCol: 'id',
    isList: false,
  );
}

Future<void> _populateRelations(
  TursoDatabaseService db,
  String baseTable,
  List<Map<String, dynamic>> rows,
  List<ParsedSelectItem> relationItems,
) async {
  for (final relItem in relationItems) {
    final relationTable = relItem.relationName!;
    final subSelect = relItem.subSelect ?? '*';

    final relInfo = _getRelationInfo(baseTable, relationTable);
    if (relInfo == null) continue;

    final localCol = relInfo.localCol;
    final foreignCol = relInfo.foreignCol;
    final isList = relInfo.isList;

    final List<dynamic> localValues = rows
        .map((r) => r[localCol])
        .where((v) => v != null)
        .toSet()
        .toList();

    if (localValues.isEmpty) {
      for (var row in rows) {
        row[relationTable] = isList ? [] : null;
      }
      continue;
    }

    final subParsedItems = _getTopLevelItems(subSelect).map(ParsedSelectItem.parse).toList();
    final subPlainCols = subParsedItems.where((item) => !item.isRelation).map((item) => item.raw).toList();
    String queryCols = subPlainCols.isEmpty ? '*' : subPlainCols.join(', ');

    if (queryCols != '*' && !queryCols.split(',').map((c) => c.trim()).contains(foreignCol)) {
      queryCols += ', $foreignCol';
    }

    final placeholders = List.filled(localValues.length, '?').join(', ');
    final relRows = await db.query(
      'SELECT $queryCols FROM $relationTable WHERE $foreignCol IN ($placeholders)',
      localValues,
    );

    final subRelationItems = subParsedItems.where((item) => item.isRelation).toList();
    if (relRows.isNotEmpty && subRelationItems.isNotEmpty) {
      await _populateRelations(db, relationTable, relRows, subRelationItems);
    }

    for (var row in rows) {
      final localVal = row[localCol];
      if (localVal == null) {
        row[relationTable] = isList ? [] : null;
        continue;
      }

      final matches = relRows.where((r) => r[foreignCol]?.toString() == localVal?.toString()).toList();
      if (isList) {
        row[relationTable] = matches;
      } else {
        row[relationTable] = matches.isNotEmpty ? matches.first : null;
      }
    }
  }
}
