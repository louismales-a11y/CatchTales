import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pro_service.dart';

/// Authentication states
enum AuthStatus { uninitialized, unauthenticated, authenticating, authenticated }

/// Handles user sign-up, login, logout, and profile management.
/// Replaces the previous anonymous-only approach with email/password accounts.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  AuthStatus _status = AuthStatus.uninitialized;
  AuthStatus get status => _status;

  User? _user;
  User? get user => _user;

  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// Whether the user has a Pro license (stored in Firestore profile).
  bool _isPro = false;
  bool get isPro => _isPro;

  String _userName = '';
  String get userName => _userName;

  String _email = '';
  String get email => _email;

  /// Error message from last failed operation.
  String? _error;
  String? get error => _error;

  /// Message shown when kicked off by another device.
  String? _logoutMessage;
  String? get logoutMessage => _logoutMessage;

  /// Initialize. Checks for existing session and enforces single-device login.
  Future<void> init() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _email = currentUser.email ?? '';
        await _loadProfile();

        // Single-device check: verify our local token matches Firestore
        final localToken = await _getLocalDeviceToken();
        final remoteToken = await _getRemoteDeviceToken();

        if (localToken != remoteToken) {
          debugPrint('AuthService: Device token mismatch — logging out other device session');
          await _forceLogout(
            'This account is being used on another device. '
            'Please log in again on this device.'
          );
          return;
        }

        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthService.init: $e');
    }
    notifyListeners();
  }

  /// Sign up with email and password. Creates a Firestore profile.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = cred.user;
      _email = email.trim();
      _userName = name.trim();

      // Update display name in Firebase Auth
      await _user?.updateDisplayName(name.trim());

      // Create user profile in Firestore with device token
      await _createProfile();
      await _storeDeviceToken();

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'An account with this email already exists.';
          break;
        case 'invalid-email':
          _error = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          _error = 'Password should be at least 6 characters.';
          break;
        case 'operation-not-allowed':
          _error = 'Email/password sign-up is not enabled.';
          break;
        default:
          _error = 'Sign-up failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = 'Sign-up failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Log in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = cred.user;
      _email = email.trim();
      _userName = cred.user?.displayName ?? '';
      await _loadProfile();
      // Update device token — any new login kicks old device
      await _storeDeviceToken();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      switch (e.code) {
        case 'user-not-found':
          _error = 'No account found with this email.';
          break;
        case 'wrong-password':
          _error = 'Incorrect password.';
          break;
        case 'invalid-credential':
          _error = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          _error = 'Too many attempts. Please try again later.';
          break;
        default:
          _error = 'Login failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = 'Login failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Log out.
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('AuthService.logout: $e');
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isPro = false;
    _userName = '';
    _email = '';
    _error = null;
    await _clearLocalDeviceToken();
    notifyListeners();
  }

  /// Upgrade the current user's account to Pro.
  Future<void> upgradeToPro() async {
    if (_user == null) return;
    _isPro = true;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({'isPro': true, 'proSince': FieldValue.serverTimestamp()},
              SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthService.upgradeToPro: $e');
    }
    notifyListeners();
  }

  /// Generate a unique device session token.
  String _generateDeviceToken() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Store the device token locally.
  Future<void> _storeLocalDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_session_token', token);
  }

  /// Get the local device token.
  Future<String?> _getLocalDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_session_token');
  }

  /// Clear the local device token.
  Future<void> _clearLocalDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_session_token');
  }

  /// Get the device token stored in Firestore for this user.
  Future<String?> _getRemoteDeviceToken() async {
    if (_user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      return doc.data()?['deviceSessionToken'] as String?;
    } catch (e) {
      debugPrint('AuthService._getRemoteDeviceToken: $e');
      return null;
    }
  }

  /// Generate a new device session token and store both locally and in Firestore.
  Future<void> _storeDeviceToken() async {
    if (_user == null) return;
    final token = _generateDeviceToken();
    await _storeLocalDeviceToken(token);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({'deviceSessionToken': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthService._storeDeviceToken: $e');
    }
  }

  /// Force logout with a message.
  Future<void> _forceLogout(String message) async {
    _logoutMessage = message;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isPro = false;
    _userName = '';
    _email = '';
    _error = message;
    await _clearLocalDeviceToken();
    notifyListeners();
  }

  /// Create a Firestore profile document for the new user.
  Future<void> _createProfile() async {
    if (_user == null) return;
    final token = _generateDeviceToken();
    await _storeLocalDeviceToken(token);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({
        'name': _userName,
        'email': _email,
        'isPro': false,
        'deviceSessionToken': token,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('AuthService._createProfile: $e');
    }
  }

  /// Load the user's Firestore profile.
  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _isPro = data['isPro'] == true;
        _userName = data['name'] as String? ?? _user?.displayName ?? '';
        _email = data['email'] as String? ?? _user?.email ?? '';

        // Sync Pro status with local ProService
        if (_isPro && !ProService.instance.isPro) {
          await ProService.instance.unlockPro();
        }

        // Update last login
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      } else {
        // Profile doesn't exist yet — create it
        await _createProfile();
      }
    } catch (e) {
      debugPrint('AuthService._loadProfile: $e');
    }
  }

  /// Clear the last error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
