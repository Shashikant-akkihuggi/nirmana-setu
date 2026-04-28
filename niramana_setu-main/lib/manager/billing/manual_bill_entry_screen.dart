import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/gst_bill_model.dart';
import '../../services/gst_bill_service.dart';
import '../manager_pages.dart';

/// Manual Bill Entry Screen
class ManualBillEntryScreen extends StatefulWidget {
  final String projectId;
  const ManualBillEntryScreen({super.key, required this.projectId});

  @override
  State<ManualBillEntryScreen> createState() => _ManualBillEntryScreenState();
}

class _ManualBillEntryScreenState extends State<ManualBillEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _vendorGSTINController = TextEditingController();
  final _vendorAddressController = TextEditingController();
  final _vendorStateController = TextEditingController();
  final _vendorStateCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'pieces');
  final _rateController = TextEditingController();
  final _gstRateController = TextEditingController(text: '18');
  final _notesController = TextEditingController();

  DateTime? _billDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _billNumberController.dispose();
    _vendorNameController.dispose();
    _vendorGSTINController.dispose();
    _vendorAddressController.dispose();
    _vendorStateController.dispose();
    _vendorStateCodeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _gstRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateGST() {
    setState(() {
      // Trigger rebuild to show calculated values
    });
  }

  Map<String, double> _getCalculatedGST() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final gstRate = double.tryParse(_gstRateController.text) ?? 0.0;

    final baseAmount = quantity * rate;
    final gst = GSTCalculator.calculateGST(
      baseAmount: baseAmount,
      gstRate: gstRate,
      vendorStateCode: _vendorStateCodeController.text.isEmpty ? null : _vendorStateCodeController.text,
      projectStateCode: null, // TODO: Get from project settings
    );

    return {
      'base': baseAmount,
      'cgst': gst['cgst']!,
      'sgst': gst['sgst']!,
      'igst': gst['igst']!,
      'total': baseAmount + gst['cgst']! + gst['sgst']! + gst['igst']!,
    };
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final calculated = _getCalculatedGST();
      final bill = GSTBillModel(
        id: '',
        projectId: widget.projectId,
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        billNumber: _billNumberController.text.trim(),
        vendorName: _vendorNameController.text.trim(),
        vendorGSTIN: _vendorGSTINController.text.trim().toUpperCase(),
        vendorAddress: _vendorAddressController.text.trim().isEmpty
            ? null
            : _vendorAddressController.text.trim(),
        vendorState: _vendorStateController.text.trim().isEmpty
            ? null
            : _vendorStateController.text.trim(),
        vendorStateCode: _vendorStateCodeController.text.trim().isEmpty
            ? null
            : _vendorStateCodeController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text.trim(),
        rate: double.parse(_rateController.text),
        baseAmount: calculated['base']!,
        gstRate: double.parse(_gstRateController.text),
        cgstAmount: calculated['cgst']!,
        sgstAmount: calculated['sgst']!,
        igstAmount: calculated['igst']!,
        totalAmount: calculated['total']!,
        billSource: 'manual',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        billDate: _billDate,
      );

      await GSTBillService.createBill(bill);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculated = _getCalculatedGST();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Bill Entry'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _BackgroundGradient(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _billNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Bill Number *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _vendorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vendor Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _vendorGSTINController,
                            decoration: const InputDecoration(
                              labelText: 'Vendor GSTIN *',
                              hintText: '15 characters',
                              border: OutlineInputBorder(),
                            ),
                            maxLength: 15,
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              if (!GSTCalculator.isValidGSTIN(value!.toUpperCase())) {
                                return 'Invalid GSTIN format';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _vendorAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Vendor Address',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _vendorStateController,
                                  decoration: const InputDecoration(
                                    labelText: 'State',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _vendorStateCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'State Code',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLength: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _billDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _billDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Bill Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _billDate != null
                                    ? '${_billDate!.day}/${_billDate!.month}/${_billDate!.year}'
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Material/Service Description *',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                            onChanged: (_) => _calculateGST(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Required';
                                    if (double.tryParse(value!) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _calculateGST(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _unitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _rateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Rate per Unit *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Required';
                                    if (double.tryParse(value!) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _calculateGST(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _gstRateController,
                                  decoration: const InputDecoration(
                                    labelText: 'GST Rate (%) *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Required';
                                    if (double.tryParse(value!) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _calculateGST(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GST Calculation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CalculationRow('Base Amount', '₹${calculated['base']!.toStringAsFixed(2)}'),
                          if (calculated['cgst']! > 0)
                            _CalculationRow('CGST', '₹${calculated['cgst']!.toStringAsFixed(2)}'),
                          if (calculated['sgst']! > 0)
                            _CalculationRow('SGST', '₹${calculated['sgst']!.toStringAsFixed(2)}'),
                          if (calculated['igst']! > 0)
                            _CalculationRow('IGST', '₹${calculated['igst']!.toStringAsFixed(2)}'),
                          const Divider(height: 24),
                          _CalculationRow(
                            'Total Amount',
                            '₹${calculated['total']!.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ManagerTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Bill',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ManagerTheme.primary.withValues(alpha: 0.12),
            ManagerTheme.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _CalculationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _CalculationRow(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w800,
              color: isTotal ? ManagerTheme.primary : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
