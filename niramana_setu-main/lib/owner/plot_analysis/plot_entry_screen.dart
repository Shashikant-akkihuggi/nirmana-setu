import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'plot_rules_service.dart';
import 'plot_summary_screen.dart';

class PlotEntryScreen extends StatefulWidget {
  const PlotEntryScreen({super.key});

  @override
  State<PlotEntryScreen> createState() => _PlotEntryScreenState();
}

class _PlotEntryScreenState extends State<PlotEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PlotRulesService();
  
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _roadWidthController = TextEditingController();
  final _cityController = TextEditingController();
  final _floorsController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String _orientation = 'North';
  bool _isLoading = false;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _roadWidthController.dispose();
    _cityController.dispose();
    _floorsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _analyzePlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double length = double.parse(_lengthController.text);
      final double width = double.parse(_widthController.text);
      final double roadWidth = double.parse(_roadWidthController.text);
      final int floors = int.parse(_floorsController.text);
      final double budget = double.parse(_budgetController.text);
      
      // 1. Validate Rules (Cloud Function)
      // For now, we simulate a response if the cloud function isn't deployed yet 
      // or rely on the service to throw if it fails.
      // Ideally, the service handles the Cloud Function call.
      
      Map<String, dynamic> validationResult;
      try {
        validationResult = await _service.validatePlotRules(
          length: length,
          width: width,
          city: _cityController.text,
          orientation: _orientation,
          roadWidth: roadWidth,
        );
      } catch (e) {
        // Fallback for development if Cloud Function is not reachable
        // Calculate mock values based on inputs
        final frontSetback = roadWidth > 12 ? 3.0 : 1.5;
        final buildableWidth = width - 3.0; // 1.5 side setbacks
        final buildableLength = length - (frontSetback + 1.5);
        final area = buildableWidth * buildableLength;
        
        validationResult = {
          'buildableArea': area > 0 ? area : 0,
          'setbacks': {
            'front': frontSetback,
            'back': 1.5,
            'left': 1.5,
            'right': 1.5,
          },
          'violations': [],
          'status': 'valid'
        };
      }

      // 2. Fetch Suggestions
      final suggestions = await _service.getDesignSuggestions(
        area: (validationResult['buildableArea'] as num).toDouble(),
        floors: floors,
        budget: budget,
      );

      // 3. Navigate to Summary
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlotSummaryScreen(
              plotData: {
                'length': length,
                'width': width,
                'city': _cityController.text,
                'orientation': _orientation,
                'roadWidth': roadWidth,
                'floors': floors,
                'budget': budget,
              },
              validationResult: validationResult,
              suggestions: suggestions,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Plot Analysis",
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter Plot Details",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll analyze regulations and suggest designs.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Dimensions
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lengthController,
                      label: "Length (m)",
                      icon: Icons.height,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _widthController,
                      label: "Width (m)",
                      icon: Icons.swap_horiz,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location & Road
              _buildTextField(
                controller: _cityController,
                label: "Pincode",
                icon: Icons.pin_drop,
                isInteger: true,
                maxLength: 6,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _roadWidthController,
                      label: "Road Width (m)",
                      icon: Icons.add_road,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _orientation,
                      decoration: InputDecoration(
                        labelText: "Orientation",
                        prefixIcon: const Icon(Icons.compass_calibration, color: Color(0xFF4F4F4F)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: ['North', 'South', 'East', 'West']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => _orientation = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Requirements
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _floorsController,
                      label: "Floors",
                      icon: Icons.layers,
                      isInteger: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _budgetController,
                      label: "Budget (Lakhs)",
                      icon: Icons.currency_rupee,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _analyzePlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ANALYZE PLOT",
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isInteger = false,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      inputFormatters: [
        isInteger
            ? FilteringTextInputFormatter.digitsOnly
            : FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
      ],
      maxLength: maxLength,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (label == "Pincode" && value.length != 6) return 'Enter 6-digit pincode';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4F4F4F)),
        counterText: maxLength != null ? '' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF1F2937), width: 2),
        ),
      ),
    );
  }
}
