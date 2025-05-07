import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../../services/classroom_service.dart';

class AssignmentUploadScreen extends StatefulWidget {
  final String classroomId;

  const AssignmentUploadScreen({super.key, required this.classroomId});

  @override
  _AssignmentUploadScreenState createState() => _AssignmentUploadScreenState();
}

class _AssignmentUploadScreenState extends State<AssignmentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  PlatformFile? _instructionFile;
  bool _isUploading = false;
  DateTime? _dueDate;
  String _errorMessage = '';

  Future<void> _pickInstructionFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
        allowMultiple: false,
        withData: true, // Ensures file data is loaded
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _errorMessage = 'No file selected');
        return;
      }

      final file = result.files.first;
      if (file.size <= 0 || file.bytes == null || file.bytes!.isEmpty) {
        setState(() => _errorMessage = 'Selected file is empty or invalid');
        return;
      }

      setState(() {
        _instructionFile = file;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() => _errorMessage = 'File selection error: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_instructionFile == null || 
        _instructionFile!.bytes == null || 
        _instructionFile!.bytes!.isEmpty) {
      setState(() => _errorMessage = 'Please select a valid file');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });

    try {
      final storage = StorageService();
      final classroom = ClassroomService();

      final downloadUrl = await storage.uploadFile(
        classroomId: widget.classroomId,
        type: 'assignments',
        file: _instructionFile!,
      );

      await classroom.createAssignment(
        classroomId: widget.classroomId,
        title: _titleController.text.trim(),
        instructions: _instructionsController.text.trim(),
        instructionFileUrl: downloadUrl,
        instructionFileName: _instructionFile!.name,
        dueDate: _dueDate ?? DateTime.now().add(Duration(days: 7)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Submission failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Assignment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Assignment Title'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              
              // Instructions field
              SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(labelText: 'Instructions'),
                maxLines: 3,
              ),
              
              // Due date picker
              SizedBox(height: 16),
              ListTile(
                title: Text('Due Date'),
                subtitle: Text(_dueDate == null 
                    ? 'Not set (default: 7 days from now)'
                    : DateFormat('MMM dd, yyyy').format(_dueDate!)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
              ),
              
              // File picker section
              SizedBox(height: 16),
              Text('Assignment File:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickInstructionFile,
                child: Text(_instructionFile == null 
                    ? 'Select File (PDF, DOC, PPT)' 
                    : 'Selected: ${_instructionFile!.name}'),
              ),
              
              // File info and errors
              if (_instructionFile != null) ...[
                SizedBox(height: 8),
                Text(
                  'Size: ${(_instructionFile!.size / 1024).toStringAsFixed(2)} KB',
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
              
              // Submit button
              SizedBox(height: 24),
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Create Assignment'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}