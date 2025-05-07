import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/classroom_model.dart';
import '../../services/auth_service.dart';
import 'assignment_upload_screen.dart';
import 'assignment_list_screen.dart';
import 'material_list_screen.dart';
import 'content_upload_screen.dart';

class TeacherClassroomDetail extends StatelessWidget {
  final Classroom classroom;

  const TeacherClassroomDetail({super.key, required this.classroom});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(classroom.name),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
              Tab(icon: Icon(Icons.library_books), text: 'Materials'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AssignmentsListScreen(
              classroomId: classroom.id,
              isTeacher: true,
            ),
            MaterialListScreen(
              classroomId: classroom.id,
              isTeacher: true,
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return FloatingActionButton(
              onPressed: () {
                final currentTab = tabController.index;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => currentTab == 0
                        ? AssignmentUploadScreen(classroomId: classroom.id)
                        : ContentUploadScreen(classroomId: classroom.id),
                  ),
                );
              },
              child: Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}