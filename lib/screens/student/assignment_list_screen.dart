import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/storage_service.dart';
import '../../services/classroom_service.dart';
import 'assignment_submission_screen.dart';
import '../../utils/app_theme.dart';

class AssignmentsListScreen extends StatelessWidget {
  final String classroomId;
  final StorageService _storageService = StorageService();
  final ClassroomService _classroomService = ClassroomService();

  AssignmentsListScreen({
    super.key,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _classroomService.getAssignments(classroomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Assignments Yet',
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
            final assignment = snapshot.data![index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      assignment['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Due: ${assignment['formattedDate'] ?? 'No due date'}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _downloadAndOpenFile(
                            context,
                            assignment['fileUrl'],
                          ),
                          icon: const Icon(Icons.download),
                          label: const Text('Instructions'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: AppTheme.buttonStyle,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignmentSubmissionScreen(
                                assignmentId: assignment['id'],
                                assignmentTitle: assignment['title'],
                                classroomId: classroomId,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ],
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