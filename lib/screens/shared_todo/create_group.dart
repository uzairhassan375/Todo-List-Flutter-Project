import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController subtaskNameController = TextEditingController();
  final TextEditingController subtaskDescriptionController = TextEditingController();
  final TextEditingController subtaskDeadlineController = TextEditingController();

  List<Map<String, dynamic>> subtasks = [];

  final currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isSaving = false;

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurpleAccent,
            onPrimary: Colors.white,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: Colors.black,
        ),
        child: child!,
      ),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurpleAccent,
            onPrimary: Colors.white,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: Colors.black,
        ),
        child: child!,
      ),
    );

    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final formatted = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    subtaskDeadlineController.text = formatted;
  }

  void addSubtask() {
    final name = subtaskNameController.text.trim();
    final description = subtaskDescriptionController.text.trim();
    final deadlineText = subtaskDeadlineController.text.trim();

    if (name.isEmpty) {
      showSnack('Please enter subtask name');
      return;
    }

    DateTime? deadline;
    if (deadlineText.isNotEmpty) {
      try {
        deadline = DateFormat('yyyy-MM-dd HH:mm').parse(deadlineText);
      } catch (_) {
        showSnack('Deadline format error');
        return;
      }
    }

    final newSubtask = {
      'title': name,
      'description': description,
    };

    if (deadline != null) newSubtask['deadline'] = deadline.toIso8601String();

    setState(() {
      subtasks.add(newSubtask);
      subtaskNameController.clear();
      subtaskDescriptionController.clear();
      subtaskDeadlineController.clear();
    });
  }

Future<void> saveGroup() async {
  final groupName = taskNameController.text.trim();
  if (groupName.isEmpty) {
    showSnack('Please enter group name');
    return;
  }

  if (subtasks.isEmpty) {
    showSnack('Add at least one subtask');
    return;
  }

  setState(() {
    isSaving = true;
  });

  try {
    final memberUids = [currentUser!.uid];

    // Step 1: Create the group document (without subtasks)
    final groupRef = await firestore.collection('groups').add({
      'name': groupName,
      'ownerId': currentUser!.uid,
      'ownerEmail': currentUser?.email ?? '',
      'members': memberUids,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Step 2: Save each subtask in the "tasks" subcollection of this group
    final tasksRef = groupRef.collection('tasks');
    for (final subtask in subtasks) {
      await tasksRef.add({
        'title': subtask['title'],
        'description': subtask['description'],
        'deadline': subtask['deadline'] != null
    ? Timestamp.fromDate(DateTime.parse(subtask['deadline']))
    : null,

        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    showSnack('Group and tasks created successfully');
    Navigator.pop(context);
  } catch (e) {
    showSnack('Error creating group: $e');
  } finally {
    setState(() {
      isSaving = false;
    });
  }
}


  @override
  void dispose() {
    taskNameController.dispose();
    subtaskNameController.dispose();
    subtaskDescriptionController.dispose();
    subtaskDeadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final whiteTextStyle = const TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Group', style: TextStyle(color: Colors.white)),
       
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Name', style: whiteTextStyle),
            const SizedBox(height: 8),
            TextField(
              controller: taskNameController,
              style: whiteTextStyle,
              decoration: const InputDecoration(
                hintText: 'Enter Group Name',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
              cursorColor: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 20),

            Text('Add Subtasks', style: whiteTextStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: subtaskNameController,
                    style: whiteTextStyle,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurpleAccent),
                      ),
                    ),
                    cursorColor: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: subtaskDescriptionController,
                    style: whiteTextStyle,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurpleAccent),
                      ),
                    ),
                    cursorColor: Colors.deepPurpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: subtaskDeadlineController,
                    readOnly: true,
                    onTap: pickDateTime,
                    style: whiteTextStyle,
                    decoration: const InputDecoration(
                      hintText: 'Deadline',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurpleAccent),
                      ),
                    ),
                    cursorColor: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                  onPressed: addSubtask,
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: subtasks.isEmpty
                  ? Center(child: Text('No subtasks added yet', style: whiteTextStyle))
                  : ListView.separated(
                      itemCount: subtasks.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white24),
                      itemBuilder: (context, index) {
                        final subtask = subtasks[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                     subtask['title'],

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if ((subtask['description'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          subtask['description'],
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Deadline: ${subtask['deadline'] != null ? DateFormat('MMM d, yyyy – h:mm a').format(DateTime.parse(subtask['deadline'])) : 'N/A'}',
                                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    subtasks.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: isSaving ? null : saveGroup,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Group',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
