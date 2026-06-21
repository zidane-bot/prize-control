import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/pin_provider.dart';
import '../screens/pin_lock_screen.dart';

/// Membungkus seluruh aplikasi (di level MaterialApp.builder) dan mendeteksi idle selama 1 menit.
/// Jika tidak ada interaksi user (tap, scroll, gesture apapun) dalam 60 detik,
/// akan menampilkan PinLockScreen sebagai overlay Stack di atas Navigator.
class AutoLockWrapper extends StatefulWidget {
  final Widget child;

  const AutoLockWrapper({super.key, required this.child});

  @override
  State<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends State<AutoLockWrapper>
    with WidgetsBindingObserver {
  static const Duration _idleTimeout = Duration(minutes: 1);

  Timer? _idleTimer;
  bool _isLocked = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to authentication changes to manage lock screen state dynamically
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        debugPrint('[AUTO-LOCK] User logged out. Dismissing lock screen & clearing timer.');
        _idleTimer?.cancel();
        if (mounted) {
          setState(() {
            _isLocked = false;
          });
        }
      } else {
        _resetTimer();
      }
    });

    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App entered background
      _idleTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground
      if (!_isLocked) {
        _resetTimer();
      }
    }
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      if (pinProvider.isPinSetupComplete) {
        _idleTimer = Timer(_idleTimeout, _lockSession);
      }
    } catch (e) {
      // PinProvider might not be ready yet in some contexts
      debugPrint('[AUTO-LOCK] Error reading PinProvider: $e');
    }
  }

  void _lockSession() {
    if (!mounted || _isLocked) return;
    debugPrint('[AUTO-LOCK] Idle timeout. Locking session.');
    setState(() => _isLocked = true);
  }

  void _unlockSession() {
    if (!mounted) return;
    debugPrint('[AUTO-LOCK] Session unlocked. Resuming activity.');
    setState(() => _isLocked = false);
    _resetTimer();
  }

  void _onUserInteraction([PointerEvent? _]) {
    if (!_isLocked) {
      _resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PinProvider>(
      builder: (context, pinProvider, child) {
        // If PIN is not set up or user is logged out, never lock
        final user = FirebaseAuth.instance.currentUser;
        final shouldShowLock = _isLocked && user != null && pinProvider.isPinSetupComplete;

        return Listener(
          onPointerDown: _onUserInteraction,
          onPointerMove: _onUserInteraction,
          onPointerUp: _onUserInteraction,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              widget.child,
              if (shouldShowLock)
                PinLockScreen(
                  key: const ValueKey('auto_lock_pin_screen'),
                  onUnlocked: _unlockSession,
                ),
            ],
          ),
        );
      },
    );
  }
}
