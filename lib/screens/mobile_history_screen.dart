import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/precision_service.dart';
import 'bandwidth_efficiency_screen.dart';
import 'mobile_history_detail_screen.dart';

class MobileHistoryScreen extends StatefulWidget {
  const MobileHistoryScreen({super.key});

  @override
  State<MobileHistoryScreen> createState() => _MobileHistoryScreenState();
}

class _MobileHistoryScreenState extends State<MobileHistoryScreen> {
  final PrecisionService _precisionService = PrecisionService();
  String _searchQuery = "";



  /// Extracts only the clean date-time portion from waktu strings that may have
  /// status text appended directly (e.g. "24/05/2026 14:30BUTUH AIR!" → "24/05/2026 14:30")
  String _cleanWaktu(String raw) {
    final match = RegExp(r'^(\d{1,2}/\d{1,2}(?:/\d{2,4})?\s+\d{1,2}:\d{2})').firstMatch(raw);
    if (match != null) return match.group(1)!;
    final parts = raw.split(' ');
    if (parts.length >= 2) {
      final timePart = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
      return '${parts[0]} $timePart';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Riwayat Log NPK",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Cari status (ideal, overdosis, dll)...",
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    icon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // --- IoT Bandwidth Efficiency Banner ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BandwidthEfficiencyScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                          : [const Color(0xFF10B981), const Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.network_ping_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Efisiensi Bandwidth IoT",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Lihat statistik kompresi data & hemat kuota",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // History Stream List
            Expanded(
              child: StreamBuilder<List<PrecisionHistoryData>>(
                stream: _precisionService.getHistoryStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allLogs = snapshot.data ?? [];
                  
                  // Filter logs by search query
                  final logs = allLogs.where((log) {
                    final status = log.data.statusPupuk.toLowerCase();
                    final time = log.waktu.toLowerCase();
                    return status.contains(_searchQuery) || time.contains(_searchQuery);
                  }).toList();

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(
                            "Tidak ada data log",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    );
                  }

                  // 1. Group logs by date
                  final Map<String, List<PrecisionHistoryData>> groupedLogs = {};
                  for (var log in logs) {
                    final date = log.waktu.split(' ')[0];
                    if (!groupedLogs.containsKey(date)) {
                      groupedLogs[date] = [];
                    }
                    groupedLogs[date]!.add(log);
                  }

                  // 2. No more 30-minute interval spam filter (Show ALL logs)
                  final Map<String, List<PrecisionHistoryData>> filteredGroupedLogs = Map.from(groupedLogs);

                  // 3. Sort dates descending (newest dates first)
                  final sortedDates = filteredGroupedLogs.keys.toList()..sort((a, b) {
                    try {
                      final partsA = a.split('/');
                      final partsB = b.split('/');
                      final dayA = int.parse(partsA[0]);
                      final monthA = int.parse(partsA[1]);
                      final dayB = int.parse(partsB[0]);
                      final monthB = int.parse(partsB[1]);
                      if (monthA != monthB) {
                        return monthB.compareTo(monthA);
                      }
                      return dayB.compareTo(dayA);
                    } catch (e) {
                      return b.compareTo(a);
                    }
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dateLogs = filteredGroupedLogs[date]!;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            expansionTileTheme: const ExpansionTileThemeData(
                              backgroundColor: Colors.transparent,
                              collapsedBackgroundColor: Colors.transparent,
                            ),
                          ),
                          child: ExpansionTile(
                            shape: const Border(),
                            iconColor: colorScheme.primary,
                            collapsedIconColor: colorScheme.onSurface.withValues(alpha: 0.6),
                            initiallyExpanded: index == 0,
                            title: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Tanggal $date",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${dateLogs.length} LOGS",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: dateLogs.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  color: Colors.transparent,
                                  elevation: 0,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MobileHistoryDetailScreen(log: item),
                                        ),
                                      );
                                    },
                                    child: _buildMobileLogCard(item, isDark, colorScheme),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLogCard(PrecisionHistoryData log, bool isDark, ColorScheme colorScheme) {
    final isNA = !log.data.isValid;
    final status = isNA ? "N/A" : log.data.statusPupuk.toUpperCase();
    final isIdeal = !isNA && status.contains("IDEAL");
    final isOver = !isNA && status.contains("OVER");
    
    final statusColor = isNA
        ? const Color(0xFFEF4444)
        : isIdeal
            ? const Color(0xFF10B981)
            : isOver
                ? const Color(0xFFEF4444)
                : Colors.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Time and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(
                    _cleanWaktu(log.waktu),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Parameters Grid Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniParam("N", isNA ? "N/A" : "${log.data.n}", Colors.blue),
              _buildMiniParam("P", isNA ? "N/A" : "${log.data.p}", Colors.purple),
              _buildMiniParam("K", isNA ? "N/A" : "${log.data.k}", Colors.orange),
              _buildMiniParam("Suhu", isNA ? "N/A" : "${log.data.suhu}°", Colors.redAccent),
              _buildMiniParam("pH", isNA ? "N/A" : "${log.data.ph}", Colors.teal),
              _buildMiniParam("Moist", isNA ? "N/A" : "${log.data.kelembaban.toInt()}%", Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniParam(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "Error loading history: $error",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
