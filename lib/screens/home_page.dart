import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../api_keys.dart';
import '../services/auth_provider.dart';
import '../services/precision_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PrecisionService _precisionService = PrecisionService();

  // Weather & Location Info
  String cuacaSuhu = "--";
  String cuacaKondisi = "Memuat...";
  List<dynamic> forecastList = [];
  IconData cuacaIcon = Icons.cloud_download_outlined;
  Color cuacaColor = Colors.orange;
  String locationName = "Mencari Lokasi...";

  // Added new weather parameters
  String cuacaKelembaban = "--";
  String cuacaAngin = "--";
  String cuacaHujan = "--";

  @override
  void initState() {
    super.initState();
    _initializeWeather();
  }

  Future<void> _initializeWeather() async {
    try {
      Position? position = await _determinePosition();
      await _fetchWeatherAndForecast(position: position);
    } catch (e) {
      debugPrint("Weather Init Error: $e");
      await _fetchWeatherAndForecast(); // Fallback to default coordinates
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint("Geolocator Timeout/Error: $e");
      return null;
    }
  }

  Future<void> _fetchWeatherAndForecast({Position? position}) async {
    double lat = -6.2088; 
    double lon = 106.8456; // Jakarta coordinates

    if (position != null) {
      lat = position.latitude;
      lon = position.longitude;
    }

    // Using WeatherAPI with fallback key, or Open-Meteo (public without API key)
    const apiKey = ApiKeys.weatherApiKey;
    final url = Uri.parse('https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$lat,$lon&days=2&aqi=no&alerts=no');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            cuacaSuhu = "${data['current']['temp_c'].round()}°C";
            cuacaKondisi = data['current']['condition']['text'];
            int code = data['current']['condition']['code'];
            bool isDay = data['current']['is_day'] == 1;
            cuacaIcon = _getWeatherIcon(code, isDay: isDay);
            cuacaColor = _getWeatherColor(code, isDay: isDay);

            cuacaKelembaban = "${data['current']['humidity']}%";
            cuacaAngin = "${data['current']['wind_kph'].round()} km/jam";
            
            // Extract rain chance for the current hour
            int currentHour = DateTime.now().hour;
            var currentHourData = data['forecast']['forecastday'][0]['hour'][currentHour];
            cuacaHujan = "${currentHourData['chance_of_rain']}%";

            forecastList.clear();
            List allHours = [];
            for (var day in data['forecast']['forecastday']) {
              allHours.addAll(day['hour']);
            }
            
            DateTime now = DateTime.now();
            for (var hourData in allHours) {
              DateTime time = DateTime.parse(hourData['time']);
              if (time.isAfter(now.subtract(const Duration(minutes: 59)))) {
                forecastList.add({
                  'time': time,
                  'temp': hourData['temp_c'],
                  'code': hourData['condition']['code'],
                  'isDay': hourData['is_day'] == 1,
                  'humidity': hourData['humidity'],
                  'wind': hourData['wind_kph'],
                  'rain': hourData['chance_of_rain'],
                });
                if (forecastList.length >= 24) break;
              }
            }
          });
          _fetchLocationName(lat, lon);
        }
      }
    } catch (e) {
      debugPrint("WeatherAPI Error: $e. Switching to fallback mock info.");
      _loadFallbackMockWeather();
    }
  }

  void _loadFallbackMockWeather() {
    if (mounted) {
      setState(() {
        cuacaSuhu = "31°C";
        cuacaKondisi = "Cerah Berawan";
        cuacaIcon = Icons.wb_cloudy_rounded;
        cuacaColor = Colors.orangeAccent;
        locationName = "Sawah Bitanic, Jakarta";
        
        cuacaKelembaban = "65%";
        cuacaAngin = "12 km/jam";
        cuacaHujan = "20%";
        
        forecastList = List.generate(24, (index) {
          final time = DateTime.now().add(Duration(hours: index));
          // Sinusoidal temperature mock: 28°C +/- 3°C depending on time of day
          final double temp = 28.0 + 3.0 * (index % 6) / 5.0;
          return {
            'time': time,
            'temp': temp,
            'code': 1003,
            'isDay': time.hour > 6 && time.hour < 18,
            'humidity': 60 + (index % 5) * 5,
            'wind': 10 + (index % 3) * 2,
            'rain': (index % 4) * 15,
          };
        });
      });
    }
  }

  IconData _getWeatherIcon(int code, {bool isDay = true}) {
    if (code == 1000) return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    if (code == 1003) return isDay ? Icons.wb_cloudy_rounded : Icons.cloud_queue_rounded;
    if (code == 1006 || code == 1009) return Icons.cloud_rounded;
    if (code >= 1063 && code <= 1201) return Icons.water_drop_rounded;
    if (code >= 1273 && code <= 1282) return Icons.thunderstorm_rounded;
    return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  }

  Color _getWeatherColor(int code, {bool isDay = true}) {
    if (code == 1000) return isDay ? Colors.orange : Colors.indigo;
    if (code == 1003) return isDay ? Colors.orangeAccent : Colors.blueGrey;
    if (code >= 1063 && code <= 1201) return Colors.blue;
    if (code >= 1273 && code <= 1282) return Colors.deepPurple;
    return Colors.blue;
  }

  Future<void> _fetchLocationName(double lat, double lon) async {
    final url = Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            locationName = data['city'] ?? data['locality'] ?? data['principalSubdivision'] ?? "Lahan Bitanic";
          });
        }
      }
    } catch (e) {
      debugPrint("Location Name Error: $e");
    }
  }

  int _calculateHST(String tanggalTanamStr) {
    try {
      final DateTime tanggalTanam = DateTime.parse(tanggalTanamStr.trim());
      final DateTime today = DateTime.now();
      final difference = today.difference(tanggalTanam).inDays;
      return difference >= 0 ? difference : 0;
    } catch (e) {
      debugPrint("Error parsing Tanggal Tanam: $e");
      return 0;
    }
  }

  String _getPhaseString(int hst) {
    if (hst <= 14) return "MASA SEMAI";
    if (hst <= 35) return "MASA VEGETATIF";
    if (hst <= 65) return "MASA BERBUNGA";
    return "MASA BERBUAH";
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return StreamBuilder<PrecisionRealtimeData>(
      stream: _precisionService.getRealtimeDataStream(),
      builder: (context, realtimeSnapshot) {
        final realtimeData = realtimeSnapshot.data ?? PrecisionRealtimeData.empty();

        return StreamBuilder<String>(
          stream: _precisionService.getTanggalTanamStream(),
          builder: (context, tanggalSnapshot) {
            final tanggalTanam = tanggalSnapshot.data ?? "2026-04-20";
            final int hst = _calculateHST(tanggalTanam);

            if (isWeb) {
              return _buildWebDashboard(realtimeData, hst);
            } else {
              return _buildMobileDashboard(realtimeData, hst);
            }
          },
        );
      },
    );
  }

  // ============================================
  // --- WEBSITE DASHBOARD VIEW ---
  // ============================================
  Widget _buildWebDashboard(PrecisionRealtimeData data, int hst) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Section (Metrics, Charts)
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header (Title & HST Badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pusat Pemantauan Presisi",
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              locationName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // HST Display Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getPhaseString(hst),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$hst HST",
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Metrics cards row
                Row(
                  children: [
                    Expanded(child: _buildMetricCard("Nitrogen", data.isValid ? "${data.n}" : "N/A", "mg/kg", Icons.opacity, Colors.blue, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard("Phosphorus", data.isValid ? "${data.p}" : "N/A", "mg/kg", Icons.science_outlined, Colors.purple, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard("Potassium", data.isValid ? "${data.k}" : "N/A", "mg/kg", Icons.grain, Colors.orange, isDark)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard("Suhu", data.isValid ? data.suhu.toStringAsFixed(1) : "N/A", "°C", Icons.thermostat_outlined, Colors.red, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard("Kelembaban", data.isValid ? data.kelembaban.toStringAsFixed(1) : "N/A", "%", Icons.water_drop_outlined, Colors.blueAccent, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard("pH Tanah", data.isValid ? data.ph.toStringAsFixed(1) : "N/A", "pH", Icons.eco_outlined, Colors.green, isDark)),
                  ],
                ),
                const SizedBox(height: 24),

                // Interactive Line Chart Card
                _buildChartSection(colorScheme, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Right Side panel (Weather & System Alert Panel)
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildWebWeatherWidget(isDark, colorScheme),
                const SizedBox(height: 24),
                _buildSystemDiagnosisWidget(data.isValid ? data.statusPupuk : "N/A", isDark, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // --- MOBILE DASHBOARD VIEW ---
  // ============================================
  Widget _buildMobileDashboard(PrecisionRealtimeData data, int hst) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // --- WELCOME PROFILE HEADER & HST ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Icon(Icons.person_rounded, color: colorScheme.primary, size: 22)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, ${user?.displayName ?? user?.email?.split('@')[0] ?? 'Petani'}",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "ROLE: ${(authProvider.userRole ?? 'petani').toUpperCase()}",
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getPhaseString(hst),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          "$hst HST",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // === DEDICATED PREMIUM WEATHER CARD ===
              _buildMobileWeatherCard(isDark, colorScheme),

              // Title Section 1: NPK
              Text(
                "Kandungan Nutrisi & Fisik Tanah",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              // Metric Cards Rows
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildCompactMetricCard("Nitrogen", data.isValid ? "${data.n}" : "N/A", "mg/kg", Icons.opacity, Colors.blue, isDark, colorScheme)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactMetricCard("Phosphorus", data.isValid ? "${data.p}" : "N/A", "mg/kg", Icons.science_outlined, Colors.purple, isDark, colorScheme)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactMetricCard("Potassium", data.isValid ? "${data.k}" : "N/A", "mg/kg", Icons.grain, Colors.orange, isDark, colorScheme)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildCompactMetricCard("Suhu", data.isValid ? data.suhu.toStringAsFixed(1) : "N/A", "°C", Icons.thermostat_outlined, Colors.red, isDark, colorScheme)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactMetricCard("Kelembaban", data.isValid ? "${data.kelembaban.toInt()}" : "N/A", "%", Icons.water_drop_outlined, Colors.blueAccent, isDark, colorScheme)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactMetricCard("pH Tanah", data.isValid ? data.ph.toStringAsFixed(1) : "N/A", "pH", Icons.eco_outlined, Colors.green, isDark, colorScheme)),
                    ],
                  ),
                ],
              ),

              // Title Section 2: Diagnosis
              Text(
                "Diagnosis Sistem",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              // Diagnosis Banner
              _buildModernDiagnosisBanner(data.isValid ? data.statusPupuk : "N/A", isDark, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getWeatherGradient(int code, {bool isDay = true}) {
    if (!isDay) {
      return const LinearGradient(
        colors: [
          Color(0xFF0F172A), // Dark slate
          Color(0xFF1E1E38), // Night purple-blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Rainy
    if ((code >= 1063 && code <= 1201) || (code >= 1273 && code <= 1282)) {
      return const LinearGradient(
        colors: [
          Color(0xFF1E293B), // Dark grey-blue
          Color(0xFF334155), // Medium grey-blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Cloudy
    if (code == 1003 || code == 1006 || code == 1009) {
      return const LinearGradient(
        colors: [
          Color(0xFF0F2A4A), // Dark blue-grey
          Color(0xFF1E3A5F), // Blue-grey
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Sunny/Clear (Day)
    return const LinearGradient(
      colors: [
        Color(0xFF0369A1), // Sky blue
        Color(0xFF0284C7), // Lighter sky blue
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildMobileWeatherCard(bool isDark, ColorScheme colorScheme) {
    final weatherGradient = _getWeatherGradient(
      forecastList.isNotEmpty ? (forecastList[0]['code'] as int? ?? 1000) : 1000,
      isDay: forecastList.isNotEmpty ? (forecastList[0]['isDay'] as bool? ?? true) : true,
    );

    return GestureDetector(
      onTap: () => _showHourlyForecastBottomSheet(context, colorScheme, isDark),
      child: Container(
        clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: weatherGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cuacaColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid lines overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _GridLinePainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prakiraan Cuaca Lahan",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              locationName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "24 JAM",
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cuacaIcon, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      cuacaSuhu,
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cuacaKondisi,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 16),
                
                // 3 columns: Humidity, Wind, Rain
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherParamItem(Icons.water_drop_outlined, "Kelembaban", cuacaKelembaban),
                    _buildWeatherParamItem(Icons.air_rounded, "Angin", cuacaAngin),
                    _buildWeatherParamItem(Icons.umbrella_rounded, "Peluang Hujan", cuacaHujan),
                  ],
                ),
                
                // The hourly forecast has been removed to save 150px vertical space,
                // preventing the overflow since the mobile dashboard cannot scroll.
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showHourlyForecastBottomSheet(BuildContext context, ColorScheme colorScheme, bool isDark) {
    if (forecastList.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Prediksi Cuaca 24 Jam",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: forecastList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final item = forecastList[index];
                      final hourStr = DateFormat('HH:mm').format(item['time']);
                      final isNow = index == 0;
                      final tempVal = (item['temp'] as num).round();
                      final rainVal = item['rain'] as int? ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isNow
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: isNow ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5)) : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              isNow ? "Sekarang" : hourStr,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (rainVal > 0) ...[
                              Icon(Icons.water_drop, size: 14, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(
                                "$rainVal%",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Icon(
                              _getWeatherIcon(item['code'], isDay: item['isDay']),
                              color: isNow ? colorScheme.primary : colorScheme.onSurface,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 40,
                              child: Text(
                                "$tempVal°",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherParamItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildCompactMetricCard(String label, String value, String unit, IconData icon, Color color, bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 8,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDiagnosisBanner(String status, bool isDark, ColorScheme colorScheme) {
    final cleanStatus = status.trim().toUpperCase();
    final isIdeal = cleanStatus.contains("IDEAL");
    final isOver = cleanStatus.contains("OVER");
    final isNA = cleanStatus == "N/A";
    
    final accentColor = isNA
        ? const Color(0xFFEF4444)
        : isIdeal
            ? const Color(0xFF10B981)
            : isOver
                ? const Color(0xFFEF4444)
                : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNA
                  ? Icons.error_rounded
                  : isIdeal
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "STATUS TANAH",
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      cleanStatus.isEmpty ? "MEMUAT DATA..." : cleanStatus,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isNA
                      ? "Data sensor tidak valid. Silakan periksa koneksi modul sensor Anda."
                      : isIdeal
                          ? "Nutrisi & kelembaban tanah stabil dan optimal untuk pertumbuhan tanaman cabai."
                          : isOver
                              ? "Hara berlebihan! Hentikan pupuk kimia & alirkan air segera."
                              : "Tanah butuh nutrisi tambahan atau air. Pompa otomatis akan aktif.",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // --- SUB WIDGET BUILDERS ---
  // ============================================

  Widget _buildMetricCard(String label, String value, String unit, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
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
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }



  Widget _buildWebWeatherWidget(bool isDark, ColorScheme colorScheme) {
    // Mini temperature chart data from forecast
    final List<FlSpot> tempSpots = [];
    double minTemp = 100, maxTemp = -100;
    final int forecastCount = forecastList.length > 12 ? 12 : forecastList.length;
    for (int i = 0; i < forecastCount; i++) {
      final double t = (forecastList[i]['temp'] as num).toDouble();
      tempSpots.add(FlSpot(i.toDouble(), t));
      if (t < minTemp) minTemp = t;
      if (t > maxTemp) maxTemp = t;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: cuacaColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP BANNER ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cuacaColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  cuacaColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: cuacaColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locationName,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cuacaColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cuacaSuhu,
                        style: GoogleFonts.outfit(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cuacaKondisi,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cuacaColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: cuacaColor.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: Icon(cuacaIcon, color: cuacaColor, size: 30),
                ),
              ],
            ),
          ),

          // ── MINI TEMP CHART ──
          if (tempSpots.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TREN SUHU (12 JAM KE DEPAN)",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxTemp - minTemp).clamp(2.0, 10.0),
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: colorScheme.onSurface.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, meta) {
                                if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                                return Text(
                                  "${val.round()}°",
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 18,
                              getTitlesWidget: (val, meta) {
                                int idx = val.toInt();
                                if (idx >= 0 && idx < forecastCount && idx % 3 == 0) {
                                  return Text(
                                    DateFormat('HH').format(forecastList[idx]['time']),
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: tempSpots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: cuacaColor,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) {
                                return spot.x == tempSpots.first.x || spot.x == tempSpots.last.x;
                              },
                              getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: cuacaColor,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  cuacaColor.withValues(alpha: 0.3),
                                  cuacaColor.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        minY: minTemp - 1,
                        maxY: maxTemp + 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── HOURLY SCROLL ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colorScheme.onSurface.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Text(
                  "PREDIKSI PER JAM",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: forecastList.length,
                    itemBuilder: (context, index) {
                      final item = forecastList[index];
                      final hourStr = DateFormat('HH:mm').format(item['time']);
                      final isNow = index == 0;
                      final itemColor = _getWeatherColor(item['code'], isDay: item['isDay']);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isNow
                                ? cuacaColor.withValues(alpha: 0.15)
                                : colorScheme.onSurface.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isNow
                                  ? cuacaColor.withValues(alpha: 0.4)
                                  : colorScheme.onSurface.withValues(alpha: 0.06),
                              width: isNow ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isNow ? "NOW" : hourStr,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: isNow ? cuacaColor : colorScheme.onSurface.withValues(alpha: 0.45),
                                  fontWeight: isNow ? FontWeight.w900 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                _getWeatherIcon(item['code'], isDay: item['isDay']),
                                color: itemColor,
                                size: 15,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(item['temp'] as num).round()}°",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isNow ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSystemDiagnosisWidget(String status, bool isDark, ColorScheme colorScheme) {
    final cleanStatus = status.trim().toUpperCase();
    final isIdeal = cleanStatus.contains("IDEAL");
    final isOver = cleanStatus.contains("OVER");
    final isNA = cleanStatus == "N/A";
    
    final accentColor = isNA
        ? const Color(0xFFEF4444)
        : isIdeal
            ? const Color(0xFF10B981)
            : isOver
                ? const Color(0xFFEF4444)
                : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Analisis Lahan Realtime", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isNA
                      ? Icons.error_outline_rounded
                      : isIdeal
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  cleanStatus.isEmpty ? "MENDAPATKAN DATA..." : cleanStatus,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNA
                ? "Data sensor tidak valid atau koneksi bermasalah. Harap periksa node hardware Anda."
                : isIdeal
                    ? "Nutrisi dan kelembaban tanah saat ini dalam keadaan stabil dan optimal untuk pertumbuhan tanaman cabai."
                    : isOver
                        ? "Kandungan unsur hara berlebihan! Harap hentikan pemberian pupuk kimia dan alirkan air murni segera."
                        : "Tanah terindikasi membutuhkan nutrisi tambahan atau air. Sekuens penyiraman otomatis akan dieksekusi.",
            style: GoogleFonts.inter(fontSize: 11, height: 1.5, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }  Widget _buildChartSection(ColorScheme colorScheme, bool isDark) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobileLayout = screenWidth <= 800;

    return Container(
      padding: EdgeInsets.all(isMobileLayout ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobileLayout)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tren NPK Tanah",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Nitrogen · Phosphorus · Potassium (mg/kg)",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLegendChip("N", const Color(0xFF3B82F6), isDark),
                    const SizedBox(width: 8),
                    _buildLegendChip("P", const Color(0xFFA855F7), isDark),
                    const SizedBox(width: 8),
                    _buildLegendChip("K", const Color(0xFFF97316), isDark),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tren NPK Tanah",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Nitrogen · Phosphorus · Potassium (mg/kg)",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildLegendChip("N", const Color(0xFF3B82F6), isDark),
                    const SizedBox(width: 8),
                    _buildLegendChip("P", const Color(0xFFA855F7), isDark),
                    const SizedBox(width: 8),
                    _buildLegendChip("K", const Color(0xFFF97316), isDark),
                  ],
                ),
              ],
            ),
          SizedBox(height: isMobileLayout ? 16 : 24),
          SizedBox(
            height: isMobileLayout ? 280 : 380,
            child: StreamBuilder<List<PrecisionHistoryData>>(
              stream: _precisionService.getHistoryStream(),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting && logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Mengunduh data historis...",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.15),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Belum ada data historis NPK",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group by date to find daily averages for the last 7 days
                final Map<String, List<PrecisionHistoryData>> groupedLogs = {};
                for (var log in logs) {
                  if (!log.data.isValid) continue;
                  // Handle different date formats (e.g., '2026-06-03' or '03/06/2026')
                  final dateStr = log.waktu.split(' ')[0];
                  if (!groupedLogs.containsKey(dateStr)) {
                    groupedLogs[dateStr] = [];
                  }
                  groupedLogs[dateStr]!.add(log);
                }

                // Generate exactly 7 days of data ending today
                final DateTime now = DateTime.now();
                final List<PrecisionHistoryData> dailyAverages = [];
                
                for (int i = 6; i >= 0; i--) {
                  final dt = now.subtract(Duration(days: i));
                  final targetDay = dt.day.toString().padLeft(2, '0');
                  final targetMonth = dt.month.toString().padLeft(2, '0');
                  
                  // Find matching date key in groupedLogs
                  String? matchedKey;
                  for (var key in groupedLogs.keys) {
                    if (key.contains(targetDay) && key.contains(targetMonth)) {
                       matchedKey = key;
                       break;
                    }
                  }

                  if (matchedKey != null && groupedLogs[matchedKey]!.isNotEmpty) {
                    final dayLogs = groupedLogs[matchedKey]!;
                    final avgN = dayLogs.map((e) => e.data.n).reduce((a, b) => a + b) ~/ dayLogs.length;
                    final avgP = dayLogs.map((e) => e.data.p).reduce((a, b) => a + b) ~/ dayLogs.length;
                    final avgK = dayLogs.map((e) => e.data.k).reduce((a, b) => a + b) ~/ dayLogs.length;
                    
                    dailyAverages.add(PrecisionHistoryData(
                      key: matchedKey,
                      waktu: "$targetDay/$targetMonth", // For X-axis label
                      data: PrecisionRealtimeData.empty(isValid: true),
                    ));
                    // Manually set n,p,k (since empty is 0, we can't use factory if fields are final)
                    // Wait, PrecisionRealtimeData has final fields. We must instantiate.
                    dailyAverages.last = PrecisionHistoryData(
                      key: matchedKey,
                      waktu: "$targetDay/$targetMonth",
                      data: PrecisionRealtimeData(
                        n: avgN, p: avgP, k: avgK, 
                        suhu: 0, kelembaban: 0, ph: 0, ec: 0, 
                        statusPupuk: "", isValid: true
                      )
                    );
                  } else {
                    // Carry forward previous day's value if no data exists
                    int prevN = dailyAverages.isNotEmpty ? dailyAverages.last.data.n : 0;
                    int prevP = dailyAverages.isNotEmpty ? dailyAverages.last.data.p : 0;
                    int prevK = dailyAverages.isNotEmpty ? dailyAverages.last.data.k : 0;
                    dailyAverages.add(PrecisionHistoryData(
                      key: "empty_$i",
                      waktu: "$targetDay/$targetMonth",
                      data: PrecisionRealtimeData(
                        n: prevN, p: prevP, k: prevK, 
                        suhu: 0, kelembaban: 0, ph: 0, ec: 0, 
                        statusPupuk: "", isValid: true
                      )
                    ));
                  }
                }
                final visibleLogs = dailyAverages;

                List<FlSpot> nSpots = [];
                List<FlSpot> pSpots = [];
                List<FlSpot> kSpots = [];

                for (int i = 0; i < visibleLogs.length; i++) {
                  nSpots.add(FlSpot(i.toDouble(), visibleLogs[i].data.n.toDouble()));
                  pSpots.add(FlSpot(i.toDouble(), visibleLogs[i].data.p.toDouble()));
                  kSpots.add(FlSpot(i.toDouble(), visibleLogs[i].data.k.toDouble()));
                }

                // Dynamic Y range calculations to amplify fluctuations
                double minYVal = 1000;
                double maxYVal = 0;
                for (var log in visibleLogs) {
                  double n = log.data.n.toDouble();
                  double p = log.data.p.toDouble();
                  double k = log.data.k.toDouble();
                  if (n < minYVal) minYVal = n;
                  if (p < minYVal) minYVal = p;
                  if (k < minYVal) minYVal = k;
                  if (n > maxYVal) maxYVal = n;
                  if (p > maxYVal) maxYVal = p;
                  if (k > maxYVal) maxYVal = k;
                }
                
                double adjustedMinY = (minYVal - 15).clamp(0, 1000);
                double adjustedMaxY = maxYVal + 40; // extra headroom so peak doesn't clip top
                if (adjustedMaxY <= adjustedMinY) {
                  adjustedMaxY = adjustedMinY + 50;
                }
                
                double range = adjustedMaxY - adjustedMinY;
                double verticalInterval = 20;
                if (range > 200) {
                  verticalInterval = 50;
                } else if (range < 50) {
                  verticalInterval = 10;
                }

                double chartWidth = MediaQuery.of(context).size.width > 800 
                    ? MediaQuery.of(context).size.width 
                    : 800.0;
                    
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24.0, top: 24.0, bottom: 8.0),
                      child: LineChart(
                        duration: const Duration(milliseconds: 400),
                  LineChartData(
                    minY: adjustedMinY,
                    maxY: adjustedMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: verticalInterval,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: colorScheme.onSurface.withValues(alpha: 0.04),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                      getDrawingVerticalLine: (v) => FlLine(
                        color: colorScheme.onSurface.withValues(alpha: 0.03),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: verticalInterval,
                          getTitlesWidget: (val, meta) {
                            if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                            return Text(
                              "${val.round()}",
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: colorScheme.onSurface.withValues(alpha: 0.35),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (val, meta) {
                            if (val != val.toInt()) return const SizedBox.shrink();
                            int idx = val.toInt();
                            if (idx >= 0 && idx < visibleLogs.length) {
                              final dateLabel = visibleLogs[idx].waktu;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dateLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipColor: (touchedSpot) => isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        tooltipBorder: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final labels = ["Nitrogen", "Phosphorus", "Potassium"];
                            final colors = [
                              const Color(0xFF3B82F6),
                              const Color(0xFFA855F7),
                              const Color(0xFFF97316),
                            ];
                            final i = spot.barIndex.clamp(0, 2);
                            return LineTooltipItem(
                              "${labels[i]}: ${spot.y.round()} mg/kg",
                              GoogleFonts.inter(
                                color: colors[i],
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((i) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: barData.color?.withValues(alpha: 0.4) ?? Colors.white24,
                              strokeWidth: 2,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                  radius: 5,
                                  color: bar.color ?? Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                    lineBarsData: [
                      _buildLineBar(nSpots, const Color(0xFF3B82F6), isDark),
                      _buildLineBar(pSpots, const Color(0xFFA855F7), isDark),
                      _buildLineBar(kSpots, const Color(0xFFF97316), isDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBar(List<FlSpot> spots, Color color, bool isDark) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.8,
      isStrokeCapRound: true,
      shadow: Shadow(
        color: color.withValues(alpha: 0.35),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3.5,
          color: color,
          strokeWidth: 2,
          strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
  Widget _buildLegendChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


}

// Decorative subtle grid line painter for the premium header card
class _GridLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.8;

    const spacing = 28.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
