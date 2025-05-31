import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:taskify/widgets/buildNavItem.dart';
import 'package:taskify/widgets/custom_bottom_nav_bar.dart';
import 'add_task_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>  {
  String? _profileImageBase64;
  String? _userName;
  int _incompleteCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadTaskStats();
  }

  Future<void> _loadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        _profileImageBase64 = data?['profileImageBase64'];
        _userName = data?['name'];
      });
    }
  }

  Future<void> _loadTaskStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .get();

    int completed = 0;
    int incomplete = 0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['completed'] == true) {
        completed++;
      } else {
        incomplete++;
      }
    }

    setState(() {
      _completedCount = completed;
      _incompleteCount = incomplete;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final compressed = await FlutterImageCompress.compressWithFile(
        picked.path,
        quality: 25,
      );

      if (compressed == null) return;

      final base64Image = base64Encode(compressed);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'profileImageBase64': base64Image}, SetOptions(merge: true));

      setState(() {
        _profileImageBase64 = base64Image;
      });
    }
  }

  void _changeAccountName() async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Account Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Update"),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .set({'name': newName}, SetOptions(merge: true));
                  setState(() => _userName = newName);
                }
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _changeAccountPassword() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new password"),
          obscureText: true,
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Update"),
            onPressed: () async {
              final newPassword = controller.text.trim();
              if (newPassword.length >= 6) {
                try {
                  await FirebaseAuth.instance.currentUser
                      ?.updatePassword(newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password must be at least 6 characters")),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
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
bottomNavigationBar: const CustomBottomNavBar(),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Profile',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: ClipOval(
                    child: _profileImageBase64 != null
                        ? Image.memory(
                            base64Decode(_profileImageBase64!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/dp.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  _userName ?? 'Loading...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTaskStat("$_incompleteCount Task${_incompleteCount != 1 ? 's' : ''} left"),
                  const SizedBox(width: 12),
                  _buildTaskStat("$_completedCount Task${_completedCount != 1 ? 's' : ''} done"),
                ],
              ),
              const SizedBox(height: 32),

              const Text("Settings", style: _sectionTitleStyle),
              const SizedBox(height: 8),
              _buildListTile(Icons.settings, "App Settings"),

              const SizedBox(height: 16),
              const Text("Account", style: _sectionTitleStyle),
              const SizedBox(height: 8),
              _buildListTile(Icons.person_outline, "Change account name", onTap: _changeAccountName),
              _buildListTile(Icons.lock_outline, "Change account password", onTap: _changeAccountPassword),

              ListTile(
                leading: const Icon(Icons.image_outlined, color: Colors.white),
                title: const Text("Change account Image", style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                onTap: _pickAndUploadImage,
              ),

              const SizedBox(height: 16),
              const Text("Upload", style: _sectionTitleStyle),
              const SizedBox(height: 8),
              _buildListTile(Icons.info_outline, "About Us"),
              _buildListTile(Icons.help_outline, "FAQ"),
              _buildListTile(Icons.feedback_outlined, "Help & Feedback"),
              _buildListTile(Icons.favorite_outline, "Support Us"),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Log out", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/loginscreen');
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static const _sectionTitleStyle = TextStyle(
    color: Colors.grey,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static Widget _buildTaskStat(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: Colors.white)),
    );
  }

  static Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }
}
