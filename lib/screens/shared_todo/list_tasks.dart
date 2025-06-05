import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taskify/services/pdf_firestore_helper.dart';
import 'package:taskify/services/pdf_list_screen.dart';
import 'members_sheet.dart';
import 'package:intl/intl.dart';

class SharedToDoListScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;
  final String ownerEmail;

  const SharedToDoListScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.ownerEmail,
  });

  @override
  State<SharedToDoListScreen> createState() => _SharedToDoListScreenState();
}

class _SharedToDoListScreenState extends State<SharedToDoListScreen> {
  String? ownerId;
  List<dynamic> members = [];
  bool loadingGroup = true;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }
Future<bool> _requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}
void _handlePdfSave() async {
  bool success = await PdfFirestoreHelper.pickAndSavePdfToFirestore(widget.groupId);
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to group successfully!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save PDF')),
    );
  }
}



  Future<void> _loadGroupData() async {
    final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        ownerId = data['ownerId'] as String?;
        members = data['members'] ?? [];
        loadingGroup = false;
      });
    } else {
      setState(() => loadingGroup = false);
    }
  }

  bool get isOwner => ownerId == widget.currentUserId;
  bool get isMember => members.contains(widget.currentUserId);

  void _openMembersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MembersSheet(
        groupId: widget.groupId,
        members: members,
        canAddMembers: isOwner,
        ownerId: ownerId ?? '',
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

void _showAddTaskDialog() {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDeadline;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Add Task', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Deadline (optional): ',
                      style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark(),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDeadline = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      selectedDeadline == null
                          ? 'Pick Date'
                          : DateFormat('yyyy-MM-dd').format(selectedDeadline!),
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                // Show error if title is empty
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Title is required'),
                  backgroundColor: Colors.red,
                ));
                return;
              }

              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('tasks')
                  .add({
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'deadline': selectedDeadline != null ? Timestamp.fromDate(selectedDeadline!) : null,

'createdBy': FirebaseAuth.instance.currentUser?.uid,

                'createdAt': Timestamp.now(),
              });

              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      );
    },
  );
}


Future<void> _addComment(String text) async {
  if (text.trim().isEmpty) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Get user document from Firestore
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  // Extract data safely
  final data = userDoc.data();
  if (data == null) return;  // No user data found, abort

  final userName = data['name'] ?? 'Unknown';
  final profileImageBase64 = data['profileImageBase64'] ?? '';

  // Add comment to Firestore with the correct fields
  await FirebaseFirestore.instance
      .collection('groups')
      .doc(widget.groupId)
      .collection('comments')
      .add({
    'userId': user.uid,
    'userName': userName,
  'userPhoto': profileImageBase64,

    'text': text.trim(),
    'timestamp': Timestamp.now(),
  });

  commentController.clear();
}



  @override
  Widget build(BuildContext context) {
    if (loadingGroup) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }

    if (!isMember && !isOwner) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text(
            'You are not a member of this group.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
         iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups, color: Colors.orange),
            onPressed: _openMembersSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tasks Section
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('tasks')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tasks found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final tasks = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white30),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final data = task.data()! as Map<String, dynamic>;
                      final title = data['title'] ?? 'Untitled';

                      final description = data['description'] ?? '';
                      final deadlineTimestamp = data['deadline'] as Timestamp?;
                      final deadline = deadlineTimestamp != null
                          ? DateFormat.yMd().format(deadlineTimestamp.toDate())
                          : 'No deadline';

                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty)
                                Text(description, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text('Deadline: $deadline', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          trailing: isOwner
                              ? IconButton(
  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
  tooltip: 'Delete Task',
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete the task?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteTask(task.id); // Make sure this handles groupId if needed
    }
  },
)

                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Add Task Button for owner only
if (isOwner || isMember)
  SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
      ),
      onPressed: _showAddTaskDialog,
      child: const Text('+ Add Task'),
    ),
  ),

  if(isOwner)
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Upload PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Optional styling
        foregroundColor: Colors.white,
         side: const BorderSide(color: Colors.white, width: 1),
      ),
      onPressed: _handlePdfSave,
    ),
  ),
  
SizedBox(
  width: double.infinity, // Ensures full width
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFListScreen(groupId: widget.groupId),
        ),
      );
    },
    icon: const Icon(Icons.picture_as_pdf),
    label: const Text('View PDFs'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white, width: 1),
    ),
  ),
),




            const SizedBox(height: 20),

            // Comments Section Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comments',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // Comments List
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true, // Newest comments at the bottom
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentData = comments[index].data()! as Map<String, dynamic>;
                      final text = commentData['text'] ?? '';
                      final userName = commentData['userName'] ?? 'Anonymous';
                      final userPhoto = commentData['userPhoto'] ?? '';

                      final commentId = comments[index].id; // get Firestore doc id
final commentUserId = commentData['userId'] ?? '';

// Check if current user can delete (owner or comment author)
final canDelete = isOwner || widget.currentUserId == commentUserId;

return Padding(
  padding: const EdgeInsets.symmetric(vertical: 0),
  child: GestureDetector(
    onLongPress: () async {
      if (widget.currentUserId == commentUserId) {
        // Show edit dialog
        final TextEditingController editController = TextEditingController(text: text);
        final edited = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Edit Comment', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: editController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Edit your comment',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, editController.text.trim()),
                child: const Text('Save', style: TextStyle(color: Colors.deepPurpleAccent)),
              ),
            ],
          ),
        );
        if (edited != null && edited.isNotEmpty && edited != text) {
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('comments')
              .doc(commentId)
              .update({'text': edited});
        }
      }
    },
child: Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Align(
        alignment: widget.currentUserId == commentUserId
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          margin: widget.currentUserId == commentUserId
              ? const EdgeInsets.only(right: 40)
              : const EdgeInsets.only(left: 40),
          decoration: BoxDecoration(
            color: widget.currentUserId == commentUserId
                ? const Color.fromARGB(255, 22, 73, 41) // WhatsApp green for current user
                : Colors.grey[850],       // Dark grey for others
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: widget.currentUserId == commentUserId
                  ? const Radius.circular(12)
                  : const Radius.circular(0),
              bottomRight: widget.currentUserId == commentUserId
                  ? const Radius.circular(0)
                  : const Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
  userName,
  style: const TextStyle(
    color: Colors.orange,
    fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(text, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      commentData['timestamp'] != null
                          ? DateFormat('hh:mm a, d MMM').format(
                              (commentData['timestamp'] as Timestamp).toDate())
                          : '',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.currentUserId == commentUserId) // only show delete for current user
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                    tooltip: 'Delete Comment',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.black,
                          title: const Text('Delete Comment?', style: TextStyle(color: Colors.white)),
                          content: const Text('Are you sure you want to delete this comment?', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('comments')
                            .doc(commentId)
                            .delete();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 6,
        left: widget.currentUserId == commentUserId ? null : 0,
        right: widget.currentUserId == commentUserId ? 0 : null,
        child: CircleAvatar(
          backgroundImage: userPhoto.isNotEmpty
              ? MemoryImage(base64Decode(userPhoto))
              : null,
          backgroundColor: Colors.grey[700],
          radius: 16,
          child: userPhoto.isEmpty
              ? const Icon(Icons.person, color: Colors.white, size: 18)
              : null,
        ),
      ),
    ],
  ),
),


  ),
);


                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Add Comment Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a comment',
                      hintStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
               ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurpleAccent, // Button background
    foregroundColor: Colors.white, // Text color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  onPressed: () => _addComment(commentController.text),
  child: const Text('Send'),
),

              ],
              
            ),
          ],
        ),
      ),
    );
  }
}
