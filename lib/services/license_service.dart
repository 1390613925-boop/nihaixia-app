import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../data/database_helper.dart';

enum LicenseResult { valid, invalid, expired, badFormat }

class LicenseInfo {
  const LicenseInfo({
    required this.result,
    required this.deviceId,
    this.code,
    this.expiresAt,
  });

  final LicenseResult result;
  final String deviceId;
  final String? code;
  final DateTime? expiresAt;

  bool get isValid => result == LicenseResult.valid;

  int? get remainingDays => remainingDaysAt(DateTime.now());

  int? remainingDaysAt(DateTime now) {
    if (expiresAt == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return expiresAt!.difference(today).inDays;
  }

  String get remainingLabel => remainingLabelAt(DateTime.now());

  String remainingLabelAt(DateTime now) {
    final days = remainingDaysAt(now);
    if (days == null) return '未激活';
    if (days < 0) return '已过期';
    if (days == 0) return '今日到期（剩余不到1天）';
    return '剩余 $days 天';
  }

  String get expiryLabel => expiresAt == null
      ? '—'
      : '${expiresAt!.year.toString().padLeft(4, '0')}-'
            '${expiresAt!.month.toString().padLeft(2, '0')}-'
            '${expiresAt!.day.toString().padLeft(2, '0')}';
}

/// Offline license verifier paired byte-for-byte with the supplied card-key
/// generator: 2 expiry bytes followed by a 12-byte HMAC, base62 encoded to
/// exactly 19 characters. The HMAC binds a card to the local 16-byte device ID.
class LicenseService {
  static const _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static const _secretHex =
      '899da048421b85fc17ede1b0dae13af8a932de30ac19d9b1479afd9864e76b01';
  static final _epoch = DateTime(2024, 1, 1);
  static const _licenseCodeKey = 'license_v1_code';
  static const _licenseExpiryKey = 'license_v1_expiry';
  static final _db = DatabaseHelper.instance;

  static Future<String> getDeviceId() async {
    final saved = await _db.getSetting('device_id');
    if (saved != null && RegExp(r'^[0-9a-f]{32}$').hasMatch(saved)) {
      return saved;
    }
    final random = Random.secure();
    final id = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _db.setSetting('device_id', id);
    return id;
  }

  static Future<LicenseInfo> current() async {
    final code = await _db.getSetting(_licenseCodeKey);
    if (code == null) {
      return LicenseInfo(
        result: LicenseResult.invalid,
        deviceId: await getDeviceId(),
      );
    }
    return verify(code);
  }

  static Future<LicenseInfo> activate(String input) async {
    final code = input.replaceAll(RegExp(r'\s+'), '');
    final info = await verify(code);
    if (info.isValid) {
      await _db.setSetting(_licenseCodeKey, code);
      await _db.setSetting(_licenseExpiryKey, info.expiryLabel);
    }
    return info;
  }

  static Future<LicenseInfo> verify(String code) =>
      verifyAt(code, DateTime.now());

  /// [now] is injectable so expiry-boundary behavior can be tested exactly.
  static Future<LicenseInfo> verifyAt(String code, DateTime now) async {
    final deviceId = await getDeviceId();
    if (!RegExp(r'^[0-9A-Za-z]{19}$').hasMatch(code)) {
      return LicenseInfo(result: LicenseResult.badFormat, deviceId: deviceId);
    }

    late Uint8List payload;
    try {
      payload = _decode(code, 14);
    } catch (_) {
      return LicenseInfo(result: LicenseResult.badFormat, deviceId: deviceId);
    }

    final expiry = payload.sublist(0, 2);
    final suppliedMac = payload.sublist(2, 14);
    final expectedMac = Hmac(
      sha256,
      _hex(_secretHex),
    ).convert([..._hex(deviceId), ...expiry]).bytes.sublist(0, 12);
    if (!_constantTimeEquals(suppliedMac, expectedMac)) {
      return LicenseInfo(
        result: LicenseResult.invalid,
        deviceId: deviceId,
        code: code,
      );
    }

    final days = (expiry[0] << 8) | expiry[1];
    final expiresAt = _epoch.add(Duration(days: days));
    final today = DateTime(now.year, now.month, now.day);
    return LicenseInfo(
      result: today.isAfter(expiresAt)
          ? LicenseResult.expired
          : LicenseResult.valid,
      deviceId: deviceId,
      code: code,
      expiresAt: expiresAt,
    );
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  static Uint8List _decode(String value, int byteLength) {
    var number = BigInt.zero;
    for (final rune in value.runes) {
      final index = _alphabet.indexOf(String.fromCharCode(rune));
      if (index < 0) throw const FormatException();
      number = number * BigInt.from(62) + BigInt.from(index);
    }
    final out = Uint8List(byteLength);
    for (var i = byteLength - 1; i >= 0; i--) {
      out[i] = (number & BigInt.from(255)).toInt();
      number >>= 8;
    }
    if (number != BigInt.zero) throw const FormatException();
    return out;
  }

  static Uint8List _hex(String value) => Uint8List.fromList([
    for (var i = 0; i < value.length; i += 2)
      int.parse(value.substring(i, i + 2), radix: 16),
  ]);
}
