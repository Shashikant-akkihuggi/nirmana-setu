import 'package:flutter/material.dart';
import '../../models/purchase_order_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';
import 'create_grn_form_screen.dart';

class GRNCreationScreen extends StatelessWidget {
  const GRNCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Delivery')),
        body: const Center(child: Text('Please select a project first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Material Delivery'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PurchaseOrderModel>>(
        stream: ProcurementService.getPOsPendingGRN(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pos = snapshot.data ?? [];
          if (pos.isEmpty) {
            return const Center(child: Text('No purchase orders pending delivery confirmation'));
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
                  title: Text('PO ID: ${po.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Vendor: ${po.vendorName}\nDate: ${po.createdAt.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateGRNFormScreen(po: po),
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
