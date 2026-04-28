import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Face Recognition Service for Labour Attendance
/// 
/// Handles face detection, embedding generation, and matching
/// for secure, ID-card-free attendance marking.
class FaceRecognitionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Minimum confidence threshold for face matching (0.0 to 1.0)
  static const double matchingThreshold = 0.75;
  
  /// Minimum number of faces required for enrollment
  static const int minEnrollmentFaces = 3;
  
  /// Maximum number of faces for enrollment
  static const int maxEnrollmentFaces = 5;

  /// Initialize face detector with optimal settings
  static FaceDetector createFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.15, // Minimum face size relative to image
      performanceMode: FaceDetectorMode.accurate,
    );
    
    return FaceDetector(options: options);
  }

  /// Detect faces in an image
  static Future<List<Face>> detectFaces(InputImage inputImage) async {
    final faceDetector = createFaceDetector();
    
    try {
      final faces = await faceDetector.processImage(inputImage);
      return faces;
    } finally {
      faceDetector.close();
    }
  }

  /// Validate face quality for enrollment/matching
  static FaceQualityResult validateFaceQuality(Face face) {
    // Check if face is too small
    if (face.boundingBox.width < 100 || face.boundingBox.height < 100) {
      return FaceQualityResult(
        isValid: false,
        message: 'Face too small. Move closer to camera.',
      );
    }

    // Check head rotation (Euler angles)
    final headEulerAngleY = face.headEulerAngleY;
    final headEulerAngleZ = face.headEulerAngleZ;
    
    if (headEulerAngleY != null && headEulerAngleZ != null &&
        (headEulerAngleY.abs() > 20 || headEulerAngleZ.abs() > 20)) {
      return FaceQualityResult(
        isValid: false,
        message: 'Face not straight. Look directly at camera.',
      );
    }

    // Check if eyes are open (if classification available)
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      if (face.leftEyeOpenProbability! < 0.5 || face.rightEyeOpenProbability! < 0.5) {
        return FaceQualityResult(
          isValid: false,
          message: 'Eyes closed. Please keep eyes open.',
        );
      }
    }

    // Check if smiling (optional - for liveness detection)
    if (face.smilingProbability != null && face.smilingProbability! < 0.1) {
      // Face is too serious - might be a photo
      // This is a basic liveness check
    }

    return FaceQualityResult(
      isValid: true,
      message: 'Face quality good',
    );
  }

  /// Generate face embedding (simplified - in production use ML model)
  /// 
  /// NOTE: This is a placeholder. In production, you should use:
  /// - TensorFlow Lite with FaceNet model
  /// - Or a cloud-based face recognition API
  /// - Or a dedicated face recognition package
  static List<double> generateFaceEmbedding(Face face) {
    // PLACEHOLDER: Generate a simple embedding based on face landmarks
    // In production, use a proper face recognition model
    
    List<double> embedding = [];
    
    // Use face landmarks to create a basic feature vector
    if (face.landmarks.isNotEmpty) {
      for (var landmark in face.landmarks.values) {
        // Safely access position with null check using optional chaining
        final position = landmark?.position;
        if (position != null) {
          embedding.add(position.x.toDouble());
          embedding.add(position.y.toDouble());
        }
      }
    }
    
    // Add bounding box features
    embedding.add(face.boundingBox.left.toDouble());
    embedding.add(face.boundingBox.top.toDouble());
    embedding.add(face.boundingBox.width.toDouble());
    embedding.add(face.boundingBox.height.toDouble());
    
    // Add head pose features
    embedding.add(face.headEulerAngleX ?? 0.0);
    embedding.add(face.headEulerAngleY ?? 0.0);
    embedding.add(face.headEulerAngleZ ?? 0.0);
    
    // Normalize embedding (simple normalization)
    double sum = embedding.fold(0, (a, b) => a + b * b);
    double magnitude = sum > 0 ? 1.0 / (sum + 1e-10) : 1.0;
    
    return embedding.map((e) => e * magnitude).toList();
  }

  /// Calculate similarity between two face embeddings (cosine similarity)
  static double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0.0;
    }

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// Match face against stored labour embeddings
  static Future<FaceMatchResult> matchFace(
    String projectId,
    List<double> faceEmbedding,
  ) async {
    try {
      // Get all active labours for this project
      QuerySnapshot labourSnapshot = await _firestore
          .collection('labours')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      if (labourSnapshot.docs.isEmpty) {
        return FaceMatchResult(
          isMatched: false,
          message: 'No enrolled labours found for this project.',
        );
      }

      // Find best match
      String? matchedLabourId;
      String? matchedLabourName;
      double bestSimilarity = 0.0;

      for (var doc in labourSnapshot.docs) {
        Map<String, dynamic> labourData = doc.data() as Map<String, dynamic>;
        List<dynamic>? storedEmbedding = labourData['faceEmbedding'] as List<dynamic>?;

        if (storedEmbedding == null || storedEmbedding.isEmpty) {
          continue;
        }

        List<double> storedEmbeddingDouble = storedEmbedding.map((e) => e as double).toList();
        double similarity = calculateSimilarity(faceEmbedding, storedEmbeddingDouble);

        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          matchedLabourId = doc.id;
          matchedLabourName = labourData['name'];
        }
      }

      // Check if best match exceeds threshold
      if (bestSimilarity >= matchingThreshold) {
        return FaceMatchResult(
          isMatched: true,
          labourId: matchedLabourId,
          labourName: matchedLabourName,
          confidence: bestSimilarity,
          message: 'Face matched: $matchedLabourName (${(bestSimilarity * 100).toStringAsFixed(1)}% confidence)',
        );
      } else {
        return FaceMatchResult(
          isMatched: false,
          confidence: bestSimilarity,
          message: 'Face not recognized. Confidence too low: ${(bestSimilarity * 100).toStringAsFixed(1)}%',
        );
      }
    } catch (e) {
      return FaceMatchResult(
        isMatched: false,
        message: 'Error matching face: $e',
      );
    }
  }

  /// Enroll labour with face embeddings
  static Future<String> enrollLabour({
    required String projectId,
    required String name,
    required String role,
    required double dailyWage,
    required List<List<double>> faceEmbeddings,
  }) async {
    if (faceEmbeddings.length < minEnrollmentFaces) {
      throw Exception('At least $minEnrollmentFaces face scans required for enrollment');
    }

    // Average the embeddings for better accuracy
    List<double> averagedEmbedding = _averageEmbeddings(faceEmbeddings);

    // Create labour document
    DocumentReference labourRef = await _firestore.collection('labours').add({
      'projectId': projectId,
      'name': name,
      'role': role,
      'dailyWage': dailyWage,
      'faceEmbedding': averagedEmbedding,
      'status': 'ACTIVE',
      'enrolledAt': FieldValue.serverTimestamp(),
      'enrolledBy': null, // Set from auth context
    });

    return labourRef.id;
  }

  /// Average multiple face embeddings
  static List<double> _averageEmbeddings(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];
    
    int embeddingLength = embeddings[0].length;
    List<double> averaged = List.filled(embeddingLength, 0.0);

    for (var embedding in embeddings) {
      for (int i = 0; i < embeddingLength; i++) {
        averaged[i] += embedding[i];
      }
    }

    for (int i = 0; i < embeddingLength; i++) {
      averaged[i] /= embeddings.length;
    }

    return averaged;
  }

  /// Get labour by ID
  static Future<Map<String, dynamic>?> getLabour(String labourId) async {
    DocumentSnapshot doc = await _firestore.collection('labours').doc(labourId).get();
    if (doc.exists) {
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    }
    return null;
  }

  /// Get all labours for a project
  static Stream<List<Map<String, dynamic>>> getProjectLabours(String projectId) {
    return _firestore
        .collection('labours')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Deactivate labour
  static Future<void> deactivateLabour(String labourId) async {
    await _firestore.collection('labours').doc(labourId).update({
      'status': 'INACTIVE',
      'deactivatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Face quality validation result
class FaceQualityResult {
  final bool isValid;
  final String message;

  FaceQualityResult({
    required this.isValid,
    required this.message,
  });
}

/// Face matching result
class FaceMatchResult {
  final bool isMatched;
  final String? labourId;
  final String? labourName;
  final double? confidence;
  final String message;

  FaceMatchResult({
    required this.isMatched,
    this.labourId,
    this.labourName,
    this.confidence,
    required this.message,
  });
}
