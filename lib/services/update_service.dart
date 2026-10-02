import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils.dart';

/// Số build, được GitHub Actions truyền vào lúc build (--dart-define=BUILD_NUMBER=...).
const int kBuild = int.fromEnvironment('BUILD_NUMBER', defaultValue: 0);

const String kRepo = 'ccon91788-ux/applich';
const String kApkUrl = 'https://github.com/$kRepo/releases/latest/download/LifeSync.apk';

/// Lấy số build từ tên tag dạng "build-12". Trả về null nếu không đọc được.
int? parseBuild(String tag) {
  final m = RegExp(r'(\d+)$').firstMatch(tag.trim());
  return m == null ? null : int.tryParse(m.group(1)!);
}

class UpdateService {
  static Future<bool> autoEnabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool('autoupdate') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setAutoEnabled(bool v) async {
    try {
      await (await SharedPreferences.getInstance()).setBool('autoupdate', v);
    } catch (_) {}
  }

  /// Số build mới nhất trên GitHub, hoặc null nếu không kiểm tra được.
  /// Chỉ đọc thông tin phiên bản công khai, không gửi dữ liệu của người dùng.
  static Future<int?> latestBuild() async {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await c.getUrl(
        Uri.parse('https://api.github.com/repos/$kRepo/releases/latest'),
      );
      req.headers.set('Accept', 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final j = jsonDecode(body);
      if (j is! Map || j['tag_name'] is! String) return null;
      return parseBuild(j['tag_name'] as String);
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  /// [silent] = true: chỉ báo khi có bản mới (dùng lúc mở app).
  static Future<void> check(BuildContext context, {bool silent = false}) async {
    final latest = await latestBuild();
    if (!context.mounted) return;
    if (latest == null) {
      if (!silent) toast(context, 'Không kiểm tra được bản mới. Hãy kiểm tra kết nối mạng.');
      return;
    }
    if (kBuild == 0 || latest <= kBuild) {
      if (!silent) {
        toast(context, kBuild == 0
            ? 'Đây là bản thử nghiệm, không có số phiên bản để so sánh.'
            : 'Bạn đang dùng bản mới nhất (build $kBuild).');
      }
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Có bản cập nhật mới 🎉'),
        content: Text(
          'Bản mới: build $latest (bạn đang dùng build $kBuild).\n\n'
          'Bấm "Tải về", mở file vừa tải và chọn Cài đặt/Cập nhật. '
          'Dữ liệu của bạn sẽ được giữ nguyên.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Để sau')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Tải về')),
        ],
      ),
    );
    if (go != true) return;
    try {
      final ok = await launchUrl(Uri.parse(kApkUrl), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) toast(context, 'Không mở được liên kết tải.');
    } catch (_) {
      if (context.mounted) toast(context, 'Không mở được liên kết tải.');
    }
  }
}
