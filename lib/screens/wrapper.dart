import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
import 'package:flutter_application_1/screens/teacher/teacher_home.dart';
import 'student/student_home.dart';
import '../widgets/role_selector.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    
    if (user == null) return LoginScreen();
    
    final userData = user.toMap();
    if (!userData.containsKey('role') || user.role == null || user.role!.isEmpty) {
      return RoleSelector();
    }
    
    return user.role == 'teacher' ? TeacherHome() : StudentHome();
  }
}