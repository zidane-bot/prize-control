import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/precision_service.dart';

class MobileHistoryDetailScreen extends StatelessWidget {
  final PrecisionHistoryData log;

  const MobileHistoryDetailScreen({super.key, required this.log});

  /// Extracts only the clean date-time portion from waktu strings that may have
  /// status text appended directly (e.g. "24/05/2026 14:00OVER DOSIS!" → "24/05/2026 14:00")
  String _cleanWaktu(String raw) {
    // Match DD/MM[/YYYY] HH:MM pattern at the start
    final match = RegExp(r'^(\d{1,2}/\d{1,2}(?:/\d{2,4})?\s+\d{1,2}:\d{2})').firstMatch(raw);
    if (match != null) return match.group(1)!;
    // Fallback: return first two space-separated tokens
    final parts = raw.split(' ');
    if (parts.length >= 2) {
      // Time part may be "14:00OVER" — take only HH:MM
      final timePart = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
      return '${parts[0]} $timePart';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isNA = !log.data.isValid;
    final status = isNA ? "N/A" : log.data.statusPupuk.toUpperCase();
    final isIdeal = !isNA && (status.contains("IDEAL") || status.contains("OPTIMAL"));
    final isOver = !isNA && status.contains("OVER");

    final statusColor = isNA
        ? const Color(0xFFEF4444)
        : isIdeal
            ? const Color(0xFF10B981)
            : isOver
                ? const Color(0xFFEF4444)
                : Colors.amber;

    // Helper functions for parameter status checking
    String getMacroStatus(int val, int min, int max) {
      if (isNA) return "N/A";
      if (val < min) return "Kurang";
      if (val > max) return "Berlebih";
      return "Optimal";
    }

    String getPHStatus(double val) {
      if (isNA) return "N/A";
      if (val < 6.0) return "Asam";
      if (val > 7.0) return "Basa";
      return "Ideal";
    }

    String getMoistureStatus(double val) {
      if (isNA) return "N/A";
      if (val < 40) return "Kering";
      if (val > 70) return "Basah";
      return "Optimal";
    }

    String getSuhuStatus(double val) {
      if (isNA) return "N/A";
      if (val < 20) return "Dingin";
      if (val > 30) return "Panas";
      return "Optimal";
    }

    String getECStatus(int val) {
      if (isNA) return "N/A";
      if (val < 200) return "Rendah";
      if (val > 800) return "Tinggi";
      return "Optimal";
    }

    Color getStatusTextColor(String statusText) {
      if (statusText == "N/A") {
        return const Color(0xFFEF4444);
      }
      if (statusText == "Optimal" || statusText == "Ideal") {
        return const Color(0xFF10B981);
      } else if (statusText == "Kurang" || statusText == "Asam" || statusText == "Kering" || statusText == "Rendah" || statusText == "Dingin") {
        return Colors.orange;
      } else {
        return const Color(0xFFEF4444);
      }
    }

    // Recommendation logic based on status
    String getRecommendationText() {
      if (isNA) {
        return "Gagal mendapatkan riwayat data valid. Data log terindikasi malformed atau korup.";
      }
      if (isIdeal) {
        return "Kadar nutrisi dan parameter fisik tanah dalam kondisi ideal untuk pertumbuhan tanaman cabai. Lanjutkan perawatan rutin sesuai jadwal.";
      } else if (isOver) {
        return "Kadar nutrisi tanah melebihi ambang batas optimal. Segera lakukan pembilasan (flushing) dengan air bersih dan hentikan sementara pemupukan guna mencegah keracunan akar.";
      } else {
        return "Kadar nutrisi tanah di bawah ambang batas optimal. Direkomendasikan melakukan pemupukan NPK 16-16-16 (dosis ringan) dan pastikan aktuator penyiraman/irigasi berjalan normal.";
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Rincian Log Parameter",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header Timestamp Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "WAKTU PENGAMBILAN DATA",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _cleanWaktu(log.waktu),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Macro Nutrients section
            Text(
              "Kandungan Unsur Makro (NPK)",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: [
                _buildParameterCard(
                  context: context,
                  label: "Nitrogen (N)",
                  value: isNA ? "N/A" : "${log.data.n}",
                  unit: "mg/kg",
                  range: "80-150",
                  status: getMacroStatus(log.data.n, 80, 150),
                  statusColor: getStatusTextColor(getMacroStatus(log.data.n, 80, 150)),
                  icon: Icons.science_rounded,
                  iconColor: Colors.blue,
                  isDark: isDark,
                ),
                _buildParameterCard(
                  context: context,
                  label: "Fosfor (P)",
                  value: isNA ? "N/A" : "${log.data.p}",
                  unit: "mg/kg",
                  range: "30-50",
                  status: getMacroStatus(log.data.p, 30, 50),
                  statusColor: getStatusTextColor(getMacroStatus(log.data.p, 30, 50)),
                  icon: Icons.bubble_chart_rounded,
                  iconColor: Colors.purple,
                  isDark: isDark,
                ),
                _buildParameterCard(
                  context: context,
                  label: "Kalium (K)",
                  value: isNA ? "N/A" : "${log.data.k}",
                  unit: "mg/kg",
                  range: "100-200",
                  status: getMacroStatus(log.data.k, 100, 200),
                  statusColor: getStatusTextColor(getMacroStatus(log.data.k, 100, 200)),
                  icon: Icons.grain_rounded,
                  iconColor: Colors.orange,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Physical & Chemical parameters section
            Text(
              "Parameter Fisik & Kimia Tanah",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildParameterCard(
                  context: context,
                  label: "pH Tanah",
                  value: isNA ? "N/A" : log.data.ph.toStringAsFixed(2),
                  unit: "pH",
                  range: "6.0-7.0",
                  status: getPHStatus(log.data.ph),
                  statusColor: getStatusTextColor(getPHStatus(log.data.ph)),
                  icon: Icons.biotech_rounded,
                  iconColor: Colors.teal,
                  isDark: isDark,
                ),
                _buildParameterCard(
                  context: context,
                  label: "Kelembaban",
                  value: isNA ? "N/A" : "${log.data.kelembaban.toInt()}",
                  unit: "%",
                  range: "40-70",
                  status: getMoistureStatus(log.data.kelembaban),
                  statusColor: getStatusTextColor(getMoistureStatus(log.data.kelembaban)),
                  icon: Icons.water_drop_rounded,
                  iconColor: Colors.blueAccent,
                  isDark: isDark,
                ),
                _buildParameterCard(
                  context: context,
                  label: "Suhu Tanah",
                  value: isNA ? "N/A" : log.data.suhu.toStringAsFixed(1),
                  unit: "°C",
                  range: "20-30",
                  status: getSuhuStatus(log.data.suhu),
                  statusColor: getStatusTextColor(getSuhuStatus(log.data.suhu)),
                  icon: Icons.thermostat_rounded,
                  iconColor: Colors.redAccent,
                  isDark: isDark,
                ),
                _buildParameterCard(
                  context: context,
                  label: "Konduktivitas EC",
                  value: isNA ? "N/A" : "${log.data.ec}",
                  unit: "µS/cm",
                  range: "200-800",
                  status: getECStatus(log.data.ec),
                  statusColor: getStatusTextColor(getECStatus(log.data.ec)),
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.amber,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Diagnostic & Recommendation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isNA
                    ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                    : isIdeal
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isNA
                      ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                      : isIdeal
                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                          : Colors.amber.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isNA
                            ? Icons.error_outline_rounded
                            : isIdeal
                                ? Icons.check_circle_outline_rounded
                                : Icons.info_outline_rounded,
                        color: isNA
                            ? const Color(0xFFEF4444)
                            : isIdeal
                                ? const Color(0xFF10B981)
                                : Colors.amber.shade800,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Diagnosis & Rekomendasi",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isNA
                              ? const Color(0xFFEF4444)
                              : isIdeal
                                  ? const Color(0xFF10B981)
                                  : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getRecommendationText(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCard({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required String range,
    required String status,
    required Color statusColor,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Ideal: $range",
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
