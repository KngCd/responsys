import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _descriptionController = TextEditingController();
  BuildContext? dialogContext;
  Timer? _syncTimer;

  // For editing
  int? _editingReportId;
  String? _existingPhotoPath;
  String? _originalBarangay;

  // Robustly save report locally and update map
  Future<void> saveReportLocally(Map<String, dynamic> reportData) async {
    final prefs = await SharedPreferences.getInstance();
    final reportsString = prefs.getString('citizenReports');
    List reports = reportsString != null
        ? List<Map<String, dynamic>>.from(jsonDecode(reportsString))
        : [];
    // If editing, replace; if new, add
    if (reportData['id'] != null) {
      final idx = reports.indexWhere((r) => r['id'] == reportData['id']);
      if (idx != -1) {
        reports[idx] = reportData;
      } else {
        reports.add(reportData);
      }
    } else {
      reports.add(reportData);
    }
    await prefs.setString('citizenReports', jsonEncode(reports));
    await sendLocalReportsToWebView(); // Always update map after save
  }

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

  Future<void> _editIncidentReport({
    required int reportId,
    required double latitude,
    required double longitude,
    required String barangay,
    required String description,
    File? newPhoto,
    String? existingPhoto,
    required BuildContext context,
    required InAppWebViewController? webViewController,
  }) async {
    final String timeNow = TimeOfDay.now().format(context); // <-- Move this up!
    final uri = Uri.parse(
      'http://192.168.197.197/Capstone-MDRRMO/php/reportings/citizens_reports/update_report.php',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['report_id'] = reportId.toString()
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['description'] = description
      ..fields['barangay'] = barangay;

    if (newPhoto != null) {
      request.fields['isNewPhoto'] = 'true';
      request.files.add(
        await http.MultipartFile.fromPath('photoData', newPhoto.path),
      );
    } else if (existingPhoto != null) {
      request.fields['isNewPhoto'] = 'false';
      request.fields['existingPhoto'] = existingPhoto;
    }

    final response = await request.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      await saveReportLocally({
        'id': data['report_id'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'description': data['description'],
        'barangay': data['barangay'],
        'photo': data['photo'],
        'status': 'Active',
        'date': DateTime.now().toIso8601String(),
        'time': timeNow, // Use the captured value
      });
      await sendLocalReportsToWebView();
      await fetchAndSyncReportsFromServer();
      webViewController?.evaluateJavascript(
        source: """
        Swal.fire({
          title: 'Success!',
          text: 'Report updated successfully!',
          icon: 'success',
          confirmButtonColor: '#232A67'
        });
      """,
      );
      // webViewController?.reload();
    } else {
      webViewController?.evaluateJavascript(
        source: """
        Swal.fire({
          title: 'Error!',
          text: 'Failed to update report.',
          icon: 'error',
          confirmButtonColor: '#d32f2f'
        });
      """,
      );
    }
  }

  Future<void> fetchAndSyncReportsFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.get(
      Uri.parse('http://192.168.197.197/Capstone-MDRRMO/php/reportings/citizens_reports/check_reports_status.php?all=1'),
    );
    if (response.statusCode == 200) {
      final List reports = jsonDecode(response.body);
      // Only keep active and not deleted in localStorage, but keep all for reference
      await prefs.setString('citizenReports', jsonEncode(reports));
      await sendLocalReportsToWebView();
    }
  }
  
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    fetchAndSyncReportsFromServer();
    // refresh every 2 seconds
    _syncTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchAndSyncReportsFromServer();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _webViewController = null; // Prevent further use
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  Future<void> deleteReportLocally(int reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final reportsString = prefs.getString('citizenReports');
    if (reportsString == null) return;
    List reports = List<Map<String, dynamic>>.from(jsonDecode(reportsString));
    reports.removeWhere((r) => r['id'] == reportId);
    await prefs.setString('citizenReports', jsonEncode(reports));
    await sendLocalReportsToWebView(); // Update the map
  }

  Future<void> sendLocalReportsToWebView() async {
    if (!mounted || _webViewController == null) return;
    final prefs = await SharedPreferences.getInstance();
    final reportsString = prefs.getString('citizenReports');
    if (reportsString == null || _webViewController == null) return;
    // Send the reports as JSON to the JS handler in your HTML
    _webViewController!.evaluateJavascript(
      source: "window.setFlutterReports($reportsString);",
    );
  }

  Future<void> _submitIncidentReport({
    required double latitude,
    required double longitude,
    required String barangay,
    required String description,
    required File photo,
    required BuildContext context,
    required InAppWebViewController? webViewController,
  }) async {
    final uri = Uri.parse(
      'http://192.168.197.197/Capstone-MDRRMO/php/reportings/citizens_reports/save_report.php',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['description'] = description
      ..fields['barangay'] = barangay
      ..files.add(await http.MultipartFile.fromPath('photoData', photo.path));

    final response = await request.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      await saveReportLocally({
        'id': data['report_id'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'description': data['description'],
        'barangay': data['barangay'],
        'photo': data['photo'],
        'status': data['status'],
        'date': data['date'],
        'time': data['time'],
      });
      await sendLocalReportsToWebView();
      await fetchAndSyncReportsFromServer();
      // webViewController?.reload();
      await _webViewController?.evaluateJavascript(
        source: """
          Swal.fire({
            title: 'Success!',
            text: 'Report added successfully!',
            icon: 'success',
            confirmButtonColor: '#232A67'
          });
        """,
      );
    } else {
      webViewController?.evaluateJavascript(
        source: """
        Swal.fire({
          title: 'Error!',
          text: 'Failed to report incident.',
          icon: 'error',
          confirmButtonColor: '#d32f2f'
        });
      """,
      );
    }
  }

  Future<void> _showValidationDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incomplete Form'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show incident form sheet with location and barangay
  void _showIncidentFormSheet({
    required double latitude,
    required double longitude,
    required String barangay,
    int? editingReportId,
    String? existingPhotoPath,
    String? originalBarangay,
  }) {
    _editingReportId = editingReportId;
    _existingPhotoPath = existingPhotoPath;
    _originalBarangay = originalBarangay;

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
                      _editingReportId != null
                          ? "Edit Incident Report"
                          : "Report an Incident",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: const Color(0xFF232A67),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            icon: Icon(Icons.camera, color: Colors.white70),
                            label: Text(
                              _capturedImage == null
                                  ? "Take Photo"
                                  : "Retake Photo",
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
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
                        controller: _descriptionController,
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
                        onPressed: () async {
                          // Validation
                          if (_capturedImage == null &&
                              _editingReportId == null) {
                            await _showValidationDialog('Please take a photo.');
                            return;
                          }
                          if (_descriptionController.text.trim().isEmpty) {
                            await _showValidationDialog(
                              'Please enter a description.',
                            );
                            return;
                          }
                          // For editing: if barangay changed, require new photo
                          if (_editingReportId != null &&
                              _originalBarangay != null &&
                              barangay != _originalBarangay &&
                              _capturedImage == null) {
                            await _showValidationDialog(
                              'Please take a new photo because the barangay was changed.',
                            );
                            return;
                          }
                          Navigator.of(context).pop(); // Close the modal

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) {
                              dialogContext = ctx;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );

                          if (_editingReportId != null) {
                            await _editIncidentReport(
                              reportId: _editingReportId!,
                              latitude: latitude,
                              longitude: longitude,
                              barangay: barangay,
                              description: _descriptionController.text.trim(),
                              newPhoto: _capturedImage,
                              existingPhoto: _existingPhotoPath,
                              context: context,
                              webViewController: _webViewController,
                            );
                          } else {
                            await _submitIncidentReport(
                              latitude: latitude,
                              longitude: longitude,
                              barangay: barangay,
                              description: _descriptionController.text.trim(),
                              photo: _capturedImage!,
                              context: context,
                              webViewController: _webViewController,
                            );
                          }

                          if (mounted &&
                              dialogContext != null &&
                              Navigator.canPop(dialogContext!)) {
                            Navigator.of(dialogContext!).pop();
                          }
                          _descriptionController.clear();
                          setState(() {
                            _capturedImage = null;
                            _editingReportId = null;
                            _existingPhotoPath = null;
                            _originalBarangay = null;
                          });
                        },
                        child: Text(
                          _editingReportId != null ? "Update" : "Submit",
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _webViewController?.reload(),
        tooltip: "Reload Map",
        child: const Icon(Icons.refresh),
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
              await Future.delayed(const Duration(milliseconds: 350));
              _showIncidentFormSheet(
                latitude: lat,
                longitude: lng,
                barangay: barangay,
              );
            },
          );
          controller.addJavaScriptHandler(
            handlerName: 'onEditReport',
            callback: (args) async {
              // args: [reportId, latitude, longitude, barangay, description, existingPhotoPath, originalBarangay]
              final int reportId = args[0];
              final double lat = args[1];
              final double lng = args[2];
              final String barangay = args[3];
              final String description = args[4];
              final String existingPhotoPath = args[5];
              final String originalBarangay = args[6];
              _descriptionController.text = description;
              _showIncidentFormSheet(
                latitude: lat,
                longitude: lng,
                barangay: barangay,
                editingReportId: reportId,
                existingPhotoPath: existingPhotoPath,
                originalBarangay: originalBarangay,
              );
            },
          );
          controller.addJavaScriptHandler(
            handlerName: 'onWarningIconClick',
            callback: (args) async {
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
