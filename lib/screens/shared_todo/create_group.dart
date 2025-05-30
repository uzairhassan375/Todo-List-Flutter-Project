import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController subtaskNameController = TextEditingController();
  final TextEditingController subtaskPriorityController = TextEditingController();
  final TextEditingController subtaskDeadlineController = TextEditingController();
  final TextEditingController memberController = TextEditingController();

  List<Map<String, dynamic>> subtasks = [];
  List<String> invitedMembers = [];

  final currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isSaving = false;

  // Show Date & Time picker when clicking deadline field
  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    subtaskDeadlineController.text = dateTime.toString();
  }

  void addSubtask() {
    final name = subtaskNameController.text.trim();
    final priorityText = subtaskPriorityController.text.trim();
    final deadlineText = subtaskDeadlineController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter subtask name')),
      );
      return;
    }

    int? priority;
    if (priorityText.isNotEmpty) {
      priority = int.tryParse(priorityText);
      if (priority == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Priority must be a valid number')),
        );
        return;
      }
    }

    DateTime? deadline;
    if (deadlineText.isNotEmpty) {
      try {
        deadline = DateTime.parse(deadlineText);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadline format error')),
        );
        return;
      }
    }

    final newSubtask = <String, dynamic>{'name': name};
    if (priority != null) newSubtask['priority'] = priority;
    if (deadline != null) newSubtask['deadline'] = deadline.toIso8601String();

    setState(() {
      subtasks.add(newSubtask);
      subtaskNameController.clear();
      subtaskPriorityController.clear();
      subtaskDeadlineController.clear();
    });
  }

  Future<void> addMember() async {
    final member = memberController.text.trim();
    if (member.isEmpty) return;

    final querySnapshot = await firestore.collection('users').where('email', isEqualTo: member).get();

    if (querySnapshot.docs.isEmpty) {
      final usernameQuery = await firestore.collection('users').where('username', isEqualTo: member).get();

      if (usernameQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "$member" not found')),
        );
        return;
      }
    }

    if (invitedMembers.contains(member)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "$member" is already invited')),
      );
      return;
    }

    setState(() {
      invitedMembers.add(member);
      memberController.clear();
    });
  }

  Future<void> saveGroup() async {
    final groupName = taskNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter group name')),
      );
      return;
    }

    if (subtasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one subtask')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      List<String> memberUids = [];

      for (String member in invitedMembers) {
        QuerySnapshot userQuery = await firestore.collection('users').where('email', isEqualTo: member).get();

        if (userQuery.docs.isEmpty) {
          userQuery = await firestore.collection('users').where('username', isEqualTo: member).get();
        }

        if (userQuery.docs.isNotEmpty) {
          memberUids.add(userQuery.docs.first.id);
        }
      }

      await firestore.collection('groups').add({
        'name': groupName,
        'ownerId': currentUser!.uid,
        'ownerEmail': currentUser?.email ?? '',
        'members': memberUids,
        'subtasks': subtasks,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
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
    subtaskPriorityController.dispose();
    subtaskDeadlineController.dispose();
    memberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Group'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.groups, color: Colors.orange),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Name'),
            const SizedBox(height: 8),
            TextField(
              controller: taskNameController,
              decoration: const InputDecoration(
                hintText: 'Lab Assignments',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add Subtasks'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: subtaskNameController,
                    decoration: const InputDecoration(
                      hintText: 'Subtask Name *',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: subtaskPriorityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Priority (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: subtaskDeadlineController,
                    readOnly: true,
                    onTap: pickDateTime,
                    decoration: const InputDecoration(
                      hintText: 'Deadline (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  onPressed: addSubtask,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: subtasks.isEmpty
                  ? const Center(child: Text('No subtasks added yet'))
                  : ListView.builder(
                      itemCount: subtasks.length,
                      itemBuilder: (context, index) {
                        final subtask = subtasks[index];
                        return ListTile(
                          title: Text(subtask['name']),
                          subtitle: Text(
                            'Priority: ${subtask['priority'] ?? 'N/A'}, Deadline: ${subtask['deadline'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                subtasks.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            const Text('Invite Members (email or username)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: memberController,
                    decoration: const InputDecoration(
                      hintText: 'Enter username or email',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  onPressed: addMember,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: invitedMembers.map((member) {
                return Chip(
                  label: Text(member),
                  onDeleted: () {
                    setState(() {
                      invitedMembers.remove(member);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isSaving ? null : saveGroup,
                  child: isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
