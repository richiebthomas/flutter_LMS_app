import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/classroom_service.dart';
import '../../services/storage_service.dart';

class MaterialListScreen extends StatelessWidget {
  final String classroomId;
  final StorageService _storageService = StorageService();
  final ClassroomService _classroomService = ClassroomService();

  MaterialListScreen({
    super.key,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _classroomService.getMaterials(classroomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final materials = snapshot.data!;
        if (materials.isEmpty) {
          return const Center(child: Text('No materials available'));
        }

        return ListView.builder(
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return ListTile(
              leading: const Icon(Icons.description),
              title: Text(material['title'] ?? 'Untitled'),
              subtitle: Text(material['fileName'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadAndOpenFile(
                  context,
                  material['fileUrl'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadAndOpenFile(BuildContext context, String fileUrl) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Downloading file...')),
      );

      final file = await _storageService.downloadFile(fileUrl);
      scaffold.hideCurrentSnackBar();

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