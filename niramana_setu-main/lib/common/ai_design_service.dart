import 'package:hive/hive.dart';
import '../models/ai_design_request.dart';
import 'feature_flags.dart';

/// Service for AI-based house image generation
/// No UI code here. Backend API can be plugged in later.
class AiDesignService {
  static const String quotaBoxName = 'ai_design_quota';

  /// Returns true if AI generation is enabled
  bool isEnabled() => FeatureFlags.enableAIDesignGeneration;

  /// Returns true if user has quota left for today
  Future<bool> hasQuotaLeft(String userId) async {
    final box = await Hive.openBox<int>(quotaBoxName);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = '$userId-$today';
    final used = box.get(key, defaultValue: 0) ?? 0;
    return used < FeatureFlags.dailyAIDesignQuota;
  }

  /// Increments quota usage for today
  Future<void> incrementQuota(String userId) async {
    final box = await Hive.openBox<int>(quotaBoxName);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = '$userId-$today';
    final used = box.get(key, defaultValue: 0) ?? 0;
    await box.put(key, used + 1);
  }

  /// Builds the AI prompt from request
  String buildPrompt(AiDesignRequest req) {
    return '''Photorealistic modern residential house design based on the following constraints:
- Plot size: ${req.plotLength}m x ${req.plotWidth}m
- Floors: ${req.floors}
- Coverage: ${req.coverage}%
- Buildable area: ${req.buildableArea} sq.m
- Indian residential architecture
- Modern materials, realistic lighting
- Front elevation visible
- No text, no watermark
- White background, professional architectural render${req.cityOrRegion != null ? '\n- Location: ${req.cityOrRegion}' : ''}''';
  }

  /// Main entry: generates image if enabled, compliant, and quota available
  /// Returns image URL or base64 (stub for now)
  Future<String?> generateImage({
    required AiDesignRequest request,
    required bool isCompliant,
    required String userId,
  }) async {
    if (!isEnabled()) return null;
    if (!isCompliant) return null;
    if (!await hasQuotaLeft(userId)) return null;
    await incrementQuota(userId);
    // TODO: Integrate with backend API (Gemini/Cloud Functions)
    // For now, return a placeholder image URL
    return 'https://via.placeholder.com/512x384.png?text=AI+Design';
  }
}
