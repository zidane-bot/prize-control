import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Data Model untuk menampung 7 parameter sensor NPK & Kualitas Tanah/Lingkungan
class SensorData {
  final double kelembaban; // Kelembaban Tanah (%)
  final double suhu;       // Suhu Tanah/Lingkungan (°C)
  final int ec;            // Electrical Conductivity (uS/cm)
  final double ph;         // Tingkat Keasaman (pH)
  final int n;             // Kandungan Nitrogen (mg/kg)
  final int p;             // Kandungan Fosfor (mg/kg)
  final int k;             // Kandungan Kalium (mg/kg)

  SensorData({
    required this.kelembaban,
    required this.suhu,
    required this.ec,
    required this.ph,
    required this.n,
    required this.p,
    required this.k,
  });

  /// Factory untuk parse data dari Firebase Map
  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    return SensorData(
      kelembaban: _toDouble(json['keLembaban'] ?? json['kelembaban']),
      suhu: _toDouble(json['suhu']),
      ec: _toInt(json['ec']),
      ph: _toDouble(json['ph']),
      n: _toInt(json['n']),
      p: _toInt(json['p']),
      k: _toInt(json['k']),
    );
  }

  /// Factory untuk object kosong/default
  factory SensorData.empty() {
    return SensorData(
      kelembaban: 0.0,
      suhu: 0.0,
      ec: 0,
      ph: 0.0,
      n: 0,
      p: 0,
      k: 0,
    );
  }

  // Helper parsing double yang aman dari dynamic types (int/double)
  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // Helper parsing int yang aman
  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}

/// Service untuk menangani operasi Firebase Realtime Database
class SensorService {
  // Instance database khusus menggunakan databaseURL dari user
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://precision-39b42-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );


  /// 1. Cek apakah inisialisasi Firebase secara umum sudah berjalan
  bool isFirebaseInitialized() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 2. Stream Status Koneksi Real-time ke Server Firebase Database (.info/connected)
  /// Ini sangat berguna untuk memverifikasi inisialisasi dan jaringan secara live di UI.
  Stream<bool> getConnectionStatusStream() {
    return _database.ref('.info/connected').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    }).handleError((error) {
      debugPrint("Koneksi Firebase info error: $error");
      return false;
    });
  }

  /// 3. Stream Data Sensor secara real-time dari path '/Bitanic/TambakUdang/Sensor_NPK' atau '/Bitanic/TambakUndang/Sensor_NPK'
  Stream<SensorData> getSensorStream() {
    return _database.ref('Bitanic').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        // Toleransi ejaan TambakUdang / TambakUndang agar selalu sinkron dengan Arduino & Firebase
        final pondData = (value['TambakUdang'] ?? value['TambakUndang']) as Map?;
        final sensorData = pondData?['Sensor_NPK'] as Map?;
        if (sensorData != null) {
          return SensorData.fromJson(sensorData);
        }
      }
      debugPrint("Data sensor kosong atau format salah, menggunakan data kosong.");
      return SensorData.empty();
    }).handleError((error) {
      debugPrint("Gagal mendengarkan perubahan data sensor: $error");
      return SensorData.empty();
    });
  }
}
