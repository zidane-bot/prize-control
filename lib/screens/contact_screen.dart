import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ContactScreen extends StatelessWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const ContactScreen({
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
                'Tim Pengembang',
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
                    width: isDesktop ? 900 : double.infinity,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Content Padding
                        Padding(
                          padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                          child: Column(
                            children: [
                              if (isEmbedded && onBack != null) ...[
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: _buildCardBackButton(
                                      context, isDark, colorScheme),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Header Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_alt_rounded,
                                    color: Colors.orange, size: 36),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Tim Pengembang",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: isDesktop ? 36 : 28,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                "Development Team",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: isDesktop ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "BITANIC Precision Control — Politeknik Negeri Jakarta, 2026",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceMono(
                                  fontSize: isDesktop ? 12 : 11,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Team Grid
                              if (isDesktop)
                                _buildDesktopTeamGrid(isDark, colorScheme)
                              else
                                _buildMobileTeamGrid(isDark, colorScheme),
                            ],
                          ),
                        ),

                        // Footer Institutional Info
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.1 : 0.05), // Light teal/tosca
                            border: Border(
                              top: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04),
                                  width: 1),
                            ),
                          ),
                          padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                          child: isDesktop
                              ? _buildDesktopFooterGrid(isDark, colorScheme)
                              : _buildMobileFooterGrid(isDark, colorScheme),
                        ),
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

  Widget _buildDesktopTeamGrid(bool isDark, ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 2.5,
      children: _teamMembers.map((member) => _buildTeamCard(member, isDark, colorScheme)).toList(),
    );
  }

  Widget _buildMobileTeamGrid(bool isDark, ColorScheme colorScheme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _teamMembers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildTeamCard(_teamMembers[index], isDark, colorScheme),
    );
  }

  Widget _buildTeamCard(Map<String, String> member, bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded,
                color: isDark ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.6),
                size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member['name']!,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "NIM: ${member['nim']}",
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black87.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member['role']!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFooterGrid(bool isDark, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFooterItem(Icons.school_rounded, "Program Studi",
                  "Teknik Multimedia Jaringan", isDark, colorScheme),
              const SizedBox(height: 20),
              _buildFooterItem(Icons.article_rounded, "Jurusan",
                  "Teknik Informatika dan Komputer", isDark, colorScheme),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFooterItem(Icons.account_balance_rounded, "Institusi",
                  "Politeknik Negeri Jakarta", isDark, colorScheme),
              const SizedBox(height: 20),
              _buildFooterItem(Icons.supervisor_account_rounded, "Dosen PK",
                  "Dr. Defiana Arnaldy, S.T.P., M.Si.", isDark, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooterGrid(bool isDark, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFooterItem(Icons.school_rounded, "Program Studi",
            "Teknik Multimedia Jaringan", isDark, colorScheme),
        const SizedBox(height: 16),
        _buildFooterItem(Icons.article_rounded, "Jurusan",
            "Teknik Informatika dan Komputer", isDark, colorScheme),
        const SizedBox(height: 16),
        _buildFooterItem(Icons.account_balance_rounded, "Institusi",
            "Politeknik Negeri Jakarta", isDark, colorScheme),
        const SizedBox(height: 16),
        _buildFooterItem(Icons.supervisor_account_rounded, "Dosen PK",
            "Dr. Defiana Arnaldy, S.T.P., M.Si.", isDark, colorScheme),
      ],
    );
  }

  Widget _buildFooterItem(
      IconData icon, String label, String value, bool isDark, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            color: isDark ? Colors.white70 : Colors.black87.withValues(alpha: 0.6),
            size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black87.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                  textBaseline: TextBaseline.alphabetic,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final List<Map<String, String>> _teamMembers = const [
    {
      "name": "Radhin Fauzan Abdillah",
      "nim": "2307422038",
      "role": "IoT Hardware & Edge Computing Engineer",
    },
    {
      "name": "Achmad Zahri Ramadhan",
      "nim": "2307422028",
      "role": "Web Dashboard UI/UX Developer",
    },
    {
      "name": "Rava Ramadhan Setiadi",
      "nim": "2307422037",
      "role": "Mobile App Flutter Developer",
    },
    {
      "name": "Zidane Rafiyanto",
      "nim": "2307422039",
      "role": "Cloud Database & Security Administrator",
    },
  ];
}
