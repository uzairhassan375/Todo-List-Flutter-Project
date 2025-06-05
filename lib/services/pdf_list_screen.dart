import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFListScreen extends StatefulWidget {
  final String groupId;

  const PDFListScreen({super.key, required this.groupId});

  @override
  State<PDFListScreen> createState() => _PDFListScreenState();
}

class _PDFListScreenState extends State<PDFListScreen> {
  String? ownerId;

  @override
  void initState() {
    super.initState();
    _loadOwnerId();
  }

  Future<void> _loadOwnerId() async {
    final doc =
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    setState(() {
      ownerId = doc.data()?['ownerId'] as String?;
    });
  }

  Future<void> openPDFfromBase64(String base64Data, String fileName) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 29) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            print('Storage permission not granted.');
            return;
          }
        }
      }

      final bytes = base64Decode(base64Data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      print("Error opening PDF: $e");
    }
  }

  Future<void> _confirmDelete(BuildContext context, String pdfDocId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Delete PDF?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this PDF?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('pdfs')
            .doc(pdfDocId)
            .delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black, // Set scaffold background to black
      appBar: AppBar(
        title: const Text('PDFs'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // Back icon white
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20), // Title white
        elevation: 0, // No shadow
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('pdfs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No PDFs uploaded yet.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final pdfs = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ownerId != null && currentUserId == ownerId)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Text(
                      'Long press on a PDF to delete it',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: pdfs.length,
                  itemBuilder: (context, index) {
                    final pdf = pdfs[index];
                    final pdfDocId = pdf.id;
                    final name = pdf['fileName'];
                    final base64Data = pdf['pdfData'];

                    return GestureDetector(
                      onLongPress: () {
                        if (ownerId != null && currentUserId == ownerId) {
                          _confirmDelete(context, pdfDocId);
                        }
                      },
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.download, color: Colors.white),
                        onTap: () => openPDFfromBase64(base64Data, name),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: Color.fromARGB(255, 82, 82, 82),
                      thickness: 1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
