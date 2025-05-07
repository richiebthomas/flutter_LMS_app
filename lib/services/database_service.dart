import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseService({this.uid});

  Future<void> updateUserData(String name, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'role': role,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }
}