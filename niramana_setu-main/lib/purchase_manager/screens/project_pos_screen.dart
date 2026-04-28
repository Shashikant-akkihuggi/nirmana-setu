import 'package:flutter/material.dart';
import '../../common/models/project_model.dart';
import '../../models/purchase_order_model.dart';
import '../../services/procurement_service.dart';
import 'po_details_screen.dart';

class ProjectPOsScreen extends StatelessWidget {
  final ProjectModel project;
  const ProjectPOsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POs - ${project.projectName}'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PurchaseOrderModel>>(
        stream: ProcurementService.getProjectPOs(project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final pos = snapshot.data ?? [];
          if (pos.isEmpty) {
            return const Center(child: Text('No Purchase Orders found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pos.length,
            itemBuilder: (context, index) {
              final po = pos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(po.vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("PO ID: ${po.id.substring(0, 8)}"),
                      Text("Total: ₹ ${po.totalAmount.toStringAsFixed(2)}"),
                    ],
                  ),
                  trailing: _buildStatusBadge(po.status),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PODetailsScreen(po: po, project: project),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'PO_CREATED': color = Colors.blue; break;
      case 'GRN_CONFIRMED': color = Colors.orange; break;
      case 'BILL_GENERATED': color = Colors.purple; break;
      case 'BILL_APPROVED': color = Colors.green; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
