import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../screens/wrapper.dart';


class RoleSelector extends StatefulWidget {
  const RoleSelector({super.key});

  @override
  _RoleSelectorState createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = Provider.of<UserModel?>(context, listen: false);
      
      if (user != null) {
        // 1. Update role in Firestore
        await DatabaseService(uid: user.uid).updateUserData(user.name ?? '', role);
        
        // 2. Force refresh auth state
        await auth.signOut();
        await auth.signInWithEmailAndPassword(user.email, 'user-provided-password');
        
        // 3. Navigate to wrapper which will handle proper routing
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Wrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Your Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Are you a teacher or student?', style: TextStyle(fontSize: 20)),
            SizedBox(height: 40),
            _isLoading
                ? CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectRole('teacher'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: Text('I am a Teacher'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _selectRole('student'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: Text('I am a Student'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}