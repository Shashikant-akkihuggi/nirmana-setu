import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../engineer/engineer_dashboard.dart';
import '../../manager/manager.dart';
import '../../owner/owner.dart';
import '../../services/public_id_service.dart';

class OnboardingStep3Work extends StatefulWidget {
  final String role;

  const OnboardingStep3Work({
    super.key,
    required this.role,
  });

  @override
  State<OnboardingStep3Work> createState() => _OnboardingStep3WorkState();
}

class _OnboardingStep3WorkState extends State<OnboardingStep3Work> {
  final _formKey = GlobalKey<FormState>();
  
  List<String> _selectedCities = [];
  String? _selectedFirmType;
  bool _isLoading = false;

  final List<String> _cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Surat',
    'Jaipur',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Pimpri-Chinchwad',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Faridabad',
    'Meerut',
    'Rajkot',
    'Kalyan-Dombivli',
    'Vasai-Virar',
    'Varanasi',
  ];

  final List<String> _firmTypes = [
    'Individual',
    'Firm',
  ];

  bool get _showCitySelection {
    return widget.role == 'engineer' || widget.role == 'manager';
  }

  bool get _showFirmType {
    return widget.role == 'engineer';
  }

  String get _stepText {
    if (widget.role == 'engineer') return 'Step 3 of 3';
    return 'Step 2 of 2';
  }

  String get _titleText {
    switch (widget.role) {
      case 'engineer':
        return 'Work Setup';
      case 'manager':
        return 'Work Preferences';
      case 'owner':
        return 'Almost Done!';
      default:
        return 'Final Step';
    }
  }

  String get _subtitleText {
    switch (widget.role) {
      case 'engineer':
        return 'Tell us about your work preferences and setup';
      case 'manager':
        return 'Where would you like to manage projects?';
      case 'owner':
        return 'Your account is ready to be activated';
      default:
        return 'Complete your profile setup';
    }
  }

  Future<void> _completeOnboarding() async {
    if (_showCitySelection || _showFirmType) {
      if (!_formKey.currentState!.validate()) return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final additionalFields = <String, dynamic>{};

      // Add role-specific fields
      if (_showCitySelection && _selectedCities.isNotEmpty) {
        additionalFields['operatingCities'] = _selectedCities;
      }

      if (_showFirmType && _selectedFirmType != null) {
        additionalFields['firmType'] = _selectedFirmType;
      }

      // Use PublicIdService to update profile without overwriting public ID
      await PublicIdService.updateUserProfile(
        uid: user.uid,
        profileCompletion: 100,
        isActive: true,
        additionalFields: additionalFields,
      );

      _navigateToDashboard();
    } catch (e) {
      _showErrorSnackBar('Failed to complete setup: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard() {
    Widget dashboard;
    
    switch (widget.role) {
      case 'engineer':
        dashboard = const EngineerDashboard();
        break;
      case 'manager':
        dashboard = const FieldManagerDashboard();
        break;
      case 'owner':
        dashboard = const OwnerDashboard();
        break;
      default:
        dashboard = const EngineerDashboard();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
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

  void _showCitySelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Operating Cities'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final isSelected = _selectedCities.contains(city);
                    
                    return CheckboxListTile(
                      title: Text(city),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedCities.add(city);
                          } else {
                            _selectedCities.remove(city);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _stepText,
          style: const TextStyle(
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
                Text(
                  _titleText,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitleText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Operating Cities (for Engineer and Manager)
                if (_showCitySelection) ...[
                  GestureDetector(
                    onTap: _showCitySelectionDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.role == 'manager' 
                                      ? 'Operating Cities (Optional)'
                                      : 'Operating Cities *',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedCities.isEmpty
                                      ? 'Select cities where you work'
                                      : _selectedCities.length == 1
                                          ? _selectedCities.first
                                          : '${_selectedCities.length} cities selected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedCities.isEmpty 
                                        ? Colors.grey[600] 
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  
                  // Validation for Engineer cities
                  if (widget.role == 'engineer' && _selectedCities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        'Please select at least one operating city',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                ],

                // Firm Type (for Engineer only)
                if (_showFirmType) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedFirmType,
                    decoration: const InputDecoration(
                      labelText: 'Firm Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    items: _firmTypes.map((firmType) {
                      return DropdownMenuItem<String>(
                        value: firmType,
                        child: Text(firmType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFirmType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your firm type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Owner welcome message
                if (widget.role == 'owner') ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[700],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Niramana Setu!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your account is ready. You can now start creating projects and managing your construction work.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                // Complete Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      // Validate cities for engineer
                      if (widget.role == 'engineer' && _selectedCities.isEmpty) {
                        _showErrorSnackBar('Please select at least one operating city');
                        return;
                      }
                      _completeOnboarding();
                    },
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
                        : Text(
                            widget.role == 'owner' ? 'Get Started' : 'Complete Setup',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Indicator
                LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A66C2)),
                ),
                const SizedBox(height: 16),

                // Success Info Card
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
                        Icons.celebration_outlined,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'re almost done! Complete this step to start using Niramana Setu.',
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