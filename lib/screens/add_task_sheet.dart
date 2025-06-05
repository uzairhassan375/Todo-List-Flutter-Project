import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskSheet extends StatefulWidget {
  final Map<String, dynamic>? taskData;
  final String? taskId;

  const AddTaskSheet({super.key, this.taskData, this.taskId});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  DateTime? _selectedDateTime;
  String? _selectedCategory;
  int? _selectedPriority;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'label': 'Grocery', 'icon': Icons.shopping_cart, 'color': Colors.green},
    {'label': 'Work', 'icon': Icons.work, 'color': Colors.orange},
    {'label': 'Sport', 'icon': Icons.fitness_center, 'color': Colors.teal},
    {'label': 'Design', 'icon': Icons.videogame_asset, 'color': Colors.cyan},
    {'label': 'University', 'icon': Icons.school, 'color': Colors.blue},
    {'label': 'Social', 'icon': Icons.people, 'color': Colors.pink},
    {'label': 'Music', 'icon': Icons.music_note, 'color': Colors.purple},
    {'label': 'Health', 'icon': Icons.favorite, 'color': Colors.greenAccent},
    {'label': 'Movie', 'icon': Icons.movie, 'color': Colors.indigo},
    {'label': 'Home', 'icon': Icons.home, 'color': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.taskData != null) {
      _titleController.text = widget.taskData!['title'] ?? '';
      _descriptionController.text = widget.taskData!['description'] ?? '';
      _selectedCategory = widget.taskData!['category'];
      _selectedPriority = widget.taskData!['priority'];
      Timestamp? ts = widget.taskData!['datetime'];
      _selectedDateTime = ts?.toDate();
    }
  }

  void _showDateTimePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDateTime != null
            ? TimeOfDay.fromDateTime(_selectedDateTime!)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showCategorySelector(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose Category', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                   onTap: () {
  if (_selectedCategory == category['label']) {
    Navigator.pop(context, null); // deselect if tapped again
  } else {
    Navigator.pop(context, category['label']);
  }
},

                      child: Container(
                        decoration: BoxDecoration(
                          color: category['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(category['icon'], color: Colors.white),
                            const SizedBox(height: 4),
                            Text(category['label'], style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

  if (selected != null) {
  setState(() => _selectedCategory = selected);
} else {
  setState(() => _selectedCategory = null); // remove selection if null
}

  }

  Future<int?> _showPrioritySelector(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true, // Important!
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: 10,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPriority == index + 1 ? Colors.deepPurple : Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
               onPressed: () {
  if (_selectedPriority == index + 1) {
    Navigator.pop(context, null); // deselect if tapped again
  } else {
    Navigator.pop(context, index + 1);
  }
},

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag, color: Colors.white),
                    Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title")),
      );
      return;
    }

    final taskData = <String, dynamic>{
      'title': title,
      'description': description,
      'datetime': _selectedDateTime ?? FieldValue.serverTimestamp(),
      'category': _selectedCategory ?? '',
      'priority': _selectedPriority,
      'completed': false,
      'uid': FirebaseAuth.instance.currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.taskId != null) {
        // Update task
        await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update(taskData);
      } else {
        // Add new task
        await FirebaseFirestore.instance.collection('tasks').add(taskData);
      }
      // Show snackbar after success:
    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(widget.taskId != null ? 'Task updated' : 'Task added'),
    duration: const Duration(seconds: 1), // Reduced duration
  ),
);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              widget.taskId != null ? 'Edit Task' : 'Add Task',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Task title',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.white),
                  onPressed: () => _showDateTimePicker(context),
                ),
                IconButton(
                  icon: const Icon(Icons.category, color: Colors.white),
                  onPressed: () => _showCategorySelector(context),
                ),
                IconButton(
                  icon: const Icon(Icons.flag, color: Colors.white),
                  onPressed: () async {
                    final selected = await _showPrioritySelector(context);
if (selected != null) {
  setState(() => _selectedPriority = selected);
} else {
  setState(() => _selectedPriority = null); // remove priority if null
}

                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                  onPressed: _saveTask,
                ),
              ],
            ),
            if (_selectedDateTime != null)
              Text('Date: ${_selectedDateTime!.toLocal()}', style: const TextStyle(color: Colors.white70)),
            if (_selectedCategory != null)
              Text('Category: $_selectedCategory', style: const TextStyle(color: Colors.white70)),
            if (_selectedPriority != null)
              Text('Priority: $_selectedPriority', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
