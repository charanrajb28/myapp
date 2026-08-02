import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'turso_database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final TursoDatabaseService _db = TursoDatabaseService.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return cred;
  }

  Future<UserCredential> createStudentAccount({
    required String email,
    required String password,
    required String name,
    String? enrollmentId,
    String? college,
    String? department,
    String? semester,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final uid = cred.user!.uid;

    await _db.execute(
      'INSERT INTO users (id, role, email, name) VALUES (?, ?, ?, ?)',
      [uid, 'student', email.trim(), name.trim()],
    );

    final studentId = 'std_${DateTime.now().millisecondsSinceEpoch}';
    await _db.execute(
      '''
      INSERT INTO students (id, user_id, name, enrollment_id, college, department, semester, contact_email)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        studentId,
        uid,
        name.trim(),
        enrollmentId,
        college ?? 'Sheshadri Institute of Technology',
        department,
        semester,
        email.trim(),
      ],
    );

    return cred;
  }

  Future<UserCredential> createCompanyAccount({
    required String email,
    required String password,
    required String name,
    String? industry,
    String? location,
    String? website,
    String? phone,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final uid = cred.user!.uid;

    await _db.execute(
      'INSERT INTO users (id, role, email, name) VALUES (?, ?, ?, ?)',
      [uid, 'company', email.trim(), name.trim()],
    );

    final companyId = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
    await _db.execute(
      '''
      INSERT INTO companies (id, user_id, name, industry, location, website, phone, contact_email)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        companyId,
        uid,
        name.trim(),
        industry ?? 'Software',
        location,
        website,
        phone,
        email.trim(),
      ],
    );

    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return await _db.querySingle(
      'SELECT id, role, email, name FROM users WHERE id = ?',
      [uid],
    );
  }

  Future<String?> getUserRole(String uid) async {
    final userMap = await getUserProfile(uid);
    return userMap?['role'] as String?;
  }

  /// Ensures the default admin account exists in Firebase Auth and Turso DB
  Future<void> ensureDefaultAdminAccount({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Try to sign in as admin
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user!.uid;

      // Check if user row exists in Turso
      final existing = await _db.querySingle('SELECT id FROM users WHERE id = ?', [uid]);
      if (existing == null) {
        await _db.execute(
          'INSERT INTO users (id, role, email, name) VALUES (?, ?, ?, ?)',
          [uid, 'admin', email.trim(), 'Platform Administrator'],
        );
      }
      debugPrint('✅ Default admin account ready (signed in): $email ($uid)');
    } catch (e) {
      // 2. If sign-in failed, try creating the account
      try {
        final cred = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final uid = cred.user!.uid;

        await _db.execute(
          'INSERT INTO users (id, role, email, name) VALUES (?, ?, ?, ?)',
          [uid, 'admin', email.trim(), 'Platform Administrator'],
        );
        debugPrint('✅ Default admin account created: $email ($uid)');
      } catch (err) {
        debugPrint('ℹ️ Admin setup check: $err');
      }
    }
  }
}
