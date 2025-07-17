import 'package:shared_preferences/shared_preferences.dart';

class IPConfig {
  static const String _key = 'backend_ip';

  static Future<void> setIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, ip);
  }

  static Future<String> getIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '192.168.1.10';
  }

  static Future<Uri> getUri(String endpoint) async {
    final ip = await getIP();
    return Uri.parse('http://$ip/Capstone-MDRRMO/$endpoint');
  }

  static Future<String> getFullImageUrl(String path) async {
    final ip = await getIP();
    if (path.startsWith('http')) return path;
    if (path.startsWith('images/')) return 'http://$ip/Capstone-MDRRMO/$path';
    return 'http://$ip/Capstone-MDRRMO/images/report_pictures/$path';
  }
}