import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'incident_map.dart';
import 'widgets/navbar.dart';

class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  final server = InAppLocalhostServer(documentRoot: 'assets/qgis_map');
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }
  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  // @override
  // void dispose() {
  //   server.close();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hazard Map"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const QgisMapScreen()),
              (route) => false,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => webViewController?.reload(),
        tooltip: "Reload Map",
        child: const Icon(Icons.refresh),
      ),
      body: InAppWebView(
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("JS LOG: ${consoleMessage.message}");
        },
        initialUrlRequest: URLRequest(
          url: WebUri("http://localhost:8080/hazards.html"),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
        ),
        onGeolocationPermissionsShowPrompt: (controller, origin) async {
          return GeolocationPermissionShowPromptResponse(
            origin: origin,
            allow: true,
            retain: true,
          );
        },
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
      ),
      bottomNavigationBar: BottomNavBar(
        current: NavPage.hazard,
        parentContext: context,
      )
    );
  }
}