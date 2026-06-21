import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk manajemen PIN Bitanic 6-digit.
/// PIN tidak pernah disimpan plaintext — selalu SHA-256 hash.
class PinService {
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  // Storage keys
  static const String _pinHashKey = 'bitanic_app_pin_hash';
  static const String _attemptsKey = 'bitanic_pin_failed_attempts';
  static const String _lockoutKey = 'bitanic_pin_lockout_until';

  /// Hash PIN dengan SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Cek apakah PIN sudah pernah dibuat
  Future<bool> hasPin() async {
    try {
      final value = await _storage.read(key: _pinHashKey);
      return value != null && value.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Simpan PIN baru (hash dulu sebelum disimpan)
  Future<void> createPin(String rawPin) async {
    final hash = _hashPin(rawPin);
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.delete(key: _attemptsKey);
    await _storage.delete(key: _lockoutKey);
  }

  /// Verifikasi PIN — return true jika cocok
  Future<bool> verifyPin(String rawPin) async {
    try {
      final storedHash = await _storage.read(key: _pinHashKey);
      if (storedHash == null) return false;
      return _hashPin(rawPin) == storedHash;
    } catch (_) {
      return false;
    }
  }

  /// Hapus PIN dan semua state terkait (dipanggil saat reset PIN)
  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _attemptsKey);
    await _storage.delete(key: _lockoutKey);
  }

  // --- Failed Attempts Management ---

  Future<int> getFailedAttempts() async {
    final val = await _storage.read(key: _attemptsKey);
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    await _storage.write(key: _attemptsKey, value: '${current + 1}');
  }

  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _attemptsKey);
    await _storage.delete(key: _lockoutKey);
  }

  // --- Lockout Management ---

  /// Cek apakah saat ini sedang dalam masa lockout
  Future<bool> isLockedOut() async {
    final until = await getLockoutUntil();
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /// Ambil waktu lockout berakhir
  Future<DateTime?> getLockoutUntil() async {
    final val = await _storage.read(key: _lockoutKey);
    if (val == null) return null;
    final ms = int.tryParse(val);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Set lockout selama [duration] ke depan
  Future<void> setLockout(Duration duration) async {
    final until = DateTime.now().add(duration);
    await _storage.write(
      key: _lockoutKey,
      value: '${until.millisecondsSinceEpoch}',
    );
  }
}
