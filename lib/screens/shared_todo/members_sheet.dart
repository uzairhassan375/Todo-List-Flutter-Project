import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersSheet extends StatefulWidget {
  final String groupId;
  final List<dynamic> members;
  final bool canAddMembers;
  final String ownerId;

  const MembersSheet({
    super.key,
    required this.groupId,
    required this.members,
    required this.canAddMembers,
    required this.ownerId,
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
    _loadOwnerData();
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
        setState(() => _ownerLoading = false);
      }
    } catch (e) {
      setState(() => _ownerLoading = false);
    }
  }

  void _removeMember(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'members': FieldValue.arrayRemove([userId])});
      setState(() => _members.remove(userId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove member')),
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
          .update({'members': FieldValue.arrayUnion([userId])});

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

  Widget _buildProfileAvatar(String? base64Image, {Widget? placeholder}) {
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        return CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: Colors.grey[800],
        );
      } catch (_) {
        // If base64 decode fails, show placeholder
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[800],
          child: placeholder,
        );
      }
    } else {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[800],
        child: placeholder,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.canAddMembers ? 'Manage Members' : 'Group Members',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (widget.canAddMembers) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter user email',
                  hintStyle: const TextStyle(color: Colors.white70),
                  errorText: _error,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple),
                  ),
                ),
                onSubmitted: (_) => _addMember(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: _isLoading ? null : _addMember,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Member',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
              const Divider(height: 30, color: Colors.white24),
            ] else
              const SizedBox(height: 20),
            const Text('Group Owner',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            _ownerLoading
                ? const CircularProgressIndicator()
                : _ownerData == null
                    ? const Text('Owner not found',
                        style: TextStyle(color: Colors.white))
                    : ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.deepPurple, width: 2),
                          ),
                          child: _buildProfileAvatar(
                            _ownerData!['profileImageBase64'],
                            placeholder: const Icon(Icons.star, color: Colors.white),
                          ),
                        ),
                        title: Text(
                          'Owner: ${_ownerData!['name'] ?? 'Unknown'}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _ownerData!['email'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
            const Divider(height: 30, color: Colors.white24),
            Expanded(
              child: _members.isEmpty
                  ? const Center(
                      child: Text('No members found',
                          style: TextStyle(color: Colors.white70)))
                  : FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where(FieldPath.documentId, whereIn: _members)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final user = docs[index].data() as Map<String, dynamic>;
                            final userId = docs[index].id;
                            return ListTile(
                              leading: _buildProfileAvatar(
                                user['profileImageBase64'],
                                placeholder:
                                    const Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(user['name'] ?? 'No Name',
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(user['email'] ?? '',
                                  style: const TextStyle(color: Colors.white70)),
                              trailing: widget.canAddMembers && userId != widget.ownerId
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
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
