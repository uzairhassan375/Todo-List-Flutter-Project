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

  Widget buildGroupList({required bool isOwnerTab}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final groups = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (isOwnerTab) {
            return data['ownerId'] == currentUser?.uid;
          } else {
            return data['members'].contains(currentUser?.uid) && data['ownerId'] != currentUser?.uid;
          }
        }).toList();

        if (groups.isEmpty) {
          return Center(child: Text(isOwnerTab ? 'No groups created yet.' : 'No groups you are added to.'));
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupData = group.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(groupData['name'] ?? 'Unnamed Group'),
              subtitle: isOwnerTab ? null : Text('Created by: ${groupData['ownerEmail'] ?? 'Unknown'}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedToDoListScreen(
                      groupId: group.id,
                      groupName: groupData['name'],
                        currentUserId: currentUserId,
                    ),
                  ),
                );
              },
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
        appBar: AppBar(
          title: const Text('Shared To-Do Groups'),
          bottom: TabBar(
            controller: _tabController,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
      );
    },
  );
}

}
