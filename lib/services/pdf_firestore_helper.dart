import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';

class PdfFirestoreHelper {
  static Future<bool> pickAndSavePdfToFirestore(String groupId) async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      print('No file selected');
      return false;
    }

    File file = File(result.files.single.path!);
    String fileName = basename(file.path);
    List<int> pdfBytes = await file.readAsBytes();
    String base64Pdf = base64Encode(pdfBytes);

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('pdfs')
          .add({
        'fileName': fileName,
        'pdfData': base64Pdf,
        'uploadedAt': Timestamp.now(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });

      print('PDF uploaded successfully to group $groupId');
      return true;
    } catch (e) {
      print('Error uploading PDF: $e');
      return false;
    }
  }
}


