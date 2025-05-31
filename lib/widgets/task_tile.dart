import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:taskify/screens/add_task_sheet.dart';
import 'package:taskify/widgets/dialologBox.dart';

class TaskTile extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool showCompleted;

  const TaskTile({super.key, required this.doc, required this.showCompleted});

  @override
  Widget build(BuildContext context) {
    final task = doc.data() as Map<String, dynamic>;
    final timestamp = task['datetime'] as Timestamp?;
    final dateTime = timestamp?.toDate();
    final isCompleted = task['completed'] == true;

    return Dismissible(
      key: Key(doc.id),
      direction: showCompleted
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      background: !showCompleted
          ? Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.green,
              child: const Icon(Icons.check, color: Colors.white),
            )
          : Container(),
      secondaryBackground: showCompleted
          ? Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.orange,
              child: const Icon(Icons.undo, color: Colors.white),
            )
          : Container(),
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(doc.id)
            .update({'completed': !showCompleted});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(showCompleted
                ? 'Task marked as incomplete'
                : 'Task marked as completed'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(doc.id)
                    .update({'completed': showCompleted});
              },
            ),
          ),
        );
      },
      child: Opacity(
        opacity: isCompleted ? 0.5 : 1.0,
        child: Card(
          color: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration:
                          showCompleted ? TextDecoration.lineThrough : null,
                      decorationThickness: 3.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task['description'] != null &&
                    task['description'].toString().isNotEmpty)
                  Text(
                    task['description'],
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (dateTime != null)
                  Text(
                    'Due: ${DateFormat('yyyy-MM-dd HH:mm').format(dateTime)}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task['priority'] != null)
                  Row(
                    children: [
                      const Icon(Icons.flag,
                          color: Colors.deepPurpleAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${task['priority']}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                Container(
                  height: 40,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white30,
                ),
                InkWell(
                  onTap: () async {
                    final taskData = doc.data() as Map<String, dynamic>;
                    final taskId = doc.id;

                   final shouldDelete = await showDialog<bool>(
  context: context,
  builder: (context) => BlackConfirmDialog(
    title: "Delete Task",
    content: "Are you sure you want to delete this task?",
    confirmText: "Delete",
    confirmColor: Colors.red,
  ),
);

if (shouldDelete == true) {
  await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Task deleted',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.grey[900],
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.fixed,
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.deepPurpleAccent,
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .set(taskData);
        },
      ),
    ),
  );
}

                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete,
                        color: Colors.redAccent, size: 20),
                  ),
                ),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    AddTaskSheet(taskId: doc.id, taskData: task),
              );
            },
          ),
        ),
      ),
    );
  }
}
