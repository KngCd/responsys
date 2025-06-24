import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsys Onboarding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _showLogo = true;

  @override
  void initState() {
    super.initState();
    // Show logo for 1.5 seconds, then go to onboarding
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _showLogo = false;
        _currentPage = 0;
      });
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  // Custom page indicator (pill for active, circle for inactive)
  Widget _buildIndicator(int count, int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: current == i ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: current == i ? const Color(0xFF232A67) : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Splash logo page
    if (_showLogo) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Onboarding pages
      final List<Widget> pages = [
      // 1. Welcome Page (with circles)
      Stack(
        children: [
          // Top left large blue circle (mostly off-screen)
          Positioned(
            left: -100,
            top: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00084D), // dark navy
                    Color(0xFF0012B3), // deep blue
                  ],                  
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Top right medium grey circle (partially offscreen)
          Positioned(
            left: 130,
            top: -100,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x991B435F),
              ),
            ),
          ),
          // Small top-right circle
          Positioned(
            right: 30,
            top: 65,
            child: Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x991B435F),
              ),
            ),
          ),
          // Bottom right medium grey circle
          Positioned(
            right: -55,
            bottom: 265,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B435F), // medium grey
                    Color(0xFF388BC5), // light blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Bottom right small grey circle
          Positioned(
            right: 170,
            bottom: 265,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x991B435F),
              ),
            ),
          ),
          // Close icon
          Positioned(
            top: 16,
            right: 16,
            child: Icon(Icons.close, color: Colors.grey[700]),
          ),
          // Text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient text: Welcome to\nResponsys
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Welcome to\nResponsys",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Gradient text: Padre Garcia
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Padre Garcia",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w200, // lighter than headline, readable
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 2. Report Incidents
      Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Icon(Icons.close, color: Colors.grey[700]),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient text
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Report\nIncidents",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Gradient text: Padre Garcia
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Incidents located in Padre Garcia can be reported\nto the MDRRMO using this app",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w200, // lighter than headline, readable
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 3. Real Time Report Collection
      Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Icon(Icons.close, color: Colors.grey[700]),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient text
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Realtime\nReport\nCollection",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Gradient text: Padre Garcia
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Incidents located in Padre Garcia can be reported\nto the MDRRMO using this app",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w200, // lighter than headline, readable
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 4. Stay Informed, Stay Alert, Stay Safe
      Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Icon(Icons.close, color: Colors.grey[700]),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient text
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Stay Informed\nStay Alert\nStay Safe",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Gradient text: Padre Garcia
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                          colors: [Color(0xFF0D001B), Color(0xFF222964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Incidents located in Padre Garcia can be reported\nto the MDRRMO using this app",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w200, // lighter than headline, readable
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => pages[index],
            physics: const BouncingScrollPhysics(),
          ),
          // Page indicator
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _buildIndicator(pages.length, _currentPage),
          ),
        ],
      ),
    );
  }
}