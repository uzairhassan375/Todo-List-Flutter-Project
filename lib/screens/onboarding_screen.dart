
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding1.png',
      'title': 'Manage your tasks',
      'subtitle': 'You can easily manage all of your daily tasks in Taskify for free',
    },
    {
      'image': 'assets/images/onboarding2.png',
      'title': 'Create daily routine',
      'subtitle': 'In Taskify you can create your personalized routine to stay productive',
    },
    {
      'image': 'assets/images/onboarding3.png',
      'title': 'Organize your tasks',
      'subtitle': 'You can organize your daily tasks by adding your tasks into separate categories',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          final page = _pages[index];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
  height: MediaQuery.of(context).size.height * 0.25, // Adjust this value as needed
  child: Image.asset(
    page['image']!,
    fit: BoxFit.contain,
  ),
),
// ignore_for_file: unused_field

                Text(
                  page['title']!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  page['subtitle']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (index > 0)
                      TextButton(
                        onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        child: const Text('BACK', style: TextStyle(color: Colors.white)),
                      )
                    else
                      const SizedBox(width: 70),
                    ElevatedButton(
                      onPressed: () {
                        if (index == _pages.length - 1) {
                          Navigator.pushReplacementNamed(context, '/startscreen');
                        } else {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white,),
                      child: Text(index == _pages.length - 1 ? 'GET STARTED' : 'NEXT'),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
