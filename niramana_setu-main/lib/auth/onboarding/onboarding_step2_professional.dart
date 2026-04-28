import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_step3_work.dart';
import '../../services/public_id_service.dart';

class OnboardingStep2Professional extends StatefulWidget {
  final String role;

  const OnboardingStep2Professional({
    super.key,
    required this.role,
  });

  @override
  State<OnboardingStep2Professional> createState() => _OnboardingStep2ProfessionalState();
}

class _OnboardingStep2ProfessionalState extends State<OnboardingStep2Professional> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedQualification;
  String? _selectedSpecialization;
  int? _experienceYears;
  bool _isLoading = false;

  final List<String> _qualifications = [
    'Diploma',
    'BE',
    'MTech',
    'Other',
  ];

  final List<String> _specializations = [
    'Civil Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'PMC (Project Management Consultant)',
    'Structural Engineering',
    'Environmental Engineering',
    'Other',
  ];

  final List<int> _experienceOptions = List.generate(31, (index) => index);

  @override
  void initState() {
    super.initState();
    // Redirect if not engineer
    if (widget.role != 'engineer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingStep3Work(role: widget.role),
          ),
        );
      });
    }
  }

  Future<void> _saveProfessionalDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use PublicIdService to update profile without overwriting public ID
      await PublicIdService.updateUserProfile(
        uid: user.uid,
        profileCompletion: 70,
        additionalFields: {
          'qualification': _selectedQualification,
          'specialization': _selectedSpecialization,
          'experienceYears': _experienceYears,
        },
      );

      _navigateToNextStep();
    } catch (e) {
      _showErrorSnackBar('Failed to save details: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToNextStep() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingStep3Work(role: widget.role),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if redirecting non-engineers
    if (widget.role != 'engineer') {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Step 2 of 3',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Background',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help us understand your engineering expertise',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Qualification Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedQualification,
                  decoration: const InputDecoration(
                    labelText: 'Qualification *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _qualifications.map((qualification) {
                    return DropdownMenuItem<String>(
                      value: qualification,
                      child: Text(qualification),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedQualification = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your qualification';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Specialization Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSpecialization,
                  decoration: const InputDecoration(
                    labelText: 'Specialization *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.engineering_outlined),
                  ),
                  items: _specializations.map((specialization) {
                    return DropdownMenuItem<String>(
                      value: specialization,
                      child: Text(specialization),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialization = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your specialization';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Experience Years Dropdown
                DropdownButtonFormField<int>(
                  value: _experienceYears,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _experienceOptions.map((years) {
                    return DropdownMenuItem<int>(
                      value: years,
                      child: Text(years == 0 ? 'Fresher' : '$years ${years == 1 ? 'year' : 'years'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _experienceYears = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your experience level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfessionalDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A66C2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Indicator
                LinearProgressIndicator(
                  value: 0.67,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A66C2)),
                ),
                const SizedBox(height: 16),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This information helps us match you with relevant projects and opportunities.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}