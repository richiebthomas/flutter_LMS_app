import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/classroom_service.dart';

class JoinClassroom extends StatefulWidget {
  const JoinClassroom({super.key});

  @override
  _JoinClassroomState createState() => _JoinClassroomState();
}

class _JoinClassroomState extends State<JoinClassroom> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinClassroom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        final user = Provider.of<UserModel?>(context, listen: false);
        if (user != null) {
          await ClassroomService().joinClassroom(
            _codeController.text.trim().toUpperCase(),
            user.uid,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _error = 'Failed to join classroom: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Classroom')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Classroom Code'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a code' : null,
              ),
              SizedBox(height: 20),
              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _joinClassroom,
                      child: Text('Join Classroom'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}