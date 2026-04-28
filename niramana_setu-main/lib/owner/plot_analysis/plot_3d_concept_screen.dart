import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../common/three_d/building_model.dart';
import '../../common/three_d/three_d_html_generator.dart';
import '../../services/pincode_pricing_service.dart';

/// Enhanced 3D Concept Visualization Screen
/// 
/// This screen displays an interactive 3D building visualization using:
/// - Modular Three.js architecture (separated geometry, rendering, camera, interaction)
/// - Realistic lighting and materials
/// - Smooth gesture controls (rotate, zoom, pan)
/// - Data-driven geometry (responds to plot dimensions and floor count)
/// - AI-ready parameters (facade style, roof type, color palette)
/// 
/// Architecture:
/// - BuildingModel: Defines parametric geometry
/// - BuildingRenderer: Handles lighting, materials, scene setup
/// - CameraController: Manages camera and orbit controls
/// - InteractionController: Handles user interactions and animation loop
/// - ThreeDHtmlGenerator: Assembles everything into HTML
class Plot3DConceptScreen extends StatefulWidget {
  final double plotLength;
  final double plotWidth;
  final int floors;
  final BuildingModel? buildingModel; // Optional AI-generated model
  final String pincode; // Pincode for location-based pricing

  const Plot3DConceptScreen({
    super.key,
    required this.plotLength,
    required this.plotWidth,
    required this.floors,
    this.buildingModel, // Can be provided by AI service
    this.pincode = '', // Default empty if not provided
  });

  @override
  State<Plot3DConceptScreen> createState() => _Plot3DConceptScreenState();
}

class _Plot3DConceptScreenState extends State<Plot3DConceptScreen> {
  late final WebViewController _controller;
  late final BuildingModel _buildingModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Use AI-generated model if provided, otherwise create default
    _buildingModel = widget.buildingModel ?? BuildingModel(
      plotWidth: widget.plotWidth,
      plotLength: widget.plotLength,
      floors: widget.floors,
      floorHeight: 3.0, // Standard 3m per floor
      buildingFootprintRatio: 0.80, // 80% of plot
      setbackRatio: 0.10, // 10% setback
      // Default parameters
      facadeStyle: 'modern',
      roofType: 'flat',
      colorPalette: [0xfafafa, 0xf5f5f5, 0xf0f0f0], // White/gray tones
    );

    // Generate HTML using modular architecture
    final String htmlContent = ThreeDHtmlGenerator.generateHtml(_buildingModel);

    // Initialize WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8F1F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(htmlContent);
    
    debugPrint('Building Model: $_buildingModel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F5),
      appBar: AppBar(
        title: const Text(
          "3D Concept View (Beta)",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          // Info button to explain controls
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Controls',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('3D Controls'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🖱️ Drag to rotate'),
                      SizedBox(height: 8),
                      Text('🔍 Scroll/Pinch to zoom'),
                      SizedBox(height: 8),
                      Text('⌨️ Right-click to pan'),
                      SizedBox(height: 8),
                      Text('👆 Double-tap to reset view'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF136DEC)),
                  SizedBox(height: 16),
                  Text(
                    'Rendering 3D Concept...',
                    style: TextStyle(
                      color: Color(0xFF5C5C5C),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Safety Label Overlay
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Concept visualization only. Not for construction.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // Plot Info Overlay (Left Side)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF136DEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.architecture,
                          size: 18,
                          color: Color(0xFF136DEC),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Building Info',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Plot',
                    value: '${widget.plotLength}m × ${widget.plotWidth}m',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Building',
                    value: '${_buildingModel.buildingLength.toStringAsFixed(1)}m × ${_buildingModel.buildingWidth.toStringAsFixed(1)}m',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Floors',
                    value: '${widget.floors} (${_buildingModel.totalHeight}m)',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Style',
                    value: _buildingModel.facadeStyle.toUpperCase(),
                  ),
                ],
              ),
            ),
          ),

          // Market Price Info (Right Side - Minimal & Transparent)
          Positioned(
            top: 16,
            right: 16,
            child: _MarketPricePanel(
              buildingModel: _buildingModel,
              pincode: widget.pincode,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row widget for building details
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Market Price Panel - Minimal & Transparent (No Background)
class _MarketPricePanel extends StatelessWidget {
  final BuildingModel buildingModel;
  final String pincode;

  const _MarketPricePanel({
    required this.buildingModel,
    required this.pincode,
  });

  // Get pricing info based on pincode
  PricingInfo get _pricingInfo {
    if (pincode.isEmpty || pincode.length != 6) {
      return PricingInfo(
        ratePerSqFt: 2500.0,
        locationName: 'Default',
        cityTier: 'Tier 2',
      );
    }
    return PincodePricingService.getPricingByPincode(pincode);
  }

  double get _totalAreaSqM {
    return buildingModel.buildingWidth * buildingModel.buildingLength * buildingModel.floors;
  }

  double get _totalAreaSqFt {
    return _totalAreaSqM * 10.764;
  }

  double get _estimatedPrice {
    return _totalAreaSqFt * _pricingInfo.ratePerSqFt;
  }

  String _formatPrice(double price) {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹${price.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Change this to true for "Sold" status
    final bool isSold = false;
    final pricingInfo = _pricingInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Location info (if pincode provided)
        if (pincode.isNotEmpty && pincode.length == 6) ...[
          Text(
            pricingInfo.locationName,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF136DEC),
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pricingInfo.cityTier,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Dimensions - Simple text with shadow for visibility
        Text(
          '${buildingModel.buildingWidth.toStringAsFixed(1)}m × ${buildingModel.buildingLength.toStringAsFixed(1)}m',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.75),
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Height
        Text(
          '${buildingModel.totalHeight.toStringAsFixed(1)}m height',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.65),
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Square Footage
        Text(
          '${_totalAreaSqFt.toStringAsFixed(0)} sq ft',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.65),
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Rate per sq ft
        Text(
          '₹${pricingInfo.ratePerSqFt.toStringAsFixed(0)}/sq ft',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Price - Emphasized
        Text(
          _formatPrice(_estimatedPrice),
          style: TextStyle(
            fontSize: 18,
            color: const Color(0xFF136DEC),
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.95),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Status Badge - Sold or Buy (minimal background)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSold 
                ? Colors.red.withOpacity(0.15)
                : const Color(0xFF10B981).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSold 
                  ? Colors.red.withOpacity(0.5)
                  : const Color(0xFF10B981).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            isSold ? 'SOLD' : 'BUY',
            style: TextStyle(
              fontSize: 11,
              color: isSold ? Colors.red[700] : const Color(0xFF10B981),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
