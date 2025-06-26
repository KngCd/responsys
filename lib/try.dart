// ignore_for_file: unused_field, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'hazard_map.dart';
// import 'dart:math' as math;

class QgisMapScreen extends StatefulWidget {
  const QgisMapScreen({super.key});

  @override
  State<QgisMapScreen> createState() => _QgisMapScreenState();
}

class _QgisMapScreenState extends State<QgisMapScreen> {
  bool _showSheet = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final double _defaultSheetSize = 0.95;
  // final double _minSheetSize = 0.4;
  // final double _maxSheetSize = 0.95;
  // bool _isSheetExpanded = false;
  // bool _isSheetClosing = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 16),
            const Text(
              "Incident reported successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF232A67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // void _openSheet() {
  //     setState(() {
  //       _showSheet = true;
  //       _isSheetExpanded = false;
  //       _isSheetClosing = false;
  //     });

  //     // Force layout to settle before accepting drag gestures
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       Future.delayed(const Duration(milliseconds: 100), () {
  //         try {
  //           _sheetController.jumpTo(_defaultSheetSize);
  //         } catch (_) {
  //           // Ignore if controller not ready, happens once sometimes
  //         }
  //       });
  //     });
  //   }

  // void _closeSheet() {
  //   setState(() {
  //     _showSheet = false;
  //     _isSheetExpanded = false;
  //     _isSheetClosing = false;
  //   });
  // }

  void _showIncidentFormSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: [0.4, 0.7, 0.95], // Snap to min, mid, and max
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Report an Incident",
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "13.869876986064197, 121.22666851341037",
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "Castillo",
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
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.black54,
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                children: [
                                  TextSpan(text: "Use this as the camera for "),
                                  TextSpan(
                                    text: "validation",
                                    style: GoogleFonts.montserrat(
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
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
                            _showSuccessDialog();
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map placeholder image
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Image.asset(
                  'assets/images/map_placeholder.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Search bar with logo inside and warning icon outside
            Positioned(
              top: 32,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Search bar with logo inside
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/images/logo.png'),
                            radius: 18,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Search',
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Warning icon (outside search bar)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) =>
                      //           HazardMap(), // Replace with your page widget
                      //     ),
                      //   );
                      // },
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Map controls (zoom in/out, location)
            Positioned(
              left: 12,
              top: 120,
              child: Column(
                children: [
                  _MapControlButton(icon: Icons.add, onTap: () {}),
                  const SizedBox(height: 4),
                  _MapControlButton(icon: Icons.remove, onTap: () {}),
                  const SizedBox(height: 4),
                  _MapControlButton(icon: Icons.location_on, onTap: () {}),
                ],
              ),
            ),

            // Small white circle button (show draggable sheet)
            // Circle button to show sheet
            if (!_showSheet)
              Positioned(
                bottom: 100,
                left: 10,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showIncidentFormSheet,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}