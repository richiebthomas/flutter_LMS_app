import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../../services/classroom_service.dart';
import '../../utils/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Create Assignment',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.secondaryColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: 'Assignment Title',
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) => value?.isEmpty ?? true 
                          ? 'Title is required' 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: 'Instructions',
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _dueDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Due Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  _dueDate == null
                                      ? 'Not set (default: 7 days from now)'
                                      : DateFormat('MMM dd, yyyy').format(_dueDate!),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignment File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickInstructionFile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _instructionFile?.name ?? 'Select File',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_instructionFile != null)
                                  Text(
                                    'Size: ${(_instructionFile!.size / 1024).toStringAsFixed(2)} KB',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            style: AppTheme.buttonStyle,
                            child: const Text(
                              'Create Assignment',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}