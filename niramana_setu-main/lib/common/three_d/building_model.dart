/// Building Model - Data-Driven 3D Geometry
/// 
/// This class defines the parametric building geometry that responds
/// to plot dimensions, floor count, and future AI-driven design parameters.
/// 
/// Why separate this?
/// - Clean separation of data from rendering
/// - Easy to modify dimensions without touching render code
/// - AI-ready: parameters can be injected from AI service
/// - Testable: geometry logic can be unit tested
class BuildingModel {
  // Core dimensions (from user input)
  final double plotWidth;
  final double plotLength;
  final int floors;
  
  // Configurable parameters (AI-ready)
  final double floorHeight;
  final double buildingFootprintRatio; // % of plot used
  final double setbackRatio; // Setback from plot edges
  
  // Future AI parameters (not implemented yet, but structured)
  final String facadeStyle; // 'modern', 'traditional', 'minimalist'
  final String roofType; // 'flat', 'sloped', 'terrace'
  final List<int> colorPalette; // RGB colors for exterior
  
  BuildingModel({
    required this.plotWidth,
    required this.plotLength,
    required this.floors,
    this.floorHeight = 3.0, // Standard 3m per floor
    this.buildingFootprintRatio = 0.80, // 80% of plot
    this.setbackRatio = 0.10, // 10% setback from edges
    this.facadeStyle = 'modern',
    this.roofType = 'flat',
    this.colorPalette = const [0xffffff, 0xf5f5f5, 0xe0e0e0], // White/gray tones
  });
  
  // Computed properties
  double get totalHeight => floors * floorHeight;
  double get buildingWidth => plotWidth * buildingFootprintRatio;
  double get buildingLength => plotLength * buildingFootprintRatio;
  double get setbackDistance => plotWidth * setbackRatio;
  
  // Building position (centered on plot)
  double get buildingOffsetX => 0.0;
  double get buildingOffsetZ => 0.0;
  
  /// Generate JavaScript object for Three.js
  /// 
  /// This creates a clean data structure that the renderer can consume.
  /// All geometry calculations happen here, not in the renderer.
  String toJavaScript() {
    return '''
    {
      // Plot dimensions
      plotWidth: $plotWidth,
      plotLength: $plotLength,
      
      // Building dimensions
      buildingWidth: $buildingWidth,
      buildingLength: $buildingLength,
      floors: $floors,
      floorHeight: $floorHeight,
      totalHeight: $totalHeight,
      
      // Positioning
      buildingOffsetX: $buildingOffsetX,
      buildingOffsetZ: $buildingOffsetZ,
      setbackDistance: $setbackDistance,
      
      // Style parameters (AI-ready)
      facadeStyle: '$facadeStyle',
      roofType: '$roofType',
      colorPalette: [${colorPalette.map((c) => '0x${c.toRadixString(16).padLeft(6, '0')}').join(', ')}],
      
      // Computed helpers
      buildingFootprintRatio: $buildingFootprintRatio,
      setbackRatio: $setbackRatio
    }
    ''';
  }
  
  /// Create a copy with modified parameters
  /// 
  /// Useful for AI-driven variations or user adjustments
  BuildingModel copyWith({
    double? plotWidth,
    double? plotLength,
    int? floors,
    double? floorHeight,
    double? buildingFootprintRatio,
    double? setbackRatio,
    String? facadeStyle,
    String? roofType,
    List<int>? colorPalette,
  }) {
    return BuildingModel(
      plotWidth: plotWidth ?? this.plotWidth,
      plotLength: plotLength ?? this.plotLength,
      floors: floors ?? this.floors,
      floorHeight: floorHeight ?? this.floorHeight,
      buildingFootprintRatio: buildingFootprintRatio ?? this.buildingFootprintRatio,
      setbackRatio: setbackRatio ?? this.setbackRatio,
      facadeStyle: facadeStyle ?? this.facadeStyle,
      roofType: roofType ?? this.roofType,
      colorPalette: colorPalette ?? this.colorPalette,
    );
  }
  
  @override
  String toString() {
    return 'BuildingModel(${plotWidth}m x ${plotLength}m, $floors floors, ${totalHeight}m height)';
  }
}
