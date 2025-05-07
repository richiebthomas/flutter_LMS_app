import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/storage_service.dart';
import '../../services/classroom_service.dart';
import 'view_submissions_screen.dart';

class AssignmentsListScreen extends StatelessWidget {
  final String classroomId;
  final bool isTeacher;

  const AssignmentsListScreen({super.key, 
    required this.classroomId,
    this.isTeacher = false,
  });

  Future<void> _downloadAndOpenFile(BuildContext context, String fileUrl) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      scaffold.showSnackBar(
        SnackBar(content: Text('Downloading file...')),
      );

      final file = await StorageService().downloadFile(fileUrl);
      
      scaffold.hideCurrentSnackBar();
      await OpenFilex.open(file.path);
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(content: Text('Failed to open file: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ClassroomService().getAssignments(classroomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading assignments'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final assignments = snapshot.data!;
          
          if (assignments.isEmpty) {
            return Center(child: Text('No assignments yet'));
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
                      title: Text(assignment['title']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assignment['description']),
                          SizedBox(height: 4),
                          Text('Due: ${assignment['formattedDate']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () => _downloadAndOpenFile(
                              context,
                              assignment['fileUrl'],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.people),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewSubmissionsScreen(
                                    assignmentId: assignment['id'],
                                    assignmentTitle: assignment['title'],
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
      ),
    );
  }
}