import 'package:flutter/material.dart';

Widget buildNavItem(BuildContext context, IconData icon, String label, String route) {
  final currentRoute = ModalRoute.of(context)?.settings.name;
  final isActive = currentRoute == route;

  return InkWell(
    onTap: () {
      if (!isActive) {
        Navigator.pushNamed(context, route);
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.blueAccent : Colors.white, // Optional: Highlight active tab
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blueAccent : Colors.white, // Optional: Highlight text too
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
