import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/classroom_model.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:intl/intl.dart';

class ClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Create a new classroom
  Future<Classroom> createClassroom(
    String name,
    String description,
    String teacherId,
  ) async {
    try {
      // Generate a unique 6-digit code
      final code = _generateClassCode();
      final createdAt = DateTime.now();

      final docRef = await _firestore.collection('classrooms').add({
        'name': name,
        'description': description,
        'code': code,
        'teacherId': teacherId,
        'students': [],
        'createdAt': createdAt,
      });

      return Classroom(
        id: docRef.id,
        name: name,
        description: description,
        code: code,
        teacherId: teacherId,
        students: [],
        createdAt: createdAt,
      );
    } catch (e) {
      throw Exception('Failed to create classroom: ${e.toString()}');
    }
  }

  // Join a classroom
  Future<void> joinClassroom(String code, String studentId) async {
    try {
      final query = await _firestore
          .collection('classrooms')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Classroom not found');
      }

      final classroom = query.docs.first;
      await _firestore
          .collection('classrooms')
          .doc(classroom.id)
          .update({
            'students': FieldValue.arrayUnion([studentId])
          });
    } catch (e) {
      throw Exception('Failed to join classroom: ${e.toString()}');
    }
  }

  // Create assignment
  Future<void> createAssignment({
    required String classroomId,
    required String title,
    String? instructions,
    required String instructionFileUrl,
    required String instructionFileName,
    DateTime? dueDate,
  }) async {
    try {
      await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .collection('assignments')
          .add({
            'title': title,
            'description': instructions ?? 'No instructions provided',
            'fileUrl': instructionFileUrl,
            'fileName': instructionFileName,
            'createdAt': FieldValue.serverTimestamp(),
            'dueDate': dueDate ?? DateTime.now().add(Duration(days: 7)),
            'formattedDate': DateFormat('MMM dd, yyyy').format(
                dueDate ?? DateTime.now().add(Duration(days: 7))),
          });
    } catch (e) {
      throw Exception('Failed to create assignment: ${e.toString()}');
    }
  }

  // Upload content material
  Future<void> uploadContent({
    required String classroomId,
    required String title,
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .collection('materials')
          .add({
            'title': title,
            'fileUrl': fileUrl,
            'fileName': fileName,
            'uploadedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to upload content: ${e.toString()}');
    }
  }

  

  

  // Stream for teacher's classrooms
  Stream<List<Classroom>> getTeacherClassrooms(String teacherId) {
    return _firestore
        .collection('classrooms')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Classroom.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream for student's classrooms
  Stream<List<Classroom>> getStudentClassrooms(String studentId) {
    return _firestore
        .collection('classrooms')
        .where('students', arrayContains: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Classroom.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream for assignments
  Stream<List<Map<String, dynamic>>> getAssignments(String classroomId) {
    return _firestore
        .collection('classrooms')
        .doc(classroomId)
        .collection('assignments')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  // Stream for materials
  Stream<List<Map<String, dynamic>>> getMaterials(String classroomId) {
    return _firestore
        .collection('classrooms')
        .doc(classroomId)
        .collection('materials')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  Future<void> deleteAssignment({
    required String classroomId,
    required String assignmentId,
    required String fileUrl,
  }) async {
    try {
      // First delete the storage file
      await _storageService.deleteFile(fileUrl);
      
      // Then delete the Firestore document
      await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .collection('assignments')
          .doc(assignmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete assignment: ${e.toString()}');
    }
  }

  Future<void> deleteMaterial({
    required String classroomId,
    required String materialId,
    required String fileUrl,
  }) async {
    try {
      // First delete the storage file
      await _storageService.deleteFile(fileUrl);
      
      // Then delete the Firestore document
      await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .collection('materials')
          .doc(materialId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete material: ${e.toString()}');
    }
  }

  // Get submissions for an assignment
  Stream<List<Map<String, dynamic>>> getSubmissions(String assignmentId) {
    return _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  // Submit an assignment
  Future<void> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String fileName,
    required String fileUrl,
  }) async {
    try {
      await _firestore.collection('submissions').add({
        'assignmentId': assignmentId,
        'studentId': studentId,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit assignment: ${e.toString()}');
    }
  }

  // Generate random 6-digit class code
  String _generateClassCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString();
  }
}