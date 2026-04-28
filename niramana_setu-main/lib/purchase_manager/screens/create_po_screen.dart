import 'package:flutter/material.dart';
import '../../models/material_request_model.dart';
import '../../common/models/project_model.dart';
import '../../models/purchase_order_model.dart';
import '../../services/procurement_service.dart';

class CreatePOScreen extends StatefulWidget {
  final ProjectModel project;
  final MaterialRequestModel mr;

  const CreatePOScreen({super.key, required this.project, required this.mr});

  @override
  State<CreatePOScreen> createState() => _CreatePOScreenState();
}

class _CreatePOScreenState extends State<CreatePOScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _vendorGSTINController = TextEditingController();
  final _vendorAddressController = TextEditingController();
  final _vendorContactController = TextEditingController();
  final _notesController = TextEditingController();
  final _poNumberController = TextEditingController();

  late List<TextEditingController> _rateControllers;
  String _gstType = 'CGST_SGST';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rateControllers = widget.mr.materials.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _vendorGSTINController.dispose();
    _vendorAddressController.dispose();
    _vendorContactController.dispose();
    _notesController.dispose();
    _poNumberController.dispose();
    for (var controller in _rateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (int i = 0; i < widget.mr.materials.length; i++) {
      final rate = double.tryParse(_rateControllers[i].text) ?? 0;
      total += rate * widget.mr.materials[i].quantity;
    }
    return total;
  }

  Future<void> _submitPO() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final items = <POItem>[];
      for (int i = 0; i < widget.mr.materials.length; i++) {
        final material = widget.mr.materials[i];
        final rate = double.parse(_rateControllers[i].text);
        items.add(POItem(
          materialName: material.name,
          quantity: material.quantity,
          unit: material.unit,
          rate: rate,
          amount: rate * material.quantity,
        ));
      }

      final po = PurchaseOrderModel(
        id: '', // Firestore will generate
        projectId: widget.project.id,
        mrId: widget.mr.id,
        createdBy: '', // Service will fill
        createdAt: DateTime.now(),
        vendorName: _vendorNameController.text.trim(),
        vendorGSTIN: _vendorGSTINController.text.trim().toUpperCase(),
        vendorAddress: _vendorAddressController.text.trim(),
        vendorContact: _vendorContactController.text.trim(),
        items: items,
        gstType: _gstType,
        totalAmount: _totalAmount,
        notes: _notesController.text.trim(),
        poNumber: _poNumberController.text.trim(),
      );

      await ProcurementService.createPurchaseOrder(po);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Order created successfully')),
        );
        Navigator.pop(context); // Back to Pending MRs
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Order'),
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
                  _buildSectionHeader('Vendor Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendorGSTINController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor GSTIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length != 15) return 'GSTIN must be 15 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendorContactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendorAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('PO Items (from MR)'),
                  const SizedBox(height: 12),
                  ...List.generate(widget.mr.materials.length, (index) {
                    final material = widget.mr.materials[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Quantity: ${material.quantity} ${material.unit}'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _rateControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Rate (per unit)',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid number';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Summary & Additional Info'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gstType,
                    decoration: const InputDecoration(
                      labelText: 'GST Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CGST_SGST', child: Text('CGST + SGST (Intra-state)')),
                      DropdownMenuItem(value: 'IGST', child: Text('IGST (Inter-state)')),
                    ],
                    onChanged: (v) => setState(() => _gstType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _poNumberController,
                    decoration: const InputDecoration(
                      labelText: 'PO Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Base Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '₹ ${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF136DEC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitPO,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('GENERATE PURCHASE ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
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
}
