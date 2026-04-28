import 'package:flutter/material.dart';
import '../../models/purchase_order_model.dart';
import '../../models/grn_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';

class CreateGRNFormScreen extends StatefulWidget {
  final PurchaseOrderModel po;
  const CreateGRNFormScreen({super.key, required this.po});

  @override
  State<CreateGRNFormScreen> createState() => _CreateGRNFormScreenState();
}

class _CreateGRNFormScreenState extends State<CreateGRNFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  final _challanController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.po.items.length; i++) {
      _controllers[i] = TextEditingController(
        text: widget.po.items[i].quantity.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _challanController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitGRN() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final List<GRNItem> receivedItems = [];
      for (int i = 0; i < widget.po.items.length; i++) {
        final poItem = widget.po.items[i];
        final receivedQty = double.parse(_controllers[i]!.text);
        
        receivedItems.add(GRNItem(
          materialName: poItem.materialName,
          orderedQuantity: poItem.quantity,
          receivedQuantity: receivedQty,
          unit: poItem.unit,
          isComplete: receivedQty >= poItem.quantity,
        ));
      }

      final grn = GRNModel(
        id: '', // Firestore will generate
        projectId: widget.po.projectId,
        poId: widget.po.id,
        verifiedBy: '', // Service will fill
        verifiedAt: DateTime.now(),
        receivedItems: receivedItems,
        deliveryChallanNumber: _challanController.text.trim(),
        notes: _notesController.text.trim(),
        deliveryDate: DateTime.now(),
      );

      await ProcurementService.createGRN(grn);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GRN confirmed successfully')),
        );
        Navigator.pop(context); // Back to list
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
        title: const Text('Verify Received Materials'),
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
                  _buildSectionHeader('Delivery Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _challanController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Challan / Invoice Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Verify Items'),
                  const SizedBox(height: 12),
                  ...widget.po.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.materialName, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Ordered: ${item.quantity} ${item.unit}'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _controllers[index],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Received Quantity (${item.unit})',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Additional Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Discrepancies',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitGRN,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('CONFIRM RECEIPT (GRN)', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
}
