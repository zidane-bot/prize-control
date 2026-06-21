import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/pin_service.dart';
import '../services/pin_provider.dart';

/// Halaman setup PIN Bitanic 6 digit untuk pertama kali.
/// Desain mengikuti 100% UI/UX Login Screen Bitanic yang sudah ada.
class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen>
    with SingleTickerProviderStateMixin {
  final PinService _pinService = PinService();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  int _step = 0; // 0 = enter, 1 = confirm
  String _firstPin = '';
  String _currentPin = '';
  String? _errorText;
  bool _isSaving = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String val) {
    if (_isSaving) return;
    setState(() {
      _errorText = null;
      _currentPin = val;
    });
    if (val.length == 6) {
      _onPinComplete();
    }
  }

  Future<void> _onPinComplete() async {
    if (_step == 0) {
      // Step 1: simpan PIN pertama, pindah ke konfirmasi
      setState(() {
        _firstPin = _currentPin;
        _currentPin = '';
        _pinController.clear();
        _step = 1;
      });
    } else {
      // Step 2: konfirmasi PIN
      if (_currentPin == _firstPin) {
        setState(() => _isSaving = true);
        await _pinService.createPin(_currentPin);
        if (mounted) {
          Provider.of<PinProvider>(context, listen: false).markPinSetupComplete();
        }
      } else {
        // PIN tidak cocok — shake & reset
        await _shakeController.forward(from: 0);
        setState(() {
          _errorText = 'PIN tidak cocok. Silakan ulangi dari awal.';
          _currentPin = '';
          _firstPin = '';
          _pinController.clear();
          _step = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String title = _step == 0 ? 'Buat PIN Bitanic' : 'Konfirmasi PIN';
    final String subtitle = _step == 0
        ? 'Masukkan PIN 6 digit untuk keamanan aplikasi'
        : 'Masukkan kembali PIN yang sama';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo — identik dengan Login Screen
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BITANIC',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keamanan PIN Aplikasi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),

                // Card — identik dengan Login Screen
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

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
                            ),
                          ),
                          
                          // PIN Dots Indicator (ignores taps so they pass to the TextField below)
                          IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                final offset =
                                    _shakeAnimation.value * 8 * ((_shakeController.value < 0.5) ? 1 : -1);
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: child,
                                );
                              },
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
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Error text
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Step indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _step ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _step
                                  ? colorScheme.primary
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
