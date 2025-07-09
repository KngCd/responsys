import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'incident_map.dart';
// import 'widgets/navbar.dart';

class HazardMapScreen extends StatefulWidget {
  static bool forceReloadOnNextBuild = false;
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  // final server = InAppLocalhostServer(documentRoot: 'assets/qgis_map');
  InAppWebViewController? webViewController;
  Completer<void>? _cleanupCompleter;
  bool _isWebViewLoading = true; 

  Future<void> cleanupWebView() async {
    try {
      await webViewController?.evaluateJavascript(
        source: """
        if (window.map && window.map.remove) {
          window.map.off();
          window.map.remove();
          window.map = null;
        }
        let id = window.setTimeout(function() {}, 0);
        while (id--) window.clearTimeout(id);
        let intervalId = window.setInterval(function() {}, 0);
        while (intervalId--) window.clearInterval(intervalId);
        """,
      );
      _cleanupCompleter = Completer<void>();
      await webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri("about:blank")),
      );
      // Wait for onLoadStop to complete the completer
      await _cleanupCompleter!.future.timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }
  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  @override
  void dispose() {
    cleanupWebView();
    webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the static flag is set, reload the WebView
    if (HazardMapScreen.forceReloadOnNextBuild && webViewController != null) {
      HazardMapScreen.forceReloadOnNextBuild = false;
      webViewController?.reload();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hazard Map"),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pushAndRemoveUntil(
        //       context,
        //       MaterialPageRoute(builder: (context) => QgisMapScreen()),
        //       (route) => false,
        //     );
        //   },
        // ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => webViewController?.reload(),
        tooltip: "Reload Map",
        child: const Icon(Icons.refresh),
      ),
      body: Stack(
        children: [
          InAppWebView(
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
              if (HazardMapScreen.forceReloadOnNextBuild) {
                HazardMapScreen.forceReloadOnNextBuild = false;
                controller.reload();
              }
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isWebViewLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              if (_cleanupCompleter != null &&
                  !_cleanupCompleter!.isCompleted &&
                  url.toString() == "about:blank") {
                _cleanupCompleter!.complete();
              }

              setState(() {
                _isWebViewLoading = false;
              });
            },
          ),
          if (_isWebViewLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white, // Just a blank white overlay
              ),
            ),
        ],
      ),
      // bottomNavigationBar: BottomNavBar(
      //   current: NavPage.hazard,
      //   parentContext: context,
      //   onCleanup: cleanupWebView,
      // )
    );
  }
}