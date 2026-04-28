import 'package:flutter/material.dart';
import '../../services/user_service.dart';

/// Widget that displays a user's name by fetching it from Firestore using their UID
/// Handles loading states and graceful fallbacks
class UserDisplayWidget extends StatefulWidget {
  final String uid;
  final String fallbackText;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool showIcon;

  const UserDisplayWidget({
    super.key,
    required this.uid,
    this.fallbackText = 'Unknown User',
    this.textStyle,
    this.icon,
    this.showIcon = false,
  });

  @override
  State<UserDisplayWidget> createState() => _UserDisplayWidgetState();
}

class _UserDisplayWidgetState extends State<UserDisplayWidget> {
  String? _displayName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  @override
  void didUpdateWidget(UserDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _fetchUserName();
    }
  }

  Future<void> _fetchUserName() async {
    if (widget.uid.isEmpty) {
      setState(() {
        _displayName = widget.fallbackText;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await UserService.getUserByUid(widget.uid);
      if (mounted) {
        setState(() {
          _displayName = userData?.fullName ?? widget.fallbackText;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayName = widget.fallbackText;
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
          if (widget.showIcon && widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 16,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon && widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 16,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            _displayName ?? widget.fallbackText,
            style: widget.textStyle ?? const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Widget that displays multiple users efficiently using batch fetching
class MultiUserDisplayWidget extends StatefulWidget {
  final List<String> uids;
  final String separator;
  final TextStyle? textStyle;
  final String fallbackText;

  const MultiUserDisplayWidget({
    super.key,
    required this.uids,
    this.separator = ', ',
    this.textStyle,
    this.fallbackText = 'Unknown Users',
  });

  @override
  State<MultiUserDisplayWidget> createState() => _MultiUserDisplayWidgetState();
}

class _MultiUserDisplayWidgetState extends State<MultiUserDisplayWidget> {
  Map<String, String> _userNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserNames();
  }

  @override
  void didUpdateWidget(MultiUserDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uids != widget.uids) {
      _fetchUserNames();
    }
  }

  Future<void> _fetchUserNames() async {
    if (widget.uids.isEmpty) {
      setState(() {
        _userNames = {};
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersData = await UserService.getUsersByUids(widget.uids);
      if (mounted) {
        setState(() {
          _userNames = usersData.map((uid, userData) => 
              MapEntry(uid, userData.fullName));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userNames = {};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
        ),
      );
    }

    final displayNames = widget.uids
        .map((uid) => _userNames[uid] ?? 'Unknown User')
        .toList();

    final displayText = displayNames.isEmpty 
        ? widget.fallbackText 
        : displayNames.join(widget.separator);

    return Text(
      displayText,
      style: widget.textStyle ?? const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}