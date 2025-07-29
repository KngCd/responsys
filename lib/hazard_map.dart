import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/server_config.dart';
import 'utils/connection_state.dart';
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
  String? _backendIP;
  bool _isIpConfigVisible = false;
  final TextEditingController _ipController = TextEditingController();
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

    IPConfig.getIP().then((ip) {
      setState(() {
        _backendIP = ip;
        _ipController.text = ip;
      });
    });
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
      appBar: null,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "reload",
            onPressed: () => webViewController?.reload(),
            tooltip: "Reload Map",
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "ipConfig",
            onPressed: () {
              setState(() {
                _isIpConfigVisible = !_isIpConfigVisible;
              });
            },
            tooltip: "Configure IP",
            backgroundColor: Colors.deepOrange,
            child: const Icon(Icons.settings_ethernet),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
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

                controller.addJavaScriptHandler(
                  handlerName: 'onConnectionChanged',
                  callback: (args) {
                    final bool isConnected = args[0];
                    ServerConnectionState.setConnected(isConnected);
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isWebViewLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                if (_cleanupCompleter != null &&
                    !_cleanupCompleter!.isCompleted &&
                    url.toString() == "about:blank") {
                  _cleanupCompleter!.complete();
                }

                setState(() {
                  _isWebViewLoading = false;
                });

                if (_backendIP != null) {
                  await controller.evaluateJavascript(
                    source: 'window.backendIP = "$_backendIP"; console.log("Injected backend IP: $_backendIP");',
                  );
                }
                // Get current connection state from Flutter
                final isAlreadyConnected = ServerConnectionState.isConnected;
              
                await controller.evaluateJavascript(
                  source: '''
                    console.log("🔁 Starting hazard map connectivity polling");
                
                    if (window.hazardConnectionInterval) clearInterval(window.hazardConnectionInterval);
                
                    // Initialize with Flutter's connection state
                    let lastSuccess = ${isAlreadyConnected ? 'true' : 'null'};
                
                    // If already connected, load hazards IMMEDIATELY
                    if ($isAlreadyConnected) {
                      console.log("✅ Already connected - IMMEDIATELY loading hazards");
                      fetchHazards(); // Load hazards right away!
                    }
                
                    setTimeout(() => {
                      window.hazardConnectionInterval = setInterval(() => {
                        const ip = window.backendIP || '192.168.1.10';
                  
                        fetch(`http://\${ip}/Capstone-MDRRMO/php/hazards/fetch_citizen_hazards.php`, {
                          method: 'HEAD'
                        })
                        .then(response => {
                          if (!response.ok) throw new Error("Server responded with error");
                  
                          if (lastSuccess !== true) {
                            lastSuccess = true;
                            
                            // Notify Flutter about connection state
                            if (window.flutter_inappwebview) {
                              window.flutter_inappwebview.callHandler('onConnectionChanged', true);
                            }
                            
                            // Only show success toast if we weren't already connected
                            if (!$isAlreadyConnected) {
                              Swal.fire({
                                toast: true,
                                position: 'top',
                                icon: 'success',
                                title: "Connected to server",
                                showConfirmButton: false,
                                timer: 1200,
                                timerProgressBar: true,
                                customClass: { popup: 'swal2-geo-tooltip' }
                              });
                            }
                  
                            // IMMEDIATE LOADING when connection is established
                            fetchHazards();
                          }
                        })
                        .catch(err => {
                          if (lastSuccess !== false) {
                            lastSuccess = false;
                            
                            // Notify Flutter about connection state
                            if (window.flutter_inappwebview) {
                              window.flutter_inappwebview.callHandler('onConnectionChanged', false);
                            }
                            
                            Swal.fire({
                              toast: true,
                              position: 'top',
                              icon: 'error',
                              title: "Could not connect to the server",
                              showConfirmButton: false,
                              timer: 1500,
                              timerProgressBar: true,
                              customClass: { popup: 'swal2-geo-tooltip' }
                            });
                          }
                        });
                      }, 1000); // 1 second polling
                    }, 2000); // Initial delay before starting polling
                  ''',
                );
              },
            ),
            if (_isWebViewLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white, // Just a blank white overlay
                ),
            ),
            if (_isIpConfigVisible)
              Positioned(
                top: 20,
                right: 16,
                left: 16,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _ipController,
                          decoration: InputDecoration(
                            labelText: "Backend IP",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                final newIp = _ipController.text.trim();
                                if (newIp.isNotEmpty) {
                                  await IPConfig.setIP(newIp);
                                  final updatedIp = await IPConfig.getIP();

                                  setState(() {
                                    _backendIP = updatedIp;
                                    _isIpConfigVisible = false;
                                  });

                                  await webViewController?.evaluateJavascript(
                                    source:
                                        'window.backendIP = "$updatedIp"; console.log("Updated window.backendIP to: $updatedIp");',
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("IP updated to $updatedIp"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _isIpConfigVisible = false);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavBar(
      //   current: NavPage.hazard,
      //   parentContext: context,
      //   onCleanup: cleanupWebView,
      // )
    );
  }
}