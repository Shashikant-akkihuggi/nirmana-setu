import 'package:flutter/material.dart';
import '../../models/material_request_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';
import 'package:intl/intl.dart';

class OwnerMRFinancialApprovalScreen extends StatelessWidget {
  const OwnerMRFinancialApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('MR Financial Approvals')),
        body: const Center(child: Text('Please select a project first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MR Financial Approvals'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MaterialRequestModel>>(
        stream: ProcurementService.getOwnerPendingMRs(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final mrs = snapshot.data ?? [];
          if (mrs.isEmpty) {
            return const Center(child: Text('No material requests pending financial approval'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mrs.length,
            itemBuilder: (context, index) {
              final mr = mrs[index];
              return _MRFinancialCard(mr: mr);
            },
          );
        },
      ),
    );
  }
}

class _MRFinancialCard extends StatelessWidget {
  final MaterialRequestModel mr;
  const _MRFinancialCard({required this.mr});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text('Request ID: ${mr.id.substring(0, 8)}', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Priority: ${mr.priority} | Needed by: ${DateFormat('dd MMM yyyy').format(mr.neededBy)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Materials:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...mr.materials.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${item.name}: ${item.quantity} ${item.unit}'),
                )),
                const SizedBox(height: 12),
                const Text('Engineer Review:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Approved By: ${mr.engineerApprovedBy?.substring(0, 8) ?? "N/A"}'),
                if (mr.engineerRemarks != null) Text('Remarks: ${mr.engineerRemarks}'),
                if (mr.notes != null && mr.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Field Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(mr.notes!),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(context),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('REJECT'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveMR(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('APPROVE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveMR(BuildContext context) async {
    try {
      await ProcurementService.ownerApproveMR(mr.projectId, mr.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial approval granted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Financial Approval'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Remarks/Reason',
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter remarks')),
                );
                return;
              }
              try {
                await ProcurementService.ownerRejectMR(mr.projectId, mr.id, controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Material Request rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }
}
