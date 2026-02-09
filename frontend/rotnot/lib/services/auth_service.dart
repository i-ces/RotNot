import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'firebase_id_token';

  /// Current Firebase user
  static User? get currentUser => _auth.currentUser;

  /// Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email & password
  static Future<UserCredential> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _storeToken();
    return credential;
  }

  /// Login with email & password
  static Future<UserCredential> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _storeToken();
    return credential;
  }

  /// Logout
  static Future<void> logout() async {
    await _auth.signOut();
    await _storage.delete(key: _tokenKey);
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Get the current Firebase ID token (refreshes if expired)
  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken(forceRefresh);
    if (token != null) {
      await _storage.write(key: _tokenKey, value: token);
    }
    return token;
  }

  /// Read cached token from secure storage
  static Future<String?> getCachedToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Store the current user's ID token in secure storage
  static Future<void> _storeToken() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token != null) {
      await _storage.write(key: _tokenKey, value: token);
    }
  }
}
