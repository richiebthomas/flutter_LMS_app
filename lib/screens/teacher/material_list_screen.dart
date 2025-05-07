import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/storage_service.dart';  // Add this import
import '../../services/classroom_service.dart';
import 'content_upload_screen.dart'; // Added import

class MaterialListScreen extends StatelessWidget {
  final String classroomId;
  final bool isTeacher;
  final StorageService _storageService = StorageService();  // Add this line

  MaterialListScreen({
    super.key, 
    required this.classroomId,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContentUploadScreen(classroomId: classroomId),
                  ),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ClassroomService().getMaterials(classroomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading materials'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final materials = snapshot.data!;

          if (materials.isEmpty) {
            return Center(child: Text('No materials available'));
          }

          return ListView.builder(
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return ListTile(
                title: Text(material['title']),
                subtitle: Text(material['description'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadAndOpenFile(context, material['fileUrl']),
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