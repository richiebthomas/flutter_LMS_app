import 'package:flutter/material.dart';
import '../../models/classroom_model.dart';
import 'assignment_list_screen.dart';
import 'material_list_screen.dart';

class StudentClassroomDetail extends StatelessWidget {
  final Classroom classroom;

  const StudentClassroomDetail({super.key, required this.classroom});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(classroom.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Assignments'),
              Tab(text: 'Materials'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AssignmentsListScreen(
              classroomId: classroom.id,
            ),
            MaterialListScreen(
              classroomId: classroom.id,
            ),
          ],
        ),
      ),
    );
  }
}