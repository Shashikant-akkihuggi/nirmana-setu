import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../services/user_service.dart';

/// Widget to display user's public ID in profile sections
/// Supports offline caching and copy functionality
class PublicIdDisplay extends StatefulWidget {
  final String label;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsets? padding;
  final bool showCopyButton;

  const PublicIdDisplay({
    super.key,
    required this.label,
    this.labelStyle,
    this.valueStyle,
    this.padding,
    this.showCopyButton = true,
  });

  @override
  State<PublicIdDisplay> createState() => _PublicIdDisplayState();
}

class _PublicIdDisplayState extends State<PublicIdDisplay> {
  String? _publicId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPublicId();
  }

  Future<void> _loadPublicId() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _publicId = user?.generatedId;
          _isLoading = false;
          _error = user == null ? 'Failed to load ID' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ID';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_publicId != null) {
      Clipboard.setData(ClipboardData(text: _publicId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.label} copied to clipboard'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  widget.label,
                  style: widget.labelStyle ?? const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Value Row
                Row(
                  children: [
                    Expanded(
                      child: _buildValueWidget(),
                    ),
                    if (widget.showCopyButton && _publicId != null) ...[
                      const SizedBox(width: 8),
                      _buildCopyButton(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueWidget() {
    if (_isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF136DEC),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: widget.valueStyle ?? const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Text(
            _error!,
            style: widget.valueStyle ?? const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onLongPress: _copyToClipboard,
      child: SelectableText(
        _publicId ?? 'Not available',
        style: widget.valueStyle ?? const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCopyButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF136DEC).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF136DEC).withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.copy,
            size: 16,
            color: Color(0xFF136DEC),
          ),
        ),
      ),
    );
  }
}

/// Simplified version for inline display
class InlinePublicIdDisplay extends StatefulWidget {
  final String prefix;
  final TextStyle? style;
  final bool showIcon;
  final String? publicId; // Optional: if provided, use this instead of fetching
  final String? role; // Optional: for display purposes

  const InlinePublicIdDisplay({
    super.key,
    this.prefix = 'ID: ',
    this.style,
    this.showIcon = true,
    this.publicId,
    this.role,
  });

  @override
  State<InlinePublicIdDisplay> createState() => _InlinePublicIdDisplayState();
}

class _InlinePublicIdDisplayState extends State<InlinePublicIdDisplay> {
  String? _publicId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicId();
  }

  Future<void> _loadPublicId() async {
    // If publicId is provided directly, use it
    if (widget.publicId != null) {
      if (mounted) {
        setState(() {
          _publicId = widget.publicId;
          _isLoading = false;
        });
      }
      return;
    }

    // Otherwise, fetch from UserService
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _publicId = user?.generatedId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '${widget.prefix}Loading...',
            style: widget.style ?? const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          const Icon(
            Icons.badge,
            size: 12,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          '${widget.prefix}${_publicId ?? 'N/A'}',
          style: widget.style ?? const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}