import 'package:flutter/material.dart';
import 'incident_map.dart';
import 'hazard_map.dart';
import 'widgets/navbar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  Key _pageKey = UniqueKey();
  bool _isSwitching = false;
  // int _switchCount = 0;

  void _onNavTap(int index) async {
    setState(() {
      _isSwitching = true;
      // _switchCount++;
      _selectedIndex = index;
      _pageKey = UniqueKey();
    });
    // Give the new page a moment to build before removing the overlay
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      setState(() {
        _isSwitching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    if (_selectedIndex == 0) {
      page = QgisMapScreen(key: _pageKey);
    } else {
      page = HazardMapScreen(key: _pageKey);
    }

    return Scaffold(
        body: Stack(
          children: [
            page,
            if (_isSwitching) // Always overlay for first 3 switches
              Positioned.fill(child: Container(color: Colors.white)
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
        current: _selectedIndex == 0 ? NavPage.incident : NavPage.hazard,
        parentContext: context,
        onNavTap: _onNavTap,
      ),
    );
  }
}