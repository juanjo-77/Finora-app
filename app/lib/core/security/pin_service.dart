import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Maneja el PIN local de la app: guarda solo el hash, nunca el PIN en texto plano.
class PinService {
  static final _storage = const FlutterSecureStorage();
  static const _kHash = 'pin_hash';
  static const _kBiometric = 'biometric_enabled';

  static String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  static Future<bool> isPinEnabled() async {
    final hash = await _storage.read(key: _kHash);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    await _storage.write(key: _kHash, value: _hash(pin));
  }

  static Future<bool> verifyPin(String pin) async {
    final hash = await _storage.read(key: _kHash);
    if (hash == null) return false;
    return hash == _hash(pin);
  }

  static Future<void> disablePin() async {
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kBiometric);
  }

  static Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _kBiometric);
    return v == 'true';
  }

  static Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(key: _kBiometric, value: value.toString());
  }
}