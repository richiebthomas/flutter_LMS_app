import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart'; // Added for PlatformFile
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required String classroomId,
    required String type,
    required PlatformFile file,
  }) async {
    try {
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('Selected file is empty or corrupted');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref().child('classrooms/$classroomId/$type/$fileName');

      final uploadTask = ref.putData(
        file.bytes!,
        SettableMetadata(contentType: _getMimeType(file.extension)),
      );

      final snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage Error: ${e.message}');
    } catch (e) {
      throw Exception('Upload Error: ${e.toString()}');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      // Create a reference from the download URL
      final ref = _storage.refFromURL(fileUrl);
      
      // Delete the file
      await ref.delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete file: ${e.message}');
    } catch (e) {
      throw Exception('Delete error: ${e.toString()}');
    }
  }

  Future<File> downloadFile(String url) async {
    try {
      // Request permissions first
      if (!await _requestPermissions()) {
        throw Exception('Storage permission denied');
      }

      // Get the file name from the URL
      final uri = Uri.parse(url);
      final fileName = path.basename(uri.path);
      
      // Get the temporary directory
      final dir = await getTemporaryDirectory();
      final filePath = path.join(dir.path, fileName);
      
      // Download file using HTTP
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      return file;
    } catch (e) {
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  String? _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc': case 'docx': return 'application/msword';
      case 'ppt': case 'pptx': return 'application/vnd.ms-powerpoint';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return null;
    }
  }
}