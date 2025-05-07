import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';

class AssignmentSubmissionScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String classroomId;

  const AssignmentSubmissionScreen({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.classroomId,
    super.key,
  });

  @override
  _AssignmentSubmissionScreenState createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends State<AssignmentSubmissionScreen> {
  bool _isUploading = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // This ensures we get the file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Could not read file data')),
          );
          return;
        }
        
        setState(() {
          _selectedFile = file;
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user == null) {
        throw Exception('User not found');
      }

      final storage = FirebaseStorage.instance;
      final firestore = FirebaseFirestore.instance;

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_${_selectedFileName}';

      // Upload file to Firebase Storage
      final storageRef = storage.ref().child(
          'submissions/${widget.classroomId}/${widget.assignmentId}/${user.uid}/$uniqueFileName');
      
      final uploadTask = storageRef.putData(
        _selectedFile!.bytes!,
        SettableMetadata(contentType: _getMimeType(_selectedFileName!)),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save submission details to Firestore
      await firestore.collection('submissions').add({
        'assignmentId': widget.assignmentId,
        'classroomId': widget.classroomId,
        'studentId': user.uid,
        'studentName': user.name ?? 'Unknown Student',
        'fileName': _selectedFileName,
        'fileUrl': downloadUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit assignment: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.assignmentTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            Text(
              'Upload your submission (PDF, DOC, or DOCX)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text(_selectedFileName ?? 'No file selected'),
                trailing: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _pickFile,
                ),
              ),
            ),
            if (_selectedFile != null) ...[
              SizedBox(height: 8),
              Text(
                'File size: ${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitAssignment,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}