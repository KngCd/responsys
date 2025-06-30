import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'hazard_map.dart';
import 'widgets/navbar.dart';

class QgisMapScreen extends StatefulWidget {
  const QgisMapScreen({super.key});

  @override
  State<QgisMapScreen> createState() => _QgisMapScreenState();
}

class _QgisMapScreenState extends State<QgisMapScreen> {
  final server = InAppLocalhostServer(documentRoot: 'assets/qgis_map');
  InAppWebViewController? _webViewController;
  File? _capturedImage;

  Future<void> _openCamera(Function(File) onImagePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      onImagePicked(file);
    }
  }

  @override
  void initState() {
    super.initState();
    // server.start();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  // Show incident form sheet with location and barangay
  void _showIncidentFormSheet({
    required double latitude,
    required double longitude,
    required String barangay,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    Text(
                      "Report an Incident",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: const Color(0xFF232A67),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Latitude & Longitude field
                    Text(
                      "Location (Latitude, Longitude)",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "$latitude, $longitude",
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Barangay field
                    Text(
                      "Barangay",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          barangay,
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Image capture section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (_capturedImage != null)
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _capturedImage!,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _capturedImage = null;
                                      });
                                      setState(() {
                                        _capturedImage = null;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.black54,
                            ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: Icon(Icons.camera, color: Colors.white70,),
                            label: Text(
                              _capturedImage == null
                                  ? "Take Photo"
                                  : "Retake Photo",
                              style: GoogleFonts.montserrat(
                                color:
                                  Colors.white70,
                                  fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF232A67),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () async {
                              await _openCamera((file) {
                                setModalState(() {
                                  _capturedImage = file;
                                });
                                setState(() {
                                  _capturedImage = file;
                                });
                              });
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Make sure it's clear and not blurred",
                            style: GoogleFonts.montserrat(
                              color: Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Description",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        maxLines: 3,
                        style: GoogleFonts.montserrat(fontSize: 13),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              "Write a short description about the witnessed incident.",
                          hintStyle: GoogleFonts.montserrat(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF232A67),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _webViewController?.evaluateJavascript(
                            source: """
                              Swal.fire({
                                title: 'Success',
                                text: 'Report updated successfully!',
                                icon: 'success',
                                confirmButtonColor: '#52b855',
                                timer: 1000
                              });
                            """,
                          );
                        },
                        child: Text(
                          "Submit",
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident Map"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: InAppWebView(
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("JS LOG: ${consoleMessage.message}");
        },
        initialUrlRequest: URLRequest(
          url: WebUri("http://localhost:8080/incident_report.html"),
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
          _webViewController = controller;
          controller.addJavaScriptHandler(
            handlerName: 'onMapClick',
            callback: (args) async {
              // args[0]: latitude, args[1]: longitude, args[2]: barangay
              final double lat = args[0];
              final double lng = args[1];
              final String barangay = args.length > 2 ? args[2] : '';
              // Add a delay for slow-mo effect
              await Future.delayed(const Duration(milliseconds: 350));
              _showIncidentFormSheet(
                latitude: lat,
                longitude: lng,
                barangay: barangay,
              );
            },
          );
          controller.addJavaScriptHandler(
            handlerName: 'onWarningIconClick',
            callback: (args) async {
              // Navigate to HazardMapScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HazardMapScreen(),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        current: NavPage.incident,
        parentContext: context,
      ),
    );
  }
}