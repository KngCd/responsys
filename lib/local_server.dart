import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LocalServer {
  static final InAppLocalhostServer _server =
      InAppLocalhostServer(documentRoot: 'assets/qgis_map', port: 8080);

  static Future<void> start() async {
    await _server.start();
  }

  static Future<void> stop() async {
    await _server.close();
  }
}