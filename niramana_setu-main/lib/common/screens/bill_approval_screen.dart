import 'package:flutter/material.dart';
import '../../models/gst_bill_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';

class BillApprovalScreen extends StatelessWidget {
  final GSTBillModel bill;
  const BillApprovalScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review GST Bill'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBillDetailsCard(),
            const SizedBox(height: 24),
            _buildAmountSummary(),
            const SizedBox(height: 24),
            _buildVendorInfo(),
            const SizedBox(height: 40),
            if (bill.approvalStatus == 'pending')
              _buildApprovalActions(context),
            if (bill.approvalStatus != 'pending')
              _buildStatusInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard() {
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
                Text("Bill #: ${bill.billNumber}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                _buildStatusBadge(bill.approvalStatus),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.description, "Description", bill.description),
            _buildInfoRow(Icons.calendar_today, "Bill Date", bill.billDate?.toString().split(' ')[0] ?? "N/A"),
            if (bill.poId != null)
              _buildInfoRow(Icons.shopping_bag, "Linked PO", bill.poId!.substring(0, 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow("Base Amount", "₹ ${bill.baseAmount.toStringAsFixed(2)}"),
            if (bill.cgstAmount > 0)
              _buildSummaryRow("CGST (${(bill.gstRate/2).toStringAsFixed(1)}%)", "₹ ${bill.cgstAmount.toStringAsFixed(2)}"),
            if (bill.sgstAmount > 0)
              _buildSummaryRow("SGST (${(bill.gstRate/2).toStringAsFixed(1)}%)", "₹ ${bill.sgstAmount.toStringAsFixed(2)}"),
            if (bill.igstAmount > 0)
              _buildSummaryRow("IGST (${bill.gstRate.toStringAsFixed(1)}%)", "₹ ${bill.igstAmount.toStringAsFixed(2)}"),
            const Divider(height: 20),
            _buildSummaryRow("Total Amount", "₹ ${bill.totalAmount.toStringAsFixed(2)}", isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Vendor Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.business, "Vendor", bill.vendorName),
                _buildInfoRow(Icons.receipt_long, "GSTIN", bill.vendorGSTIN),
                if (bill.vendorAddress != null)
                  _buildInfoRow(Icons.location_on, "Address", bill.vendorAddress!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showRejectDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("REJECT"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _approveBill(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("APPROVE"),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    final isApproved = bill.approvalStatus == 'approved';
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isApproved ? Colors.green : Colors.red),
        ),
        child: Column(
          children: [
            Icon(isApproved ? Icons.check_circle : Icons.cancel, 
              color: isApproved ? Colors.green : Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              isApproved ? "This bill has been approved" : "This bill was rejected",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isApproved ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
            if (!isApproved && bill.rejectionRemarks != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Remarks: ${bill.rejectionRemarks}"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          )),
          Text(value, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? const Color(0xFF136DEC) : Colors.black,
          )),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _approveBill(BuildContext context) async {
    try {
      await ProcurementService.approveBill(bill.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill approved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Bill"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Reason for rejection"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              // We need a reject method in ProcurementService
              // For now let's assume we'll add it
              Navigator.pop(context);
              _rejectBill(context, controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("REJECT"),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectBill(BuildContext context, String remarks) async {
    try {
      await ProcurementService.rejectBill(bill.id, remarks);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill rejected')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
