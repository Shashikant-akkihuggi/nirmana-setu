import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';

class _GalleryTheme {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class OwnerGalleryScreen extends StatelessWidget {
  final String projectId;
  const OwnerGalleryScreen({super.key, required this.projectId});

  Stream<List<_GalleryItem>> _items() {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('dpr')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final List<_GalleryItem> items = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final images = List<String>.from(data['images'] ?? []);
            final uploadedAt = (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final workDescription = data['workDescription'] ?? '';
            
            // Create one gallery item per image
            for (int i = 0; i < images.length; i++) {
              items.add(_GalleryItem(
                photoId: images[i],
                date: _fmtDate(uploadedAt),
                description: workDescription,
                status: data['status'] ?? 'Pending',
                engineerNote: data['engineerComment'] ?? '',
                title: 'DPR - ${_fmtDate(uploadedAt)}',
              ));
            }
          }
          return items;
        });
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year;
    return '$dd-$mm-$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: Column(
              children: [
                // Header bar matching Owner Dashboard style
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                        color: const Color(0xFF1F1F1F),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Progress Gallery',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid - FIX: Responsive grid with better aspect ratio handling
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: StreamBuilder<List<_GalleryItem>>(
                      stream: _items(),
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? const <_GalleryItem>[];
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = constraints.maxWidth;
                            final crossAxisCount = screenWidth > 600 ? 3 : 2;
                            final childAspectRatio = screenWidth > 600 ? 0.85 : 0.82;
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) => _GalleryCard(item: items[i]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryItem {
  final String photoId; // image url
  final String date;
  final String description;
  final String status;
  final String engineerNote;
  final String title;
  _GalleryItem({
    required this.photoId,
    required this.date,
    required this.description,
    required this.status,
    required this.engineerNote,
    required this.title,
  });
}

class _GalleryCard extends StatelessWidget {
  final _GalleryItem item;
  const _GalleryCard({required this.item});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _FullScreenViewer(item: item)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: _GalleryTheme.accent.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image area - FIX: Better proportions
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.grey[300]),
                        // Image is kept simple to preserve layout; replace with Image.network without changing layout
                        // while maintaining fallback grey box if url is empty
                        if (item.photoId.isNotEmpty)
                          Image.network(item.photoId, fit: BoxFit.cover)
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
                // Content area - FIX: Better text layout and constraints
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and status row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(item.status).withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  color: _getStatusColor(item.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Description - FIX: Proper text overflow handling
                        Expanded(
                          child: Text(
                            item.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                              fontSize: 13,
                              height: 1.3, // Better line height for readability
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _FullScreenViewer extends StatelessWidget {
  final _GalleryItem item;
  const _FullScreenViewer({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
                            BoxShadow(color: _GalleryTheme.primary.withValues(alpha: 0.12), blurRadius: 26, spreadRadius: 1),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.grey[300]),
                            if (item.photoId.isNotEmpty)
                              Image.network(item.photoId, fit: BoxFit.cover)
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassBlock(
                    title: 'Description',
                    icon: Icons.description_rounded,
                    child: Text(item.description),
                  ),
                  const SizedBox(height: 10),
                  _GlassBlock(
                    title: 'Approval Date',
                    icon: Icons.event,
                    child: Text(item.date),
                  ),
                  const SizedBox(height: 10),
                  if (item.engineerNote.isNotEmpty)
                    _GlassBlock(
                      title: 'Engineer Note',
                      icon: Icons.comment_rounded,
                      child: Text(item.engineerNote),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _GalleryTheme.primary.withValues(alpha: 0.12),
            _GalleryTheme.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _GlassBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _GlassBlock({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF374151)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                ],
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: const TextStyle(color: Color(0xFF1F2937)),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
