import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/notification_service.dart';

// In-app Notifications for Niramana Setu
// - Real-time Firestore notifications
// - Badge helpers
// - Glassmorphism list UI

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: StreamBuilder<List<AppNotification>>(
              stream: NotificationService.getUserNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF136DEC)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      onTap: () async {
                        if (!notification.isRead) {
                          await NotificationService.markAsRead(notification.id);
                        }
                        // TODO: Handle notification action based on type
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  Color get typeColor {
    switch (notification.type.toLowerCase()) {
      case 'project_assignment':
      case 'project_update':
        return const Color(0xFF2563EB);
      case 'dpr_approval':
      case 'dpr_review':
        return const Color(0xFF7C3AED);
      case 'material_request':
      case 'material_approval':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get typeIcon {
    switch (notification.type.toLowerCase()) {
      case 'project_assignment':
      case 'project_update':
        return Icons.folder;
      case 'dpr_approval':
      case 'dpr_review':
        return Icons.assignment;
      case 'material_request':
      case 'material_approval':
        return Icons.inventory;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: !notification.isRead ? 0.65 : 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: !notification.isRead 
                    ? const Color(0xFF136DEC).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: const Color(0xFF7A5AF8).withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF136DEC), Color(0xFF7A5AF8)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF136DEC).withValues(alpha: 0.25), blurRadius: 14),
                        ],
                      ),
                      child: Icon(typeIcon, color: Colors.white),
                    ),
                    if (!notification.isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 12,
                          width: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.35), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: !notification.isRead ? FontWeight.w800 : FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: typeColor.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              notification.type.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRelative(notification.createdAt),
                            style: const TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF136DEC), Color(0xFF7A5AF8), Colors.white]
              .map((c) => c.withValues(alpha: 0.12))
              .toList(),
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

// Badge helpers for backward compatibility
int getUnreadCount({String? role}) {
  // This should now use StreamBuilder in the UI
  // Return 0 as default for any remaining hardcoded calls
  return 0;
}

void markAllRead({String? role}) {
  // This is now handled by NotificationService.markAllAsRead()
  // Keep empty for backward compatibility
}

String formatRelative(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${t.day.toString().padLeft(2, '0')}-${t.month.toString().padLeft(2, '0')}-${t.year}';
}

// Usage notes:
// - To open the center: Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
// - To show a badge on dashboards: use StreamBuilder with NotificationService.getUnreadNotificationsCount()