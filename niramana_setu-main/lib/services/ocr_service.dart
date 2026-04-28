import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// OCR Service for extracting bill data from images
/// Uses Google ML Kit for text recognition
class OCRService {
  static TextRecognizer? _textRecognizerInstance;
  
  static TextRecognizer get _textRecognizer {
    _textRecognizerInstance ??= TextRecognizer();
    return _textRecognizerInstance!;
  }

  /// Extract text from image
  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR failed: $e');
    } finally {
      // Note: Don't close the recognizer if it's static and reused
    }
  }

  /// Extract structured bill data from image
  /// Returns a map with extracted fields
  static Future<Map<String, dynamic>> extractBillDataFromImage(File imageFile) async {
    try {
      final text = await extractTextFromImage(imageFile);
      
      // Parse text to extract bill information
      // This is a basic implementation - can be enhanced with ML models
      final extractedData = <String, dynamic>{
        'rawText': text,
        'billNumber': _extractBillNumber(text),
        'vendorName': _extractVendorName(text),
        'gstin': _extractGSTIN(text),
        'amount': _extractAmount(text),
        'gstRate': _extractGSTRate(text),
        'cgst': _extractCGST(text),
        'sgst': _extractSGST(text),
        'igst': _extractIGST(text),
        'date': _extractDate(text),
      };

      return extractedData;
    } catch (e) {
      // Return empty data on failure - allow manual entry
      return {
        'rawText': '',
        'error': e.toString(),
      };
    }
  }

  /// Pick image from gallery or camera
  static Future<File?> pickBillImage({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Helper methods for text extraction

  static String? _extractBillNumber(String text) {
    // Look for patterns like "Bill No:", "Invoice No:", etc.
    final patterns = [
      RegExp(r'Bill\s*[#:]?\s*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'Invoice\s*[#:]?\s*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'Bill\s*No[.:]\s*([A-Z0-9\-]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  static String? _extractVendorName(String text) {
    // Look for company/vendor name patterns (usually at the top)
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      // Usually vendor name is in first few lines
      for (int i = 0; i < lines.length.clamp(0, 5); i++) {
        final line = lines[i].trim();
        // Skip common headers
        if (!line.toLowerCase().contains('bill') &&
            !line.toLowerCase().contains('invoice') &&
            !line.toLowerCase().contains('gst') &&
            line.length > 3) {
          return line;
        }
      }
    }
    return null;
  }

  static String? _extractGSTIN(String text) {
    // GSTIN is 15 characters alphanumeric
    final pattern = RegExp(r'\b([0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[0-9A-Z]{1}[Z]{1}[0-9A-Z]{1})\b');
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  static double? _extractAmount(String text) {
    // Look for total amount patterns
    final patterns = [
      RegExp(r'Total[:\s]+₹?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Grand\s*Total[:\s]+₹?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Amount[:\s]+₹?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }
    return null;
  }

  static double? _extractGSTRate(String text) {
    // Look for GST rate percentages
    final pattern = RegExp(r'GST[:\s]+(\d+(?:\.\d+)?)\s*%', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  static double? _extractCGST(String text) {
    final pattern = RegExp(r'CGST[:\s]+₹?\s*([\d,]+\.?\d*)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return amountStr != null ? double.tryParse(amountStr) : null;
    }
    return null;
  }

  static double? _extractSGST(String text) {
    final pattern = RegExp(r'SGST[:\s]+₹?\s*([\d,]+\.?\d*)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return amountStr != null ? double.tryParse(amountStr) : null;
    }
    return null;
  }

  static double? _extractIGST(String text) {
    final pattern = RegExp(r'IGST[:\s]+₹?\s*([\d,]+\.?\d*)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return amountStr != null ? double.tryParse(amountStr) : null;
    }
    return null;
  }

  static DateTime? _extractDate(String text) {
    // Look for date patterns
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      RegExp(r'Date[:\s]+(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 3) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          final fullYear = year < 100 ? 2000 + year : year;
          return DateTime(fullYear, month, day);
        } catch (e) {
          // Continue to next pattern
        }
      }
    }
    return null;
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _textRecognizerInstance?.close();
    _textRecognizerInstance = null;
  }
}
