/// Pincode-based Pricing Service
/// 
/// Determines construction cost per square foot based on Indian pincodes.
/// Prices vary by city tier and region (2026 estimates).
class PincodePricingService {
  /// Get construction rate per sq ft based on pincode
  /// Returns rate in INR and location name
  static PricingInfo getPricingByPincode(String pincode) {
    // Validate pincode
    if (pincode.length != 6) {
      return PricingInfo(
        ratePerSqFt: 2500.0,
        locationName: 'Unknown',
        cityTier: 'Tier 2',
      );
    }

    // Extract first 3 digits to determine region
    final prefix = pincode.substring(0, 3);
    final prefixInt = int.tryParse(prefix) ?? 0;

    // Metro Cities (Tier 1) - Higher rates
    if (_isMetroCity(prefixInt)) {
      return _getMetroCityPricing(prefixInt);
    }
    
    // Tier 2 Cities - Medium rates
    if (_isTier2City(prefixInt)) {
      return _getTier2CityPricing(prefixInt);
    }
    
    // Tier 3 / Rural - Lower rates
    return PricingInfo(
      ratePerSqFt: 1800.0,
      locationName: 'Tier 3 / Rural Area',
      cityTier: 'Tier 3',
    );
  }

  /// Check if pincode belongs to metro city
  static bool _isMetroCity(int prefix) {
    // Mumbai: 400xxx
    if (prefix >= 400 && prefix <= 402) return true;
    
    // Delhi NCR: 110xxx, 121xxx, 122xxx, 201xxx
    if (prefix >= 110 && prefix <= 111) return true;
    if (prefix >= 121 && prefix <= 122) return true;
    if (prefix >= 201 && prefix <= 203) return true;
    
    // Bangalore: 560xxx
    if (prefix >= 560 && prefix <= 562) return true;
    
    // Hyderabad: 500xxx
    if (prefix >= 500 && prefix <= 502) return true;
    
    // Chennai: 600xxx
    if (prefix >= 600 && prefix <= 603) return true;
    
    // Kolkata: 700xxx
    if (prefix >= 700 && prefix <= 702) return true;
    
    // Pune: 411xxx
    if (prefix >= 411 && prefix <= 412) return true;
    
    return false;
  }

  /// Check if pincode belongs to tier 2 city
  static bool _isTier2City(int prefix) {
    // Ahmedabad: 380xxx
    if (prefix >= 380 && prefix <= 382) return true;
    
    // Jaipur: 302xxx
    if (prefix >= 302 && prefix <= 303) return true;
    
    // Lucknow: 226xxx
    if (prefix >= 226 && prefix <= 227) return true;
    
    // Chandigarh: 160xxx
    if (prefix >= 160 && prefix <= 161) return true;
    
    // Kochi: 682xxx
    if (prefix >= 682 && prefix <= 683) return true;
    
    // Indore: 452xxx
    if (prefix >= 452 && prefix <= 453) return true;
    
    // Bhopal: 462xxx
    if (prefix >= 462 && prefix <= 463) return true;
    
    // Coimbatore: 641xxx
    if (prefix >= 641 && prefix <= 642) return true;
    
    // Visakhapatnam: 530xxx
    if (prefix >= 530 && prefix <= 531) return true;
    
    // Nagpur: 440xxx
    if (prefix >= 440 && prefix <= 441) return true;
    
    return false;
  }

  /// Get pricing for metro cities
  static PricingInfo _getMetroCityPricing(int prefix) {
    // Mumbai - Highest rates
    if (prefix >= 400 && prefix <= 402) {
      return PricingInfo(
        ratePerSqFt: 3500.0,
        locationName: 'Mumbai',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Delhi NCR - Very high rates
    if ((prefix >= 110 && prefix <= 111) || 
        (prefix >= 121 && prefix <= 122) || 
        (prefix >= 201 && prefix <= 203)) {
      return PricingInfo(
        ratePerSqFt: 3200.0,
        locationName: 'Delhi NCR',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Bangalore - High rates
    if (prefix >= 560 && prefix <= 562) {
      return PricingInfo(
        ratePerSqFt: 3000.0,
        locationName: 'Bangalore',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Hyderabad
    if (prefix >= 500 && prefix <= 502) {
      return PricingInfo(
        ratePerSqFt: 2800.0,
        locationName: 'Hyderabad',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Chennai
    if (prefix >= 600 && prefix <= 603) {
      return PricingInfo(
        ratePerSqFt: 2800.0,
        locationName: 'Chennai',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Kolkata
    if (prefix >= 700 && prefix <= 702) {
      return PricingInfo(
        ratePerSqFt: 2600.0,
        locationName: 'Kolkata',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Pune
    if (prefix >= 411 && prefix <= 412) {
      return PricingInfo(
        ratePerSqFt: 2900.0,
        locationName: 'Pune',
        cityTier: 'Metro (Tier 1)',
      );
    }
    
    // Default metro
    return PricingInfo(
      ratePerSqFt: 2800.0,
      locationName: 'Metro City',
      cityTier: 'Metro (Tier 1)',
    );
  }

  /// Get pricing for tier 2 cities
  static PricingInfo _getTier2CityPricing(int prefix) {
    String cityName = 'Tier 2 City';
    
    if (prefix >= 380 && prefix <= 382) cityName = 'Ahmedabad';
    else if (prefix >= 302 && prefix <= 303) cityName = 'Jaipur';
    else if (prefix >= 226 && prefix <= 227) cityName = 'Lucknow';
    else if (prefix >= 160 && prefix <= 161) cityName = 'Chandigarh';
    else if (prefix >= 682 && prefix <= 683) cityName = 'Kochi';
    else if (prefix >= 452 && prefix <= 453) cityName = 'Indore';
    else if (prefix >= 462 && prefix <= 463) cityName = 'Bhopal';
    else if (prefix >= 641 && prefix <= 642) cityName = 'Coimbatore';
    else if (prefix >= 530 && prefix <= 531) cityName = 'Visakhapatnam';
    else if (prefix >= 440 && prefix <= 441) cityName = 'Nagpur';
    
    return PricingInfo(
      ratePerSqFt: 2200.0,
      locationName: cityName,
      cityTier: 'Tier 2',
    );
  }
}

/// Pricing information data class
class PricingInfo {
  final double ratePerSqFt;
  final String locationName;
  final String cityTier;

  PricingInfo({
    required this.ratePerSqFt,
    required this.locationName,
    required this.cityTier,
  });

  @override
  String toString() {
    return 'PricingInfo(₹$ratePerSqFt/sq ft, $locationName, $cityTier)';
  }
}
