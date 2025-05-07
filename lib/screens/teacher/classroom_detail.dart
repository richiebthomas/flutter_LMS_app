import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/classroom_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
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
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classroom.name,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Class Code: ${classroom.code}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppTheme.secondaryColor),
              onSelected: (value) async {
                if (value == 'logout') {
                  await authService.signOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'code',
                  child: ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Copy Class Code'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      // Add clipboard functionality here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Class code copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryColor,
            tabs: const [
              Tab(
                icon: Icon(Icons.assignment),
                text: 'Assignments',
              ),
              Tab(
                icon: Icon(Icons.library_books),
                text: 'Materials',
              ),
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
            return FloatingActionButton.extended(
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
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: Text(
                DefaultTabController.of(context).index == 0
                    ? 'Add Assignment'
                    : 'Add Material',
              ),
            );
          },
        ),
      ),
    );
  }
}