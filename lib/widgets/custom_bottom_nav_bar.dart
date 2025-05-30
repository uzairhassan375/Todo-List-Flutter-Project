import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF2E2E2E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildNavItem(context, Icons.home, "Index", '/homescreen'),
          buildNavItem(context, Icons.calendar_today, "Shared Todo", '/sharedtodo'),
          const SizedBox(width: 40),
          buildNavItem(context, Icons.timelapse, "Focus", '/focus'),
          buildNavItem(context, Icons.person, "Profile", '/profilescreen'),
        ],
      ),
    );
  }

  Widget buildNavItem(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
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
}
