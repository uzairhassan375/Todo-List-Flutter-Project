import 'package:flutter/material.dart';

Widget buildNavItem(BuildContext context, IconData icon, String label, String route) {
  return InkWell(
    onTap: () {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != route) {
        Navigator.pushNamed(context, route);
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}
