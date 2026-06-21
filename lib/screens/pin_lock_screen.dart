import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../services/pin_service.dart';

/// Lock screen yang muncul saat sesi idle selama 1 menit.
/// Desain mengikuti 100% SecurityVerificationScreen Bitanic yang sudah ada.
class PinLockScreen extends StatefulWidget {
  /// Callback dipanggil setelah PIN benar atau biometrik berhasil.
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final PinService _pinService = PinService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  String _currentPin = '';
  String? _errorText;
  bool _isBiometricLoading = false;

  bool _isLockedOut = false;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;

  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _loadLockoutState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLockoutState() async {
    final lockout = await _pinService.getLockoutUntil();
    if (!mounted) return;
    setState(() {
      if (lockout != null && DateTime.now().isBefore(lockout)) {
        _isLockedOut = true;
        _lockoutUntil = lockout;
        _startLockoutCountdown();
      }
    });
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _lockoutUntil?.difference(DateTime.now());
      if (remaining == null || remaining.isNegative) {
        setState(() {
          _isLockedOut = false;
          _lockoutUntil = null;
          _errorText = null;
        });
        _pinService.resetFailedAttempts();
        _lockoutTimer?.cancel();
        _pinFocusNode.requestFocus(); // Re-focus keyboard when lockout ends
      } else {
        setState(() {}); // refresh countdown UI
      }
    });
  }

  void _onPinChanged(String val) {
    if (_isLockedOut || _isBiometricLoading) return;
    setState(() {
      _errorText = null;
      _currentPin = val;
    });
    if (val.length == 6) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    final correct = await _pinService.verifyPin(_currentPin);
    if (!mounted) return;

    if (correct) {
      await _pinService.resetFailedAttempts();
      widget.onUnlocked();
    } else {
      await _pinService.incrementFailedAttempts();
      final attempts = await _pinService.getFailedAttempts();
      if (!mounted) return;

      if (attempts >= _maxAttempts) {
        await _pinService.setLockout(_lockoutDuration);
        setState(() {
          _isLockedOut = true;
          _lockoutUntil = DateTime.now().add(_lockoutDuration);
          _currentPin = '';
          _pinController.clear();
          _errorText = 'Terlalu banyak percobaan. Tunggu 30 detik.';
        });
        _startLockoutCountdown();
      } else {
        setState(() {
          _currentPin = '';
          _pinController.clear();
          _errorText = 'PIN salah. ${_maxAttempts - attempts} percobaan tersisa.';
        });
      }
    }
  }

  Future<void> _useBiometric() async {
    if (_isBiometricLoading) return;
    setState(() {
      _isBiometricLoading = true;
      _errorText = null;
    });

    try {
      final canAuth = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuth) {
        setState(() {
          _isBiometricLoading = false;
          _errorText = 'Biometrik tidak tersedia di perangkat ini.';
        });
        return;
      }

      final success = await _localAuth.authenticate(
        localizedReason: 'Buka kunci aplikasi Bitanic',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!mounted) return;
      if (success) {
        await _pinService.resetFailedAttempts();
        widget.onUnlocked();
      } else {
        setState(() {
          _isBiometricLoading = false;
          _errorText = 'Biometrik gagal. Gunakan PIN Bitanic.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBiometricLoading = false;
        _errorText = 'Gagal membuka biometrik.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hitung sisa lockout
    String? lockoutText;
    if (_isLockedOut && _lockoutUntil != null) {
      final secs = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      lockoutText = 'Coba lagi dalam ${secs > 0 ? secs : 0} detik';
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Lock Icon — identik dengan SecurityVerificationScreen
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  _isBiometricLoading
                      ? SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary),
                          ),
                        )
                      : Icon(
                          Icons.lock_rounded,
                          size: 60,
                          color: colorScheme.primary,
                        ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Sesi Terkunci',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan PIN Bitanic untuk melanjutkan',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),

              // PIN Input Area: Stack with transparent TextField and custom Dots
              Stack(
                alignment: Alignment.center,
                children: [
                  // Fully layouted but transparent TextField to ensure keyboard opens reliably
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: TextField(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      showCursor: false,
                      cursorColor: Colors.transparent,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onPinChanged,
                      enabled: !_isLockedOut,
                    ),
                  ),

                  // PIN Dots (ignores taps so they pass to the TextField below)
                  IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final filled = i < _currentPin.length;
                        final hasError = _errorText != null;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? (hasError
                                    ? colorScheme.error
                                    : colorScheme.primary)
                                : Colors.transparent,
                            border: Border.all(
                              color: filled
                                  ? (hasError
                                      ? colorScheme.error
                                      : colorScheme.primary)
                                  : colorScheme.onSurface.withValues(alpha: 0.2),
                              width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Error / lockout text
              if (_errorText != null)
                Text(
                  _errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (lockoutText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lockoutText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),

              // Biometric button — identik dengan ElevatedButton di security screen
              if (!_isBiometricLoading && !_isLockedOut)
                ElevatedButton.icon(
                  onPressed: _useBiometric,
                  icon: const Icon(Icons.fingerprint_rounded, size: 20),
                  label: Text(
                    'Gunakan Fingerprint / Face ID',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
