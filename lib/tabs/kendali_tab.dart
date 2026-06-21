import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/precision_service.dart';
import 'package:intl/intl.dart';

class KendaliTab extends StatefulWidget {
  const KendaliTab({super.key});

  @override
  State<KendaliTab> createState() => _KendaliTabState();
}


class _KendaliTabState extends State<KendaliTab> {
  final PrecisionService _precisionService = PrecisionService();
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    // Rebuild every 15 seconds to refresh the ESP32 offline check
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<String>(
        stream: _precisionService.getLastActiveTimeStream(),
        builder: (context, activeTimeSnapshot) {
          bool isEspOnline = false;
          
          if (activeTimeSnapshot.hasData && activeTimeSnapshot.data!.isNotEmpty) {
            final timeStr = activeTimeSnapshot.data!;
            try {
              final lastTime = DateFormat('dd/MM/yyyy HH:mm:ss').parse(timeStr.trim());
              isEspOnline = DateTime.now().difference(lastTime).inSeconds < 120;
            } catch (_) {}
          }

          return StreamBuilder<Map<String, bool>>(
            stream: _precisionService.getControlStream(),
            builder: (context, controlSnapshot) {
              final controls = controlSnapshot.data ?? {
                'R1': false,
                'R2': false,
                'R3': false,
                'R4': false,
              };

              final r1 = isEspOnline ? (controls['R1'] ?? false) : false;
              final r2 = isEspOnline ? (controls['R2'] ?? false) : false;
              final r3 = isEspOnline ? (controls['R3'] ?? false) : false;
              final r4 = isEspOnline ? (controls['R4'] ?? false) : false;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    "Pemantauan Sistem Otomatis",
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Memantau status aktuator relay R1-R4 yang bekerja secara real-time di lahan.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- MAIN STATUS CARD ---
                  _buildMainStatusCard(isEspOnline, r1, r2, r3, r4, colorScheme, isDark),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Daftar Aktuator Relay",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "OTOMATIS (READ-ONLY)",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- ACTUATOR SWITCH GRID ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildActuatorCard(
                        title: "R1: Pompa Besar",
                        subtitle: "Dripper irigasi utama",
                        isOn: r1,
                        icon: Icons.speed_rounded,
                        activeColor: Colors.deepPurple,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        isEspOnline: isEspOnline,
                      ),
                      _buildActuatorCard(
                        title: "R2: Pompa Pupuk",
                        subtitle: "Menyalakan dosing pupuk",
                        isOn: r2,
                        icon: Icons.opacity_rounded,
                        activeColor: Colors.teal,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        isEspOnline: isEspOnline,
                      ),
                      _buildActuatorCard(
                        title: "R3: Pompa Air",
                        subtitle: "Mengalirkan air irigasi",
                        isOn: r3,
                        icon: Icons.water_drop_rounded,
                        activeColor: Colors.blue,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        isEspOnline: isEspOnline,
                      ),
                      _buildActuatorCard(
                        title: "R4: Motor Pengaduk",
                        subtitle: "Mengaduk pupuk & air",
                        isOn: r4,
                        icon: Icons.autorenew_rounded,
                        activeColor: Colors.amber.shade700,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        isEspOnline: isEspOnline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Informative Footer Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Seluruh kendali berjalan otomatis berdasarkan kebutuhan tanaman Anda dan perintah dari modul ESP32 Central.",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainStatusCard(bool isEspOnline, bool r1, bool r2, bool r3, bool r4, ColorScheme colorScheme, bool isDark) {
    final int activeCount = isEspOnline ? ((r1 ? 1 : 0) + (r2 ? 1 : 0) + (r3 ? 1 : 0) + (r4 ? 1 : 0)) : 0;
    
    final String activeLabel;
    final List<Color> gradientColors;
    final IconData cardIcon;
    final String descriptionText;

    if (!isEspOnline) {
      activeLabel = "ESP32 Central Offline";
      gradientColors = [const Color(0xFFEF4444), const Color(0xFF991B1B)]; // Crimson Red
      cardIcon = Icons.cloud_off_rounded;
      descriptionText = "Modul ESP32 Central terputus. Menampilkan status siaga terakhir. Periksa daya dan jaringan internet alat.";
    } else if (activeCount > 0) {
      activeLabel = "$activeCount Aktuator Bekerja";
      gradientColors = [colorScheme.primary, colorScheme.secondary];
      cardIcon = Icons.settings_suggest_rounded;
      descriptionText = "Sistem sedang mengoperasikan penyiraman & pemupukan otomatis. Pastikan tangki penampung memiliki stok air & pupuk yang cukup.";
    } else {
      activeLabel = "Sistem Siaga (Standby)";
      gradientColors = [const Color(0xFF475569), const Color(0xFF1E293B)];
      cardIcon = Icons.lock_clock_rounded;
      descriptionText = "Tidak ada perintah berjalan. Aktuator berada dalam mode standby dan mematuhi jadwal sekuens otomatis dari Central.";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (!isEspOnline ? const Color(0xFFEF4444) : (activeCount > 0 ? colorScheme.primary : Colors.grey)).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cardIcon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "OVERVIEW OPERASIONAL",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            descriptionText,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorCard({
    required String title,
    required String subtitle,
    required bool isOn,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
    required ColorScheme colorScheme,
    required bool isEspOnline,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn ? activeColor.withValues(alpha: 0.4) : colorScheme.onSurface.withValues(alpha: 0.05),
          width: isOn ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isOn ? activeColor : Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _AnimatedActuatorIcon(
                  icon: icon,
                  isOn: isOn,
                  color: activeColor,
                ),
              ),
              
              // Clean Premium Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: !isEspOnline
                      ? Colors.red.withValues(alpha: 0.1)
                      : (isOn ? activeColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isEspOnline
                        ? Colors.red.withValues(alpha: 0.2)
                        : (isOn ? activeColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1)),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOn && isEspOnline) ...[
                      _PulseDot(color: activeColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      !isEspOnline
                          ? "OFFLINE"
                          : (isOn ? "AKTIF" : "SIAGA"),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: !isEspOnline
                            ? Colors.red
                            : (isOn ? activeColor : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 3,
              spreadRadius: 0.5,
            )
          ],
        ),
      ),
    );
  }
}

class _AnimatedActuatorIcon extends StatefulWidget {
  final IconData icon;
  final bool isOn;
  final Color color;
  const _AnimatedActuatorIcon({
    required this.icon,
    required this.isOn,
    required this.color,
  });

  @override
  State<_AnimatedActuatorIcon> createState() => _AnimatedActuatorIconState();
}

class _AnimatedActuatorIconState extends State<_AnimatedActuatorIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.isOn) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedActuatorIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isOn && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOn) {
      return Icon(widget.icon, color: Colors.grey, size: 24);
    }
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: 24),
    );
  }
}
