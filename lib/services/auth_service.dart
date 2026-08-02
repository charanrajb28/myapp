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
  /// without disrupting any existing user session in local storage.
  Future<void> ensureDefaultAdminAccount({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();

      // 1. Check if the default admin user already exists in Turso DB
      final existing = await _db.querySingle(
        'SELECT id FROM users WHERE email = ?',
        [cleanEmail],
      );

      if (existing != null) {
        debugPrint('✅ Default admin account already exists in database.');
        return;
      }

      // 2. If a user is already signed in, do NOT overwrite their session!
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        debugPrint('ℹ️ Active user session detected (${currentUser.email}). Skipping admin account seeding check.');
        return;
      }

      // 3. If admin account is missing from DB and no user is signed in:
      String? adminUid;
      try {
        final cred = await _firebaseAuth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        adminUid = cred.user?.uid;
      } catch (_) {
        try {
          final cred = await _firebaseAuth.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          adminUid = cred.user?.uid;
        } catch (err) {
          debugPrint('ℹ️ Admin account creation check: $err');
        }
      }

      if (adminUid != null) {
        await _db.execute(
          'INSERT INTO users (id, role, email, name) VALUES (?, ?, ?, ?)',
          [adminUid, 'admin', cleanEmail, 'Platform Administrator'],
        );
        debugPrint('✅ Default admin account seeded in Turso: $cleanEmail ($adminUid)');
      }

      // 4. Clean up Firebase Auth state so the app starts in a logged-out state (LoginPage)
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.signOut();
      }
    } catch (e) {
      debugPrint('Error in ensureDefaultAdminAccount: $e');
    }
  }
}
