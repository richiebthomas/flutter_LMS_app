class UserModel {
  final String uid;
  final String email;
  final String? role;
  final String? name;
  
  UserModel({
    required this.uid,
    required this.email,
    this.role,
    this.name,
  });
  
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'],
      name: data['name'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      if (role != null) 'role': role,
      if (name != null) 'name': name,
    };
  }
}