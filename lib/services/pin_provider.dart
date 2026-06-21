import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pin_service.dart';

/// ChangeNotifier untuk state PIN Bitanic.
/// Digunakan oleh AuthWrapper untuk memutuskan gate mana yang ditampilkan.
class PinProvider with ChangeNotifier {
  final PinService _pinService = PinService();

  bool _isPinSetupComplete = false;
  bool _isInitialized = false;
  bool _isPinVerified = false;
  bool _isInitializing = false;

  bool get isPinSetupComplete => _isPinSetupComplete;
  bool get isInitialized => _isInitialized;
  bool get isPinVerified => _isPinVerified;
  PinService get pinService => _pinService;

  PinProvider() {
    _initialize();
    
    // Listen to authentication changes to recheck PIN status dynamically
    FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('[PIN] Auth state changed for user: ${user?.uid}. Re-initializing PIN status...');
      _initialize();
    });
  }

  Future<void> _initialize() async {
    if (_isInitializing) {
      debugPrint('[PIN] Already initializing. Skipping concurrent call.');
      return;
    }
    _isInitializing = true;
    _isInitialized = false;
    _isPinVerified = false; // Reset verification status on new auth state
    notifyListeners();
    
    try {
      _isPinSetupComplete = await _pinService.hasPin();
    } catch (e) {
      debugPrint('[PIN] Error during PIN init: $e');
      _isPinSetupComplete = false;
    } finally {
      _isInitialized = true;
      _isInitializing = false;
      debugPrint('[PIN] Initialized. PIN setup complete: $_isPinSetupComplete');
      notifyListeners();
    }
  }

  /// Dipanggil setelah user berhasil membuat PIN baru
  void markPinSetupComplete() {
    _isPinSetupComplete = true;
    _isPinVerified = true;
    debugPrint('[PIN] Setup complete. Granting dashboard access.');
    notifyListeners();
  }

  /// Dipanggil setelah user berhasil memasukkan PIN yang benar pada sesi saat ini
  void markPinVerified() {
    _isPinVerified = true;
    debugPrint('[PIN] Session verified.');
    notifyListeners();
  }

  /// Re-cek dari secure storage (misalnya setelah reset)
  Future<void> refresh() async {
    _isPinSetupComplete = await _pinService.hasPin();
    notifyListeners();
  }
}
