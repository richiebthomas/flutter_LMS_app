import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/storage_service.dart';  // Add this import
import '../../services/classroom_service.dart';
import 'content_upload_screen.dart'; // Added import
import '../../utils/app_theme.dart';


class MaterialListScreen extends StatelessWidget {
  final String classroomId;
  final bool isTeacher;
  final StorageService _storageService = StorageService();  // Add this line
  final ClassroomService _classroomService = ClassroomService();

  MaterialListScreen({
    super.key, 
    required this.classroomId,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContentUploadScreen(classroomId: classroomId),
                ),
              ),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: const Text('Add Material'),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _classroomService.getMaterials(classroomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  SizedBox(height: 16),
                  Text(
                    'Error loading materials',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final materials = snapshot.data!;

          if (materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No Materials Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isTeacher
                        ? 'Add your first learning material!'
                        : 'No materials have been added yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: AppTheme.cardDecoration,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    material['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: material['description'] != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(material['description']),
                        )
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      Icons.download_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => _downloadAndOpenFile(
                      context,
                      material['fileUrl'],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _downloadAndOpenFile(BuildContext context, String fileUrl) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Downloading file...')),
      );

      final file = await _storageService.downloadFile(fileUrl);  // Use the instance
      
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        const SnackBar(content: Text('Opening file...')),
      );

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Could not open file');
      }
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}