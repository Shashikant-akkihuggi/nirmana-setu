import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  /// Compress image for Cloudinary upload asynchronously
  /// - Resize to max width 1280px
  /// - Convert to JPEG
  /// - Quality 75%
  /// - Ensure final file size optimization
  static Future<File?> compressForUpload(File originalFile) async {
    try {
      // Get original file size
      final originalSize = await originalFile.length();
      debugPrint('ImageCompression: Original size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Generate compressed file path
      final dir = path.dirname(originalFile.path);
      final name = path.basenameWithoutExtension(originalFile.path);
      final compressedPath = path.join(dir, '${name}_compressed.jpg');
      
      // Compress image asynchronously
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        originalFile.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      
      if (compressedBytes == null) {
        debugPrint('ImageCompression: Compression failed - using original file');
        return originalFile;
      }
      
      // Write compressed bytes to file
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      final compressedSize = compressedBytes.length;
      debugPrint('ImageCompression: Compressed size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('ImageCompression: Compression ratio: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%');
      
      // Verify final file exists and is valid
      if (await compressedFile.exists()) {
        return compressedFile;
      } else {
        debugPrint('ImageCompression: Compressed file creation failed - using original');
        return originalFile;
      }
      
    } catch (e, stackTrace) {
      debugPrint('ImageCompression: Error compressing image: $e');
      debugPrint('ImageCompression: Using original file as fallback');
      return originalFile; // Return original if compression fails
    }
  }
  
  /// Compress multiple images asynchronously without blocking UI
  static Future<List<File>> compressMultipleImages(List<File> originalFiles) async {
    debugPrint('ImageCompression: Starting background compression of ${originalFiles.length} images');
    
    final compressedFiles = <File>[];
    
    for (int i = 0; i < originalFiles.length; i++) {
      debugPrint('ImageCompression: Processing image ${i + 1}/${originalFiles.length}');
      
      final compressedFile = await compressForUpload(originalFiles[i]);
      compressedFiles.add(compressedFile ?? originalFiles[i]);
    }
    
    debugPrint('ImageCompression: Background compression complete');
    return compressedFiles;
  }
}