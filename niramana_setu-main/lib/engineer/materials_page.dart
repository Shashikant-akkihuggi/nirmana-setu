import 'package:flutter/material.dart';
import 'engineer_dashboard.dart';

class EngineerMaterialsScreen extends StatelessWidget {
  const EngineerMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for material requests
    final requests = [
      {'name': 'Cement Bags', 'quantity': '50 bags', 'status': 'Pending'},
      {'name': 'Steel Rods', 'quantity': '200 kg', 'status': 'Approved'},
      {'name': 'Bricks', 'quantity': '1000 pcs', 'status': 'Rejected'},
      {'name': 'Sand', 'quantity': '5 tons', 'status': 'Pending'},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Add Request"),
        icon: const Icon(Icons.add),
        backgroundColor: EngineerDashboard.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          Color statusColor;
          switch (req['status']) {
            case 'Approved':
              statusColor = Colors.green;
              break;
            case 'Rejected':
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.orange;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: EngineerDashboard.primary.withValues(alpha: 0.1),
                child: Icon(Icons.inventory_2_outlined, color: EngineerDashboard.primary),
              ),
              title: Text(req['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Quantity: ${req['quantity']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  req['status'] as String,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
