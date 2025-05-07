import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/storage_service.dart';
import '../../services/classroom_service.dart';

class ContentUploadScreen extends StatefulWidget {
  final String classroomId;

  const ContentUploadScreen({super.key, required this.classroomId});

  @override
  _ContentUploadScreenState createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  PlatformFile? _contentFile;
  bool _isUploading = false;
  String _errorMessage = '';

  // Add validation for content type
  Future<void> _pickContentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _contentFile = result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: ${e.toString()}')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_contentFile == null || 
        _contentFile!.bytes == null || 
        _contentFile!.bytes!.isEmpty) {
      setState(() => _errorMessage = 'Please select a valid file');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });

    try {
      final downloadUrl = await StorageService().uploadFile(
        classroomId: widget.classroomId,
        type: 'materials',
        file: _contentFile!,
      );

      await ClassroomService().uploadContent(
        classroomId: widget.classroomId,
        title: _titleController.text.trim(),
        fileUrl: downloadUrl,
        fileName: _contentFile!.name,
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Upload failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Content')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Material Title'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              
              SizedBox(height: 20),
              Text('Content File:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickContentFile,
                child: Text(_contentFile == null
                    ? 'Select File (PDF, DOC, PPT, JPG, PNG)'
                    : 'Selected: ${_contentFile!.name}'),
              ),
              
              if (_contentFile != null) ...[
                SizedBox(height: 8),
                Text(
                  'Size: ${(_contentFile!.size / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],
              
              SizedBox(height: 24),
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Upload Content'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}