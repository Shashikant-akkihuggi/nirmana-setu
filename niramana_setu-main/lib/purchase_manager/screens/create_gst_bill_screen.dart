import 'package:flutter/material.dart';
import '../../common/models/project_model.dart';
import '../../models/purchase_order_model.dart';
import '../../models/grn_model.dart';
import '../../models/gst_bill_model.dart';
import '../../services/procurement_service.dart';

class CreateGSTBillScreen extends StatefulWidget {
  final PurchaseOrderModel po;
  final GRNModel grn;
  final ProjectModel project;

  const CreateGSTBillScreen({
    super.key,
    required this.po,
    required this.grn,
    required this.project,
  });

  @override
  State<CreateGSTBillScreen> createState() => _CreateGSTBillScreenState();
}

class _CreateGSTBillScreenState extends State<CreateGSTBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _billDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _billNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // In this simplified version, we create a bill for the entire PO
      // Usually, there might be multiple bills or itemized rates
      // Here we use the PO total and items summary
      
      final bill = GSTBillModel(
        id: '', // Firestore will generate
        projectId: widget.project.id,
        poId: widget.po.id,
        grnId: widget.grn.id,
        createdBy: '', // Service will fill
        createdAt: DateTime.now(),
        billNumber: _billNumberController.text.trim(),
        vendorName: widget.po.vendorName,
        vendorGSTIN: widget.po.vendorGSTIN,
        vendorAddress: widget.po.vendorAddress,
        description: "Materials as per PO ${widget.po.id.substring(0, 8)}",
        quantity: 1,
        unit: "lot",
        rate: widget.po.totalAmount,
        baseAmount: widget.po.totalAmount,
        gstRate: 18.0, // Default 18% for now, should ideally be dynamic
        cgstAmount: widget.po.gstType == 'CGST_SGST' ? (widget.po.totalAmount * 0.09) : 0,
        sgstAmount: widget.po.gstType == 'CGST_SGST' ? (widget.po.totalAmount * 0.09) : 0,
        igstAmount: widget.po.gstType == 'IGST' ? (widget.po.totalAmount * 0.18) : 0,
        totalAmount: widget.po.totalAmount * 1.18, // Simplified
        billSource: 'manual',
        notes: _notesController.text.trim(),
        billDate: _billDate,
      );

      await ProcurementService.createGSTBill(bill);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GST Bill generated successfully')),
        );
        Navigator.pop(context); // Back to PO Details
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _billDate) {
      setState(() => _billDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate GST Bill'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Bill Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _billNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Bill/Invoice Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Bill Date'),
                    subtitle: Text("${_billDate.toLocal()}".split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Summary (from PO)'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow("Vendor", widget.po.vendorName),
                          _buildSummaryRow("PO ID", widget.po.id.substring(0, 8)),
                          _buildSummaryRow("Base Amount", "₹ ${widget.po.totalAmount.toStringAsFixed(2)}"),
                          _buildSummaryRow("GST Type", widget.po.gstType.replaceAll('_', ' + ')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('CONFIRM & GENERATE BILL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF136DEC),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
