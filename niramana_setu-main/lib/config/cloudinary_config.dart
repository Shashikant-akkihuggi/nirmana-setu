/// Cloudinary Configuration
/// 
/// Production credentials for Niramana Setu DPR image uploads
class CloudinaryConfig {
  // Production Cloudinary cloud name
  static const String cloudName = 'df7vsrq2s';
  
  // Unsigned upload preset for mobile app uploads
  static const String uploadPreset = 'niramana_unsigned';
  
  // Base URL for Cloudinary uploads
  static const String apiBaseUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  /// Check if Cloudinary is properly configured
  static bool get isConfigured {
    return cloudName.isNotEmpty && 
           uploadPreset.isNotEmpty &&
           cloudName != 'your-cloud-name' && 
           uploadPreset != 'your-upload-preset';
  }
}