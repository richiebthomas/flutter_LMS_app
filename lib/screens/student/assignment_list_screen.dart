import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/storage_service.dart';
import '../../services/classroom_service.dart';
import 'assignment_submission_screen.dart';

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
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = snapshot.data!;
        if (assignments.isEmpty) {
          return const Center(child: Text('No assignments available'));
        }

        return ListView.builder(
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(assignment['title'] ?? 'Untitled'),
                    subtitle: Text('Due: ${assignment['formattedDate'] ?? 'No due date'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadAndOpenFile(
                            context,
                            assignment['fileUrl'],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.upload),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignmentSubmissionScreen(
                                  assignmentId: assignment['id'],
                                  assignmentTitle: assignment['title'],
                                  classroomId: classroomId,
                                ),
                              ),
                            );
                          },
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