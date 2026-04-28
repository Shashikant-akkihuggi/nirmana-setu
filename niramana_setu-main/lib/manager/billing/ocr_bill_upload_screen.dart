import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/gst_bill_model.dart';
import '../../services/gst_bill_service.dart';
import '../../services/ocr_service.dart';
import '../manager_pages.dart';

/// OCR Bill Upload Screen
class OCRBillUploadScreen extends StatefulWidget {
  final String projectId;
  const OCRBillUploadScreen({super.key, required this.projectId});

  @override
  State<OCRBillUploadScreen> createState() => _OCRBillUploadScreenState();
}

class _OCRBillUploadScreenState extends State<OCRBillUploadScreen> {
  File? _selectedImage;
  bool _isProcessingOCR = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _extractedData;
  String? _ocrError;

  // Form controllers for extracted/editable data
  final _billNumberController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _vendorGSTINController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'pieces');
  final _rateController = TextEditingController();
  final _gstRateController = TextEditingController();
  final _cgstController = TextEditingController();
  final _sgstController = TextEditingController();
  final _igstController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _billNumberController.dispose();
    _vendorNameController.dispose();
    _vendorGSTINController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _gstRateController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final image = await OCRService.pickBillImage(fromCamera: fromCamera);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _extractedData = null;
          _ocrError = null;
        });
        await _processOCR();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processOCR() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessingOCR = true;
      _ocrError = null;
    });

    try {
      final extracted = await OCRService.extractBillDataFromImage(_selectedImage!);

      if (extracted.containsKey('error')) {
        setState(() {
          _ocrError = extracted['error'] as String;
          _isProcessingOCR = false;
        });
        return;
      }

      setState(() {
        _extractedData = extracted;
        _billNumberController.text = extracted['billNumber'] ?? '';
        _vendorNameController.text = extracted['vendorName'] ?? '';
        _vendorGSTINController.text = extracted['gstin'] ?? '';
        _descriptionController.text = extracted['description'] ?? 'Material/Service';
        _gstRateController.text = extracted['gstRate']?.toString() ?? '18';
        
        // Calculate base amount from total if available
        final totalAmount = extracted['amount'] as double?;
        if (totalAmount != null) {
          final gstRate = double.tryParse(_gstRateController.text) ?? 18.0;
          final baseAmount = totalAmount / (1 + (gstRate / 100));
          _rateController.text = baseAmount.toStringAsFixed(2);
          _totalAmountController.text = totalAmount.toStringAsFixed(2);
          
          final cgst = extracted['cgst'] as double?;
          final sgst = extracted['sgst'] as double?;
          final igst = extracted['igst'] as double?;
          
          if (cgst != null) _cgstController.text = cgst.toStringAsFixed(2);
          if (sgst != null) _sgstController.text = sgst.toStringAsFixed(2);
          if (igst != null) _igstController.text = igst.toStringAsFixed(2);
        }
        
        _isProcessingOCR = false;
      });
    } catch (e) {
      setState(() {
        _ocrError = 'OCR processing failed. Please enter data manually.';
        _isProcessingOCR = false;
      });
    }
  }

  Future<String?> _uploadImageToStorage() async {
    if (_selectedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('bills')
          .child('${widget.projectId}')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      return null; // Fail gracefully - bill can still be created
    }
  }

  Future<void> _submitBill() async {
    setState(() => _isSubmitting = true);

    try {
      // Upload image if available
      final imageUrl = await _uploadImageToStorage();

      // Parse form data
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      final rate = double.tryParse(_rateController.text) ?? 0.0;
      final gstRate = double.tryParse(_gstRateController.text) ?? 18.0;
      final baseAmount = quantity * rate;

      final cgst = double.tryParse(_cgstController.text) ?? 0.0;
      final sgst = double.tryParse(_sgstController.text) ?? 0.0;
      final igst = double.tryParse(_igstController.text) ?? 0.0;
      final total = double.tryParse(_totalAmountController.text) ?? 
                    (baseAmount + cgst + sgst + igst);

      final bill = GSTBillModel(
        id: '',
        projectId: widget.projectId,
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        billNumber: _billNumberController.text.trim(),
        vendorName: _vendorNameController.text.trim(),
        vendorGSTIN: _vendorGSTINController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
        quantity: quantity,
        unit: _unitController.text.trim(),
        rate: rate,
        baseAmount: baseAmount,
        gstRate: gstRate,
        cgstAmount: cgst,
        sgstAmount: sgst,
        igstAmount: igst,
        totalAmount: total,
        billSource: 'ocr',
        ocrImageUrl: imageUrl,
        ocrRawData: _extractedData,
        ocrVerified: true,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Bill Photo (OCR)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _BackgroundGradient(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image picker section
                  _GlassCard(
                    child: Column(
                      children: [
                        if (_selectedImage == null) ...[
                          const Text(
                            'Select Bill Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(fromCamera: false),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ManagerTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(fromCamera: true),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ManagerTheme.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_isProcessingOCR)
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: Colors.white),
                                        SizedBox(height: 12),
                                        Text(
                                          'Processing OCR...',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessingOCR ? null : () => _pickImage(fromCamera: false),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Change Image'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessingOCR ? null : _processOCR,
                                  icon: const Icon(Icons.auto_fix_high),
                                  label: const Text('Re-process'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ManagerTheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_ocrError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _ocrError!,
                                    style: const TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Extracted/Editable data form
                  if (_selectedImage != null) ...[
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review & Edit Extracted Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _billNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Bill Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _vendorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vendor Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _vendorGSTINController,
                            decoration: const InputDecoration(
                              labelText: 'Vendor GSTIN',
                              border: OutlineInputBorder(),
                            ),
                            maxLength: 15,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _unitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _rateController,
                            decoration: const InputDecoration(
                              labelText: 'Rate',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _gstRateController,
                            decoration: const InputDecoration(
                              labelText: 'GST Rate (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cgstController,
                                  decoration: const InputDecoration(
                                    labelText: 'CGST',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _sgstController,
                                  decoration: const InputDecoration(
                                    labelText: 'SGST',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _igstController,
                            decoration: const InputDecoration(
                              labelText: 'IGST',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _totalAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Total Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
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
                ],
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
