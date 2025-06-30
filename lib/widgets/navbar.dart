import 'package:flutter/material.dart';
import '../incident_map.dart';
import '../hazard_map.dart';

enum NavPage { incident, hazard }

class BottomNavBar extends StatelessWidget {
  final NavPage current;
  final BuildContext parentContext;

  const BottomNavBar({super.key, required this.current, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    // Colors for active/inactive states
    const activeColor = Color(0xFF232A67);
    const inactiveColor = Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.map,
              label: 'Incident Map',
              isActive: current == NavPage.incident,
              onTap: () {
                if (current != NavPage.incident) {
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (_) => const QgisMapScreen()),
                    (route) => false,
                  );
                }
              },
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
            _NavBarItem(
              icon: Icons.warning_amber_rounded,
              label: 'Hazard Map',
              isActive: current == NavPage.hazard,
              onTap: () {
                if (current != NavPage.hazard) {
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (_) => const HazardMapScreen()),
                    (route) => false,
                  );
                }
              },
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withAlpha((0.08 * 255).toInt()) : Colors.transparent, // use withAlpha for opacity
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: isActive ? 24 : 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: isActive ? 12 : 11,
                  letterSpacing: 0.2,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 3,
                  width: 18,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}