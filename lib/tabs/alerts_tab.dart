import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/precision_service.dart';
import 'package:intl/intl.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> with SingleTickerProviderStateMixin {
  final PrecisionService _precisionService = PrecisionService();
  
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  
  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _controlSubscription;
  StreamSubscription? _sensorActiveSubscription;
  StreamSubscription? _lastActiveTimeSubscription;
  Timer? _heartbeatTimer;

  // Liveness States
  DateTime? _lastDataReceivedTime;
  String _lastActiveTimeString = "Offline";
  int _n = 0;
  int _p = 0;
  int _k = 0;
  bool _firebaseSensorActiveState = true;
  
  Map<String, bool> _relays = {
    'R1': false,
    'R2': false,
    'R3': false,
    'R4': false,
  };

  @override
  void initState() {
    super.initState();

    // Pulse animation for status dots
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Subscribe to realtime DB updates
    _realtimeSubscription = _precisionService.getRealtimeDataStream().listen((data) {
      if (mounted) {
        setState(() {
          _n = data.n;
          _p = data.p;
          _k = data.k;
        });
      }
    });

    _controlSubscription = _precisionService.getControlStream().listen((controls) {
      if (mounted) {
        setState(() {
          _relays = controls;
        });
      }
    });

    _sensorActiveSubscription = _precisionService.getSensorActiveStream().listen((isActive) {
      if (mounted) {
        setState(() {
          _firebaseSensorActiveState = isActive;
        });
      }
    });

    _lastActiveTimeSubscription = _precisionService.getLastActiveTimeStream().listen((timeStr) {
      if (mounted && timeStr.isNotEmpty) {
        setState(() {
          _lastActiveTimeString = timeStr;
          // timeStr is DD/MM/YYYY HH:MM:SS
          try {
            _lastDataReceivedTime = DateFormat('dd/MM/yyyy HH:mm:ss').parse(timeStr.trim());
          } catch (_) {}
        });
      }
    });

    // Rebuild every 5 seconds to update the "elapsed minutes" and online/offline check
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _realtimeSubscription?.cancel();
    _controlSubscription?.cancel();
    _sensorActiveSubscription?.cancel();
    _lastActiveTimeSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  // Heartbeat helper: checks the ESP32 Central state based on last data received
  // 0: Online (< 30s), 1: Offline (>= 30s, < 60s), 2: Rusak (>= 60s or null)
  int get _espState {
    if (_lastDataReceivedTime == null) return 2;
    final diff = DateTime.now().difference(_lastDataReceivedTime!).inSeconds;
    if (diff < 120) return 0;
    if (diff < 180) return 1;
    return 2;
  }

  // Checks if the NPK Sensor is healthy
  int get _sensorState {
    final esp = _espState;
    if (esp == 2) return 2; // If ESP is Rusak, Sensor is also Rusak (or unreachable)
    if (esp == 1) return 1; // If ESP is Offline, Sensor is Offline
    if (!_firebaseSensorActiveState) return 2;
    if (_n == 0 && _p == 0 && _k == 0) return 2; // Probe is reading 0 (Rusak)
    return 0; // Online
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final espState = _espState;
    final sensorState = _sensorState;

    // Determine alerts log list based on health states
    final List<Map<String, dynamic>> dynamicAlerts = [];

    if (espState == 2) {
      dynamicAlerts.add({
        'title': "ESP32 Central Node Rusak / Terputus Total",
        'subtitle': "Tidak menerima data lebih dari 1 menit. Periksa catu daya & perangkat keras.",
        'type': AlertType.critical,
        'isActive': true,
        'time': _lastDataReceivedTime != null 
            ? "Terakhir aktif: $_lastActiveTimeString" 
            : "Tidak ada data",
      });
    } else if (espState == 1) {
      dynamicAlerts.add({
        'title': "ESP32 Central Node Offline Sementara",
        'subtitle': "Koneksi terhambat selama lebih dari 30 detik. Sedang mencoba menghubungkan ulang...",
        'type': AlertType.warning,
        'isActive': true,
        'time': _lastDataReceivedTime != null 
            ? "Terakhir aktif: $_lastActiveTimeString" 
            : "Menunggu koneksi...",
      });
    } else {
      dynamicAlerts.add({
        'title': "ESP32 Central Terhubung",
        'subtitle': "Modul gateway IoT utama aktif dan mengirimkan data secara real-time.",
        'type': AlertType.info,
        'isActive': false,
        'time': "Baru saja",
      });
    }

    if (sensorState == 2 && espState == 0) {
      dynamicAlerts.add({
        'title': "Peringatan Probe NPK Rusak",
        'subtitle': "Pembacaan error atau kabel terlepas. Segera periksa fisik sensor.",
        'type': AlertType.critical,
        'isActive': true,
        'time': "Baru saja",
      });
    }

    // Add some static mock history logs for context, just like on the web
    dynamicAlerts.addAll([
      {
        'title': "Sistem Irigasi Sukses",
        'subtitle': "Sekuens penyiraman presisi 65s diselesaikan",
        'type': AlertType.info,
        'isActive': false,
        'time': "24 Mei 09:05",
      },
      {
        'title': "Modbus RTU Handshake Gagal",
        'subtitle': "Timeout komunikasi pada port Serial2 (Pin 25, 26)",
        'type': AlertType.warning,
        'isActive': false,
        'time': "23 Mei 18:22",
      }
    ]);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            "Status Perangkat & Alerts",
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Monitor toleransi kesalahan sistem dan status koneksi node IoT.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // --- DEVICE STATUS CHECKERS SECTION ---
          _buildDeviceStatusCard(
            title: "ESP32 Central Node",
            subtitle: "Gateway & Transceiver Lahan",
            stateCode: espState,
            detailText: espState == 0
                ? "Terhubung ke Database"
                : (_lastDataReceivedTime != null 
                    ? "Terakhir aktif: $_lastActiveTimeString" 
                    : "Belum menerima data"),
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),

          _buildDeviceStatusCard(
            title: "Sensor NPK Tanah (RS485)",
            subtitle: "Probe Modbus RTU Lahan",
            stateCode: sensorState,
            detailText: sensorState == 0 
                ? "Pembacaan Normal & Akurat"
                : (sensorState == 1 ? "Menunggu koneksi..." : "Error / Rusak / Putus"),
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),

          _buildActuatorsStatusCard(isDark: isDark, colorScheme: colorScheme),
          const SizedBox(height: 24),

          // --- DIAGNOSTICS CARD FOR ISSUES ---
          if (espState != 0 || sensorState != 0) 
            _buildDiagnosticsCard(colorScheme, isDark),

          // --- ALERTS TIMELINE LOG ---
          Text(
            "Riwayat Log Peringatan",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          ...dynamicAlerts.map((alert) => _buildAlertItem(
            title: alert['title'],
            subtitle: alert['subtitle'],
            time: alert['time'],
            type: alert['type'],
            isActive: alert['isActive'],
            isDark: isDark,
            colorScheme: colorScheme,
          )),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Custom high-fidelity Device status card matching Web visual
  Widget _buildDeviceStatusCard({
    required String title,
    required String subtitle,
    required int stateCode,
    required String detailText,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final statusColor = stateCode == 2
        ? const Color(0xFFEF4444)
        : (stateCode == 1 ? Colors.orange : const Color(0xFF10B981));
    
    final statusLabel = stateCode == 2
        ? "RUSAK"
        : (stateCode == 1 ? "OFFLINE" : "ONLINE");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              stateCode == 2
                  ? Icons.error_outline_rounded
                  : (stateCode == 1 ? Icons.warning_amber_rounded : Icons.router_rounded),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Detail Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withValues(
                      alpha: 0.15 + (_blinkAnimation.value * 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing Dot
                    Opacity(
                      opacity: stateCode == 0 ? 1.0 : _blinkAnimation.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Actuators card representing R1 to R4 state details
  Widget _buildActuatorsStatusCard({
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aktuator Relay",
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Status Aktuator Lapangan",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),

          // Relay grid row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRelayGridItem("R1", "Besar", _relays['R1'] ?? false, Colors.deepPurple),
              _buildRelayGridItem("R2", "Pupuk", _relays['R2'] ?? false, Colors.teal),
              _buildRelayGridItem("R3", "Air", _relays['R3'] ?? false, Colors.blue),
              _buildRelayGridItem("R4", "Aduk", _relays['R4'] ?? false, Colors.amber.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelayGridItem(String code, String name, bool isOn, Color activeColor) {
    final statusColor = isOn ? activeColor : Colors.grey;

    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 6 * _blinkAnimation.value,
                            spreadRadius: 2 * _blinkAnimation.value,
                          )
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            code,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOn ? "AKTIF" : "STANDBY",
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsCard(ColorScheme colorScheme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle_outlined, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Panduan Penyelesaian Fisik Lahan",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCheckItem("Periksa sambungan kabel sensor NPK RS485 / Modbus ke Node ESP32.", true),
            _buildCheckItem("Pastikan catu daya baterai / solar panel di lahan menyala stabil.", false),
            _buildCheckItem("Periksa apakah ada penghalang fisik (dinding/pohon) yang memutus sinyal ESP-NOW.", false),
            _buildCheckItem("Periksa log Modbus registers di serial monitor Node Sensor.", false),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 16,
            color: isChecked ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String subtitle,
    required String time,
    required AlertType type,
    required bool isActive,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final statusColor = type == AlertType.critical
        ? const Color(0xFFEF4444)
        : type == AlertType.warning
            ? Colors.orange
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? statusColor.withValues(alpha: 0.3) 
              : colorScheme.onSurface.withValues(alpha: 0.05),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              type == AlertType.critical
                  ? Icons.error_outline_rounded
                  : type == AlertType.warning
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "AKTIF",
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum AlertType { critical, warning, info }
