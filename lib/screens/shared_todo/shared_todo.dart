import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskify/screens/shared_todo/list_tasks.dart';
import 'package:taskify/screens/shared_todo/create_group.dart';

class SharedTodoScreen extends StatefulWidget {
  const SharedTodoScreen({super.key});

  @override
  State<SharedTodoScreen> createState() => _SharedTodoScreenState();
}

class _SharedTodoScreenState extends State<SharedTodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

Future<void> _deleteGroup(String groupId) async {
  final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);

  // Delete all tasks in the tasks subcollection
  final tasksSnapshot = await groupRef.collection('tasks').get();
  for (var taskDoc in tasksSnapshot.docs) {
    await taskDoc.reference.delete();
  }

  // Delete all comments in the comments subcollection
  final commentsSnapshot = await groupRef.collection('comments').get();
  for (var commentDoc in commentsSnapshot.docs) {
    await commentDoc.reference.delete();
  }

  // Finally, delete the group document itself
  await groupRef.delete();
}


  Future<void> _leaveGroup(String groupId) async {
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([currentUserId])
    });
  }

  Widget buildGroupList({required bool isOwnerTab}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final groups = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (isOwnerTab) {
            return data['ownerId'] == currentUserId;
          } else {
            return data['members'].contains(currentUserId) && data['ownerId'] != currentUserId;
          }
        }).toList();

        if (groups.isEmpty) {
          return Center(
            child: Text(
              isOwnerTab ? 'No groups created yet.' : 'No groups you are added to.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: groups.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.grey),
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupData = group.data() as Map<String, dynamic>;
            final groupName = groupData['name'] ?? 'Unnamed Group';

            return ListTile(
              tileColor: const Color(0xFF1E1E1E),
              title: Text(
                groupName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedToDoListScreen(
                      groupId: group.id,
                      groupName: groupName,
                      currentUserId: currentUserId,
                      ownerEmail: groupData['ownerEmail'] ?? '',
                    ),
                  ),
                );
              },
              trailing: isOwnerTab
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Group',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Are you sure you want to delete "$groupName"?',
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
                          await _deleteGroup(group.id);
                        }
                      },
                    )
                  : TextButton.icon(
                      icon: const Icon(Icons.exit_to_app, color: Colors.orangeAccent),
                      label: const Text('Leave', style: TextStyle(color: Colors.orangeAccent)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Confirm Leave', style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Are you sure you want to leave "$groupName"?',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Leave', style: TextStyle(color: Colors.orangeAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _leaveGroup(group.id);
                        }
                      },
                    ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
         title: const Text(
  'Shared To-Do Groups',
  style: TextStyle(color: Colors.white),
),
             iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orangeAccent,
              labelColor: Colors.orangeAccent,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'My Groups'),
                Tab(text: 'Groups I am Added To'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              buildGroupList(isOwnerTab: true),
              buildGroupList(isOwnerTab: false),
            ],
          ),
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton(
                  backgroundColor: Colors.deepPurple,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }
}
