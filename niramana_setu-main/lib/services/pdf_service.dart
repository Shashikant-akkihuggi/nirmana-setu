import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gst_bill_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// PDF Service for generating GST-compliant invoice PDFs
class PDFService {
  /// Generate and save GST invoice PDF
  static Future<File> generateInvoicePDF(GSTBillModel bill) async {
    final pdf = pw.Document();

    // Get project details
    final projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(bill.projectId)
        .get();
    
    final projectName = projectDoc.data()?['projectName'] ?? 'Project';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(projectName),
              pw.SizedBox(height: 30),
              
              // Bill Details
              _buildBillDetails(bill),
              pw.SizedBox(height: 20),
              
              // Vendor Details
              _buildVendorDetails(bill),
              pw.SizedBox(height: 20),
              
              // Item Details
              _buildItemDetails(bill),
              pw.SizedBox(height: 20),
              
              // GST Breakdown
              _buildGSTBreakdown(bill),
              pw.SizedBox(height: 20),
              
              // Total
              _buildTotal(bill),
              pw.SizedBox(height: 30),
              
              // Footer
              _buildFooter(bill),
            ],
          );
        },
      ),
    );

    // Save PDF to temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/invoice_${bill.billNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Share PDF
  static Future<void> sharePDF(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'GST Invoice',
        text: 'Please find attached GST invoice',
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  // Private helper methods for PDF building

  static pw.Widget _buildHeader(String projectName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Niramana Setu',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              'Construction Project Management',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              projectName,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBillDetails(GSTBillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill Number:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(bill.billNumber, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (bill.billDate != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Bill Date:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text(
                  '${bill.billDate!.day}/${bill.billDate!.month}/${bill.billDate!.year}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildVendorDetails(GSTBillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vendor Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(bill.vendorName, style: pw.TextStyle(fontSize: 12)),
          if (bill.vendorAddress != null)
            pw.Text(bill.vendorAddress!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('GSTIN: ${bill.vendorGSTIN}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemDetails(GSTBillModel bill) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Description', isHeader: true),
            _tableCell('Qty', isHeader: true),
            _tableCell('Unit', isHeader: true),
            _tableCell('Rate', isHeader: true),
            _tableCell('Amount', isHeader: true),
          ],
        ),
        // Data row
        pw.TableRow(
          children: [
            _tableCell(bill.description),
            _tableCell(bill.quantity.toStringAsFixed(2)),
            _tableCell(bill.unit),
            _tableCell('₹${bill.rate.toStringAsFixed(2)}'),
            _tableCell('₹${bill.baseAmount.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildGSTBreakdown(GSTBillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GST Breakdown',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Base Amount:', style: pw.TextStyle(fontSize: 11)),
              pw.Text('₹${bill.baseAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)),
            ],
          ),
          if (bill.cgstAmount > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('CGST (${(bill.gstRate / 2).toStringAsFixed(1)}%):', style: pw.TextStyle(fontSize: 11)),
                pw.Text('₹${bill.cgstAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
          if (bill.sgstAmount > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SGST (${(bill.gstRate / 2).toStringAsFixed(1)}%):', style: pw.TextStyle(fontSize: 11)),
                pw.Text('₹${bill.sgstAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
          if (bill.igstAmount > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('IGST (${bill.gstRate.toStringAsFixed(1)}%):', style: pw.TextStyle(fontSize: 11)),
                pw.Text('₹${bill.igstAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildTotal(GSTBillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue300, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total Amount:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '₹${bill.totalAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(GSTBillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Status: ${bill.approvalStatus.toUpperCase()}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: bill.approvalStatus == 'approved' ? PdfColors.green700 : PdfColors.orange700,
            ),
          ),
          if (bill.approvedAt != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Approved on: ${bill.approvedAt!.day}/${bill.approvedAt!.month}/${bill.approvedAt!.year}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          if (bill.notes != null && bill.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Notes:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(bill.notes!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
  }
}
