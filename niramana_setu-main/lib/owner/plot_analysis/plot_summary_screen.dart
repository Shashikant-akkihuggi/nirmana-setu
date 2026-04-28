import 'package:flutter/material.dart';
import 'plot_visual_view.dart';
import 'plot_design_suggestions.dart';
import 'plot_rules_service.dart';
import 'plot_3d_concept_screen.dart';
import '../../services/ai_concept_service_enhanced.dart';
import '../../models/ai_concept_models.dart';

class PlotSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> plotData;
  final Map<String, dynamic> validationResult;
  final List<Map<String, dynamic>> suggestions;

  const PlotSummaryScreen({
    super.key,
    required this.plotData,
    required this.validationResult,
    required this.suggestions,
  });

  @override
  State<PlotSummaryScreen> createState() => _PlotSummaryScreenState();
}

class _PlotSummaryScreenState extends State<PlotSummaryScreen> {
  bool _isSaving = false;
  bool _isRequestingAi = false;

  Future<void> _savePlot(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final service = PlotRulesService();
      await service.savePlotRequest({
        ...widget.plotData,
        'analysis': widget.validationResult,
        'suggestedTemplates': widget.suggestions
            .map((e) => e['id'] ?? 'unknown')
            .toList(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plot saved for Engineer Review'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        // Pop back to dashboard (pop twice)
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double length = widget.plotData['length'];
    final double width = widget.plotData['width'];

    // Safely cast setbacks
    final Map<String, dynamic> rawSetbacks =
        widget.validationResult['setbacks'] ?? {};
    final Map<String, double> setbacks = rawSetbacks.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    final double buildableArea =
        (widget.validationResult['buildableArea'] as num).toDouble();
    final bool isValid = widget.validationResult['status'] == 'valid';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analysis Result",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: isValid
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isValid
                        ? "Compliant with Regulations"
                        : "Violations Detected",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isValid
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),

            // Visual View
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  PlotVisualView(
                    plotLength: length,
                    plotWidth: width,
                    setbacks: setbacks,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    "Plot Area",
                    "${(length * width).toStringAsFixed(1)} m²",
                  ),
                  _buildStatRow(
                    "Buildable Area",
                    "${buildableArea.toStringAsFixed(1)} m²",
                    isHighlight: true,
                  ),
                  _buildStatRow(
                    "Coverage",
                    "${((buildableArea / (length * width)) * 100).toStringAsFixed(1)} %",
                  ),
                ],
              ),
            ),

            const Divider(height: 32, thickness: 8, color: Color(0xFFF3F4F6)),

            // Suggestions
            PlotDesignSuggestions(suggestions: widget.suggestions),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Plot3DConceptScreen(
                              plotLength: length,
                              plotWidth: width,
                              floors: widget.plotData['floors'] ?? 1,
                              pincode: widget.plotData['city'] ?? '', // City field now contains pincode
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "View 3D Concept (Beta)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isRequestingAi ? null : () => _requestAiPreview(length, width),
                      icon: const Icon(Icons.auto_awesome),
                      label: _isRequestingAi
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Generate AI Design Preview (AI Concept)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _savePlot(context),
                      icon: const Icon(Icons.save_alt),
                      label: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE FOR REVIEW"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isHighlight
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAiPreview(double length, double width) async {
    setState(() => _isRequestingAi = true);
    
    try {
      final floors = (widget.plotData['floors'] ?? 1) as int;
      final styleStr = (widget.plotData['style'] ?? 'modern') as String;
      final locStr = (widget.plotData['locationContext'] ?? 'urban') as String;
      final budgetStr = (widget.plotData['budgetRange'] ?? 'medium') as String;
      final projectId = (widget.plotData['projectId'] ?? 'default-project') as String;

      AiStyle _parseStyle(String s) {
        switch (s) {
          case 'contemporary':
            return AiStyle.contemporary;
          case 'luxury':
            return AiStyle.luxury;
          default:
            return AiStyle.modern;
        }
      }

      LocationContext _parseLoc(String s) => 
          s == 'suburban' ? LocationContext.suburban : LocationContext.urban;
      
      BudgetRange _parseBudget(String s) => 
          s == 'low' ? BudgetRange.low : 
          (s == 'high' ? BudgetRange.high : BudgetRange.medium);

      final input = ConceptInput(
        plotLength: length.toDouble(),
        plotWidth: width.toDouble(),
        floors: floors,
        style: _parseStyle(styleStr),
        locationContext: _parseLoc(locStr),
        budgetRange: _parseBudget(budgetStr),
        projectId: projectId,
      );

      // Use enhanced AI service with Gemini integration
      final svc = AiConceptServiceEnhanced();
      final result = await svc.generateConcept(input);

      if (!mounted) return;

      // Show result dialog with AI-generated concept
      showDialog(
        context: context,
        builder: (_) => _AiConceptResultDialog(result: result),
      );
      
    } catch (e) {
      // This should never happen due to fallback, but just in case
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Concept generation failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingAi = false);
    }
  }
}


/// AI Concept Result Dialog
/// 
/// Displays the AI-generated architectural concept with:
/// - Building parameters
/// - Material recommendations
/// - Design notes
/// - Option to view in 3D
class _AiConceptResultDialog extends StatelessWidget {
  final AiConceptResult result;

  const _AiConceptResultDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: result.isFallback 
                          ? const Color(0xFFFEF3C7) 
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      result.isFallback ? Icons.auto_fix_high : Icons.auto_awesome,
                      color: result.isFallback 
                          ? const Color(0xFFD97706) 
                          : const Color(0xFF16A34A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.displayTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.generationSource,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Fallback warning (if applicable)
              if (result.isFallback) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI service unavailable. Showing auto-generated concept based on plot dimensions.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Building Info
              _InfoSection(
                title: 'Building Overview',
                items: [
                  _InfoItem(
                    label: 'Type',
                    value: result.buildingType.toUpperCase(),
                  ),
                  _InfoItem(
                    label: 'Dimensions',
                    value: '${result.buildingModel.buildingLength.toStringAsFixed(1)}m × ${result.buildingModel.buildingWidth.toStringAsFixed(1)}m',
                  ),
                  _InfoItem(
                    label: 'Floors',
                    value: '${result.buildingModel.floors} (${result.buildingModel.totalHeight}m total)',
                  ),
                  _InfoItem(
                    label: 'Floor Height',
                    value: '${result.buildingModel.floorHeight}m',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Design Details
              _InfoSection(
                title: 'Design Details',
                items: [
                  _InfoItem(
                    label: 'Facade Style',
                    value: result.buildingModel.facadeStyle.toUpperCase(),
                  ),
                  _InfoItem(
                    label: 'Roof Type',
                    value: result.buildingModel.roofType.toUpperCase(),
                  ),
                  _InfoItem(
                    label: 'Primary Material',
                    value: result.primaryMaterial.toUpperCase(),
                  ),
                  _InfoItem(
                    label: 'Secondary Material',
                    value: result.secondaryMaterial.toUpperCase(),
                  ),
                  _InfoItem(
                    label: 'Accent Color',
                    value: result.accentColor.toUpperCase(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Design Notes
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Design Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.designNotes,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Concept visualization only. Not for construction. Consult a licensed architect.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Plot3DConceptScreen(
                              plotLength: result.buildingModel.plotLength,
                              plotWidth: result.buildingModel.plotWidth,
                              floors: result.buildingModel.floors,
                              buildingModel: result.buildingModel,
                              pincode: '', // No pincode in AI-generated concepts
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text('View in 3D'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info Section Widget
class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

/// Info Item Data Class
class _InfoItem {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });
}
