import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/precision_service.dart';
import '../widgets/glass_card.dart';

class BandwidthEfficiencyScreen extends StatefulWidget {
  const BandwidthEfficiencyScreen({super.key});

  @override
  State<BandwidthEfficiencyScreen> createState() => _BandwidthEfficiencyScreenState();
}

class _BandwidthEfficiencyScreenState extends State<BandwidthEfficiencyScreen> {
  final PrecisionService _precisionService = PrecisionService();
  int _updateTrigger = 0;
  StreamSubscription<PrecisionRealtimeData>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = _precisionService.getRealtimeDataStream().listen((data) {
      if (mounted) {
        setState(() {
          _updateTrigger++;
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<PrecisionRealtimeData>(
      stream: _precisionService.getRealtimeDataStream(),
      builder: (context, realtimeSnapshot) {
        final realtimeData = realtimeSnapshot.data ?? PrecisionRealtimeData.empty();

        return StreamBuilder<CompressionStats>(
          stream: _precisionService.getCompressionStatsStream(),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ?? CompressionStats.empty();
            
            // Calculate saved percentage
            double savedPercent = 0.0;
            if (stats.originalSize > 0) {
              savedPercent = ((stats.originalSize - stats.compressedSize) / stats.originalSize) * 100;
            }
            if (savedPercent < 0) savedPercent = 0.0;

            // Build dynamic telemetry representation
            final String nVal = realtimeData.isValid ? "${realtimeData.n}" : "37";
            final String pVal = realtimeData.isValid ? "${realtimeData.p}" : "131";
            final String kVal = realtimeData.isValid ? "${realtimeData.k}" : "124";
            final String tempVal = realtimeData.isValid ? realtimeData.suhu.toStringAsFixed(1) : "27.5";
            final String humVal = realtimeData.isValid ? realtimeData.kelembaban.toStringAsFixed(1) : "31.9";
            final String phVal = realtimeData.isValid ? realtimeData.ph.toStringAsFixed(1) : "4.8";
            final String ecVal = realtimeData.isValid ? "${realtimeData.ec}" : "362";
            final String statusVal = realtimeData.isValid ? realtimeData.statusPupuk : "BUTUH PUPUK (RENDAH)";

            final String jsonString = '{\n'
                '  "n": $nVal,\n'
                '  "p": $pVal,\n'
                '  "k": $kVal,\n'
                '  "suhu": $tempVal,\n'
                '  "moisture": $humVal,\n'
                '  "ph": $phVal,\n'
                '  "ec": $ecVal,\n'
                '  "status": "$statusVal"\n'
                '}';

            final String csvString = '$nVal,$pVal,$kVal,$tempVal,$humVal,$phVal,$ecVal,$statusVal';

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  "Efisiensi Bandwidth IoT",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: colorScheme.onSurface),
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  // --- TOP HERO CARD (Angka Hemat Gede) ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Color(0xFF34D399), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "BANDWIDTH SAVED",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFA7F3D0),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${stats.savedBytes} Bytes",
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Lebih hemat ${savedPercent.toStringAsFixed(1)}% per pengiriman data!",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD1FAE5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Section: Apa Yang Sedang Terjadi?
                  _buildSectionHeader("Apa Yang Sedang Terjadi?"),
                  _buildIntroCard(isDark, colorScheme),
                  const SizedBox(height: 20),

                  // 2. Section: Alur Data Realtime
                  _buildSectionHeader("Alur Data Realtime"),
                  _buildRealtimeFlowchart(colorScheme, _updateTrigger),
                  const SizedBox(height: 24),

                  // 3. Section: Compression Efficiency (Persentase Efisiensi)
                  _buildSectionHeader("Compression Efficiency"),
                  _buildCompressionEfficiencyCard(isDark, colorScheme, stats, savedPercent),
                  const SizedBox(height: 20),

                  // 4. Section: Payload Sebelum vs Setelah Optimasi
                  _buildSectionHeader("Perbandingan Payload"),
                  _buildPayloadComparison(jsonString, csvString, stats, colorScheme),
                  const SizedBox(height: 20),

                  // 5. Section: Kenapa CSV Dipilih?
                  _buildSectionHeader("Kenapa CSV Dipilih?"),
                  _buildWhyCsvCard(isDark, colorScheme),
                  const SizedBox(height: 20),

                  // 6. Section: Dampak Terhadap Sistem
                  _buildSectionHeader("Dampak Terhadap Sistem"),
                  _buildImpactCard(isDark, colorScheme),
                  const SizedBox(height: 20),

                  // 7. Section: Kesimpulan
                  _buildSectionHeader("Kesimpulan"),
                  _buildConclusionCard(isDark, colorScheme),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildIntroCard(bool isDark, ColorScheme colorScheme) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline_rounded, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Sistem Bitanic mengoptimalkan pengiriman data dari perangkat IoT dengan melakukan serialisasi payload menjadi format CSV di tingkat hardware (ESP32 Central) sebelum dikirim ke Firebase Realtime Database. Hal ini bertujuan untuk menghemat penggunaan data internet secara berkala dengan memangkas overhead data secara masif dibandingkan format JSON biasa.",
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRealtimeFlowchart(ColorScheme colorScheme, int updateTrigger) {
    return Center(
      child: Column(
        children: [
          _PulsingNode(
            icon: Icons.sensors_rounded,
            title: "Sensor NPK",
            subtitle: "Mengukur unsur tanah mentah",
            color: const Color(0xFF38BDF8),
            updateTrigger: updateTrigger,
          ),
          _AnimatedConnector(color: const Color(0xFF38BDF8), updateTrigger: updateTrigger),
          _PulsingNode(
            icon: Icons.developer_board_rounded,
            title: "ESP32 Sensor",
            subtitle: "Transmitter pemrosesan lokal",
            color: const Color(0xFF38BDF8),
            updateTrigger: updateTrigger,
          ),
          _AnimatedConnector(color: const Color(0xFF818CF8), updateTrigger: updateTrigger),
          _PulsingNode(
            icon: Icons.wifi_tethering_rounded,
            title: "ESP-NOW Link",
            subtitle: "Transmisi nirkabel lokal",
            color: const Color(0xFF818CF8),
            updateTrigger: updateTrigger,
          ),
          _AnimatedConnector(color: const Color(0xFF818CF8), updateTrigger: updateTrigger),
          _PulsingNode(
            icon: Icons.router_rounded,
            title: "ESP32 Central",
            subtitle: "Receiver Gateway",
            color: const Color(0xFF34D399),
            updateTrigger: updateTrigger,
          ),
          _AnimatedConnector(color: const Color(0xFF34D399), updateTrigger: updateTrigger),
          _PulsingNode(
            icon: Icons.published_with_changes_rounded,
            title: "Optimasi Payload (JSON ➡️ CSV)",
            subtitle: "Menghapus overhead key-value",
            color: const Color(0xFF10B981),
            isHighlighted: true,
            updateTrigger: updateTrigger,
          ),
          _AnimatedConnector(color: const Color(0xFF10B981), updateTrigger: updateTrigger),
          _PulsingNode(
            icon: Icons.cloud_done_rounded,
            title: "Firebase Cloud DB",
            subtitle: "Penyimpanan data efisien",
            color: const Color(0xFFFBBF24),
            updateTrigger: updateTrigger,
          ),
          _AnimatedConnector(color: const Color(0xFFFBBF24), updateTrigger: updateTrigger),
          _PulsingNode(
            icon: Icons.eco_rounded,
            title: "BITANIC Mobile App",
            subtitle: "Aplikasi Flutter (Penerima Akhir)",
            color: const Color(0xFF34D399),
            updateTrigger: updateTrigger,
          ),
        ],
      ),
    );
  }

  Widget _buildCompressionEfficiencyCard(
      bool isDark, ColorScheme colorScheme, CompressionStats stats, double savedPercent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color ?? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pemberitahuan Sistem",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Persentase Data yang Dipangkas",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SemiCircleGauge(
              percentage: savedPercent,
              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                label: "Original JSON",
                value: "${stats.originalSize} B",
                color: const Color(0xFFEF4444),
              ),
              _buildMiniMetric(
                label: "Optimized CSV",
                value: "${stats.compressedSize} B",
                color: const Color(0xFF10B981),
              ),
              _buildMiniMetric(
                label: "Saved Bytes",
                value: "${stats.savedBytes} B",
                color: const Color(0xFF38BDF8),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniMetric({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPayloadComparison(
      String jsonString, String csvString, CompressionStats stats, ColorScheme colorScheme) {
    return Column(
      children: [
        // 1. JSON Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Format JSON Asli",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${stats.originalSize} Bytes",
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFCA5A5),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                jsonString,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: const Color(0xFFFECDD3),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: const Color(0xFFEF4444),
                  decorationThickness: 1.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        // Arrow Down Separator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ),

        // 2. CSV Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Format CSV Teroptimasi",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF86EFAC),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${stats.compressedSize} Bytes",
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF86EFAC),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                csvString,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFA7F3D0),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhyCsvCard(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color ?? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.help_outline_rounded, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Format JSON memiliki overhead key-value yang berulang pada setiap atribut (misalnya nama kunci 'n', 'p', 'k', 'suhu' dikirim terus-menerus). Sebaliknya, CSV hanya menyimpan nilai data mentah (value-only) yang dipisahkan tanda koma, memangkas byte berlebih secara masif.",
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImpactCard(bool isDark, ColorScheme colorScheme) {
    final impacts = [
      "Payload lebih kecil",
      "Transmisi lebih cepat",
      "Beban Firebase lebih ringan",
      "Cocok untuk ESP32",
      "Menghemat bandwidth IoT",
      "Mudah diproses Flutter",
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color ?? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: impacts.map((text) {
              return SizedBox(
                width: itemWidth,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildConclusionCard(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                "Rangkuman Teknis",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Optimasi payload pada sistem Bitanic dilakukan dengan meminimalkan format overhead data menggunakan serialisasi CSV di sisi gateway (ESP32 Central) sebelum dilempar ke cloud Firebase, menghasilkan efisiensi bandwidth yang terukur dan konstan di setiap interval transmisi.",
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingNode extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isHighlighted;
  final int updateTrigger;

  const _PulsingNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isHighlighted = false,
    this.updateTrigger = 0,
  });

  @override
  State<_PulsingNode> createState() => _PulsingNodeState();
}

class _PulsingNodeState extends State<_PulsingNode> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: widget.isHighlighted ? 1.08 : 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _pulseController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _PulsingNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateTrigger != oldWidget.updateTrigger && widget.updateTrigger > 0) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isHighlighted 
              ? widget.color.withValues(alpha: 0.15)
              : (isDark ? Theme.of(context).cardTheme.color ?? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isHighlighted 
                ? widget.color
                : widget.color.withValues(alpha: 0.2),
            width: widget.isHighlighted ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: widget.isHighlighted ? 0.25 : 0.05),
              blurRadius: widget.isHighlighted ? 12 : 6,
              offset: const Offset(0, 3),
            ),
            if (_glowAnimation.value > 0.0)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.7 * _glowAnimation.value),
                blurRadius: 16 * _glowAnimation.value,
                spreadRadius: 2.0 * _glowAnimation.value,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: widget.isHighlighted 
                        ? (isDark ? Colors.white : Colors.black)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AnimatedConnector extends StatefulWidget {
  final Color color;
  final int updateTrigger;

  const _AnimatedConnector({required this.color, this.updateTrigger = 0});

  @override
  State<_AnimatedConnector> createState() => _AnimatedConnectorState();
}

class _AnimatedConnectorState extends State<_AnimatedConnector> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late AnimationController _packetController;
  late Animation<double> _packetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _packetAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _packetController, curve: Curves.easeOut),
    );

    _packetController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedConnector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateTrigger != oldWidget.updateTrigger && widget.updateTrigger > 0) {
      _packetController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _packetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: 20,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConnectorPainter(
              progress: _animation.value,
              packetProgress: _packetAnimation.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final double progress;
  final double packetProgress;
  final Color color;

  _ConnectorPainter({
    required this.progress,
    required this.packetProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double startY = 0;
    final double endY = size.height;
    final double x = size.width / 2;

    // Draw dashed vertical line
    double y = startY;
    const double dashHeight = 4.0;
    const double spaceHeight = 4.0;
    while (y < endY) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dashHeight, endY)), paint);
      y += dashHeight + spaceHeight;
    }

    // Draw standard moving data packet (dot)
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final double currentY = startY + (endY - startY) * progress;
    canvas.drawCircle(Offset(x, currentY), 3.0, dotPaint);

    // Draw high priority packet transfer when updated
    if (packetProgress > 0.0 && packetProgress < 1.0) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.5 * (1.0 - packetProgress))
        ..style = PaintingStyle.fill;
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final double packetY = startY + (endY - startY) * packetProgress;
      // Draw pulse glow ring
      canvas.drawCircle(Offset(x, packetY), 6.5, pulsePaint);
      // Draw bright core
      canvas.drawCircle(Offset(x, packetY), 3.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.packetProgress != packetProgress ||
        oldDelegate.color != color;
  }
}

class SemiCircleGauge extends StatelessWidget {
  final double percentage;
  final double width;
  final List<Color> gradientColors;

  const SemiCircleGauge({
    super.key,
    required this.percentage,
    this.width = 180,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final height = width / 2;

    return SizedBox(
      width: width,
      height: height + 10,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: SemiCircleGaugePainter(
              percentage: percentage,
              backgroundColor: bgColor,
              gradientColors: gradientColors,
            ),
          ),
          Positioned(
            bottom: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${percentage.toStringAsFixed(1)}%",
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  "Efisiensi",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SemiCircleGaugePainter extends CustomPainter {
  final double percentage; // 0.0 to 100.0
  final Color backgroundColor;
  final List<Color> gradientColors;

  SemiCircleGaugePainter({
    required this.percentage,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    // Draw background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // start angle (180 degrees)
      math.pi, // sweep angle (180 degrees)
      false,
      bgPaint,
    );

    // Draw active gradient arc
    if (percentage > 0) {
      final sweepAngle = math.pi * (percentage / 100.0);
      final rect = Rect.fromCircle(center: center, radius: radius);
      
      final activePaint = Paint()
        ..shader = LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        math.pi,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
