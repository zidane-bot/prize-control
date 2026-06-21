import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/precision_service.dart';

class WebHistoryTab extends StatefulWidget {
  const WebHistoryTab({super.key});

  @override
  State<WebHistoryTab> createState() => _WebHistoryTabState();
}

class _WebHistoryTabState extends State<WebHistoryTab> {
  final PrecisionService _precisionService = PrecisionService();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateQuery = DateFormat('dd/MM').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<PrecisionHistoryData>>(
        stream: _precisionService.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLogs = snapshot.data ?? [];
          // Filter by selected date
          final dateFilteredLogs = allLogs.where((log) => log.waktu.contains(dateQuery)).toList();
          
          final List<PrecisionHistoryData> filteredLogs = List.from(dateFilteredLogs);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header & Calendar Picker Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Riwayat Log Buku (Web)",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Pilih tanggal untuk menganalisis rekapan nutrisi lahan.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  
                  // Date Picker Trigger Button
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMMM yyyy', 'id').format(_selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Stats for the selected day
              _buildSummaryRow(filteredLogs, colorScheme, isDark),
              const SizedBox(height: 24),

              // Logs Table Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: filteredLogs.isEmpty
                      ? _buildEmptyState(colorScheme, dateQuery)
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            dataTextStyle: GoogleFonts.inter(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                            ),
                            headingTextStyle: GoogleFonts.inter(
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            headingRowColor: WidgetStateProperty.all(
                              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            ),
                            showCheckboxColumn: false,
                            columnSpacing: 36,
                            horizontalMargin: 24,
                            columns: [
                              DataColumn(label: Text('WAKTU', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('N (mg/kg)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('P (mg/kg)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('K (mg/kg)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('SUHU (°C)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('MOIST (%)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('pH', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                              DataColumn(label: Text('STATUS NUTRISI', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface))),
                            ],
                            rows: filteredLogs.map((log) {
                              final isNA = !log.data.isValid;
                              final timeOnly = log.waktu.split(' ').length > 1 ? log.waktu.split(' ')[1] : log.waktu;
                              return DataRow(
                                onSelectChanged: (selected) {
                                  if (selected != null && selected) {
                                    _showLogDetail(context, log, isDark, colorScheme);
                                  }
                                },
                                cells: [
                                  DataCell(Text(timeOnly, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: colorScheme.onSurface))),
                                  DataCell(Text(isNA ? "N/A" : '${log.data.n}', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.85)))),
                                  DataCell(Text(isNA ? "N/A" : '${log.data.p}', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.85)))),
                                  DataCell(Text(isNA ? "N/A" : '${log.data.k}', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.85)))),
                                  DataCell(Text(isNA ? "N/A" : '${log.data.suhu.toStringAsFixed(1)}°C', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.85)))),
                                  DataCell(Text(isNA ? "N/A" : '${log.data.kelembaban.toStringAsFixed(1)}%', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.85)))),
                                  DataCell(Text(isNA ? "N/A" : log.data.ph.toStringAsFixed(1), style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.85)))),
                                  DataCell(_buildStatusBadge(isNA ? "N/A" : log.data.statusPupuk)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final cleanStatus = status.toUpperCase();
    final isIdeal = cleanStatus.contains("IDEAL");
    final isOver = cleanStatus.contains("OVER");
    final isError = cleanStatus.contains("ERROR");

    final color = isError
        ? const Color(0xFFEF4444)
        : isIdeal
            ? const Color(0xFF10B981)
            : isOver
                ? const Color(0xFFEF4444)
                : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        cleanStatus,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(List<PrecisionHistoryData> logs, ColorScheme colorScheme, bool isDark) {
    if (logs.isEmpty) return const SizedBox.shrink();

    final validLogs = logs.where((l) => l.data.isValid).toList();
    
    double avgN = 0.0;
    double avgP = 0.0;
    double avgK = 0.0;
    int idealCount = 0;
    
    if (validLogs.isNotEmpty) {
      avgN = validLogs.map((l) => l.data.n).reduce((a, b) => a + b) / validLogs.length;
      avgP = validLogs.map((l) => l.data.p).reduce((a, b) => a + b) / validLogs.length;
      avgK = validLogs.map((l) => l.data.k).reduce((a, b) => a + b) / validLogs.length;
      idealCount = validLogs.where((l) => l.data.statusPupuk.toUpperCase().contains("IDEAL")).length;
    }

    final averageNPKString = validLogs.isNotEmpty
        ? "${avgN.round()}-${avgP.round()}-${avgK.round()} mg/kg"
        : "N/A";
        
    final idealRateString = validLogs.isNotEmpty
        ? "${((idealCount / validLogs.length) * 100).round()}%"
        : "N/A";

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Total Data Terkumpul",
            value: "${logs.length} Log",
            sub: "Kondisi: ${logs.length - validLogs.length} data rusak/invalid",
            icon: Icons.analytics_outlined,
            color: colorScheme.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: "Rata-Rata NPK Hari Ini",
            value: averageNPKString,
            sub: "Status rata-rata harian",
            icon: Icons.grain_rounded,
            color: Colors.purple,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: "Tingkat Tanah Ideal",
            value: idealRateString,
            sub: validLogs.isNotEmpty ? "$idealCount dari ${validLogs.length} data ideal" : "0 dari 0 data ideal",
            icon: Icons.eco_outlined,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, String dateQuery) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            "Tidak Ada Data Log pada Tanggal Ini",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Node sensor tidak mengupload data bertanggal '$dateQuery'.",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Text(
        "Gagal memuat log book: $error",
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  void _showLogDetail(BuildContext context, PrecisionHistoryData log, bool isDark, ColorScheme colorScheme) {
    final isNA = !log.data.isValid;
    final status = isNA ? "N/A" : log.data.statusPupuk.toUpperCase();
    final isIdeal = !isNA && (status.contains("IDEAL") || status.contains("OPTIMAL"));
    final isOver = !isNA && status.contains("OVER");
    
    final statusColor = isNA ? Colors.red : isIdeal ? Colors.green : isOver ? Colors.red : Colors.amber;
    
    String getRecommendationText() {
      if (isNA) return "Data tidak valid. Periksa hardware sensor.";
      if (isIdeal) return "Kadar nutrisi dan parameter fisik tanah dalam kondisi ideal. Lanjutkan perawatan rutin sesuai jadwal.";
      if (isOver) return "Kadar nutrisi berlebihan (Overdosis). Segera lakukan pembilasan (flushing) dengan air bersih dan hentikan pemupukan sementara waktu.";
      return "Kadar nutrisi rendah. Direkomendasikan melakukan pemupukan tambahan.";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rincian Log - ${log.waktu}",
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(isIdeal ? Icons.check_circle : Icons.warning_rounded, color: statusColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: statusColor, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getRecommendationText(),
                              style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("Parameter Sensor", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  children: [
                    _buildModalParam(context, "Nitrogen (N)", "${log.data.n} mg/kg", isDark),
                    _buildModalParam(context, "Phosphorus (P)", "${log.data.p} mg/kg", isDark),
                    _buildModalParam(context, "Potassium (K)", "${log.data.k} mg/kg", isDark),
                    _buildModalParam(context, "Suhu", "${log.data.suhu}°C", isDark),
                    _buildModalParam(context, "Kelembaban", "${log.data.kelembaban}%", isDark),
                    _buildModalParam(context, "pH", "${log.data.ph}", isDark),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalParam(BuildContext context, String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
