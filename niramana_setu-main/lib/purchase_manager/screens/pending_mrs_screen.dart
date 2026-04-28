import 'package:flutter/material.dart';
import '../../models/material_request_model.dart';
import '../../common/models/project_model.dart';
import '../../services/procurement_service.dart';
import 'create_po_screen.dart';

class PendingMRsScreen extends StatelessWidget {
  final ProjectModel project;
  const PendingMRsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending MRs - ${project.projectName}'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MaterialRequestModel>>(
        stream: ProcurementService.getOwnerApprovedMRs(project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final mrs = snapshot.data ?? [];
          if (mrs.isEmpty) {
            return const Center(child: Text('No owner-approved MRs found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mrs.length,
            itemBuilder: (context, index) {
              final mr = mrs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text("MR ID: ${mr.id.substring(0, 8)}", 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      ...mr.materials.map((m) => Text("• ${m.name}: ${m.quantity} ${m.unit}")),
                      const SizedBox(height: 8),
                      Text("Priority: ${mr.priority}", 
                        style: TextStyle(color: _getPriorityColor(mr.priority), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreatePOScreen(project: project, mr: mr),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }
}
