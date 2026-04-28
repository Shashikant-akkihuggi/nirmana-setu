import 'package:flutter/material.dart';
import '../services/public_id_service.dart';
import '../services/project_reassignment_service.dart';

/// Debug screen to check and fix user public ID issues
/// This screen helps diagnose why users aren't showing up in project creation
class UserDebugScreen extends StatefulWidget {
  const UserDebugScreen({super.key});

  @override
  State<UserDebugScreen> createState() => _UserDebugScreenState();
}

class _UserDebugScreenState extends State<UserDebugScreen> {
  bool _isLoading = false;
  String _debugOutput = '';

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
    print(message);
  }

  Future<void> _checkUsers() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    _addOutput('🔍 Checking user data...\n');

    try {
      // Check users missing public IDs
      final missingUsers = await PublicIdService.getUsersMissingPublicIds();
      _addOutput('⚠️  Users missing public IDs: ${missingUsers.length}');
      for (final user in missingUsers) {
        _addOutput('   - ${user['fullName']} (${user['role']}) - UID: ${user['uid']}');
      }
      _addOutput('');

      // Check available owners
      _addOutput('👑 Checking available owners...');
      final owners = await ProjectReassignmentService.getAvailableUsersByRole('ownerClient');
      _addOutput('   Found ${owners.length} available owners');
      for (final owner in owners) {
        _addOutput('   - ${owner.fullName} (${owner.publicId})');
      }
      _addOutput('');

      // Check available managers
      _addOutput('👔 Checking available managers...');
      final managers = await ProjectReassignmentService.getAvailableUsersByRole('manager');
      _addOutput('   Found ${managers.length} available managers');
      for (final manager in managers) {
        _addOutput('   - ${manager.fullName} (${manager.publicId})');
      }
      _addOutput('');

      // Check available engineers
      _addOutput('🔧 Checking available engineers...');
      final engineers = await ProjectReassignmentService.getAvailableUsersByRole('engineer');
      _addOutput('   Found ${engineers.length} available engineers');
      for (final engineer in engineers) {
        _addOutput('   - ${engineer.fullName} (${engineer.publicId})');
      }

    } catch (e) {
      _addOutput('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fixMissingPublicIds() async {
    setState(() {
      _isLoading = true;
    });

    _addOutput('\n🔧 Starting public ID migration...');

    try {
      await PublicIdService.fixUsersMissingPublicIds();
      _addOutput('✅ Migration completed!');
      
      // Refresh the check
      await Future.delayed(const Duration(seconds: 1));
      await _checkUsers();
    } catch (e) {
      _addOutput('❌ Migration failed: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Debug'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkUsers,
                    icon: const Icon(Icons.search),
                    label: const Text('Check Users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF136DEC),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fixMissingPublicIds,
                    icon: const Icon(Icons.build),
                    label: const Text('Fix Missing IDs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A5AF8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? 'Click "Check Users" to start debugging...' : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}