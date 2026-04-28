import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_recognition_service.dart';
import '../common/project_context.dart';

class LabourEnrollmentScreen extends StatefulWidget {
  const LabourEnrollmentScreen({super.key});

  @override
  State<LabourEnrollmentScreen> createState() => _LabourEnrollmentScreenState();
}

class _LabourEnrollmentScreenState extends State<LabourEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wageController = TextEditingController();
  String _selectedRole = 'Mason';
  
  final List<String> _roles = [
    'Mason',
    'Helper',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Welder',
    'Driver',
  ];

  List<List<double>> _capturedFaceEmbeddings = [];
  bool _isEnrolling = false;

  @override
  void dispose() {
    _nameController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    if (_capturedFaceEmbeddings.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 face scans captured')),
      );
      return;
    }

    final result = await Navigator.push<List<double>>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceCaptureScreen(
          scanNumber: _capturedFaceEmbeddings.length + 1,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _capturedFaceEmbeddings.add(result);
      });
    }
  }

  Future<void> _enrollLabour() async {
    if (!_formKey.currentState!.validate()) return;

    if (_capturedFaceEmbeddings.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture at least 3 face scans')),
      );
      return;
    }

    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active project')),
      );
      return;
    }

    setState(() => _isEnrolling = true);

    try {
      await FaceRecognitionService.enrollLabour(
        projectId: projectId,
        name: _nameController.text.trim(),
        role: _selectedRole,
        dailyWage: double.parse(_wageController.text),
        faceEmbeddings: _capturedFaceEmbeddings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_nameController.text} enrolled successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Labour'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Labour Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wageController,
                decoration: const InputDecoration(
                  labelText: 'Daily Wage (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Enter wage' : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Face Scans: ${_capturedFaceEmbeddings.length}/5 (min 3 required)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(_capturedFaceEmbeddings.length, (i) {
                  return Chip(
                    label: Text('Scan ${i + 1}'),
                    backgroundColor: Colors.green.shade100,
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _captureFace,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Face'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isEnrolling ? null : _enrollLabour,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                ),
                child: _isEnrolling
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enroll Labour', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceCaptureScreen extends StatefulWidget {
  final int scanNumber;
  const FaceCaptureScreen({super.key, required this.scanNumber});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
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

  Future<void> _captureFace() async {
    if (_isDetecting) return;
    setState(() => _isDetecting = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      
      final faces = await FaceRecognitionService.detectFaces(inputImage);

      if (faces.isEmpty) {
        setState(() => _message = 'No face detected. Try again.');
        setState(() => _isDetecting = false);
        return;
      }

      if (faces.length > 1) {
        setState(() => _message = 'Multiple faces detected. Only one person.');
        setState(() => _isDetecting = false);
        return;
      }

      final face = faces.first;
      final quality = FaceRecognitionService.validateFaceQuality(face);

      if (!quality.isValid) {
        setState(() => _message = quality.message);
        setState(() => _isDetecting = false);
        return;
      }

      final embedding = FaceRecognitionService.generateFaceEmbedding(face);
      
      if (mounted) {
        Navigator.pop(context, embedding);
      }
    } catch (e) {
      setState(() => _message = 'Error: $e');
      setState(() => _isDetecting = false);
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
        title: Text('Face Scan ${widget.scanNumber}'),
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
                  onPressed: _isDetecting ? null : _captureFace,
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture'),
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
