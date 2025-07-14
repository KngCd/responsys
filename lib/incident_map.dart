import 'dart:io';
// import 'dart:developer';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart'; 
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'hazard_map.dart';
// import 'widgets/navbar.dart';

class QgisMapScreen extends StatefulWidget {
  static bool forceReloadOnNextBuild = false;
  const QgisMapScreen({super.key});

  @override
  State<QgisMapScreen> createState() => _QgisMapScreenState();
}

class _QgisMapScreenState extends State<QgisMapScreen> {
  // final server = InAppLocalhostServer(documentRoot: 'assets/qgis_map');
  bool _isWebViewLoading = true; 
  InAppWebViewController? _webViewController;
  final Completer<InAppWebViewController> _controllerCompleter = Completer<InAppWebViewController>();
  Completer<void>? _cleanupCompleter;

  File? _capturedImage;
  final TextEditingController _descriptionController = TextEditingController();
  BuildContext? dialogContext;
  // Timer? _syncTimer;

  // For editing
  int? _editingReportId;
  String? _existingPhotoPath;
  String? _originalBarangay;
  String? _editingDescription;
  bool _isEditingLocation = false;

  Future<bool> checkLocationServicesEnabled(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to prompt user to enable location
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Disabled'),
          content: Text('Please enable location services in your device settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

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

  Future<File> addWatermarkToImage(File originalImage, String barangay) async {
    final bytes = await originalImage.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return originalImage;

    // Format date in 12-hour format with leading zero fix
    final now = DateTime.now();
    int hour = now.hour % 12;
    hour = hour == 0 ? 12 : hour;
    final dateStr =
        "${now.month}/${now.day}/${now.year}, $hour:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    final watermark = "Date/Time: $dateStr\nBarangay: $barangay";

    // Font setup
    final font = img.arial48;

    // Split text into lines
    final linesList = watermark.split('\n');
    final lineSpacing = 4;

    // Total text height (with spacing)
    final totalTextHeight =
        linesList.length * font.lineHeight +
        ((linesList.length - 1) * lineSpacing);

    final barHeight = totalTextHeight + 40; // padding

    // Draw white background bar
    img.fillRect(
      image,
      x1: 0,
      y1: image.height - barHeight,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgb8(255, 255, 255),
    );

    // Center text vertically
    int textY = image.height - barHeight + ((barHeight - totalTextHeight) ~/ 2);
    final textX = 20;

    // Draw each line (bold simulation)
    for (final line in linesList) {
      for (int dx = 0; dx <= 1; dx++) {
        for (int dy = 0; dy <= 1; dy++) {
          img.drawString(
            image,
            line,
            font: font,
            x: textX + dx,
            y: textY + dy,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
      textY += font.lineHeight + lineSpacing;
    }

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final newPath =
        "${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final newFile = File(newPath)
      ..writeAsBytesSync(img.encodeJpg(image, quality: 90));

    return newFile;
  }

  Future<String> _getBarangayFromLeaflet() async {
    try {
      final controller = await _controllerCompleter.future;
      final result = await controller.callAsyncJavaScript(
        functionBody: "return window.resolveBarangayViaHiddenLocate();",
      );

      final dynamic value = result?.value;
      debugPrint("🟡 JS returned: $value");

      if (value == null) {
        return "NO_GPS";
      }

      final trimmed = value.toString().trim();

      debugPrint("Barangay result from JS: $trimmed");

      return trimmed.isEmpty ? "NO_GPS" : trimmed;
    } catch (e) {
      debugPrint("❌ JS geolocation failed: $e");
      return "NO_GPS";
    }
  }

  Future<void> _openCamera(Function(File?) onImagePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile == null) {
      onImagePicked(null); // User cancelled
      return;
    }

    final file = File(pickedFile.path);
    final barangay = await _getBarangayFromLeaflet();

    if (!mounted) return; // Safety check

    if (barangay == 'NO_GPS') {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text(
            'Location is required to take a photo. Please turn on your device\'s location (GPS) and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close form sheet
      }

      onImagePicked(null);
      return;
    }

    if (barangay == 'OUTSIDE_BOUNDARY') {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Outside Boundary'),
          content: const Text(
            'You are outside the Padre Garcia boundary. Please move inside the area to take a photo and submit a report.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close form sheet
      }

      onImagePicked(null);
      return;
    }

    // Valid barangay
    final watermarkedFile = await addWatermarkToImage(file, barangay);
    onImagePicked(watermarkedFile);
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
    final String timeNow = TimeOfDay.now().format(context);
    final uri = Uri.parse(
      'http://192.168.1.10/Capstone-MDRRMO/php/reportings/citizens_reports/update_report.php',
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
          window.saveUserReportToLocalStorage && window.saveUserReportToLocalStorage(${jsonEncode(data)});
          window.setFlutterReports && window.setFlutterReports();
          Swal.fire({
            toast: true,
            position: 'top',
            icon: 'success',
            title: "Report updated successfully!",
            showConfirmButton: false,
            timer: 1500,
            timerProgressBar: true,
            customClass: { popup: 'swal2-geo-tooltip' }
        });
        """,
      );
      if (mounted) {
        setState(() {
          _isEditingLocation = false;
          _editingReportId = null;
          _existingPhotoPath = null;
          _originalBarangay = null;
          _editingDescription = null;
        });
      }
    } else {
      webViewController?.evaluateJavascript(
        source: """
        Swal.fire({
            toast: true,
            position: 'top',
            icon: 'error',
            title: "Failed to update report.",
            showConfirmButton: false,
            timer: 1500,
            timerProgressBar: true,
            customClass: { popup: 'swal2-geo-tooltip' }
        });
      """,
      );
    }
  }

  Future<void> fetchAndSyncReportsFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        Uri.parse('http://192.168.1.10/Capstone-MDRRMO/php/reportings/citizens_reports/check_reports_status.php'),
      );
      if (response.statusCode == 200) {
        final List reports = jsonDecode(response.body);
        // Only keep active and not deleted in localStorage, but keep all for reference
        await prefs.setString('citizenReports', jsonEncode(reports));
        await sendLocalReportsToWebView();
      }
    } catch (e) {
      _webViewController?.evaluateJavascript(
        source: """
          Swal.fire({
            toast: true,
            position: 'top',
            icon: 'error',
            title: "Could not connect to the server",
            text: "${e.runtimeType}: ${e.toString().replaceAll('"', "'").replaceAll('\n', ' ')}",
            showConfirmButton: false,
            timer: 1500,
            timerProgressBar: true,
            customClass: { popup: 'swal2-geo-tooltip' }
          });
        """,
      );
    }
  }
  
  Future<void> cleanupWebView() async {
    try {
      await _webViewController?.evaluateJavascript(
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
      await _webViewController?.loadUrl(
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
    fetchAndSyncReportsFromServer();
    // Increase interval to 10 seconds
    // _syncTimer = Timer.periodic(Duration(seconds: 10), (timer) {
    //   fetchAndSyncReportsFromServer();
    // });
  }

  @override
  void dispose() {
    cleanupWebView();
    //  _syncTimer?.cancel();
    _webViewController = null; // Prevent further use
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
    await _ensureLocationServiceEnabled();
  }
  
  Future<void> _ensureLocationServiceEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled && mounted) {
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text('Please enable location services (GPS) in your device settings to use this app.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx, false);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (result != true) break; // User cancelled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }
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

  // Send local reports to JS for marker update
  Future<void> sendLocalReportsToWebView() async {
    if (!mounted || _webViewController == null) return;
    final prefs = await SharedPreferences.getInstance();
    final reportsString = prefs.getString('citizenReports');
    final safeJson = (reportsString == null || reportsString.isEmpty)
        ? '[]'
        : reportsString;
    _webViewController!.evaluateJavascript(
      source: "window.setFlutterReports($safeJson);",
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
      // Check if location services are enabled before submitting
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        // Prompt user to enable location
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'Please enable location services (GPS) in your device settings to submit a report.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        return; // Cancel submission
      }
    
      try {
        final uri = Uri.parse(
          'http://192.168.1.10/Capstone-MDRRMO/php/reportings/citizens_reports/save_report.php',
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
          await _webViewController?.evaluateJavascript(
            source: """
              window.saveUserReportToLocalStorage && window.saveUserReportToLocalStorage(${jsonEncode(data)});
              window.setFlutterReports && window.setFlutterReports();
              Swal.fire({
                  toast: true,
                  position: 'top',
                  icon: 'success',
                  title: "Report added successfully!",
                  showConfirmButton: false,
                  timer: 1500,
                  timerProgressBar: true,
                  customClass: { popup: 'swal2-geo-tooltip' }
              });
            """,
          );
        } else {
          webViewController?.evaluateJavascript(
            source: """
            Swal.fire({
                toast: true,
                position: 'top',
                icon: 'error',
                title: "Failed to add report.",
                showConfirmButton: false,
                timer: 1500,
                timerProgressBar: true,
                customClass: { popup: 'swal2-geo-tooltip' }
            });
          """,
          );
        }
      } catch (e){
          if (dialogContext != null && Navigator.canPop(dialogContext!)) {
            Navigator.of(dialogContext!).pop();
          }
          webViewController?.evaluateJavascript(
            source: """
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
    VoidCallback? onClosed,
  }) async {
    _editingReportId = editingReportId;
    _existingPhotoPath = existingPhotoPath;
    _originalBarangay = originalBarangay;
    bool isPhotoLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // smoother drag/animation
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
                    Container(
                      width: double.infinity,
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
                    const SizedBox(height: 10),
                    Text(
                      "Barangay",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
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
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 250),
                            child: isPhotoLoading
                                ? const Padding(
                                    key: ValueKey('loading'),
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: CircularProgressIndicator(),
                                  )
                                : _capturedImage != null
                                    ? Stack(
                                        key: ValueKey('image'),
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
                                                decoration: const BoxDecoration(
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
                                    : (_existingPhotoPath ?? '').isNotEmpty
                                        ? ClipRRect(
                                            key: ValueKey('network'),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              (() {
                                                if (_existingPhotoPath!.startsWith('http')) {
                                                  return _existingPhotoPath!;
                                                } else if (_existingPhotoPath!.startsWith('images/')) {
                                                  return 'http://192.168.1.10/Capstone-MDRRMO/${_existingPhotoPath!}';
                                                } else {
                                                  return 'http://192.168.1.10/Capstone-MDRRMO/images/report_pictures/${_existingPhotoPath!}';
                                                }
                                              })(),
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: Colors.red,
                                                  ),
                                            ),
                                          )
                                        : const Icon(
                                            key: ValueKey('icon'),
                                            Icons.camera_alt,
                                            size: 40,
                                            color: Colors.black54,
                                          ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.camera,
                              color: Colors.white70,
                            ),
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
                              setModalState(() => isPhotoLoading = true);
                              await Future.microtask(() {}); // let spinner show
                              await _openCamera((file) {
                                if (!mounted) return;
                                if (file != null) {
                                  setModalState(() {
                                    _capturedImage = file;
                                    isPhotoLoading = false;
                                  });
                                  setState(() {
                                    _capturedImage = file;
                                  });
                                } else {
                                  setModalState(() => isPhotoLoading = false);
                                }
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
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Opacity(
                        opacity:
                            isPhotoLoading ||
                                (_editingReportId == null &&
                                    _capturedImage == null) ||
                                _descriptionController.text.trim().isEmpty
                            ? 0.4
                            : 1.0,
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
                          onPressed:
                              isPhotoLoading ||
                                  (_editingReportId == null &&
                                      _capturedImage == null) ||
                                  _descriptionController.text.trim().isEmpty
                              ? () {} // Do nothing
                              : () async {
                                  final isNewReport = _editingReportId == null;
                                  final hasImage = _capturedImage != null;
                                  final hasDescription = _descriptionController.text
                                      .trim()
                                      .isNotEmpty;

                                  final isBarangayChangedWithoutNewPhoto =
                                      !isNewReport &&
                                      _originalBarangay != null &&
                                      barangay != _originalBarangay &&
                                      !hasImage;

                                  if (!hasImage && isNewReport) {
                                    await _showValidationDialog(
                                      'Please take a photo.',
                                    );
                                    return;
                                  }
                                  if (!hasDescription) {
                                    await _showValidationDialog(
                                      'Please enter a description.',
                                    );
                                    return;
                                  }
                                  if (isBarangayChangedWithoutNewPhoto) {
                                    await _showValidationDialog(
                                      'Please take a new photo because the barangay was changed.',
                                    );
                                    return;
                                  }

                                  Navigator.of(context).pop();
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
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      if (onClosed != null) onClosed();
      _webViewController?.evaluateJavascript(
        source:
            "window.isIncidentFormOpen = false; window.removeGeolocateMarker && window.removeGeolocateMarker();",
      );
      if (_editingReportId == null) {
        _descriptionController.clear();
        setState(() {
          _capturedImage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the static flag is set, reload the WebView
    if (QgisMapScreen.forceReloadOnNextBuild && _webViewController != null) {
      QgisMapScreen.forceReloadOnNextBuild = false;
      _webViewController?.reload();
    }

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
      body: Stack(
        children: [
          InAppWebView(
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

              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
              }

              // Force reload if coming from navbar navigation
              if (QgisMapScreen.forceReloadOnNextBuild) {
                QgisMapScreen.forceReloadOnNextBuild = false;
                controller.reload();
              }

              controller.addJavaScriptHandler(
                handlerName: 'onMapClick',
                callback: (args) async {
                  final double lat = args[0];
                  final double lng = args[1];
                  final String barangay = args.length > 2 ? args[2] : '';
                  await Future.delayed(const Duration(milliseconds: 350));
                  if (_editingReportId != null) {
                    // Use retained fields for the form
                    _descriptionController.text = _editingDescription ?? '';
                    _showIncidentFormSheet(
                      latitude: lat,
                      longitude: lng,
                      barangay: barangay,
                      editingReportId: _editingReportId,
                      existingPhotoPath: _existingPhotoPath,
                      originalBarangay: _originalBarangay,
                    );
                    // setState(() {
                    //   _isEditingLocation = false; // Hide banner after picking location
                    //   // Do NOT clear editing fields here, only after submit/cancel
                    // });
                  } else {
                    _showIncidentFormSheet(
                      latitude: lat,
                      longitude: lng,
                      barangay: barangay,
                    );
                  }
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'onEditReport',
                callback: (args) async {
                  final int reportId = args[0];
                  final double lat = args[1];
                  final double lng = args[2];
                  final String barangay = args[3];
                  final String description = args[4];
                  final String existingPhotoPath = args[5];
                  final String originalBarangay = args[6];
      
                  final updateLocation = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Update Location?'),
                      content: const Text('Do you want to update the location for this report?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
      
                  if (updateLocation == true) {
                    _descriptionController.text = description;
                    setState(() {
                      _editingReportId = reportId;
                      _existingPhotoPath = existingPhotoPath;
                      _originalBarangay = originalBarangay;
                      _editingDescription = description;
                      _isEditingLocation = true; // Show banner
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tap on the map to select the new location.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    // Wait for map click, then open form with new lat/lng
                  } else {
                    _descriptionController.text = description;
                    _showIncidentFormSheet(
                      latitude: lat,
                      longitude: lng,
                      barangay: barangay,
                      editingReportId: reportId,
                      existingPhotoPath: existingPhotoPath,
                      originalBarangay: originalBarangay,
                      onClosed: () {
                        setState(() {
                          _editingDescription = null;
                          _isEditingLocation = false;
                          _editingReportId = null;
                          _existingPhotoPath = null;
                          _originalBarangay = null;
                        });
                      },
                    );
                  }
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'onOpenLocationSettings',
                callback: (_) async {
                  await Geolocator.openLocationSettings();
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

              // Inject your updated JS function after the page finishes loading
              await controller.evaluateJavascript(source: '''
                console.log("🟢 JS injected from Dart - v1.4");

                window.resolveBarangayViaHiddenLocate = function () {
                    return new Promise((resolve) => {
                        if (!navigator.geolocation) {
                            console.log("Returning from JS: NO_GPS");
                            return resolve("NO_GPS");
                        }

                        navigator.geolocation.getCurrentPosition(
                            function (position) {
                                const lat = position.coords.latitude;
                                const lng = position.coords.longitude;

                                const barangay = getBarangayForLatLng(lat, lng);
                                if (!barangay) {
                                    console.log("Returning from JS: OUTSIDE_BOUNDARY");
                                    resolve("OUTSIDE_BOUNDARY");
                                } else {
                                    console.log("Returning from JS:", barangay);
                                    resolve(barangay);
                                }
                            },
                            function (error) {
                                console.log("Returning from JS: NO_GPS (error)", error);
                                resolve("NO_GPS");
                            },
                            {
                                enableHighAccuracy: true,
                                maximumAge: 0,
                                timeout: 10000
                            }
                        );
                    });
                };
              ''');
            },
          ),
          if (_isWebViewLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white, // Just a blank white overlay
              ),
          ),
          if (_isEditingLocation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.amber[700],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "You're currently editing the report location",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isEditingLocation = false;
                          _editingReportId = null;
                          _existingPhotoPath = null;
                          _originalBarangay = null;
                          _editingDescription = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // bottomNavigationBar: BottomNavBar(
      //   current: NavPage.incident,
      //   parentContext: context,
      //   onCleanup: cleanupWebView,
      // ),
    );
  }
}