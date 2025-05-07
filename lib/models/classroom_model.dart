// lib/models/classroom_model.dart
class Classroom {
  final String id;
  final String name;
  final String description;
  final String code;
  final String teacherId;
  final List<String> students;
  final DateTime createdAt;
  
  Classroom({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.teacherId,
    required this.students,
    required this.createdAt,
  });
  
  factory Classroom.fromMap(Map<String, dynamic> data, String id) {
    return Classroom(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      code: data['code'] ?? '',
      teacherId: data['teacherId'] ?? '',
      students: List<String>.from(data['students'] ?? []),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'code': code,
      'teacherId': teacherId,
      'students': students,
      'createdAt': createdAt,
    };
  }
}