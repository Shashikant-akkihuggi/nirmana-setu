import 'package:flutter/material.dart';
import '../../common/models/project_model.dart';
import '../../models/purchase_order_model.dart';
import '../../models/grn_model.dart';
import '../../services/procurement_service.dart';
import 'create_gst_bill_screen.dart';

class PODetailsScreen extends StatelessWidget {
  final PurchaseOrderModel po;
  final ProjectModel project;

  const PODetailsScreen({super.key, required this.po, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PO Details'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 24),
            const Text("Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildItemsList(),
            const SizedBox(height: 24),
            _buildGRNSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PO ID: ${po.id.substring(0, 8)}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _buildStatusBadge(po.status),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.business, "Vendor", po.vendorName),
            _buildInfoRow(Icons.receipt_long, "GSTIN", po.vendorGSTIN),
            if (po.poNumber != null && po.poNumber!.isNotEmpty)
              _buildInfoRow(Icons.numbers, "PO Number", po.poNumber!),
            _buildInfoRow(Icons.calendar_today, "Date", po.createdAt.toString().split(' ')[0]),
            _buildInfoRow(Icons.account_balance, "GST Type", po.gstType.replaceAll('_', ' + ')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: po.items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${item.quantity} ${item.unit} @ ₹ ${item.rate}"),
          trailing: Text("₹ ${item.amount.toStringAsFixed(2)}", 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildGRNSection(BuildContext context) {
    return FutureBuilder<GRNModel?>(
      future: ProcurementService.getGRNByPOId(po.projectId, po.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final grn = snapshot.data;
        if (grn == null) {
          return const Card(
            color: Color(0xFFFFF9C4),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(child: Text("Waiting for GRN (Material Delivery Confirmation by Field Manager)")),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("GRN Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text("Material Received & Verified", 
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("Verified At: ${grn.verifiedAt.toString().split('.')[0]}"),
                    if (grn.notes != null) Text("Notes: ${grn.notes}"),
                    const SizedBox(height: 16),
                    if (po.status == 'GRN_CONFIRMED')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateGSTBillScreen(po: po, grn: grn, project: project),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt),
                          label: const Text("GENERATE GST BILL"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF136DEC),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (po.status == 'BILL_GENERATED' || po.status == 'BILL_APPROVED')
                      const Center(
                        child: Text("Bill has been generated for this PO", 
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
