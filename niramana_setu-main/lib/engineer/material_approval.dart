import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/material_request_service.dart';

class _ThemeMA {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class MaterialApprovalScreen extends StatefulWidget {
  const MaterialApprovalScreen({super.key});

  @override
  State<MaterialApprovalScreen> createState() => _MaterialApprovalScreenState();
}

class _MaterialApprovalScreenState extends State<MaterialApprovalScreen> {
  void _openDetail(MaterialRequestModel req) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ApprovalDetail(
          request: req,
          onDecision: (status, comment) async {
            print('🔍 MaterialApproval - Starting $status action for request: ${req.id}');
            try {
              await MaterialRequestService.updateMaterialRequestStatus(req.projectId, req.id, status, comment);
              print('✅ MaterialApproval - Successfully ${status} request: ${req.id}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request ${status} successfully')),
                );
              }
            } catch (e) {
              print('❌ MaterialApproval - Error ${status} request: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: Failed to $status request'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    final status = s.toLowerCase();
    switch (status) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Approvals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: StreamBuilder<List<MaterialRequestModel>>(
              stream: MaterialRequestService.getEngineerMaterialRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final materialRequests = snapshot.data ?? [];
                
                if (materialRequests.isEmpty) {
                  return const Center(
                    child: Text(
                      'No material requests to review',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: materialRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final req = materialRequests[i];
                    final c = _statusColor(req.status);
                    return GestureDetector(
                      onTap: () => _openDetail(req),
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
                                BoxShadow(color: _ThemeMA.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: [_ThemeMA.primary, _ThemeMA.accent]),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(req.material, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                                      const SizedBox(height: 4),
                                      Text('Qty: ${req.quantity}   •   Priority: ${req.priority}', style: const TextStyle(color: Color(0xFF4B5563))),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: c.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(req.status[0].toUpperCase() + req.status.substring(1), style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _ApprovalDetail extends StatelessWidget {
  final MaterialRequestModel request;
  final Future<void> Function(String status, String comment) onDecision;
  const _ApprovalDetail({required this.request, required this.onDecision});

  Color _statusColor(String s) {
    final status = s.toLowerCase();
    switch (status) {
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
    final c = _statusColor(request.status);
    final commentController = TextEditingController(text: request.comment);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
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
                            BoxShadow(color: _ThemeMA.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: [_ThemeMA.primary, _ThemeMA.accent]),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(request.material, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                                      const SizedBox(height: 4),
                                      Text('Quantity: ${request.quantity}', style: const TextStyle(color: Color(0xFF4B5563))),
                                      const SizedBox(height: 2),
                                      Text('Priority: ${request.priority}', style: const TextStyle(color: Color(0xFF4B5563))),
                                      const SizedBox(height: 2),
                                      Text('Needed by: ${request.dateNeeded.day.toString().padLeft(2, '0')}-${request.dateNeeded.month.toString().padLeft(2, '0')}-${request.dateNeeded.year}', style: const TextStyle(color: Color(0xFF4B5563))),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: c.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(request.status[0].toUpperCase() + request.status.substring(1), style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                            const SizedBox(height: 6),
                            Text(request.note.isEmpty ? '—' : request.note, style: const TextStyle(color: Color(0xFF1F2937))),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  ClipRRect(
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
                            const Text('Engineer Comment', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                            const SizedBox(height: 8),
                            TextField(
                              controller: commentController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Optional note for manager…',
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                      BoxShadow(color: _ThemeMA.accent.withValues(alpha: 0.18), blurRadius: 34, spreadRadius: 2),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            print('🔍 MaterialApproval - Approve button pressed for request: ${request.id}');
                            try {
                              await onDecision('approved', commentController.text.trim());
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              print('❌ MaterialApproval - Error in approve button handler: $e');
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            print('🔍 MaterialApproval - Reject button pressed for request: ${request.id}');
                            try {
                              await onDecision('rejected', commentController.text.trim());
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              print('❌ MaterialApproval - Error in reject button handler: $e');
                            }
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ),
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
            _ThemeMA.primary.withValues(alpha: 0.12),
            _ThemeMA.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
