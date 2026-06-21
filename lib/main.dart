import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart' as bitanic;
import 'services/theme_provider.dart';
import 'services/pin_provider.dart';
import 'main_layout.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/security_verification_screen.dart';
import 'screens/access_denied_screen.dart';
import 'screens/create_pin_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'widgets/auto_lock_wrapper.dart';




import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  runApp(const BitanicApp());
}

class BitanicApp extends StatelessWidget {
  const BitanicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => bitanic.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PinProvider()),
      ],
      child: const SecurityLifecycleWrapper(
        child: BitanicMaterialApp(),
      ),
    );
  }
}

class BitanicMaterialApp extends StatelessWidget {
  const BitanicMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BITANIC Precision Control',
      themeMode: themeProvider.themeMode,
      theme: _BitanicAppThemes.light(),
      darkTheme: _BitanicAppThemes.dark(),
      home: const AuthWrapper(),
      builder: (context, child) {
        if (kIsWeb) return child!;
        return AutoLockWrapper(child: child!);
      },
    );
  }
}

class SecurityLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const SecurityLifecycleWrapper({super.key, required this.child});

  @override
  State<SecurityLifecycleWrapper> createState() => _SecurityLifecycleWrapperState();
}

class _SecurityLifecycleWrapperState extends State<SecurityLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      debugPrint("[LIFECYCLE] App paused. Locking system & resetting biometrics.");
      Provider.of<bitanic.AuthProvider>(context, listen: false).resetBiometrics();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _BitanicAppThemes {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.light(
        primary: kIsWeb ? const Color(0xFF10B981) : const Color(0xFF0081C9),
        secondary: kIsWeb ? const Color(0xFF059669) : const Color(0xFF00AFEF),
        surface: Colors.white,
        onSurface: const Color(0xFF1E293B),
        error: const Color(0xFFEF4444),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kIsWeb ? const Color(0xFF060F08) : const Color(0xFF0F172A),
      colorScheme: ColorScheme.dark(
        primary: kIsWeb ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
        secondary: kIsWeb ? const Color(0xFF10B981) : const Color(0xFF00AFEF),
        surface: kIsWeb ? const Color(0xFF0C1E0F) : const Color(0xFF1E293B),
        onSurface: kIsWeb ? const Color(0xFFF0FDF4) : Colors.white,
        error: kIsWeb ? const Color(0xFFEF4444) : const Color(0xFFF87171),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: kIsWeb ? const Color(0xFF0C1E0F) : const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: kIsWeb ? const Color(0x1F22C55E) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _minLoadingDone = false;
  bool _wasAlreadyLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Cek apakah user sudah ada dari awal (auto-login)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _wasAlreadyLoggedIn = true;
      // Kalau sudah login dari awal, kita kasih liat loading screen yang "lama" (V1) biar estetik
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            _minLoadingDone = true;
          });
        }
      });
    } else {
      // Kalau belum login, kita tandai biar pas nanti login gak pake nunggu 6 detik lagi
      _minLoadingDone = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<bitanic.AuthProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1000),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildCurrentScreen(authProvider, user),
    );
  }

  Widget _buildCurrentScreen(bitanic.AuthProvider authProvider, User? user) {
    if (user == null) return const LoginScreen(key: ValueKey('login'));

    // Gate 1: Biometrics Verification (APK Mobile only — bypassed on Web)
    if (!kIsWeb && !authProvider.isBiometricVerified) {
      return const SecurityVerificationScreen(
        key: ValueKey('gate_biometrics'),
        mode: VerificationMode.biometrics,
      );
    }

    // Gate 2: Magic Link (Double 2FA) Verification — dinonaktifkan sepenuhnya
    // if (!authProvider.isMagicLinkVerified) {
    //   return const SecurityVerificationScreen(
    //     key: ValueKey('gate_magiclink'),
    //     mode: VerificationMode.magicLink,
    //   );
    // }

    // All gates cleared: wait for role synchronization
    if (authProvider.userRole == null || (_wasAlreadyLoggedIn && !_minLoadingDone)) {
      return const LoadingScreen(
        key: ValueKey('loading_v1'),
        message: "Sinkronisasi Sistem Presisi...",
      );
    }

    // Enforce role-based access restrictions
    if (kIsWeb) {
      // Web dashboard is restricted to admin only (petani is blocked)
      if (authProvider.userRole == 'petani') {
        return const AccessDeniedScreen(
          key: ValueKey('gate_access_denied_web'),
        );
      }
    }

    // Gate 3: PIN Security (APK Mobile only — tidak berlaku di Web)
    if (!kIsWeb) {
      final pinProvider = Provider.of<PinProvider>(context);

      // Tunggu PinProvider selesai membaca dari secure storage
      if (!pinProvider.isInitialized) {
        return const LoadingScreen(
          key: ValueKey('loading_pin_init'),
          message: "Memverifikasi Keamanan PIN...",
        );
      }

      // Jika PIN belum pernah dibuat → wajib setup dulu
      if (!pinProvider.isPinSetupComplete) {
        debugPrint('[GATE] PIN not set up. Showing CreatePinScreen.');
        return const CreatePinScreen(key: ValueKey('gate_pin_setup'));
      }

      // Jika PIN sudah ada tapi belum diverifikasi pada sesi ini → wajib verifikasi dulu
      if (!pinProvider.isPinVerified) {
        debugPrint('[GATE] PIN is set up but not verified. Showing PinLockScreen.');
        return PinLockScreen(
          key: const ValueKey('gate_pin_verify'),
          onUnlocked: () {
            pinProvider.markPinVerified();
          },
        );
      }
    }

    debugPrint("[GATE] ALL GATES CLEARED. ROLE: ${authProvider.userRole}");

    return const MainShell(key: ValueKey('mainShell'));
  }
}




