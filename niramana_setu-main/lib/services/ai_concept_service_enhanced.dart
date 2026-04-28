import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_concept_models.dart';
import '../common/three_d/building_model.dart';

/// Enhanced AI Concept Service with Gemini Integration
/// 
/// This service generates architectural concepts using Google's Gemini API.
/// It provides:
/// - Structured architectural recommendations (not images)
/// - Fallback mode for offline/failed scenarios
/// - Proper error handling (never crashes the app)
/// - Local 3D preview generation
/// 
/// Why Gemini?
/// - Generates structured architectural data (not images)
/// - Fast response times
/// - Cost-effective
/// - Reliable API
/// 
/// What it does NOT do:
/// - Generate photorealistic renders (that requires specialized AI models)
/// - Create actual 3D models (we use local Three.js for that)
/// - Make construction decisions (concept only)
class AiConceptServiceEnhanced {
  // TODO: Replace with your actual Gemini API key
  // Get it from: https://makersuite.google.com/app/apikey
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  /// Generate architectural concept using Gemini AI
  /// 
  /// This method:
  /// 1. Sends plot data to Gemini
  /// 2. Receives structured architectural recommendations
  /// 3. Converts to BuildingModel for 3D visualization
  /// 4. Falls back to default concept if API fails
  /// 
  /// Parameters:
  /// - input: Plot dimensions, floors, style preferences
  /// 
  /// Returns:
  /// - AiConceptResult with building parameters and metadata
  Future<AiConceptResult> generateConcept(ConceptInput input) async {
    try {
      // Check if API key is configured
      if (_geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' || _geminiApiKey.isEmpty) {
        print('⚠️ Gemini API key not configured. Using fallback concept.');
        return _generateFallbackConcept(input, 'API key not configured');
      }
      
      // Build prompt for Gemini
      final String prompt = _buildArchitecturalPrompt(input);
      
      // Call Gemini API with timeout
      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Gemini API timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        
        if (text != null && text.isNotEmpty) {
          // Parse Gemini response into structured concept
          return _parseGeminiResponse(text, input);
        } else {
          print('⚠️ Empty response from Gemini. Using fallback.');
          return _generateFallbackConcept(input, 'Empty API response');
        }
      } else {
        print('⚠️ Gemini API error: ${response.statusCode}. Using fallback.');
        return _generateFallbackConcept(input, 'API error: ${response.statusCode}');
      }
      
    } catch (e) {
      // Network errors, timeouts, parsing errors - all handled gracefully
      print('⚠️ AI concept generation failed: $e. Using fallback.');
      return _generateFallbackConcept(input, e.toString());
    }
  }
  
  /// Build architectural prompt for Gemini
  /// 
  /// This creates a structured prompt that guides Gemini to return
  /// architectural recommendations in a parseable format.
  String _buildArchitecturalPrompt(ConceptInput input) {
    final styleDesc = _getStyleDescription(input.style);
    final locationDesc = _getLocationDescription(input.locationContext);
    final budgetDesc = _getBudgetDescription(input.budgetRange);
    
    return '''
You are an expert architect. Generate a structured architectural concept for a building with these specifications:

PLOT SPECIFICATIONS:
- Dimensions: ${input.plotLength}m × ${input.plotWidth}m
- Total Area: ${(input.plotLength * input.plotWidth).toStringAsFixed(1)} m²
- Number of Floors: ${input.floors}
- Style Preference: $styleDesc
- Location Context: $locationDesc
- Budget Range: $budgetDesc

TASK:
Provide architectural recommendations in this EXACT format (use | as separator):

BUILDING_TYPE: [residential/commercial/mixed-use]
FACADE_STYLE: [modern/contemporary/traditional/minimalist]
ROOF_TYPE: [flat/sloped/terrace/mixed]
PRIMARY_MATERIAL: [concrete/brick/glass/steel/wood]
SECONDARY_MATERIAL: [glass/metal/stone/wood]
ACCENT_COLOR: [color name]
FLOOR_HEIGHT: [2.8-3.5 meters]
SETBACK_RATIO: [0.05-0.15]
FOOTPRINT_RATIO: [0.70-0.90]
DESIGN_NOTES: [brief architectural notes, max 100 words]

Provide realistic, buildable recommendations based on the specifications.
''';
  }
  
  /// Parse Gemini's text response into structured concept
  /// 
  /// This extracts architectural parameters from Gemini's response
  /// and creates a BuildingModel for 3D visualization.
  AiConceptResult _parseGeminiResponse(String text, ConceptInput input) {
    try {
      // Extract parameters using regex patterns
      final buildingType = _extractValue(text, 'BUILDING_TYPE') ?? 'residential';
      final facadeStyle = _extractValue(text, 'FACADE_STYLE') ?? 'modern';
      final roofType = _extractValue(text, 'ROOF_TYPE') ?? 'flat';
      final primaryMaterial = _extractValue(text, 'PRIMARY_MATERIAL') ?? 'concrete';
      final secondaryMaterial = _extractValue(text, 'SECONDARY_MATERIAL') ?? 'glass';
      final accentColor = _extractValue(text, 'ACCENT_COLOR') ?? 'white';
      final floorHeight = double.tryParse(_extractValue(text, 'FLOOR_HEIGHT') ?? '3.0') ?? 3.0;
      final setbackRatio = double.tryParse(_extractValue(text, 'SETBACK_RATIO') ?? '0.10') ?? 0.10;
      final footprintRatio = double.tryParse(_extractValue(text, 'FOOTPRINT_RATIO') ?? '0.80') ?? 0.80;
      final designNotes = _extractValue(text, 'DESIGN_NOTES') ?? 'AI-generated architectural concept';
      
      // Convert to color palette
      final colorPalette = _getColorPaletteForMaterial(primaryMaterial, accentColor);
      
      // Create BuildingModel with AI parameters
      final buildingModel = BuildingModel(
        plotWidth: input.plotWidth,
        plotLength: input.plotLength,
        floors: input.floors,
        floorHeight: floorHeight.clamp(2.8, 3.5),
        buildingFootprintRatio: footprintRatio.clamp(0.70, 0.90),
        setbackRatio: setbackRatio.clamp(0.05, 0.15),
        facadeStyle: facadeStyle,
        roofType: roofType,
        colorPalette: colorPalette,
      );
      
      return AiConceptResult(
        buildingModel: buildingModel,
        buildingType: buildingType,
        primaryMaterial: primaryMaterial,
        secondaryMaterial: secondaryMaterial,
        accentColor: accentColor,
        designNotes: designNotes,
        isAiGenerated: true,
        isFallback: false,
        generationSource: 'Gemini AI',
      );
      
    } catch (e) {
      print('⚠️ Failed to parse Gemini response: $e. Using fallback.');
      return _generateFallbackConcept(input, 'Parse error: $e');
    }
  }
  
  /// Extract value from Gemini response
  String? _extractValue(String text, String key) {
    final pattern = RegExp('$key:\\s*\\[?([^\\]\\n]+)\\]?', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }
  
  /// Generate fallback concept when AI fails
  /// 
  /// This creates a sensible default concept based on plot size
  /// and floor count. Always works, even offline.
  AiConceptResult _generateFallbackConcept(ConceptInput input, String reason) {
    // Determine building type based on floors
    final buildingType = input.floors <= 2 ? 'residential' : 
                        input.floors <= 4 ? 'mixed-use' : 'commercial';
    
    // Determine style based on input preference
    final facadeStyle = input.style == AiStyle.modern ? 'modern' :
                       input.style == AiStyle.contemporary ? 'contemporary' : 'luxury';
    
    // Calculate optimal parameters based on plot size
    final plotArea = input.plotLength * input.plotWidth;
    final footprintRatio = plotArea < 100 ? 0.85 : plotArea < 200 ? 0.80 : 0.75;
    final setbackRatio = input.locationContext == LocationContext.urban ? 0.08 : 0.12;
    
    // Default color palette (neutral modern)
    final colorPalette = [0xfafafa, 0xf5f5f5, 0xe8e8e8];
    
    final buildingModel = BuildingModel(
      plotWidth: input.plotWidth,
      plotLength: input.plotLength,
      floors: input.floors,
      floorHeight: 3.0,
      buildingFootprintRatio: footprintRatio,
      setbackRatio: setbackRatio,
      facadeStyle: facadeStyle,
      roofType: 'flat',
      colorPalette: colorPalette,
    );
    
    return AiConceptResult(
      buildingModel: buildingModel,
      buildingType: buildingType,
      primaryMaterial: 'concrete',
      secondaryMaterial: 'glass',
      accentColor: 'white',
      designNotes: 'Auto-generated concept based on plot dimensions and floor count. '
                  'This is a fallback design created when AI service is unavailable.',
      isAiGenerated: false,
      isFallback: true,
      generationSource: 'Local Fallback',
      fallbackReason: reason,
    );
  }
  
  /// Get color palette based on material and accent
  List<int> _getColorPaletteForMaterial(String material, String accent) {
    switch (material.toLowerCase()) {
      case 'concrete':
        return [0xf5f5f5, 0xe8e8e8, 0xd0d0d0];
      case 'brick':
        return [0xd4a574, 0xc89563, 0xb87d52];
      case 'glass':
        return [0xe0f2f7, 0xb3e5fc, 0x81d4fa];
      case 'steel':
        return [0xe0e0e0, 0xbdbdbd, 0x9e9e9e];
      case 'wood':
        return [0xd7ccc8, 0xbcaaa4, 0xa1887f];
      default:
        return [0xfafafa, 0xf5f5f5, 0xe8e8e8];
    }
  }
  
  String _getStyleDescription(AiStyle style) {
    switch (style) {
      case AiStyle.modern:
        return 'Modern (clean lines, minimalist, functional)';
      case AiStyle.contemporary:
        return 'Contemporary (current trends, mixed materials, innovative)';
      case AiStyle.luxury:
        return 'Luxury (premium materials, elegant details, sophisticated)';
    }
  }
  
  String _getLocationDescription(LocationContext context) {
    switch (context) {
      case LocationContext.urban:
        return 'Urban (city center, high density, vertical emphasis)';
      case LocationContext.suburban:
        return 'Suburban (residential area, moderate density, horizontal spread)';
    }
  }
  
  String _getBudgetDescription(BudgetRange budget) {
    switch (budget) {
      case BudgetRange.low:
        return 'Budget-conscious (cost-effective materials, simple design)';
      case BudgetRange.medium:
        return 'Moderate (balanced quality and cost, standard materials)';
      case BudgetRange.high:
        return 'Premium (high-quality materials, custom details)';
    }
  }
}

/// AI Concept Result
/// 
/// Contains the generated architectural concept with all parameters
/// needed for 3D visualization and display.
class AiConceptResult {
  final BuildingModel buildingModel;
  final String buildingType;
  final String primaryMaterial;
  final String secondaryMaterial;
  final String accentColor;
  final String designNotes;
  final bool isAiGenerated;
  final bool isFallback;
  final String generationSource;
  final String? fallbackReason;
  
  AiConceptResult({
    required this.buildingModel,
    required this.buildingType,
    required this.primaryMaterial,
    required this.secondaryMaterial,
    required this.accentColor,
    required this.designNotes,
    required this.isAiGenerated,
    required this.isFallback,
    required this.generationSource,
    this.fallbackReason,
  });
  
  /// Get display title for the concept
  String get displayTitle {
    if (isFallback) {
      return 'Auto-Generated Concept';
    } else {
      return 'AI-Generated Concept';
    }
  }
  
  /// Get display subtitle
  String get displaySubtitle {
    return '$buildingType • ${buildingModel.floors} floors • $primaryMaterial & $secondaryMaterial';
  }
}
