import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store credentials for re-authentication
  String _lastEmail = '';
  String _lastPassword = '';

  // Auth state stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      
      // Get user document from Firestore
      DocumentSnapshot doc = 
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (!doc.exists) {
        // New user - no document yet
        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
        );
      }
      
      // Existing user
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // Registration
  Future<UserModel?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name
  ) async {
    try {
      // Store credentials
      _lastEmail = email;
      _lastPassword = password;
      
      // Create Firebase user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user == null) return null;
      
      // Create user document WITHOUT role
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        // No role set here - will be set later in role selector
      });
      
      return UserModel(
        uid: user.uid,
        email: email,
        name: name,
      );
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Login
  Future<UserModel?> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      // Store credentials
      _lastEmail = email;
      _lastPassword = password;
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      return user != null 
          ? UserModel(uid: user.uid, email: user.email ?? '') 
          : null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Re-authenticate (for role updates)
  Future<UserModel?> reloadUser() async {
    try {
      if (_lastEmail.isEmpty || _lastPassword.isEmpty) return null;
      return await signInWithEmailAndPassword(_lastEmail, _lastPassword);
    } catch (e) {
      print('Reload error: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      // Clear stored credentials
      _lastEmail = '';
      _lastPassword = '';
      await _auth.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}