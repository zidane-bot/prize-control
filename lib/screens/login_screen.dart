import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart' as bitanic_auth;
import '../services/theme_provider.dart';
import 'loading_screen_v2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isRegisterMode = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleAuth(BuildContext context) async {
    final authProvider = Provider.of<bitanic_auth.AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email dan password wajib diisi");
      return;
    }

    try {
      if (_isRegisterMode) {
        debugPrint("[UI] Initializing account setup...");
        await authProvider.registerWithEmail(email, password);
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registrasi Berhasil! Silakan Masuk."), backgroundColor: Colors.green),
          );
          setState(() => _isRegisterMode = false);
        }
      } else {
        debugPrint("[UI] Initializing password authorization...");
        await authProvider.loginWithEmail(email, password);
      }
    } catch (e) {
      if (!mounted) return;
      if (authProvider.errorMessage != null) {
        _showError(authProvider.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = themeProvider.isDarkMode;
    final authProvider = Provider.of<bitanic_auth.AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark 
          ? (kIsWeb ? const Color(0xFF060F08) : const Color(0xFF0F172A)) 
          : const Color(0xFFF8FAFC),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: authProvider.isLoading 
          ? LoadingScreenV2(
              key: const ValueKey('login_loading'),
              message: _isRegisterMode ? "Mendaftarkan Akun Baru..." : "Memverifikasi Kredensial...",
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: kIsWeb ? 420 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Friendly Agriculture Leaf Logo
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
                          Icons.eco_rounded, 
                          size: 48, 
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "BITANIC",
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sistem Presisi Petani Cabai",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Premium Card for Login fields
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? (kIsWeb ? const Color(0xFF0C1E0F) : const Color(0xFF1E293B)) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: kIsWeb 
                                ? const Color(0x1F22C55E) 
                                : colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isRegisterMode ? "Pendaftaran Akun" : "Masuk Akun",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            _buildTextField(
                              controller: _emailController,
                              label: "Surel / Email",
                              icon: Icons.mail_outline_rounded,
                              hint: "nama@email.com",
                              context: context,
                            ),
                            const SizedBox(height: 18),
                            _buildTextField(
                              controller: _passwordController,
                              label: "Kata Sandi",
                              icon: Icons.lock_open_rounded,
                              hint: "Kata sandi akun Anda",
                              isPassword: true,
                              obscureText: !_isPasswordVisible,
                              onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              context: context,
                            ),
                            const SizedBox(height: 28),

                            // Submit Button
                            ElevatedButton(
                              onPressed: authProvider.isLoading ? null : () => _handleAuth(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                shadowColor: colorScheme.primary.withValues(alpha: 0.2),
                              ),
                              child: Text(
                                _isRegisterMode ? "Daftar Akun Baru" : "Masuk ke Aplikasi",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Toggle Mode Button
                            TextButton(
                              onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                              child: Text(
                                _isRegisterMode
                                    ? "Sudah punya akun? Masuk disini"
                                    : "Belum punya akses? Hubungi Admin / Daftar",
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Google Login Button (Only in login mode)
                      if (!_isRegisterMode) ...[
                        OutlinedButton.icon(
                          onPressed: authProvider.isLoading ? null : () => authProvider.signInWithGoogle(),
                          icon: Image.network(
                            'https://www.gstatic.com/images/branding/product/2x/googleg_96dp.png',
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.login_rounded, size: 20),
                          ),
                          label: Text(
                            "Masuk dengan Google",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            side: BorderSide(
                              color: kIsWeb 
                                  ? const Color(0x1F22C55E) 
                                  : colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: isDark 
                                ? (kIsWeb ? const Color(0xFF0C1E0F) : const Color(0xFF1E293B)).withValues(alpha: 0.5) 
                                : Colors.white,
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required BuildContext context,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              fontSize: 15, 
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon, 
                color: colorScheme.primary.withValues(alpha: 0.7), 
                size: 18,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                        color: colorScheme.onSurface.withValues(alpha: 0.3), 
                        size: 18,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
