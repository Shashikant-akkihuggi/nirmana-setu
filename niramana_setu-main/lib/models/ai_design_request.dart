/// Model for AI Design Request
class AiDesignRequest {
  final double plotLength;
  final double plotWidth;
  final int floors;
  final double coverage;
  final double buildableArea;
  final String orientation;
  final DateTime timestamp;
  final String? cityOrRegion;

  AiDesignRequest({
    required this.plotLength,
    required this.plotWidth,
    required this.floors,
    required this.coverage,
    required this.buildableArea,
    required this.orientation,
    required this.timestamp,
    this.cityOrRegion,
  });
}
