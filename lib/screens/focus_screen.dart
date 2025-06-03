import 'dart:async';
import 'package:do_not_disturb/do_not_disturb_plugin.dart';
import 'package:do_not_disturb/types.dart';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:taskify/widgets/custom_bottom_nav_bar.dart';
import 'add_task_sheet.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final dndPlugin = DoNotDisturbPlugin();
  Duration _focusDuration = const Duration(minutes: 0);
  Duration _originalDuration = const Duration(minutes: 0);
  Timer? _timer;
  bool _isFocusing = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Manually open the DND permission settings using android_intent_plus
  Future<void> _openDndSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      print('Could not open DND settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open DND settings: $e')),
      );
    }
  }

  Future<void> _startButtonPressed() async {
    if (_focusDuration.inSeconds == 0) return;

    if (_isFocusing) {
      _stopFocusing();
      return;
    }

    final hasAccess = await dndPlugin.isNotificationPolicyAccessGranted();

    if (!hasAccess) {
      await _openDndSettings();
      // Show dialog to instruct user
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'To enable Focus Mode, please grant "Do Not Disturb" access to this app in your device settings, then press Start again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If permission granted, enable DND and start timer
    await dndPlugin.setInterruptionFilter(InterruptionFilter.priority);

    setState(() {
      _isFocusing = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_focusDuration.inSeconds == 0) {
        timer.cancel();
        _stopFocusing();
        return;
      }
      setState(() {
        _focusDuration -= const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopFocusing() async {
    _timer?.cancel();
    setState(() {
      _isFocusing = false;
      _focusDuration = _originalDuration;
    });

    final hasAccess = await dndPlugin.isNotificationPolicyAccessGranted();
    if (hasAccess) {
      await dndPlugin.setInterruptionFilter(InterruptionFilter.all);
    }
  }

  Future<void> _pickTime() async {
    int? selectedMinutes = await showDialog<int>(
      context: context,
      builder: (context) {
        int minutes = 0;
        return AlertDialog(
          backgroundColor: const Color(0xFF121212), // Dark black background
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            "Select Focus Time (in minutes)",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white), // input text color
            cursorColor: Colors.deepPurple.shade300,
            decoration: InputDecoration(
              hintText: "Enter minutes",
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.deepPurple.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Colors.deepPurple.shade300, width: 2),
              ),
            ),
            onChanged: (value) {
              minutes = int.tryParse(value) ?? 0;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(minutes),
              child: Text('Set', style: TextStyle(color: Colors.deepPurple.shade300)),
            ),
          ],
        );
      },
    );

    if (selectedMinutes != null && selectedMinutes > 0) {
      final duration = Duration(minutes: selectedMinutes);
      setState(() {
        _focusDuration = duration;
        _originalDuration = duration;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  double _calculateProgress() {
    if (_originalDuration.inSeconds == 0) return 0;
    return 1 - (_focusDuration.inSeconds / _originalDuration.inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isFocusing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Focus Mode',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: !_isFocusing ? _pickTime : null,
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 280,
                          width: 280,
                          child: CircularProgressIndicator(
                            value: _calculateProgress(),
                            strokeWidth: 16,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple.shade300,
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(_focusDuration),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "While your focus mode is on, your timer will count down",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade300,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isFocusing ? "Stop Focusing" : "Start Focusing",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _isFocusing ? null : const CustomBottomNavBar(),
        floatingActionButton: _isFocusing
            ? null
            : FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddTaskSheet(),
                  );
                },
                backgroundColor: Colors.deepPurple.shade300,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
