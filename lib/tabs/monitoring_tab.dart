import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/precision_service.dart';

class MonitoringTab extends StatefulWidget {
  const MonitoringTab({super.key});

  @override
  State<MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends State<MonitoringTab> with SingleTickerProviderStateMixin {
  final PrecisionService _precisionService = PrecisionService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Pulse animation for network connection state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _refreshSensorData() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Data disinkronkan secara real-time!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER WITH SYNC INDICATOR ---
              _buildHeader(colorScheme, isDark),
              const SizedBox(height: 20),

              // --- MAIN REAL-TIME DASHBOARD ---
              Expanded(
                child: _buildRealtimeTab(colorScheme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Builder
  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Precision Control",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Analisis kesuburan tanah & log historis pupuk NPK.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              
              // Firebase Live connection status
              StreamBuilder<bool>(
                stream: _precisionService.getConnectionStatusStream(),
                builder: (context, connectionSnapshot) {
                  final bool isConnected = connectionSnapshot.data ?? false;
                  Color statusColor = isConnected ? const Color(0xFF10B981) : Colors.amber;
                  String statusLabel = isConnected ? "Firebase Terkoneksi" : "Menghubungkan Database...";

                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(
                              alpha: isConnected ? 0.2 + (_pulseController.value * 0.3) : 0.2
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.6),
                                    blurRadius: isConnected ? 4 + (_pulseController.value * 4) : 4,
                                    spreadRadius: isConnected ? _pulseController.value * 2 : 0,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor.darken(0.1, isDark),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        
        // Manual Sync trigger
        Tooltip(
          message: "Sinkronkan Data Sensor",
          child: InkWell(
            onTap: _refreshSensorData,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Icon(Icons.sync_rounded, color: colorScheme.primary, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  // TAB 1: REAL-TIME DASHBOARD
  Widget _buildRealtimeTab(ColorScheme colorScheme, bool isDark) {
    return StreamBuilder<PrecisionRealtimeData>(
      stream: _precisionService.getRealtimeDataStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(colorScheme, "Menghubungkan ke Realtime Database...", "/Bitanic/Precision/Sensor_NPK_Realtime");
        }

        final data = snapshot.data ?? PrecisionRealtimeData.empty();

        return RefreshIndicator(
          onRefresh: () async {
            _refreshSensorData();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Fuzzy Logic Recommendation Banner
                _buildFuzzyBanner(data),
                const SizedBox(height: 20),

                // 2. Section Title
                Text(
                  "Parameter Nutrisi & Lingkungan",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Grid representation (Using rows for responsive scaling & full-width layout)
                Row(
                  children: [
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "Nitrogen (N)",
                        value: data.isValid ? "${data.n} mg/kg" : "N/A",
                        subtitle: "Unsur Hara Makro",
                        icon: Icons.grass_rounded,
                        color: Colors.blue,
                        progress: data.isValid ? (data.n / 300.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "Fosfor (P)",
                        value: data.isValid ? "${data.p} mg/kg" : "N/A",
                        subtitle: "Unsur Hara Makro",
                        icon: Icons.grain_rounded,
                        color: Colors.purple,
                        progress: data.isValid ? (data.p / 150.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "Kalium (K)",
                        value: data.isValid ? "${data.k} mg/kg" : "N/A",
                        subtitle: "Unsur Hara Makro",
                        icon: Icons.bolt_rounded,
                        color: Colors.orange,
                        progress: data.isValid ? (data.k / 250.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "Suhu Tanah",
                        value: data.isValid ? "${data.suhu.toStringAsFixed(1)}°C" : "N/A",
                        subtitle: "Kondisi Tanah",
                        icon: Icons.thermostat_rounded,
                        color: Colors.redAccent,
                        progress: data.isValid ? (data.suhu / 50.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "Kelembaban",
                        value: data.isValid ? "${data.kelembaban.toStringAsFixed(1)}%" : "N/A",
                        subtitle: "Kandungan Air",
                        icon: Icons.water_drop_rounded,
                        color: Colors.blueAccent,
                        progress: data.isValid ? (data.kelembaban / 100.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "pH Tanah",
                        value: data.isValid ? data.ph.toStringAsFixed(1) : "N/A",
                        subtitle: "Keasaman Tanah",
                        icon: Icons.science_rounded,
                        color: Colors.teal,
                        progress: data.isValid ? (data.ph / 14.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildRealtimeCard(
                        context: context,
                        title: "Konduktivitas (EC)",
                        value: data.isValid ? "${data.ec} µS/cm" : "N/A",
                        subtitle: "Electrical Conductivity",
                        icon: Icons.electric_bolt_rounded,
                        color: Colors.indigo,
                        progress: data.isValid ? (data.ec / 1000.0).clamp(0.0, 1.0) : 0.0,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }


  // Fuzzy Logic Banner
  Widget _buildFuzzyBanner(PrecisionRealtimeData data) {
    final isNA = !data.isValid;
    final isIdeal = !isNA && data.statusPupuk.toUpperCase().contains("IDEAL");
    final isUnknown = !isNA && data.statusPupuk == "MEMUAT DATA...";
    
    final statusColor = isNA
        ? const Color(0xFFEF4444)
        : isUnknown
            ? Colors.grey
            : isIdeal
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444);

    final gradient = isNA
        ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : isUnknown
            ? const LinearGradient(
                colors: [Color(0xFF64748B), Color(0xFF475569)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isIdeal
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNA
                  ? Icons.error_outline_rounded
                  : isUnknown
                      ? Icons.sync_rounded
                      : isIdeal
                          ? Icons.eco_rounded
                          : Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNA
                      ? "ERROR PEMBACAAN"
                      : isUnknown
                          ? "KONEKSI SENSOR"
                          : "STATUS NUTRISI TANAH (FUZZY)",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isNA ? "N/A" : data.statusPupuk,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNA
                      ? "Gagal mengurai telemetry sensor. Format data salah atau terputus."
                      : isUnknown
                          ? "Menghubungkan ke IoT Node..."
                          : isIdeal
                              ? "Kondisi tanah optimal! Kebutuhan makro NPK terpenuhi dengan seimbang."
                              : data.statusPupuk.toUpperCase().contains("BUTUH")
                                  ? "Segera berikan pupuk tambahan NPK untuk mencukupi nutrisi tanaman."
                                  : "Kandungan pupuk berlebihan! Kurangi dosis pemupukan untuk mencegah keracunan tanah.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Real-time Card Helper
  Widget _buildRealtimeCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              // Mini progress visualizer circle
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.2,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Loading indicator helper
  Widget _buildLoadingState(ColorScheme colorScheme, String message, String path) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Mengunduh data di path '$path'...",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // Error state helper
  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            "Terjadi Kesalahan Sinkronisasi",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red.shade900),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade800),
          ),
        ],
      ),
    );
  }
}

// HistoryCard stateful widget for smooth micro-animations
class HistoryCard extends StatefulWidget {
  final PrecisionHistoryData history;
  const HistoryCard({super.key, required this.history});

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  bool _isExpanded = false;

  Widget _buildAnalysisBox(BuildContext context, PrecisionRealtimeData data, bool isDark, Color statusColor, Color statusBgColor) {
    // 1. Determine status for N, P, K
    String nStatus = data.n < 80 ? "Kurang" : (data.n > 150 ? "Berlebih" : "Optimal");
    String pStatus = data.p < 30 ? "Kurang" : (data.p > 50 ? "Berlebih" : "Optimal");
    String kStatus = data.k < 100 ? "Kurang" : (data.k > 200 ? "Berlebih" : "Optimal");
    String phStatus = data.ph < 6.0 ? "Asam" : (data.ph > 7.0 ? "Basa" : "Ideal");
    String moistStatus = data.kelembaban < 40 ? "Kering" : (data.kelembaban > 70 ? "Basah" : "Optimal");
    String tempStatus = data.suhu < 20 ? "Dingin" : (data.suhu > 30 ? "Panas" : "Optimal");
    String ecStatus = data.ec < 200 ? "Rendah" : (data.ec > 800 ? "Tinggi" : "Optimal");

    // 2. Generate detailed agricultural recommendation
    List<String> deficiencies = [];
    List<String> excesses = [];
    if (data.n < 80) deficiencies.add("Nitrogen (N)");
    if (data.p < 30) deficiencies.add("Fosfor (P)");
    if (data.k < 100) deficiencies.add("Kalium (K)");
    if (data.n > 150) excesses.add("Nitrogen (N)");
    if (data.p > 50) excesses.add("Fosfor (P)");
    if (data.k > 200) excesses.add("Kalium (K)");

    String conclusion = "";
    if (deficiencies.isNotEmpty) {
      conclusion = "Kandungan hara ${deficiencies.join(', ')} di bawah ambang batas optimal. Disarankan untuk segera melakukan aplikasi pupuk NPK agar nutrisi tanah tercukupi.";
    } else if (excesses.isNotEmpty) {
      conclusion = "Kandungan hara ${excesses.join(', ')} terdeteksi berlebih (overdosis). Kurangi intensitas pemupukan sementara waktu agar tanah terhindar dari toksisitas.";
    } else {
      conclusion = "Seluruh parameter unsur hara makro (N, P, K) berada pada batas optimal. Tanah siap mendukung pertumbuhan tanaman dengan sangat baik.";
    }

    if (data.ph < 6.0) {
      conclusion += " Catatan tambahan: pH tanah terdeteksi asam. Pertimbangkan penambahan kapur dolomit.";
    } else if (data.ph > 7.0) {
      conclusion += " Catatan tambahan: pH tanah terdeteksi basa. Pertimbangkan pemberian bahan organik asam.";
    }

    if (data.kelembaban < 40) {
      conclusion += " Tanah terlalu kering, lakukan penyiraman air secara teratur.";
    } else if (data.kelembaban > 70) {
      conclusion += " Kelembaban tanah tinggi, pastikan drainase lahan berfungsi optimal.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                "DIAGNOSIS & ANALSIS TANAH",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: statusColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: "Status Hara Makro: ", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "N ($nStatus), P ($pStatus), K ($kStatus)\n"),
                const TextSpan(text: "Parameter Fisik: ", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "pH ($phStatus), Lembab ($moistStatus), Suhu ($tempStatus), EC ($ecStatus)\n\n"),
                const TextSpan(text: "Rekomendasi Tindakan:\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: conclusion, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.history.data;
    final isIdeal = data.statusPupuk.toUpperCase().contains("IDEAL");
    final statusColor = isIdeal ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusBgColor = isIdeal ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: statusColor, width: 6),
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Column(
            children: [
              // Closed Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIdeal ? Icons.eco_rounded : Icons.warning_amber_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.history.waktu,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "Log Sensor NPK",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data.statusPupuk,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Smooth Animated Expanded Body
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.02),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rincian Log Parameter",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // NPK details grid
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.8,
                        ),
                        children: [
                          _buildMiniParam(context, "Nitrogen", "${data.n} mg/kg", Icons.grass_rounded, Colors.blue),
                          _buildMiniParam(context, "Phosphorus", "${data.p} mg/kg", Icons.grain_rounded, Colors.purple),
                          _buildMiniParam(context, "Potassium", "${data.k} mg/kg", Icons.bolt_rounded, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Environmental details grid
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.6,
                        ),
                        children: [
                          _buildMiniParam(context, "Suhu", "${data.suhu.toStringAsFixed(1)}°C", Icons.thermostat_rounded, Colors.redAccent),
                          _buildMiniParam(context, "Kelembaban", "${data.kelembaban.toStringAsFixed(1)}%", Icons.water_drop_rounded, Colors.blueAccent),
                          _buildMiniParam(context, "pH Tanah", data.ph.toStringAsFixed(1), Icons.science_rounded, Colors.teal),
                          _buildMiniParam(context, "Konduktivitas", "${data.ec} µS/cm", Icons.electric_bolt_rounded, Colors.indigo),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      _buildAnalysisBox(context, data, isDark, statusColor, statusBgColor),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniParam(BuildContext context, String name, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF334155) 
              : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
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

// Extension to darken/lighten color dynamically
extension ColorDarken on Color {
  Color darken([double amount = .1, bool isDarkTheme = false]) {
    assert(amount >= 0 && amount <= 1);
    if (!isDarkTheme) {
      final hsl = HSLColor.fromColor(this);
      final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
      return hslDark.toColor();
    }
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
