import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/widgets/user_display_widget.dart';
import '../../owner/plot_analysis/plot_rules_service.dart';
import '../../owner/plot_analysis/plot_visual_view.dart';

class PlotReviewScreen extends StatefulWidget {
  const PlotReviewScreen({super.key});

  @override
  State<PlotReviewScreen> createState() => _PlotReviewScreenState();
}

class _PlotReviewScreenState extends State<PlotReviewScreen> {
  final _service = PlotRulesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pending Plot Reviews",
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getPendingReviews(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No pending reviews."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    "Plot: ${data['city'] ?? 'Unknown City'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Area: ${(data['length'] ?? 0) * (data['width'] ?? 0)} m²"),
                      Row(
                        children: [
                          const Text("Owner: "),
                          UserDisplayWidget(
                            uid: data['ownerId'] ?? '',
                            fallbackText: 'Unknown Owner',
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Pending Review",
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _ReviewDetailScreen(
                          plotId: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewDetailScreen extends StatefulWidget {
  final String plotId;
  final Map<String, dynamic> data;

  const _ReviewDetailScreen({required this.plotId, required this.data});

  @override
  State<_ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<_ReviewDetailScreen> {
  final _service = PlotRulesService();
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview(bool isApproved) async {
    if (_remarksController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add remarks before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.submitEngineerReview(
        plotId: widget.plotId,
        isApproved: isApproved,
        remarks: _remarksController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isApproved ? 'Approved successfully' : 'Rejected')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.data['analysis'] as Map<String, dynamic>? ?? {};
    final rawSetbacks = analysis['setbacks'] as Map<String, dynamic>? ?? {};
    final setbacks = rawSetbacks.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Plot", style: TextStyle(color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual
            PlotVisualView(
              plotLength: (widget.data['length'] as num).toDouble(),
              plotWidth: (widget.data['width'] as num).toDouble(),
              setbacks: setbacks,
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow("City", widget.data['city']),
            _buildDetailRow("Dimensions", "${widget.data['length']}m x ${widget.data['width']}m"),
            _buildDetailRow("Road Width", "${widget.data['roadWidth']}m"),
            _buildDetailRow("Orientation", widget.data['orientation']),
            _buildDetailRow("Budget", "₹${widget.data['budget']} Lakhs"),
            _buildDetailRow("Floors", "${widget.data['floors']}"),
            
            const SizedBox(height: 24),
            const Text(
              "Engineer Remarks",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                hintText: "Enter remarks for approval/rejection...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _submitReview(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("REJECT"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitReview(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("APPROVE"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
