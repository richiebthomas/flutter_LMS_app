import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/classroom_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Materials Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final material = snapshot.data![index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                  material['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(material['fileName'] ?? ''),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.download_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _downloadAndOpenFile(context, material['fileUrl']),
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