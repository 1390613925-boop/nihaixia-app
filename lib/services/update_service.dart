import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

class UpdateInfo {
  final String version;
  final String tagName;
  final String body;
  final String apkDownloadUrl;
  final int apkSize;
  final String? apkSha256;

  UpdateInfo({
    required this.version,
    required this.tagName,
    required this.body,
    required this.apkDownloadUrl,
    required this.apkSize,
    this.apkSha256,
  });
}

class UpdateService {
  static const _repoOwner = 'jangviktor-web';
  static const _repoName = 'nihaixia-app';
  static const _ignoredVersionKey = 'ignored_update_version';
  static const _permanentlyIgnoredKey = 'permanently_ignored_versions';
  static const _mirrorEnabledKey = 'update_mirror_enabled';

  /// 获取当前应用版本号
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 是否启用镜像加速（默认开启：国内 GitHub 访问慢时自动切换镜像）
  static Future<bool> isMirrorEnabled() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('user_settings',
          where: "key = ?", whereArgs: [_mirrorEnabledKey]);
      if (rows.isEmpty) return true;
      return (rows.first['value'] as String) == 'true';
    } catch (_) {
      return true;
    }
  }

  /// 设置是否启用镜像加速
  static Future<void> setMirrorEnabled(bool enabled) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': _mirrorEnabledKey, 'value': enabled ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 检查是否有新版本（自动尝试主源 + 镜像源）
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final sources = const <String>[
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      ];

      Map<String, dynamic>? releaseData;
      for (final url in sources) {
        try {
          final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('网络超时'),
          );
          if (response.statusCode == 200) {
            releaseData = json.decode(response.body) as Map<String, dynamic>;
            break;
          }
        } catch (e) {
          debugPrint('更新源不可用，尝试下一镜像: $url -> $e');
        }
      }
      if (releaseData == null) return null;

      final tagName = releaseData['tag_name'] ?? '';
      final remoteVersion = tagName.replaceFirst('v', '');

      if (!_isNewerVersion(remoteVersion, currentVersion)) return null;
      if (await _isIgnored(remoteVersion)) return null;

      String apkUrl = '';
      int apkSize = 0;
      final assets = releaseData['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] ?? '';
          apkSize = asset['size'] ?? 0;
          break;
        }
      }

      if (apkUrl.isEmpty) return null;

      // 从 Release 说明中解析随包下发的 SHA-256（约定：正文含 "SHA256: <64位十六进制>" 一行）
      final bodyText = releaseData['body'] as String? ?? '暂无更新说明';
      String? apkSha256;
      final hashMatch = RegExp(r'(?:sha256|sha-256)[:\s]+([0-9a-fA-F]{64})',
              caseSensitive: false)
          .firstMatch(bodyText);
      if (hashMatch != null) apkSha256 = hashMatch.group(1)!.toLowerCase();

      return UpdateInfo(
        version: remoteVersion,
        tagName: tagName,
        body: bodyText,
        apkDownloadUrl: apkUrl,
        apkSize: apkSize,
        apkSha256: apkSha256,
      );
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  /// 比较版本号，判断remote是否比current新
  static bool _isNewerVersion(String remote, String current) {
    final remoteParts = remote.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final r = (i < remoteParts.length) ? (remoteParts[i] ?? 0) : 0;
      final c = (i < currentParts.length) ? (currentParts[i] ?? 0) : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// 检查版本是否已被忽略
  static Future<bool> _isIgnored(String version) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('user_settings',
        where: "key = ?", whereArgs: [_permanentlyIgnoredKey]);
    if (rows.isNotEmpty) {
      final ignored = (rows.first['value'] as String).split(',');
      if (ignored.contains(version)) return true;
    }

    final ignoreRow = await db.query('user_settings',
        where: "key = ?", whereArgs: [_ignoredVersionKey]);
    if (ignoreRow.isNotEmpty && ignoreRow.first['value'] == version) {
      return true;
    }

    return false;
  }

  /// 忽略当前版本（下次还会提醒）
  static Future<void> ignoreVersion(String version) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': _ignoredVersionKey, 'value': version},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 永久忽略版本
  static Future<void> permanentlyIgnoreVersion(String version) async {
    final db = await DatabaseHelper.instance.database;
    // 读取现有永久忽略列表
    final rows = await db.query('user_settings',
        where: "key = ?", whereArgs: [_permanentlyIgnoredKey]);
    List<String> ignored = [];
    if (rows.isNotEmpty) {
      final val = rows.first['value'] as String;
      if (val.isNotEmpty) ignored = val.split(',');
    }
    if (!ignored.contains(version)) ignored.add(version);

    await db.insert(
      'user_settings',
      {'key': _permanentlyIgnoredKey, 'value': ignored.join(',')},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 下载APK文件。
  /// 安全约束：仅允许 GitHub 官方资产主机，禁用任何第三方镜像；
  /// 下载完成后若提供 expectedSize / expectedSha256 则分别校验体积与哈希，不符即丢弃，杜绝投毒安装。
  static Future<File?> downloadApk(
    String url,
    void Function(double progress)? onProgress, {
    int expectedSize = 0,
    String? expectedSha256,
  }) async {
    if (!_isTrustedHost(url)) {
      debugPrint('拒绝下载：非受信任主机 $url');
      return null;
    }
    return _tryDownload(url, onProgress,
        expectedSize: expectedSize, expectedSha256: expectedSha256);
  }

  /// 仅允许 GitHub 官方资产主机，杜绝第三方镜像投毒。
  static bool _isTrustedHost(String url) {
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return false;
    }
    final host = uri.host;
    return host == 'github.com' ||
        host == 'objects.githubusercontent.com' ||
        host.endsWith('.githubusercontent.com');
  }

  /// 单个下载源尝试：15s 内未收到首字节判定该镜像过慢，返回 null 交由上层切换
  static Future<File?> _tryDownload(
    String url,
    void Function(double progress)? onProgress, {
    int expectedSize = 0,
    String? expectedSha256,
  }) async {
    final client = http.Client();
    File? file;
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/nihaisha_update.apk';
      file = File(filePath);
      if (await file.exists()) await file.delete();

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(
        const Duration(minutes: 5),
      );
      if (response.statusCode != 200) {
        debugPrint('下载失败[HTTP ${response.statusCode}]: $url');
        return null;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = file.openWrite();

      final firstByteCompleter = Completer<void>();
      late StreamSubscription<List<int>> subscription;
      Timer? firstByteTimer;
      var firstByteArrived = false;

      firstByteTimer = Timer(const Duration(seconds: 15), () {
        if (!firstByteArrived) {
          debugPrint('镜像首字节超时，切换: $url');
          firstByteCompleter.completeError(Exception('first_byte_timeout'));
        }
      });

      subscription = response.stream.listen(
        (chunk) {
          if (!firstByteArrived) {
            firstByteArrived = true;
            firstByteTimer?.cancel();
          }
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        },
        onError: (e, _) => firstByteCompleter.completeError(e),
        onDone: () => firstByteCompleter.complete(),
        cancelOnError: true,
      );

      try {
        await firstByteCompleter.future;
      } catch (e) {
        firstByteTimer.cancel();
        await subscription.cancel();
        await sink.close();
        return null;
      }
      await sink.flush();
      await sink.close();
      if (expectedSize > 0) {
        final actual = await file.length();
        if (actual != expectedSize) {
          debugPrint('APK 体积校验不符：期望 $expectedSize，实际 $actual，已丢弃');
          await file.delete();
          return null;
        }
      }
      if (expectedSha256 != null) {
        final bytes = await file.readAsBytes();
        final digest = sha256.convert(bytes).toString().toLowerCase();
        if (digest != expectedSha256.toLowerCase()) {
          debugPrint('APK SHA-256 校验不符：期望 $expectedSha256，实际 $digest，已丢弃');
          await file.delete();
          return null;
        }
      }
      return file;
    } catch (e) {
      debugPrint('下载APK失败[$url]: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
