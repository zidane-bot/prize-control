import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AboutScreen extends StatelessWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const AboutScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Check screen width for responsiveness
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isEmbedded
          ? Colors.transparent
          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
      extendBodyBehindAppBar: false,
      appBar: isEmbedded
          ? null
          : AppBar(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'Tentang Bitanic',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : Colors.black, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  height: 1.0,
                ),
              ),
            ),
      body: Stack(
        children: [
          // Background Image with Dark Overlay (Agriculture / Teal Vibe)
          if (!isEmbedded)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF0F172A), // Dark slate
                            const Color(0xFF064E3B), // Deep emerald/teal
                            const Color(0xFF022C22), // Even deeper green
                          ]
                        : [
                            const Color(0xFFE2E8F0), // Softer slate
                            const Color(0xFFD1FAE5), // Soft mint green
                            const Color(0xFFA7F3D0), // Slightly darker mint
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

          // Subtle glowing orb effect in the background
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF10B981).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 100,
                      spreadRadius: 50)
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: 24, vertical: isEmbedded ? 20 : 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: isDesktop ? 1000 : double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isDark ? 0.4 : 0.04),
                          blurRadius: 30,
                          spreadRadius: isDark ? -5 : 0,
                          offset: isDark ? Offset.zero : const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEmbedded && onBack != null) ...[
                          _buildCardBackButton(context, isDark, colorScheme),
                          const SizedBox(height: 24),
                        ],
                        isDesktop
                            ? _buildDesktopLayout(context, isDark, colorScheme)
                            : _buildMobileLayout(context, isDark, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBackButton(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onBack,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : colorScheme.onSurface,
                  size: 12),
              const SizedBox(width: 8),
              Text(
                'Kembali ke Dashboard',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Indonesia)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("Tentang BITANIC Precision Control", isDark, colorScheme,
                  isSecondary: false),
              const SizedBox(height: 16),
              _buildParagraph(
                  "Sistem otomasi pertanian berbasis IoT yang mengintegrasikan sensor NPK RS485, komputasi tepi (Edge Computing) ESP32 dengan Logika Fuzzy, dan Firebase. Sistem ini tidak hanya memantau, tetapi secara otonom mengeksekusi peracikan presisi dan penyiraman nutrisi sesuai jadwal biologis tanaman.",
                  isDark,
                  colorScheme),
              const SizedBox(height: 32),
              _buildSectionTitle("Fitur Utama", const Color(0xFF10B981)),
              const SizedBox(height: 16),
              _buildFeatureItem(
                  Icons.memory_rounded,
                  "Sensor NPK & Komputasi Tepi",
                  "Pemrosesan data tanah (N, P, K, pH, Suhu) secara lokal menggunakan Fuzzy Logic tanpa delay internet.",
                  isDark,
                  colorScheme),
              _buildFeatureItem(
                  Icons.wifi_tethering_rounded,
                  "Jaringan Radio ESP-NOW",
                  "Komunikasi kilat antar-node di lahan terbuka bebas hambatan router Wi-Fi.",
                  isDark,
                  colorScheme),
              _buildFeatureItem(
                  Icons.schedule_rounded,
                  "Sistem Schedulling & Fail-Safe",
                  "Eksekusi penyiraman cerdas berbasis modul RTC (Jam 03:00 & 09:00) yang tetap berjalan meski sensor atau internet terputus.",
                  isDark,
                  colorScheme),
              _buildFeatureItem(
                  Icons.dashboard_rounded,
                  "Dashboard Interaktif Flutter",
                  "Kendali jarak jauh, visualisasi tren historis, dan status toleransi kesalahan perangkat via Web & Mobile.",
                  isDark,
                  colorScheme),
              const SizedBox(height: 32),
              _buildSectionTitle("Manfaat", const Color(0xFF10B981)),
              const SizedBox(height: 8),
              _buildParagraph(
                  "Mencegah keracunan akibat overdosis pupuk, menghemat konsumsi air dan kuota bandwidth, serta memastikan tanaman cabai mendapat nutrisi pada waktu fotosintesis yang paling optimal.",
                  isDark,
                  colorScheme),
            ],
          ),
        ),

        // Vertical Divider
        Container(
          width: 1,
          height: 600, // Approximate height to keep separator visible
          margin: const EdgeInsets.symmetric(horizontal: 40),
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
        ),

        // Right Column (English)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("About BITANIC Precision Control", isDark, colorScheme,
                  isSecondary: true),
              const SizedBox(height: 16),
              _buildParagraph(
                  "An IoT-based agricultural automation system integrating NPK RS485 sensors, ESP32 Edge Computing with Fuzzy Logic, and Firebase. This system doesn't just monitor; it autonomously executes precise nutrient mixing and watering based on the plant's biological schedule.",
                  isDark,
                  colorScheme,
                  isSecondary: true),
              const SizedBox(height: 32),
              _buildSectionTitle("Key Features", const Color(0xFF34D399)),
              const SizedBox(height: 16),
              _buildFeatureItem(
                  Icons.memory_rounded,
                  "NPK Sensor & Edge Computing",
                  "Localized soil data processing (N, P, K, pH, Temp) using Fuzzy Logic with zero internet delay.",
                  isDark,
                  colorScheme,
                  isSecondary: true),
              _buildFeatureItem(
                  Icons.wifi_tethering_rounded,
                  "ESP-NOW Radio Network",
                  "Lightning-fast, node-to-node communication in open fields independent of Wi-Fi routers.",
                  isDark,
                  colorScheme,
                  isSecondary: true),
              _buildFeatureItem(
                  Icons.schedule_rounded,
                  "Scheduling & Fail-Safe System",
                  "Smart watering execution powered by an RTC module (03:00 & 09:00) that remains operational even if the sensor or internet fails.",
                  isDark,
                  colorScheme,
                  isSecondary: true),
              _buildFeatureItem(
                  Icons.dashboard_rounded,
                  "Interactive Flutter Dashboard",
                  "Remote override, historical trend visualization, and device fault-tolerance status via Web & Mobile.",
                  isDark,
                  colorScheme,
                  isSecondary: true),
              const SizedBox(height: 32),
              _buildSectionTitle("Benefits", const Color(0xFF34D399)),
              const SizedBox(height: 8),
              _buildParagraph(
                  "Prevents plant toxicity from fertilizer overdose, saves water and bandwidth consumption, and ensures chili plants receive nutrients at their optimal photosynthetic times.",
                  isDark,
                  colorScheme,
                  isSecondary: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indonesian Section
        _buildHeader("Tentang BITANIC Precision Control", isDark, colorScheme,
            isSecondary: false),
        const SizedBox(height: 16),
        _buildParagraph(
            "Sistem otomasi pertanian berbasis IoT yang mengintegrasikan sensor NPK RS485, komputasi tepi (Edge Computing) ESP32 dengan Logika Fuzzy, dan Firebase. Sistem ini tidak hanya memantau, tetapi secara otonom mengeksekusi peracikan presisi dan penyiraman nutrisi sesuai jadwal biologis tanaman.",
            isDark,
            colorScheme),
        const SizedBox(height: 32),
        _buildSectionTitle("Fitur Utama", const Color(0xFF10B981)),
        const SizedBox(height: 16),
        _buildFeatureItem(
            Icons.memory_rounded,
            "Sensor NPK & Komputasi Tepi",
            "Pemrosesan data tanah secara lokal menggunakan Fuzzy Logic tanpa delay internet.",
            isDark,
            colorScheme),
        _buildFeatureItem(
            Icons.wifi_tethering_rounded,
            "Jaringan Radio ESP-NOW",
            "Komunikasi kilat antar-node di lahan terbuka.",
            isDark,
            colorScheme),
        _buildFeatureItem(
            Icons.schedule_rounded,
            "Sistem Schedulling & Fail-Safe",
            "Eksekusi cerdas berbasis RTC yang kebal putus internet.",
            isDark,
            colorScheme),
        _buildFeatureItem(
            Icons.dashboard_rounded,
            "Dashboard Interaktif Flutter",
            "Kendali jarak jauh & visualisasi via Web/Mobile.",
            isDark,
            colorScheme),
        const SizedBox(height: 24),
        _buildSectionTitle("Manfaat", const Color(0xFF10B981)),
        const SizedBox(height: 8),
        _buildParagraph(
            "Mencegah keracunan pupuk, menghemat air, dan memastikan nutrisi di waktu optimal.",
            isDark,
            colorScheme),

        const SizedBox(height: 40),
        Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            thickness: 1),
        const SizedBox(height: 40),

        // English Section
        _buildHeader("About BITANIC Precision Control", isDark, colorScheme,
            isSecondary: true),
        const SizedBox(height: 16),
        _buildParagraph(
            "An IoT-based agricultural automation system integrating NPK RS485 sensors, ESP32 Edge Computing with Fuzzy Logic, and Firebase.",
            isDark,
            colorScheme,
            isSecondary: true),
        const SizedBox(height: 32),
        _buildSectionTitle("Key Features", const Color(0xFF34D399)),
        const SizedBox(height: 16),
        _buildFeatureItem(
            Icons.memory_rounded,
            "NPK Sensor & Edge Computing",
            "Localized soil data processing using Fuzzy Logic.",
            isDark,
            colorScheme,
            isSecondary: true),
        _buildFeatureItem(
            Icons.wifi_tethering_rounded,
            "ESP-NOW Radio Network",
            "Node-to-node communication in open fields.",
            isDark,
            colorScheme,
            isSecondary: true),
        _buildFeatureItem(
            Icons.schedule_rounded,
            "Scheduling & Fail-Safe System",
            "RTC-powered execution immune to internet drops.",
            isDark,
            colorScheme,
            isSecondary: true),
        _buildFeatureItem(
            Icons.dashboard_rounded,
            "Interactive Flutter Dashboard",
            "Remote override via Web & Mobile.",
            isDark,
            colorScheme,
            isSecondary: true),
      ],
    );
  }

  // --- Typography & UI Helpers ---

  Widget _buildHeader(String text, bool isDark, ColorScheme colorScheme,
      {bool isSecondary = false}) {
    Color baseColor = isDark ? Colors.white : Colors.black87;
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: isSecondary ? baseColor.withValues(alpha: 0.75) : baseColor,
        height: 1.2,
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildParagraph(String text, bool isDark, ColorScheme colorScheme,
      {bool isSecondary = false}) {
    Color baseColor = isDark ? Colors.white : Colors.black87;
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: isSecondary
            ? baseColor.withValues(alpha: 0.65)
            : baseColor.withValues(alpha: 0.82),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description,
      bool isDark, ColorScheme colorScheme,
      {bool isSecondary = false}) {
    Color baseTitleColor = isDark ? Colors.white : Colors.black87;
    Color baseDescColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: const Color(0xFF34D399), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSecondary
                        ? baseTitleColor.withValues(alpha: 0.75)
                        : baseTitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: isSecondary
                        ? baseDescColor.withValues(alpha: 0.55)
                        : baseDescColor.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
