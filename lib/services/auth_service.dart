import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pro_service.dart';

/// Authentication states
enum AuthStatus { uninitialized, unauthenticated, authenticating, emailVerificationPending, authenticated }

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

  String _profilePhotoUrl = '';
  String get profilePhotoUrl => _profilePhotoUrl;

  /// Error message from last failed operation.
  String? _error;
  String? get error => _error;

  /// Message shown when kicked off by another device.
  String? _logoutMessage;
  String? get logoutMessage => _logoutMessage;

  /// Whether the current user's email is verified.
  bool get emailVerified => _user?.emailVerified ?? false;

  /// Check if email is verified and transition to authenticated if so.
  /// Returns true if verification is complete.
  Future<bool> checkEmailVerification() async {
    if (_user == null) return false;
    try {
      // Force a fresh token and user reload from server
      await _user!.getIdToken(true);
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;
      if (_user?.emailVerified == true) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('AuthService.checkEmailVerification: $e');
      // If reload failed, try one more time with fresh token
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.getIdToken(true);
          await user.reload();
          if (user.emailVerified) {
            _user = user;
            _status = AuthStatus.authenticated;
            notifyListeners();
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  /// Initialize. Checks for existing session and enforces single-device login.
  Future<void> init() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Reload user to get latest emailVerified status
        try {
          await currentUser.getIdToken(true);
          await currentUser.reload();
        } catch (_) {
          // Reload failed — use cached user
          debugPrint('AuthService.init: user reload failed, using cached');
        }
        _user = FirebaseAuth.instance.currentUser;
        _email = _user?.email ?? '';
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

        // If email not verified on restored session, require verification
        if (_user?.emailVerified != true) {
          _status = AuthStatus.emailVerificationPending;
        } else {
          _status = AuthStatus.authenticated;
        }
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
    File? profilePhoto,
  }) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    final lowerName = name.trim().toLowerCase();

        // Claim username atomically — prevents duplicates
    final usernameRef = FirebaseFirestore.instance.collection('usernames').doc(lowerName);
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final existing = await txn.get(usernameRef);
        if (existing.exists) {
          final data = existing.data()!;
          final uid = data['uid'] as String?;
          // If reserved but no uid yet (stale from a crash), allow re-use
          if (uid == null || uid.isEmpty) {
            // Stale reservation — overwrite it
            txn.set(usernameRef, {'reserved': true, 'reservedAt': FieldValue.serverTimestamp()});
          } else {
            // Check if the owning user's Firestore profile still exists
            final userDoc = await txn.get(FirebaseFirestore.instance.collection('users').doc(uid));
            if (userDoc.exists) {
              throw FirebaseAuthException(
                code: 'username-taken',
                message: 'The username "$name" is already taken. Please choose another.',
              );
            }
            // User profile deleted — username is orphaned, allow re-use
            txn.set(usernameRef, {'reserved': true, 'reservedAt': FieldValue.serverTimestamp()});
          }
        } else {
          // Reserve it with a temp placeholder — real uid written after Auth account
          txn.set(usernameRef, {'reserved': true, 'reservedAt': FieldValue.serverTimestamp()});
        }
      });
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      _error = 'Could not check username availability. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = cred.user;
      _email = email.trim();
      _userName = name.trim();

      // Finalize username claim with real userId
      await usernameRef.set({
        'uid': _user!.uid,
        'name': _userName,
        'email': _email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update display name in Firebase Auth
      await _user?.updateDisplayName(_userName);

      // Create user profile in Firestore with device token
      try {
        await _createProfile();
      } catch (e) {
        debugPrint('AuthService.signUp: profile creation failed (non-fatal): $e');
      }
      try {
        await _storeDeviceToken();
      } catch (e) {
        debugPrint('AuthService.signUp: device token failed (non-fatal): $e');
      }

      // Send email verification (non-blocking, non-fatal)
      try {
        await sendEmailVerification();
      } catch (e) {
        debugPrint('AuthService.signUp: email verification failed (non-fatal): $e');
      }

      // Upload profile photo if provided (before returning, so URL is saved)
      if (profilePhoto != null) {
        debugPrint('AuthService.signUp: profilePhoto file exists=${profilePhoto.existsSync()} path=${profilePhoto.path}');
        try {
          final url = await uploadProfilePhoto(profilePhoto);
          debugPrint('AuthService.signUp: upload result url=$url');
        } catch (e) {
          debugPrint('AuthService.signUp: profile photo upload failed (non-fatal): $e');
        }
      } else {
        debugPrint('AuthService.signUp: profilePhoto is NULL');
      }

      // Don't mark as authenticated yet — email must be verified first
      _status = AuthStatus.emailVerificationPending;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Clean up reserved username on failure
      try { await usernameRef.delete(); } catch (_) {}

      _status = AuthStatus.unauthenticated;
      switch (e.code) {
        case 'username-taken':
          _error = e.message ?? 'Username already taken.';
          break;
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
      // Clean up reserved username on failure
      try { await usernameRef.delete(); } catch (_) {}

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

      // Ensure username document has email (for new sign-ups and existing users)
      final lowerName = _userName.trim().toLowerCase();
      if (lowerName.isNotEmpty && _email.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(lowerName)
              .set({'email': _email}, SetOptions(merge: true));
        } catch (_) {}
      }

      // Update device token — any new login kicks old device
      await _storeDeviceToken();

      // Block login if email not verified
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        _status = AuthStatus.emailVerificationPending;
        notifyListeners();
        return true; // Returns true so UI shows verification screen, not error
      }

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
        'profilePhotoUrl': _profilePhotoUrl,
        'deviceSessionToken': token,
        'totalSessions': 1,
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
        _profilePhotoUrl = data['profilePhotoUrl'] as String? ?? '';

        // Sync Pro status with local ProService
        if (_isPro && !ProService.instance.isPro) {
          await ProService.instance.unlockPro();
        }

        // Update last login, activity stats, and daily log
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final currentSessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
        final log = Map<String, dynamic>.from(data['activityLog'] as Map? ?? {});
        final todayCount = (log[dateKey] as num?)?.toInt() ?? 0;
        log[dateKey] = todayCount + 1;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
          'totalSessions': currentSessions + 1,
          'activityLog': log,
        });
      } else {
        // Profile doesn't exist yet — create it
        await _createProfile();
      }
    } catch (e) {
      debugPrint('AuthService._loadProfile: $e');
    }
  }

  /// Send email verification link to the current user.
  Future<bool> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Force refresh to get latest emailVerified status
        try {
          await user.getIdToken(true);
          await user.reload();
        } catch (_) {}
        // Only send if still not verified
        if (user.emailVerified) {
          // Already verified - update local state
          _user = FirebaseAuth.instance.currentUser;
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthService.sendEmailVerification: $e');
      return false;
    }
  }

  /// Refresh the current user to get latest emailVerified status.
  Future<void> refreshEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService.refreshEmailVerification: $e');
    }
  }

  /// Delete the current user's account and all associated data.
  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    try {
      // Free up the username for others
      final lowerName = _userName.trim().toLowerCase();
      if (lowerName.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('usernames').doc(lowerName).delete();
        } catch (_) {}
      }

      // Delete Firestore user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .delete();

      // Delete catches subcollection
      final catches = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('catches')
          .get();
      for (final doc in catches.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await _user!.delete();

      // Clear local state
      _user = null;
      _status = AuthStatus.unauthenticated;
      _isPro = false;
      _userName = '';
      _email = '';
      _error = null;
      await _clearLocalDeviceToken();

      // Reset local Pro status
      await ProService.instance.resetToFree();

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _error = 'For security, please log out and log back in before deleting your account.';
      } else {
        _error = 'Failed to delete account: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to delete account. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Delete the current unverified user account and go back to sign-in.
  /// Called when the user cancels email verification during sign-up.
  Future<void> cancelSignUp() async {
    if (_user != null) {
      try {
        // Delete the username reservation
        final lowerName = _userName.trim().toLowerCase();
        if (lowerName.isNotEmpty) {
          try {
            await FirebaseFirestore.instance.collection('usernames').doc(lowerName).delete();
          } catch (_) {}
        }
        // Delete the Firestore user profile
        try {
          await FirebaseFirestore.instance.collection('users').doc(_user!.uid).delete();
        } catch (_) {}
        // Delete the Firebase Auth account
        await _user!.delete();
      } catch (e) {
        debugPrint('AuthService.cancelSignUp: $e');
      }
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isPro = false;
    _userName = '';
    _email = '';
    _profilePhotoUrl = '';
    _error = null;
    await _clearLocalDeviceToken();
    await ProService.instance.resetToFree();
    notifyListeners();
  }

  /// Send a password reset email.
  /// Returns true if the email was sent successfully.
  Future<bool> sendPasswordResetEmail(String email) async {
    _error = null;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'No account found with this email.';
          break;
        case 'invalid-email':
          _error = 'Please enter a valid email address.';
          break;
        default:
          _error = 'Failed to send reset email. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Update the user's profile photo URL in Firestore.
  Future<void> updateProfilePhotoUrl(String url) async {
    _profilePhotoUrl = url;
    if (_user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'profilePhotoUrl': url});
      } catch (e) {
        debugPrint('AuthService.updateProfilePhotoUrl: $e');
      }
    }
    notifyListeners();
  }

  /// Upload a profile photo using base64 encoding into Firestore.
  /// Resizes to 256x256 to stay well under Firestore's 1MB limit.
  /// Returns the data URL, or null if failed.
  Future<String?> uploadProfilePhoto(File file) async {
    if (_user == null) return null;
    try {
      final bytes = await file.readAsBytes();
      // Decode, resize to 256x256, re-encode as JPEG quality 70
      final original = img.decodeImage(bytes);
      if (original == null) {
        debugPrint('AuthService.uploadProfilePhoto: could not decode image');
        return null;
      }
      final resized = img.copyResize(original, width: 256, height: 256);
      final outBytes = img.encodeJpg(resized, quality: 70);
      final b64 = base64Encode(outBytes);
      final dataUrl = 'data:image/jpeg;base64,$b64';
      await updateProfilePhotoUrl(dataUrl);
      debugPrint('AuthService.uploadProfilePhoto: SUCCESS (${outBytes.length} bytes)');
      return dataUrl;
    } catch (e) {
      debugPrint('AuthService.uploadProfilePhoto: FAILED: $e');
      return null;
    }
  }

  /// Return the correct [ImageProvider] for a profile photo URL.
  /// Supports both regular http/https URLs and base64 data URIs.
  static ImageProvider? imageProviderFor(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      // base64 data URI — decode and use MemoryImage
      try {
        final comma = url.indexOf(',');
        if (comma < 0) return null;
        final b64 = url.substring(comma + 1);
        final bytes = base64Decode(b64);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('AuthService.imageProviderFor: $e');
        return null;
      }
    }
    return NetworkImage(url);
  }

  /// Clear the last error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Called when app resumes from background — increments today's session count.
  Future<void> recordAppOpen() async {
    if (_user == null) return;
    if (_status != AuthStatus.authenticated) return;
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Read current data, increment, write back (more reliable than FieldValue.increment)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final currentSessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
        final log = Map<String, dynamic>.from(data['activityLog'] as Map? ?? {});
        final todayCount = (log[dateKey] as num?)?.toInt() ?? 0;
        log[dateKey] = todayCount + 1;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
          'totalSessions': currentSessions + 1,
          'activityLog': log,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('AuthService.recordAppOpen: $e');
    }
  }
}
