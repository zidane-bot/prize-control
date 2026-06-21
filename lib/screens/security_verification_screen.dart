import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_provider.dart' as bitanic_auth;

enum VerificationMode { magicLink, biometrics }

class SecurityVerificationScreen extends StatefulWidget {
  final VerificationMode mode;
  const SecurityVerificationScreen({super.key, this.mode = VerificationMode.biometrics});

  @override
  State<SecurityVerificationScreen> createState() => _SecurityVerificationScreenState();
}

class _SecurityVerificationScreenState extends State<SecurityVerificationScreen> {
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Decide what to do based on mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mode == VerificationMode.biometrics) {
        _authenticateBiometrics();
      }
    });
  }

  Future<void> _authenticateBiometrics() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    
    debugPrint("[UI] Triggering biometric scan gate...");
    final authProvider = Provider.of<bitanic_auth.AuthProvider>(context, listen: false);
    await authProvider.authenticateWithBiometrics();
    
    if (mounted) {
      setState(() => _isVerifying = false);
    }
  }

  void _showManualLinkDialog(BuildContext context, bitanic_auth.AuthProvider authProvider) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          title: Text(
            "Verifikasi Manual",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Salin tautan login dari email Anda dan tempel di bawah ini:",
                style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: "Tautan Verifikasi (URL)",
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal", style: GoogleFonts.inter(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                final link = textController.text.trim();
                if (link.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await authProvider.completeMagicLink(link);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal verifikasi link: $e"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              },
              child: const Text("Verifikasi"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<bitanic_auth.AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Status Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 1),
                    ),
                  ),
                  _isVerifying || authProvider.isLoading
                    ? SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      )
                    : InkWell(
                        onTap: widget.mode == VerificationMode.biometrics ? _authenticateBiometrics : null,
                        child: Icon(
                          widget.mode == VerificationMode.magicLink ? Icons.mark_email_unread_outlined : Icons.fingerprint_rounded,
                          size: 60,
                          color: colorScheme.primary,
                        ),
                      ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              Text(
                widget.mode == VerificationMode.magicLink ? "Verifikasi Email" : "Keamanan Perangkat",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24, 
                  fontWeight: FontWeight.w800, 
                  color: colorScheme.onSurface
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.onSurface.withValues(alpha: 0.03),
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.mode == VerificationMode.magicLink
                        ? "Link verifikasi telah dikirim ke email Anda. Silakan klik link tersebut untuk melepaskan sistem penguncian."
                        : "Sistem terkunci. Scan biometrics atau masukkan PIN perangkat untuk melanjutkan akses kontrol.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    if (widget.mode == VerificationMode.magicLink && authProvider.pendingEmail != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        authProvider.pendingEmail!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 48),

              if (widget.mode == VerificationMode.biometrics && !_isVerifying)
                ElevatedButton(
                  onPressed: _authenticateBiometrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text(
                    "SCAN SEKARANG",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (widget.mode == VerificationMode.magicLink) ...[
                  TextButton.icon(
                    onPressed: authProvider.isLoading ? null : () => authProvider.initiateMagicLink(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      "Kirim Ulang Link",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: authProvider.isLoading ? null : () => _showManualLinkDialog(context, authProvider),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text("Masukkan Link Secara Manual"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
                
              const Spacer(),
              
              TextButton(
                onPressed: () => authProvider.logout(),
                child: Text(
                  "Keluar Sesi",
                  style: GoogleFonts.inter(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
