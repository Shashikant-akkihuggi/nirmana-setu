import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/geofencing_service.dart';
import '../services/face_recognition_service.dart';
import '../common/project_context.dart';

class GPSFaceAttendanceScreen extends StatefulWidget {
  const GPSFaceAttendanceScreen({super.key});

  @override
  State<GPSFaceAttendanceScreen> createState() => _GPSFaceAttendanceScreenState();
}

class _GPSFaceAttendanceScreenState extends State<GPSFaceAttendanceScreen> {
  bool _isVerifyingGPS = false;
  bool _gpsVerified = false;
  GeofenceVerificationResult? _gpsResult;
  
  String _statusMessage = 'Tap to start attendance verification';
  Color _statusColor = Colors.blue;

  Future<void> _startAttendanceFlow() async {
    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      _showError('No active project selected');
      return;
    }

    // Step 1: Verify GPS
    setState(() {
      _isVerifyingGPS = true;
      _statusMessage = 'Verifying GPS location...';
      _statusColor = Colors.orange;
    });

    try {
      _gpsResult = await GeofencingService.verifyLocationAtSite(projectId);
      
      if (!_gpsResult!.isWithinGeofence) {
        setState(() {
          _isVerifyingGPS = false;
          _statusMessage = _gpsResult!.errorMessage ?? 'GPS verification failed';
          _statusColor = Colors.red;
        });
        return;
      }

      setState(() {
        _gpsVerified = true;
        _statusMessage = 'GPS verified! Now scan face...';
        _statusColor = Colors.green;
        _isVerifyingGPS = false;
      });

      // Step 2: Proceed to face recognition
      await Future.delayed(const Duration(seconds: 1));
      _startFaceRecognition();
      
    } catch (e) {
      setState(() {
        _isVerifyingGPS = false;
        _statusMessage = 'GPS Error: $e';
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _startFaceRecognition() async {
    final result = await Navigator.push<FaceMatchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceRecognitionScreen(),
      ),
    );

    if (result == null) {
      setState(() {
        _statusMessage = 'Face scan cancelled';
        _statusColor = Colors.orange;
        _gpsVerified = false;
      });
      return;
    }

    if (!result.isMatched) {
      setState(() {
        _statusMessage = result.message;
        _statusColor = Colors.red;
        _gpsVerified = false;
      });
      return;
    }

    // Both GPS and Face verified - Mark attendance
    await _markAttendance(result);
  }

  Future<void> _markAttendance(FaceMatchResult faceResult) async {
    setState(() {
      _statusMessage = 'Marking attendance...';
      _statusColor = Colors.blue;
    });

    try {
      final projectId = ProjectContext.activeProjectId!;
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Check if already marked today
      final existing = await FirebaseFirestore.instance
          .collection('attendance')
          .where('projectId', isEqualTo: projectId)
          .where('labourId', isEqualTo: faceResult.labourId)
          .where('date', isEqualTo: dateKey)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          _statusMessage = '${faceResult.labourName} already marked present today';
          _statusColor = Colors.orange;
          _gpsVerified = false;
        });
        return;
      }

      // Mark attendance
      await FirebaseFirestore.instance.collection('attendance').add({
        'projectId': projectId,
        'labourId': faceResult.labourId,
        'labourName': faceResult.labourName,
        'date': dateKey,
        'checkInTime': '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}',
        'markedBy': currentUser.uid,
        'gpsVerified': true,
        'faceVerified': true,
        'gps': {
          'lat': _gpsResult!.currentLat,
          'lng': _gpsResult!.currentLng,
          'distanceFromSite': _gpsResult!.distance,
          'accuracy': _gpsResult!.accuracy,
        },
        'faceConfidence': faceResult.confidence,
        'status': 'PRESENT',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _statusMessage = '✓ ${faceResult.labourName} marked PRESENT';
        _statusColor = Colors.green;
        _gpsVerified = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Attendance Marked'),
            content: Text(
              '${faceResult.labourName} has been marked present.\n\n'
              'Time: ${today.hour}:${today.minute}\n'
              'GPS Distance: ${_gpsResult!.distance!.toStringAsFixed(1)}m'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error marking attendance: $e';
        _statusColor = Colors.red;
        _gpsVerified = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _gpsVerified ? Icons.check_circle : Icons.fingerprint,
                size: 100,
                color: _statusColor,
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 48),
              if (!_isVerifyingGPS && !_gpsVerified)
                ElevatedButton.icon(
                  onPressed: _startAttendanceFlow,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Verification'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                ),
              if (_isVerifyingGPS)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  String _message = 'Position face in frame';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _recognizeFace() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      
      final faces = await FaceRecognitionService.detectFaces(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _message = 'No face detected. Try again.';
          _isProcessing = false;
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _message = 'Multiple faces detected. Only one person.';
          _isProcessing = false;
        });
        return;
      }

      final face = faces.first;
      final quality = FaceRecognitionService.validateFaceQuality(face);

      if (!quality.isValid) {
        setState(() {
          _message = quality.message;
          _isProcessing = false;
        });
        return;
      }

      // Generate embedding and match
      final embedding = FaceRecognitionService.generateFaceEmbedding(face);
      final projectId = ProjectContext.activeProjectId!;
      
      final matchResult = await FaceRecognitionService.matchFace(projectId, embedding);
      
      if (mounted) {
        Navigator.pop(context, matchResult);
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_cameraController!),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _recognizeFace,
                  icon: const Icon(Icons.face),
                  label: const Text('Recognize Face'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
