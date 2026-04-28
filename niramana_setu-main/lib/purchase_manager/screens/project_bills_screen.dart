import 'package:flutter/material.dart';
import '../../common/models/project_model.dart';
import '../../models/gst_bill_model.dart';
import '../../services/procurement_service.dart';

class ProjectBillsScreen extends StatelessWidget {
  final ProjectModel project;
  const ProjectBillsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bills - ${project.projectName}'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<GSTBillModel>>(
        stream: ProcurementService.getProjectBills(project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bills = snapshot.data ?? [];
          if (bills.isEmpty) {
            return const Center(child: Text('No GST Bills found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(bill.vendorName),
                      Text("Total: ₹ ${bill.totalAmount.toStringAsFixed(2)}"),
                    ],
                  ),
                  trailing: _buildStatusBadge(bill.approvalStatus),
                  onTap: () {
                    // Navigate to Bill details (can implement if needed)
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
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'rejected': color = Colors.red; break;
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
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
