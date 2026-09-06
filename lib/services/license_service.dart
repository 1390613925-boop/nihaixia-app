import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../data/database_helper.dart';

enum LicenseResult { valid, invalid, expired, badFormat, deviceMismatch }

class LicenseInfo {
  const LicenseInfo({
    required this.result,
    required this.deviceId,
    this.code,
    this.expiresAt,
    this.isPermanent = false,
  });

  final LicenseResult result;
  final String deviceId;
  final String? code;
  final DateTime? expiresAt;
  final bool isPermanent;

  bool get isValid => result == LicenseResult.valid;

  int? get remainingDays {
    if (isPermanent || expiresAt == null) return null;
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return expiresAt!.difference(today).inDays;
  }

  String get expiryLabel => isPermanent
      ? '永久有效'
      : expiresAt == null
      ? '—'
      : '${expiresAt!.year.toString().padLeft(4, '0')}-'
            '${expiresAt!.month.toString().padLeft(2, '0')}-'
            '${expiresAt!.day.toString().padLeft(2, '0')}';
}

/// 岐黄经方离线授权 v2。
///
/// 本文件已在原项目基础上修改：增加设备绑定、到期日、永久卡和启动闸门。
/// v2 保留 19 位 base62 短码：2 字节到期日 + 3 字节设备标识 + 9 字节 HMAC。
class LicenseService {
  static const _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static const _secretHex =
      '96ea52939c4b88644d762268d8431d5818a8d433d49a715c264d1fdfc6b9c806';
  static final _epoch = DateTime.utc(2024, 1, 1);
  static const _permanentDays = 0xFFFF;
  static const _licenseCodeKey = 'license_v2_code';
  static const _licenseDeviceKey = 'license_v2_device';
  static const _licenseExpiryKey = 'license_v2_expiry';
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
      await _db.setSetting(_licenseDeviceKey, info.deviceId);
      await _db.setSetting(_licenseExpiryKey, info.expiryLabel);
    }
    return info;
  }

  static Future<LicenseInfo> verify(String code) async {
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

    final deviceBytes = _hex(deviceId);
    final suppliedDeviceTag = payload.sublist(2, 5);
    final expectedDeviceTag = sha256.convert(deviceBytes).bytes.sublist(0, 3);
    if (!_constantTimeEquals(suppliedDeviceTag, expectedDeviceTag)) {
      return LicenseInfo(
        result: LicenseResult.deviceMismatch,
        deviceId: deviceId,
        code: code,
      );
    }

    final expiry = payload.sublist(0, 2);
    final suppliedMac = payload.sublist(5, 14);
    final expectedMac = Hmac(sha256, _hex(_secretHex))
        .convert([
          ...utf8.encode('QHJ2'),
          ...deviceBytes,
          ...expiry,
          ...expectedDeviceTag,
        ])
        .bytes
        .sublist(0, 9);
    if (!_constantTimeEquals(suppliedMac, expectedMac)) {
      return LicenseInfo(
        result: LicenseResult.invalid,
        deviceId: deviceId,
        code: code,
      );
    }

    final days = (expiry[0] << 8) | expiry[1];
    if (days == _permanentDays) {
      return LicenseInfo(
        result: LicenseResult.valid,
        deviceId: deviceId,
        code: code,
        isPermanent: true,
      );
    }

    final expiresAt = _epoch.add(Duration(days: days));
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final result = today.isAfter(expiresAt)
        ? LicenseResult.expired
        : LicenseResult.valid;
    return LicenseInfo(
      result: result,
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
