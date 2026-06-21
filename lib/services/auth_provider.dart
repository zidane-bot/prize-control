import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _appLinks = AppLinks();
  final List<StreamSubscription> _roleSubscriptions = [];
  final Map<String, String?> _sourceRoles = {};

  bool _isBiometricVerified = kIsWeb;
  bool _isMagicLinkVerified = true; // Bypassed as per user request to disable email 2FA
  bool _isWaitingForMagicLink = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingEmail;
  String? _userRole;

  bool get isBiometricVerified => _isBiometricVerified;
  bool get isMagicLinkVerified => _isMagicLinkVerified;
  bool get isWaitingForMagicLink => _isWaitingForMagicLink;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  String? get pendingEmail => _pendingEmail;

  AuthProvider() {
    _initDeepLinkListener();

    // Fetch role if user is already logged in and all gates are cleared
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        if (_isBiometricVerified && _isMagicLinkVerified) {
          _subscribeToUserRole();
        }
      } else {
        _unsubscribeFromUserRole();
        _userRole = null;
        notifyListeners();
      }
    });
  }

  void _initDeepLinkListener() {
    _appLinks.uriLinkStream.listen((uri) async {
      debugPrint("[AUTH] Captured Deep Link: $uri");
      if (_auth.isSignInWithEmailLink(uri.toString())) {
        await completeMagicLink(uri.toString());
      }
    });
  }

  void _subscribeToUserRole() {
    final user = _auth.currentUser;
    if (user == null) {
      _unsubscribeFromUserRole();
      return;
    }

    if (_roleSubscriptions.isNotEmpty) return; // Already subscribed

    debugPrint("[RBAC] Subscribing to multi-source role streams for user: ${user.email} (UID: ${user.uid})...");

    _sourceRoles.clear();

    // Instant hardcoded admin check
    if (user.email != null) {
      final emailNormalized = user.email!.toLowerCase();
      if (emailNormalized == 'jidanliebert@gmail.com' ||
          emailNormalized == 'admin@gmail.com' ||
          emailNormalized == 'admin@example.com' ||
          emailNormalized == 'admin2@example.com') {
        _userRole = 'admin';
        debugPrint("[RBAC] Resolved hardcoded admin role instantly for ${user.email}");
        notifyListeners();
      }
    }

    // Helper to register a listener to a document snapshot stream
    void listenToDoc(String sourceKey, DocumentReference docRef) {
      final sub = docRef.snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          _sourceRoles[sourceKey] = data['role'] as String?;
        } else {
          _sourceRoles[sourceKey] = null;
        }
        _resolveRoleFromSources(user);
      }, onError: (e) {
        debugPrint("[RBAC] Error in stream $sourceKey: $e");
      });
      _roleSubscriptions.add(sub);
    }

    // Helper to register a listener to a query snapshot stream
    void listenToQuery(String sourceKey, Query query) {
      final sub = query.snapshots().listen((querySnapshot) {
        String? resolvedRole;
        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data['role'] != null) {
              resolvedRole = data['role'] as String?;
              break;
            }
          }
        }
        _sourceRoles[sourceKey] = resolvedRole;
        _resolveRoleFromSources(user);
      }, onError: (e) {
        debugPrint("[RBAC] Error in query stream $sourceKey: $e");
      });
      _roleSubscriptions.add(sub);
    }

    // 1. Listen to UID document
    listenToDoc('uid_doc', _db.collection('users').doc(user.uid));

    // 2. Listen to email document (if email exists)
    if (user.email != null && user.email!.isNotEmpty) {
      final emailNormalized = user.email!.toLowerCase();
      listenToDoc('email_lower_doc', _db.collection('users').doc(emailNormalized));
      if (emailNormalized != user.email) {
        listenToDoc('email_orig_doc', _db.collection('users').doc(user.email!));
      }

      // 3. Listen to queries
      listenToQuery('email_query', _db.collection('users').where('email', isEqualTo: user.email));
      if (emailNormalized != user.email) {
        listenToQuery('email_lower_query', _db.collection('users').where('email', isEqualTo: emailNormalized));
      }
    }

    // Fallback: Jika setelah 1.5 detik stream role masih belum selesai (karena kendala jaringan/permission),
    // jalankan evaluasi fallback manual agar user tidak stuck di loading screen.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_userRole == null) {
        debugPrint("[RBAC] Stream role timed out. Resolving role fallback...");
        _resolveRoleFromSources(user);
      }
    });
  }

  void _resolveRoleFromSources(User user) async {
    // Determine the best role from all currently emitted values
    String? resolvedRole;
    for (var role in _sourceRoles.values) {
      if (role == 'admin') {
        resolvedRole = 'admin';
        break; // admin takes highest precedence
      } else if (role == 'petani') {
        resolvedRole = 'petani';
      }
    }

    // Email-based hardcoded admin override
    if (user.email != null) {
      final emailNormalized = user.email!.toLowerCase();
      if (emailNormalized == 'jidanliebert@gmail.com' ||
          emailNormalized == 'admin@gmail.com' ||
          emailNormalized == 'admin@example.com' ||
          emailNormalized == 'admin2@example.com') {
        resolvedRole = 'admin';
      }
    }

    if (resolvedRole != null) {
      if (_userRole != resolvedRole) {
        _userRole = resolvedRole;
        debugPrint("[RBAC] Role resolved from streams: $_userRole (sources: $_sourceRoles)");
        notifyListeners();

        // Self-heal: If resolved role is admin, make sure UID doc in Firestore is also updated to admin
        if (resolvedRole == 'admin') {
          try {
            final docRef = _db.collection('users').doc(user.uid);
            final docSnap = await docRef.get();
            if (!docSnap.exists || docSnap.data()?['role'] != 'admin') {
              await docRef.set({
                'email': user.email,
                'role': 'admin',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              debugPrint("[RBAC] Self-healed UID document to role 'admin' for ${user.email}");
            }
          } catch (e) {
            debugPrint("[RBAC] Self-heal failed: $e");
          }
        }
      }
      return;
    }

    // If all streams have emitted and no role is resolved, check Firestore with async calls
    // Wait a brief moment to let other streams emit
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if a role was resolved while waiting
    for (var role in _sourceRoles.values) {
      if (role == 'admin') {
        _userRole = 'admin';
        notifyListeners();
        return;
      } else if (role == 'petani') {
        _userRole = 'petani';
      }
    }

    if (_userRole == null) {
      // Perform fallback async checks before creating default
      debugPrint("[RBAC] No role resolved yet. Performing fallback checks...");
      
      // Check if document exists under lowercase or original email
      if (user.email != null) {
        try {
          final docLower = await _db.collection('users').doc(user.email!.toLowerCase()).get();
          if (docLower.exists && docLower.data()?['role'] != null) {
            _userRole = docLower.data()?['role'] as String?;
            notifyListeners();
            return;
          }
        } catch (_) {}

        try {
          final docOrig = await _db.collection('users').doc(user.email!).get();
          if (docOrig.exists && docOrig.data()?['role'] != null) {
            _userRole = docOrig.data()?['role'] as String?;
            notifyListeners();
            return;
          }
        } catch (_) {}
      }

      // Ensure user in Firestore (will only create if completely missing)
      await _ensureUserInFirestore(user);
      _userRole = 'petani';
      notifyListeners();
    }
  }

  void _unsubscribeFromUserRole() {
    for (var sub in _roleSubscriptions) {
      sub.cancel();
    }
    _roleSubscriptions.clear();
    _sourceRoles.clear();
    debugPrint("[RBAC] Unsubscribed from all role streams.");
  }

  Future<void> _ensureUserInFirestore(User user) async {
    try {
      // 1. Check if UID doc exists
      final uidDoc = await _db.collection('users').doc(user.uid).get();
      if (uidDoc.exists) return;

      // 2. Check if email doc exists (lowercase)
      if (user.email != null) {
        final emailDoc = await _db.collection('users').doc(user.email!.toLowerCase()).get();
        if (emailDoc.exists) return;
        
        // 3. Check if email doc exists (original/mixed case)
        final emailDocOrig = await _db.collection('users').doc(user.email!).get();
        if (emailDocOrig.exists) return;

        // 4. Check if any doc has email field matching case-insensitively
        final querySnap = await _db
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        if (querySnap.docs.isNotEmpty) return;

        final querySnapLower = await _db
            .collection('users')
            .where('email', isEqualTo: user.email!.toLowerCase())
            .get();
        if (querySnapLower.docs.isNotEmpty) return;
      }

      // If absolutely no document matches, only then do we create a new user profile
      final docRef = _db.collection('users').doc(user.uid);
      await docRef.set({
        'email': user.email,
        'role': 'petani',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("[RBAC] New user profile created in Firestore (role: petani)");
    } catch (e) {
      debugPrint("[RBAC] Error ensuring user in Firestore: $e");
    }
  }

  void resetBiometrics() {
    debugPrint("[AUTH] System Locked: Biometric status reset.");
    _isBiometricVerified = false;
    notifyListeners();
  }

  // --- Manual registration ---
  Future<void> registerWithEmail(String email, String password) async {
    debugPrint("[AUTH] Initializing Registration for: $email");
    _setLoading(true);
    _clearError();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _ensureUserInFirestore(userCredential.user!);
      }
      debugPrint("[AUTH] Registration Success for $email.");
      _pendingEmail = email;
      _isBiometricVerified = kIsWeb;
      _isMagicLinkVerified = true;
      _isWaitingForMagicLink = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint("[AUTH] Registration Error: ${e.code}");
      _handleAuthError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    debugPrint("[FLOW] Step A: Authenticating Credentials for $email...");
    _setLoading(true);
    _clearError();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      _pendingEmail = email;
      _isBiometricVerified = kIsWeb;
      _isMagicLinkVerified = true;
      _isWaitingForMagicLink = false;
      _userRole = null; // Reset role on new login
      
      debugPrint("[FLOW] Step A SUCCESS. Restored 2FA: redirecting to Biometrics first...");
      notifyListeners(); 
    } catch (e) {
      debugPrint("[FLOW] Step A FAILED: $e");
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    debugPrint("[AUTH] Initiating Global Sign Out...");
    _unsubscribeFromUserRole();
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _isBiometricVerified = kIsWeb;
    _isMagicLinkVerified = true;
    _isWaitingForMagicLink = false;
    _pendingEmail = null;
    _userRole = null;
    debugPrint("[AUTH] Clean Logout Success.");
    notifyListeners();
  }

  // --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    debugPrint("[AUTH] Step 1: Initializing Google Identity Authorization...");
    _setLoading(true);
    _clearError();
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Flutter Web: Gunakan Firebase signInWithPopup langsung
        // (google_sign_in package butuh JS library tambahan yang tidak tersedia)
        debugPrint("[AUTH] Web mode: using FirebaseAuth signInWithPopup...");
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile (APK): Gunakan google_sign_in package seperti biasa
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint("[AUTH] Google Sign-In aborted by user.");
          _setLoading(false);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        debugPrint("[FLOW] Google Step A SUCCESS: ${userCredential.user?.email}");
        await _ensureUserInFirestore(userCredential.user!);

        _isBiometricVerified = kIsWeb;
        _isMagicLinkVerified = true;
        _pendingEmail = userCredential.user?.email;
        _userRole = null;

        debugPrint("[FLOW] Google Sign-In SUCCESS. Redirecting to dashboard...");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("[AUTH] Google Sign-In Exception: $e");
      _errorMessage = "Google Sign-In failed: $e";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initiateMagicLink() async {
    final email = _pendingEmail ?? _auth.currentUser?.email;
    if (email == null) {
      debugPrint("[AUTH] ABORT: No email available for Magic Link.");
      return;
    }

    debugPrint("[AUTH] Triggering Magic Link for: $email");
    _setLoading(true);
    _clearError();
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://precision-39b42.firebaseapp.com/finish2fa',
        handleCodeInApp: true,
        androidPackageName: 'com.example.precision',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      _isWaitingForMagicLink = true;
      debugPrint("[AUTH] SUCCESS: Magic Link sent to Gmail.");
      notifyListeners();
    } catch (e) {
      debugPrint("[AUTH] ERROR: Failed to send Magic Link: $e");
      _isWaitingForMagicLink = false;
      _errorMessage = "Gagal mengirim email: ${e.toString()}";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeMagicLink(String link) async {
    final email = _pendingEmail ?? _auth.currentUser?.email;
    debugPrint("[AUTH] Step 4: Finalizing Magic Link Verification...");
    if (email == null) {
      debugPrint("[AUTH] Error: No email found for link completion.");
      return;
    }

    try {
      _setLoading(true);
      await _auth.signInWithEmailLink(email: email, emailLink: link);
      _isMagicLinkVerified = true;
      _isWaitingForMagicLink = false;
      debugPrint("[AUTH] Magic Link Verified.");
      
      if (_isBiometricVerified) {
        _subscribeToUserRole();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("[AUTH] Magic Link Verification Failure: $e");
    } finally {
      _setLoading(false);
    }
  }

  void onExternalLoginSuccess() {
    debugPrint("[AUTH] External Session Detected. Bypassing Magic Link Gate.");
    _isMagicLinkVerified = true; 
    _isBiometricVerified = kIsWeb; 
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics() async {
    debugPrint("[AUTH] Step 2: Triggering Industrial Biometric Scan...");
    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        debugPrint("[AUTH] Biometrics Unavailable. Fallback used.");
        _isBiometricVerified = true; 
        if (_isMagicLinkVerified) {
          _subscribeToUserRole();
        } else {
          await initiateMagicLink();
        }
        notifyListeners();
        return true;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Industrial Security: Scan biometrics to unlock Precision Control',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );

      debugPrint("[AUTH] Biometric Scan Result: $didAuthenticate");
      if (didAuthenticate) {
        _isBiometricVerified = true;
        if (_isMagicLinkVerified) {
          _subscribeToUserRole();
        } else {
          await initiateMagicLink();
        }
        notifyListeners();
      }
      return didAuthenticate;
    } catch (e) {
      debugPrint("[AUTH] Biometric Plugin Error: $e");
      return false;
    }
  }

  void logout() {
    debugPrint("[AUTH] Terminating Connection. Clearing all gates.");
    _unsubscribeFromUserRole();
    _auth.signOut();
    GoogleSignIn().signOut();
    _isBiometricVerified = kIsWeb;
    _isMagicLinkVerified = true;
    _isWaitingForMagicLink = false;
    _pendingEmail = null;
    _userRole = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': _errorMessage = "Email tidak terdaftar."; break;
      case 'wrong-password': _errorMessage = "Password salah."; break;
      case 'invalid-credential': _errorMessage = "Email atau password salah."; break;
      case 'email-already-in-use': _errorMessage = "Email sudah digunakan."; break;
      case 'weak-password': _errorMessage = "Password minimum 6 karakter."; break;
      case 'biometric-failed': _errorMessage = "Verifikasi biometrik gagal."; break;
      default: _errorMessage = "Galat: ${e.message}";
    }
    notifyListeners();
  }
}
