import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/gst_bill_model.dart';
import '../services/procurement_service.dart';
import '../services/pdf_service.dart';
import '../common/screens/bill_approval_screen.dart';

class _ThemeINV {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class InvoiceModel {
  final String id;
  final String title;
  final double amount; // base amount (pre-GST)
  final String status; // paid / pending
  final DateTime date;
  final double gst; // percentage (e.g., 18)
  final String notes;

  const InvoiceModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.status,
    required this.date,
    required this.gst,
    this.notes = '',
  });

  static InvoiceModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      status: data['status'] ?? 'pending',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gst: (data['gst'] is num) ? (data['gst'] as num).toDouble() : 0.0,
      notes: data['notes'] ?? '',
    );
  }
}

class OwnerInvoicesScreen extends StatelessWidget {
  final String projectId;
  const OwnerInvoicesScreen({super.key, required this.projectId});

  Stream<List<InvoiceModel>> _invoicesStream() {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('invoices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(InvoiceModel.fromFirestore).toList());
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          _Background(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Billing & GST Invoices',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Pending Review'),
                    Tab(text: 'GST Bills'),
                    Tab(text: 'Legacy Invoices'),
                  ],
                  labelColor: Color(0xFF136DEC),
                  unselectedLabelColor: Color(0xFF6B7280),
                  isScrollable: true,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Pending Review Tab
                      StreamBuilder<List<GSTBillModel>>(
                        stream: ProcurementService.getPendingBills(projectId),
                        builder: (context, snapshot) {
                          final bills = snapshot.data ?? [];
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (bills.isEmpty) {
                            return _buildEmptyState("No Bills Pending Review", "All bills have been processed");
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: bills.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final bill = bills[i];
                              return _GSTBillCard(
                                bill: bill,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BillApprovalScreen(
                                        bill: bill,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      // GST Bills Tab (Approved)
                      StreamBuilder<List<GSTBillModel>>(
                        stream: ProcurementService.getProjectBills(projectId), // This returns all, but we can filter or use another method
                        builder: (context, snapshot) {
                          final allBills = snapshot.data ?? [];
                          final bills = allBills.where((b) => b.approvalStatus == 'approved').toList();
                          
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (bills.isEmpty) {
                            return _buildEmptyState("No Approved Bills", "Approved bills will appear here");
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: bills.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final bill = bills[i];
                              return _GSTBillCard(
                                bill: bill,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _GSTBillDetailScreen(
                                        projectId: projectId,
                                        bill: bill,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      // Legacy Invoices Tab
                      StreamBuilder<List<InvoiceModel>>(
                        stream: _invoicesStream(),
                        builder: (context, snapshot) {
                          final items = snapshot.data ?? const <InvoiceModel>[];
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (items.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Invoices',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final inv = items[i];
                              return _InvoiceCard(
                                invoice: inv,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _InvoiceDetailScreen(invoice: inv),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  const _InvoiceCard({required this.invoice, required this.onTap});

  Color get statusColor => invoice.status == 'paid' ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
  String get statusLabel => invoice.status == 'paid' ? 'Paid' : 'Pending';

  @override
  Widget build(BuildContext context) {
    final String d = '${invoice.date.day.toString().padLeft(2, '0')}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.year}';
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: _ThemeINV.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.all(16), // Increased padding for better spacing
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_ThemeINV.primary, _ThemeINV.accent]),
                    boxShadow: [
                      BoxShadow(color: _ThemeINV.primary.withValues(alpha: 0.25), blurRadius: 14),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16), // Increased spacing
                // FIX: Better text layout with proper constraints
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600, // Consistent font weight
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invoice.id}  •  $d',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // FIX: Better layout for amount and status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatAmount(invoice.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status badges in a column for better mobile layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'GST ${invoice.gst.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FIX: Helper method to format large amounts properly
  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

class _InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailScreen({required this.invoice});

  double get gstAmount => invoice.amount * (invoice.gst / 100.0);
  double get totalWithGst => invoice.amount + gstAmount;

  @override
  Widget build(BuildContext context) {
    final String d = '${invoice.date.day.toString().padLeft(2, '0')}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.year}';
    final bool isPaid = invoice.status == 'paid';
    final Color statusColor = isPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassBlock(
                    title: invoice.title,
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${invoice.id}  •  $d'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(isPaid ? 'Paid' : 'Pending', style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassBlock(
                    title: 'Breakdown',
                    icon: Icons.grid_view_rounded,
                    child: Column(
                      children: [
                        _row('Base Amount', '₹${invoice.amount.toStringAsFixed(2)}'),
                        _row('GST (${invoice.gst.toStringAsFixed(0)}%)', '₹${gstAmount.toStringAsFixed(2)}'),
                        const Divider(height: 18),
                        _row('Total', '₹${totalWithGst.toStringAsFixed(2)}', bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassBlock(
                    title: 'Notes',
                    icon: Icons.notes_rounded,
                    child: Text(invoice.notes.isEmpty ? '—' : invoice.notes),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ThemeINV.primary.withValues(alpha: 0.12),
            _ThemeINV.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _GlassBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _GlassBlock({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
              BoxShadow(color: _ThemeINV.accent.withValues(alpha: 0.18), blurRadius: 30, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF374151)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                ],
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(style: const TextStyle(color: Color(0xFF1F2937)), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// GST Bill Components
class _GSTBillCard extends StatelessWidget {
  final GSTBillModel bill;
  final VoidCallback onTap;
  const _GSTBillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String d = bill.billDate != null
        ? '${bill.billDate!.day.toString().padLeft(2, '0')}-${bill.billDate!.month.toString().padLeft(2, '0')}-${bill.billDate!.year}'
        : '${bill.createdAt.day.toString().padLeft(2, '0')}-${bill.createdAt.month.toString().padLeft(2, '0')}-${bill.createdAt.year}';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: _ThemeINV.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_ThemeINV.primary, _ThemeINV.accent]),
                    boxShadow: [
                      BoxShadow(color: _ThemeINV.primary.withValues(alpha: 0.25), blurRadius: 14),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.billNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bill.vendorName}  •  $d',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatAmount(bill.totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'APPROVED',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

class _GSTBillDetailScreen extends StatefulWidget {
  final String projectId;
  final GSTBillModel bill;
  const _GSTBillDetailScreen({required this.projectId, required this.bill});

  @override
  State<_GSTBillDetailScreen> createState() => _GSTBillDetailScreenState();
}

class _GSTBillDetailScreenState extends State<_GSTBillDetailScreen> {
  bool _isGeneratingPDF = false;

  Future<void> _downloadPDF() async {
    setState(() => _isGeneratingPDF = true);

    try {
      final pdfFile = await PDFService.generateInvoicePDF(widget.bill);
      
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => await pdfFile.readAsBytes(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String d = widget.bill.billDate != null
        ? '${widget.bill.billDate!.day.toString().padLeft(2, '0')}-${widget.bill.billDate!.month.toString().padLeft(2, '0')}-${widget.bill.billDate!.year}'
        : '${widget.bill.createdAt.day.toString().padLeft(2, '0')}-${widget.bill.createdAt.month.toString().padLeft(2, '0')}-${widget.bill.createdAt.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isGeneratingPDF
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isGeneratingPDF ? null : _downloadPDF,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassBlock(
                    title: widget.bill.billNumber,
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.35)),
                              ),
                              child: const Text(
                                'APPROVED',
                                style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassBlock(
                    title: 'Vendor Details',
                    icon: Icons.business,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bill.vendorName),
                        if (widget.bill.vendorAddress != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.bill.vendorAddress!),
                        ],
                        const SizedBox(height: 4),
                        Text('GSTIN: ${widget.bill.vendorGSTIN}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassBlock(
                    title: 'Item Details',
                    icon: Icons.inventory_2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bill.description),
                        const SizedBox(height: 4),
                        Text('Quantity: ${widget.bill.quantity} ${widget.bill.unit}'),
                        Text('Rate: ₹${widget.bill.rate.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassBlock(
                    title: 'Breakdown',
                    icon: Icons.grid_view_rounded,
                    child: Column(
                      children: [
                        _row('Base Amount', '₹${widget.bill.baseAmount.toStringAsFixed(2)}'),
                        if (widget.bill.cgstAmount > 0)
                          _row('CGST (${(widget.bill.gstRate / 2).toStringAsFixed(1)}%)', '₹${widget.bill.cgstAmount.toStringAsFixed(2)}'),
                        if (widget.bill.sgstAmount > 0)
                          _row('SGST (${(widget.bill.gstRate / 2).toStringAsFixed(1)}%)', '₹${widget.bill.sgstAmount.toStringAsFixed(2)}'),
                        if (widget.bill.igstAmount > 0)
                          _row('IGST (${widget.bill.gstRate.toStringAsFixed(1)}%)', '₹${widget.bill.igstAmount.toStringAsFixed(2)}'),
                        const Divider(height: 18),
                        _row('Total', '₹${widget.bill.totalAmount.toStringAsFixed(2)}', bold: true),
                      ],
                    ),
                  ),
                  if (widget.bill.notes != null && widget.bill.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _GlassBlock(
                      title: 'Notes',
                      icon: Icons.notes_rounded,
                      child: Text(widget.bill.notes!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingPDF ? null : _downloadPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Download PDF Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ThemeINV.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
