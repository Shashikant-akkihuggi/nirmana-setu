import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  static const int _timeoutSeconds = 30;
  static const int _retryDelaySeconds = 2;

  /// Upload a single compressed image to Cloudinary with retry logic
  /// Returns the secure URL of the uploaded image
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      debugPrint('Cloudinary: Starting upload - File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // First upload attempt
      String? result = await _attemptUpload(imageFile);
      
      if (result != null) {
        debugPrint('Cloudinary: Upload successful on first attempt');
        return result;
      }
      
      // Retry after delay
      debugPrint('Cloudinary: First attempt failed, retrying after ${_retryDelaySeconds}s...');
      await Future.delayed(Duration(seconds: _retryDelaySeconds));
      
      result = await _attemptUpload(imageFile);
      
      if (result != null) {
        debugPrint('Cloudinary: Upload successful on retry');
        return result;
      }
      
      debugPrint('Cloudinary: Upload failed after retry - will fallback to offline');
      return null;
      
    } catch (e, stackTrace) {
      debugPrint('Cloudinary: Upload process error - $e');
      return null;
    }
  }

  /// Attempt a single upload to Cloudinary
  static Future<String?> _attemptUpload(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(CloudinaryConfig.apiBaseUrl));
      
      // Set proper headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'NiramanaSetu/1.0',
      });
      
      // Add required fields for unsigned upload
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'niramana_setu/dpr_images';
      request.fields['public_id'] = 'dpr_${DateTime.now().millisecondsSinceEpoch}';
      request.fields['resource_type'] = 'image';
      
      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'dpr_image.jpg',
      );
      request.files.add(multipartFile);
      
      debugPrint('Cloudinary: Sending request to ${CloudinaryConfig.apiBaseUrl}');
      
      // Send request with timeout
      final response = await request.send().timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Cloudinary upload timeout', Duration(seconds: _timeoutSeconds));
        },
      );
      
      final responseBody = await response.stream.bytesToString();
      
      debugPrint('Cloudinary: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final secureUrl = jsonResponse['secure_url'] as String?;
        
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('Cloudinary: Upload successful - URL received');
          return secureUrl;
        } else {
          debugPrint('Cloudinary: Response missing secure_url field');
          return null;
        }
      } else {
        debugPrint('Cloudinary: Upload failed - Status: ${response.statusCode}');
        if (response.statusCode >= 500) {
          debugPrint('Cloudinary: Server error (5xx) - Cloudinary service issue');
        } else if (response.statusCode == 400) {
          debugPrint('Cloudinary: Bad request (400) - Check upload preset');
        }
        return null;
      }
      
    } on TimeoutException catch (e) {
      debugPrint('Cloudinary: Upload timeout - $e');
      return null;
    } on SocketException catch (e) {
      debugPrint('Cloudinary: Network error - $e');
      return null;
    } catch (e) {
      debugPrint('Cloudinary: Upload attempt error - $e');
      return null;
    }
  }

  /// Upload multiple images to Cloudinary sequentially
  /// Returns a list of secure URLs for successfully uploaded images
  /// Returns null if ANY upload fails after retry
  static Future<List<String>?> uploadMultipleImages(List<File> imageFiles) async {
    debugPrint('Cloudinary: Starting sequential upload of ${imageFiles.length} images');
    
    final uploadedUrls = <String>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      debugPrint('Cloudinary: Uploading image ${i + 1}/${imageFiles.length}');
      
      final url = await uploadImage(imageFiles[i]);
      if (url != null) {
        uploadedUrls.add(url);
        debugPrint('Cloudinary: Image ${i + 1} uploaded successfully');
      } else {
        debugPrint('Cloudinary: Image ${i + 1} upload failed - aborting batch upload');
        return null; // Return null to indicate batch failure
      }
    }
    
    debugPrint('Cloudinary: All ${uploadedUrls.length} images uploaded successfully');
    return uploadedUrls;
  }

  /// Upload attendance photo to Cloudinary with custom folder structure
  /// folder: attendance/{projectId}/{date}
  /// public_id: manager_{managerId}
  /// Returns the secure URL of the uploaded image
  static Future<String?> uploadAttendancePhoto({
    required File imageFile,
    required String projectId,
    required String date,
    required String managerId,
  }) async {
    try {
      final fileSize = await imageFile.length();
      debugPrint('Cloudinary: Starting attendance photo upload - File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('Cloudinary: Folder: attendance/$projectId/$date');
      debugPrint('Cloudinary: Public ID: manager_$managerId');
      
      // First upload attempt
      String? result = await _attemptAttendanceUpload(
        imageFile: imageFile,
        projectId: projectId,
        date: date,
        managerId: managerId,
      );
      
      if (result != null) {
        debugPrint('Cloudinary: Attendance photo upload successful on first attempt');
        return result;
      }
      
      // Retry after delay
      debugPrint('Cloudinary: First attempt failed, retrying after ${_retryDelaySeconds}s...');
      await Future.delayed(Duration(seconds: _retryDelaySeconds));
      
      result = await _attemptAttendanceUpload(
        imageFile: imageFile,
        projectId: projectId,
        date: date,
        managerId: managerId,
      );
      
      if (result != null) {
        debugPrint('Cloudinary: Attendance photo upload successful on retry');
        return result;
      }
      
      debugPrint('Cloudinary: Attendance photo upload failed after retry');
      return null;
      
    } catch (e, stackTrace) {
      debugPrint('Cloudinary: Attendance photo upload process error - $e');
      return null;
    }
  }

  /// Attempt a single attendance photo upload to Cloudinary
  static Future<String?> _attemptAttendanceUpload({
    required File imageFile,
    required String projectId,
    required String date,
    required String managerId,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(CloudinaryConfig.apiBaseUrl));
      
      // Set proper headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'NiramanaSetu/1.0',
      });
      
      // Add required fields for unsigned upload with custom folder structure
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'attendance/$projectId/$date';
      request.fields['public_id'] = 'manager_$managerId';
      request.fields['resource_type'] = 'image';
      
      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'attendance_photo.jpg',
      );
      request.files.add(multipartFile);
      
      debugPrint('Cloudinary: Sending attendance photo request to ${CloudinaryConfig.apiBaseUrl}');
      
      // Send request with timeout
      final response = await request.send().timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Cloudinary upload timeout', Duration(seconds: _timeoutSeconds));
        },
      );
      
      final responseBody = await response.stream.bytesToString();
      
      debugPrint('Cloudinary: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final secureUrl = jsonResponse['secure_url'] as String?;
        
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('Cloudinary: Attendance photo upload successful - URL: $secureUrl');
          return secureUrl;
        } else {
          debugPrint('Cloudinary: Response missing secure_url field');
          return null;
        }
      } else {
        debugPrint('Cloudinary: Attendance photo upload failed - Status: ${response.statusCode}');
        debugPrint('Cloudinary: Response body: $responseBody');
        if (response.statusCode >= 500) {
          debugPrint('Cloudinary: Server error (5xx) - Cloudinary service issue');
        } else if (response.statusCode == 400) {
          debugPrint('Cloudinary: Bad request (400) - Check upload preset and folder structure');
        }
        return null;
      }
      
    } on TimeoutException catch (e) {
      debugPrint('Cloudinary: Attendance photo upload timeout - $e');
      return null;
    } on SocketException catch (e) {
      debugPrint('Cloudinary: Network error - $e');
      return null;
    } catch (e) {
      debugPrint('Cloudinary: Attendance photo upload attempt error - $e');
      return null;
    }
  }

  /// Check if Cloudinary service is properly configured
  static bool isConfigured() {
    return CloudinaryConfig.isConfigured;
  }
}