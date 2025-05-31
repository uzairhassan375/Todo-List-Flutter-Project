import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late Stream<QuerySnapshot> tasksStream;

  String? ownerId;
  List<dynamic> members = [];
  bool loadingGroup = true;

  @override
  void initState() {
    super.initState();
    tasksStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('tasks')
        .snapshots();

    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        ownerId = data['ownerId'] as String?;
        members = data['members'] ?? [];
        loadingGroup = false;
      });
    } else {
      setState(() {
        loadingGroup = false;
      });
      // Optionally handle group not found error
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

  @override
  Widget build(BuildContext context) {
      final Stream<DocumentSnapshot> groupStream = FirebaseFirestore.instance
      .collection('groups')
      .doc(widget.groupId)
      .snapshots();
    if (loadingGroup) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isMember && !isOwner) {
      // User not in group, show error or redirect
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.groupName),
        ),
        body: const Center(
          child: Text('You are not a member of this group.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups, color: Colors.orange),
            onPressed: _openMembersSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.groupName,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tasks List
           Expanded(
  child: StreamBuilder<DocumentSnapshot>(
    stream: groupStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const Center(child: Text('Group not found.'));
      }

      final groupData = snapshot.data!.data() as Map<String, dynamic>;

      final List<dynamic> subtasks = groupData['subtasks'] ?? [];

      if (subtasks.isEmpty) {
        return const Center(child: Text('No tasks found.'));
      }

      return ListView.builder(
        itemCount: subtasks.length,
        itemBuilder: (context, index) {
          final task = subtasks[index] as Map<String, dynamic>;
          final done = task['done'] ?? false;
          final title = task['name'] ?? 'Untitled task';
          final priority = task['priority'] ?? '0';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: done,
                  onChanged: (bool? newValue) {
                    final updatedSubtasks = List<Map<String, dynamic>>.from(subtasks);
                    updatedSubtasks[index]['done'] = newValue;

                    FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .update({'subtasks': updatedSubtasks});
                  },
                  checkColor: Colors.black,
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'P $priority',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
),


            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () {
                  // TODO: Implement add task logic
                },
                child: const Text('+ Add Task'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/avatar.png'),
                  radius: 16,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("David I need help in it"),
                      SizedBox(height: 4),
                      Text("Just now",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a comment',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // TODO: Implement comment save logic
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The MembersSheet widget: shows members list and add members if allowed

class MembersSheet extends StatefulWidget {
  final String groupId;
  final List<dynamic> members;
  final bool canAddMembers;
   final String ownerId; // New

  const MembersSheet({
    super.key,
    required this.groupId,
    required this.members,
    required this.canAddMembers,
    required this.ownerId, // New
  });

  @override
  State<MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<MembersSheet> {
  Map<String, dynamic>? _ownerData;
bool _ownerLoading = true;

  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  late List<dynamic> _members;

  @override
  void initState() {
    super.initState();
    _members = widget.members;
     _loadOwnerData(); // New
  }
  Future<void> _loadOwnerData() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.ownerId)
        .get();
    if (doc.exists) {
      setState(() {
        _ownerData = doc.data();
        _ownerLoading = false;
      });
    } else {
      setState(() {
        _ownerLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _ownerLoading = false;
    });
  }
}
void _removeMember(String userId) async {
  try {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({
      'members': FieldValue.arrayRemove([userId]),
    });

    setState(() {
      _members.remove(userId);
    });
  } catch (e) {
    print('Error removing member: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to remove member')),
    );
  }
}

  Future<void> _addMember() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _error = "Please enter a user email";
        _isLoading = false;
      });
      return;
    }

    try {
      // Search user by email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: input)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _error = "User not found";
          _isLoading = false;
        });
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userName = userDoc.data()['name'] ?? input;

      if (_members.contains(userId)) {
        setState(() {
          _error = "$userName is already a member";
          _isLoading = false;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayUnion([userId])
      });

      setState(() {
        _members.add(userId);
        _isLoading = false;
      });

      _controller.clear();
    } catch (e) {
      setState(() {
        _error = "Error adding member: $e";
        _isLoading = false;
      });
    }
  }

@override
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.all(16),
      height: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.canAddMembers ? 'Manage Members' : 'Group Members',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          if (widget.canAddMembers) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter user email',
                errorText: _error,
              ),
              onSubmitted: (_) => _addMember(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addMember,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Member'),
              ),
            ),
            const Divider(height: 30),
          ] else
            const SizedBox(height: 20),

          // Group Owner Info
          const Text('Group Owner', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _ownerLoading
              ? const CircularProgressIndicator()
              : _ownerData == null
                  ? const Text('Owner not found')
                  : ListTile(
                      leading: const Icon(Icons.star, color: Colors.orange),
                      title: Text(_ownerData!['name'] ?? 'Unknown'),
                      subtitle: Text(_ownerData!['email'] ?? ''),
                    ),
          const Divider(height: 30),

          // Members List
          Expanded(
            child: _members.isEmpty
                ? const Center(child: Text('No members found'))
                : FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: _members)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No members found'));
                      }
                      final users = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final data = user.data()! as Map<String, dynamic>;
                          final userId = user.id;

                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(data['name'] ?? 'Unknown'),
                            subtitle: Text(data['email'] ?? ''),
                            trailing: (FirebaseAuth.instance.currentUser!.uid ==
                                        widget.ownerId &&
                                    userId != widget.ownerId)
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeMember(userId),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}


}
