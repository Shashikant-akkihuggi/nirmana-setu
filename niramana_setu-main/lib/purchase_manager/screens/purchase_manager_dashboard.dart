import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/models/project_model.dart';
import '../../services/auth_service.dart';
import 'pending_mrs_screen.dart';
import 'project_pos_screen.dart';
import 'project_bills_screen.dart';

class PurchaseManagerDashboard extends StatefulWidget {
  const PurchaseManagerDashboard({super.key});

  @override
  State<PurchaseManagerDashboard> createState() => _PurchaseManagerDashboardState();
}

class _PurchaseManagerDashboardState extends State<PurchaseManagerDashboard> {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  Widget _buildStatsSummary(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    // Note: Stats should be calculated from assigned projects, not top-level collection
    // This is a placeholder - proper implementation would aggregate from all assigned projects
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard("Assigned Projects", "0", Icons.folder, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard("Pending MRs", "0", Icons.pending_actions, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hi, Purchase Manager 📦', 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                                  const SizedBox(height: 4),
                                  const Text("Procurement Control Center", style: TextStyle(color: Color(0xFF5C5C5C))),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => AuthService().logout(),
                              icon: const Icon(Icons.logout, color: Color(0xFF5C5C5C)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats Summary
                _buildStatsSummary(user?.uid),

                // Content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('projects')
                        .where('purchaseManagerUid', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No projects assigned to you yet", 
                                style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final project = ProjectModel.fromFirestore(docs[index]);
                          return _ProjectProcurementCard(project: project);
                        },
                      );
                    },
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

class _ProjectProcurementCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectProcurementCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(project.projectName, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(project.statusDisplayText, 
                    style: TextStyle(
                      color: project.isActive ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    )),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Pending Material Requests", 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            
            // Pending Material Requests for this project
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(project.id)
                  .collection('materialRequests')
                  .where('status', isEqualTo: 'OWNER_APPROVED')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$count Requests ready for PO", 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ElevatedButton(
                      onPressed: count > 0 ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PendingMRsScreen(project: project),
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("View MRs"),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Purchase Orders", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectPOsScreen(project: project),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt, color: Color(0xFF136DEC)),
                  label: const Text("View All POs", style: TextStyle(color: Color(0xFF136DEC))),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("GST Bills", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectBillsScreen(project: project),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, color: Color(0xFF136DEC)),
                  label: const Text("View All Bills", style: TextStyle(color: Color(0xFF136DEC))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
