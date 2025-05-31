
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskify/widgets/custom_bottom_nav_bar.dart';
import 'package:taskify/widgets/task_tile.dart';
import 'add_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profileImageBase64;
  String _sortBy = 'datetime';
String? _categoryFilter;

  String? _uid;
  bool showCompleted = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadProfileImage();
  }
Future<String?> _showCategoryDialog() async {
  String selectedCategory = '';
  return showDialog<String>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text('Enter Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Work, Personal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
}


// ignore_for_file: unused_local_variable
  Future<void> _loadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _profileImageBase64 = doc.data()?['profileImageBase64'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profilescreen');
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: _profileImageBase64 != null
                    ? MemoryImage(base64Decode(_profileImageBase64!))
                    : const AssetImage('assets/images/profile.png')
                        as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // 🔁 Toggle filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        chipTheme: ChipTheme.of(context).copyWith(
                          selectedColor: const Color.fromARGB(255, 233, 23, 23),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      child: ChoiceChip(
                        label: const Text('Incomplete'),
                        selected: !showCompleted,
                        backgroundColor: const Color.fromARGB(0, 238, 170, 170),
                        labelStyle: TextStyle(
                            color:
                                !showCompleted ? Colors.white : Colors.black),
                        onSelected: (val) =>
                            setState(() => showCompleted = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Theme(
                      data: Theme.of(context).copyWith(
                        chipTheme: ChipTheme.of(context).copyWith(
                          selectedColor: const Color.fromARGB(255, 40, 145, 8),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      child: ChoiceChip(
                        label: const Text('Completed'),
                        selected: showCompleted,
                        backgroundColor: Colors.transparent,
                        labelStyle: TextStyle(
                            color: showCompleted ? Colors.white : Colors.black),
                        onSelected: (val) =>
                            setState(() => showCompleted = true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    showCompleted
                        ? 'Swipe left to mark as incomplete'
                        : 'Swipe right to mark as completed',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ),

const SizedBox(height: 14),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ChoiceChip(
      label: const Text('DateTime'),
      selected: _sortBy == 'datetime',
      onSelected: (_) {
        setState(() {
          _sortBy = 'datetime';
          _categoryFilter = null;
        });
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey, // gray when not selected
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.white),
    ),
    ChoiceChip(
      label: const Text('Priority'),
      selected: _sortBy == 'priority',
      onSelected: (_) {
        setState(() {
          _sortBy = 'priority';
          _categoryFilter = null;
        });
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey, // gray when not selected
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.white),
    ),
    ChoiceChip(
      label: const Text('Category'),
      selected: _sortBy == 'category',
      onSelected: (_) async {
        final selectedCategory = await _showCategoryDialog();
        if (selectedCategory != null) {
          setState(() {
            _sortBy = 'category';
            _categoryFilter = selectedCategory;
          });
        }
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey, // gray when not selected
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.white),
    ),
  ],
),





                // 🔄 Task Stream
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tasks')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (_uid == null) {
                      return const Center(
                        child: Text(
                          "User not logged in",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final rawTasks = snapshot.data!.docs.where((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return data['uid'] == _uid && data['completed'] == showCompleted;
}).toList();

rawTasks.sort((a, b) {
  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  switch (_sortBy) {
    case 'priority':
      return (bData['priority'] ?? 0).compareTo(aData['priority'] ?? 0);
    case 'category':
      if (_categoryFilter == null) return 0;
      final aCat = aData['category'] == _categoryFilter ? 0 : 1;
      final bCat = bData['category'] == _categoryFilter ? 0 : 1;
      return aCat.compareTo(bCat);
    case 'datetime':
    default:
      final aTime = (aData['datetime'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (bData['datetime'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);

  }
});

final tasks = rawTasks;
                    

                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/tasks.png', height: 200),
                            const SizedBox(height: 24),
                            const Text(
                              'What do you want to do today?',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap + to add your tasks',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final doc = tasks[index];
                        final task = doc.data() as Map<String, dynamic>;
                        final timestamp = task['datetime'] as Timestamp?;
                        final dateTime = timestamp?.toDate();
                        final isCompleted = task['completed'] == true;

                        return TaskTile(doc: doc, showCompleted: showCompleted);

                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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

    );
  }
}
