import 'package:flutter/material.dart';
import '../../models/material_request_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';
import 'package:intl/intl.dart';

class EnhancedMRScreen extends StatefulWidget {
  const EnhancedMRScreen({super.key});

  @override
  State<EnhancedMRScreen> createState() => _EnhancedMRScreenState();
}

class _EnhancedMRScreenState extends State<EnhancedMRScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<MaterialItem> _items = [];
  final _notesController = TextEditingController();
  String _priority = 'Medium';
  DateTime _neededBy = DateTime.now().add(const Duration(days: 3));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final qtyController = TextEditingController();
        final unitController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Material'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Material Name')),
              TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (e.g. bags, tons)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                  setState(() {
                    _items.add(MaterialItem(
                      name: nameController.text.trim(),
                      quantity: double.tryParse(qtyController.text) ?? 0.0,
                      unit: unitController.text.trim(),
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one material')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final mr = MaterialRequestModel(
        id: '', // Firestore will generate
        projectId: ProjectContext.activeProjectId!,
        createdBy: '', // Service will fill
        createdAt: DateTime.now(),
        materials: _items,
        priority: _priority,
        neededBy: _neededBy,
        notes: _notesController.text.trim(),
      );

      await ProcurementService.createMaterialRequest(mr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material Request submitted successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Materials'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Materials List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: _addItem, icon: const Icon(Icons.add_circle, color: Color(0xFF136DEC), size: 32)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(child: Text('No materials added yet. Tap + to add.'))
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item.name),
                                  subtitle: Text('${item.quantity} ${item.unit}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => setState(() => _items.removeAt(index)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                          items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _neededBy,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _neededBy = d);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Needed By', border: OutlineInputBorder()),
                            child: Text(DateFormat('dd/MM/yy').format(_neededBy)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF136DEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
