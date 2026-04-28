import 'package:flutter/material.dart';
import '../../services/procurement_service.dart';
import '../../models/material_request_model.dart';
import '../../models/purchase_order_model.dart';
import '../../models/grn_model.dart';
import '../../models/gst_bill_model.dart';
import 'package:intl/intl.dart';

class ProcurementChainWidget extends StatelessWidget {
  final String projectId;
  final String mrId;
  
  const ProcurementChainWidget({super.key, required this.projectId, required this.mrId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProcurementService.getProcurementChain(projectId, mrId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final data = snapshot.data!;
        final mr = data['mr'] as MaterialRequestModel;
        final po = data['po'] as PurchaseOrderModel?;
        final grn = data['grn'] as GRNModel?;
        final bill = data['bill'] as GSTBillModel?;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Procurement Timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildStep(
              title: 'Material Request',
              subtitle: 'Status: ${mr.status}',
              date: mr.createdAt,
              isCompleted: true,
              isCurrent: po == null,
            ),
            _buildStep(
              title: 'Purchase Order',
              subtitle: po != null ? 'PO: ${po.id.substring(0, 8)} (${po.status})' : 'Pending PO Creation',
              date: po?.createdAt,
              isCompleted: po != null,
              isCurrent: po != null && grn == null,
            ),
            _buildStep(
              title: 'Goods Receipt (GRN)',
              subtitle: grn != null ? 'Verified by: ${grn.verifiedBy.substring(0, 8)}' : 'Pending Delivery',
              date: grn?.verifiedAt,
              isCompleted: grn != null,
              isCurrent: grn != null && bill == null,
            ),
            _buildStep(
              title: 'GST Bill',
              subtitle: bill != null ? 'Amount: ₹${bill.totalAmount} (${bill.approvalStatus})' : 'Pending Bill Generation',
              date: bill?.createdAt,
              isCompleted: bill != null,
              isCurrent: bill != null,
              isLast: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    DateTime? date,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    final color = isCompleted ? Colors.green : (isCurrent ? Colors.blue : Colors.grey);
    
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.white,
                  border: Border.all(color: color, width: 2),
                ),
                child: isCompleted 
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isCurrent ? Container(margin: const EdgeInsets.all(4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue)) : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted || isCurrent ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted || isCurrent ? Colors.black54 : Colors.grey[400],
                    ),
                  ),
                  if (date != null)
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(date),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
