import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';

/// Owner Attendance View Screen - READ ONLY
/// Owner can VIEW attendance but CANNOT mark, edit, or override
/// Shows GPS-verified + face-verified attendance records
/// 
/// ROLE-BASED ACCESS:
/// - Field Manager: Create & Mark
/// - Engineer: View
/// - Owner: View (this screen)
/// - Purchase Manager: No Access
/// 
/// OWNER PERMISSIONS:
/// - read: true
/// - write: false
/// 
/// GPS LOGIC (OWNER SIDE):
/// - Does NOT ask for location permission
/// - Does NOT calculate distance
/// - Does NOT perform geofence checks
/// - Only views the result of GPS validation already performed by Field Manager
class OwnerAttendanceViewScreen extends StatefulWidget {
  final String projectId;
  
  const OwnerAttendanceViewScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<OwnerAttendanceViewScreen> createState() => _OwnerAttendanceViewScreenState();
}

class _OwnerAttendanceViewScreenState extends State<OwnerAttendanceViewScreen> {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
  
  DateTime _selectedDate = DateTime.now();
  
  /// Date key in YYYY-MM-DD format for Firestore query
  String get _dateKey {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header with back button and date selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _buildHeader(),
                ),
                
                // Summary stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSummaryStats(),
                ),
                
                const SizedBox(height: 16),
                
                // Attendance list
                Expanded(
                  child: _buildAttendanceList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    final dateLabel = DateFormat('dd MMM yyyy').format(_selectedDate);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1F1F1F)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance View',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Color(0xFF5C5C5C)),
                        const SizedBox(width: 4),
                        Text(
                          'Read Only • ${isToday ? "Today" : dateLabel}',
                          style: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: [primary, accent]),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Change Date',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryStats() {
    // Query attendance from subcollection: projects/{projectId}/attendance
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('attendance')
          .where('date', isEqualTo: _dateKey)
          .snapshots(),
      builder: (context, snapshot) {
        int totalWorkers = 0;
        int presentCount = 0;
        int gpsVerifiedCount = 0;
        int faceVerifiedCount = 0;
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final record = AttendanceRecord.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
            
            // Each record contains a workers array
            for (var worker in record.workers) {
              totalWorkers++;
              
              if (worker.present) {
                presentCount++;
                
                // Check GPS verification
                if (worker.geoLocation != null && worker.geoLocation!['distanceFromSite'] != null) {
                  final distance = (worker.geoLocation!['distanceFromSite'] as num).toDouble();
                  if (distance <= 100) { // Within 100 meters
                    gpsVerifiedCount++;
                  }
                }
                
                // Check face verification
                if (worker.faceId != null && worker.faceId!.isNotEmpty) {
                  faceVerifiedCount++;
                }
              }
            }
          }
        }
        
        final absentCount = totalWorkers - presentCount;
        
        return Column(
          children: [
            // Main stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    totalWorkers.toString(),
                    Icons.people_outline,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    presentCount.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    absentCount.toString(),
                    Icons.cancel_outlined,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Verification stats row
            Row(
              children: [
                Expanded(
                  child: _buildVerificationStatCard(
                    'GPS Verified',
                    '$gpsVerifiedCount / $presentCount',
                    Icons.location_on,
                    gpsVerifiedCount == presentCount && presentCount > 0 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVerificationStatCard(
                    'Face Verified',
                    '$faceVerifiedCount / $presentCount',
                    Icons.face,
                    faceVerifiedCount == presentCount && presentCount > 0 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVerificationStatCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttendanceList() {
    // Query attendance from subcollection: projects/{projectId}/attendance
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('attendance')
          .where('date', isEqualTo: _dateKey)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No attendance records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Attendance is marked by Field Manager only',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }
        
        // Collect all workers from all attendance records
        final List<WorkerAttendance> allWorkers = [];
        for (var doc in snapshot.data!.docs) {
          final record = AttendanceRecord.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
          allWorkers.addAll(record.workers);
        }
        
        // Sort: Present first, then by name
        allWorkers.sort((a, b) {
          if (a.present != b.present) {
            return a.present ? -1 : 1;
          }
          return a.name.compareTo(b.name);
        });
        
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: allWorkers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildWorkerTile(allWorkers[index]);
          },
        );
      },
    );
  }
  
  Widget _buildWorkerTile(WorkerAttendance worker) {
    // Extract GPS verification data
    double? distanceFromSite;
    bool gpsVerified = false;
    if (worker.geoLocation != null && worker.geoLocation!['distanceFromSite'] != null) {
      distanceFromSite = (worker.geoLocation!['distanceFromSite'] as num).toDouble();
      gpsVerified = distanceFromSite <= 100; // Within 100 meters = GPS verified
    }
    
    // Check face verification
    final faceVerified = worker.faceId != null && worker.faceId!.isNotEmpty;
    
    // Format check-in time
    String? checkInTimeStr;
    if (worker.checkInTime != null) {
      checkInTimeStr = DateFormat('hh:mm a').format(worker.checkInTime!);
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: worker.present 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: worker.present 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      worker.present ? Icons.check_circle : Icons.cancel,
                      color: worker.present ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          worker.role,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: worker.present 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      worker.present ? 'PRESENT' : 'ABSENT',
                      style: TextStyle(
                        color: worker.present ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (worker.present) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Check-in time
                if (checkInTimeStr != null)
                  _buildInfoRow(
                    Icons.access_time,
                    'Check-in',
                    checkInTimeStr,
                    Colors.blue,
                  ),
                
                const SizedBox(height: 8),
                
                // GPS Verification
                _buildVerificationRow(
                  Icons.location_on,
                  'GPS Verified',
                  gpsVerified,
                  distanceFromSite != null 
                      ? '${distanceFromSite.toStringAsFixed(1)}m from site'
                      : 'No GPS data',
                ),
                
                const SizedBox(height: 8),
                
                // Face Verification
                _buildVerificationRow(
                  Icons.face,
                  'Face Verified',
                  faceVerified,
                  faceVerified ? 'Biometric confirmed' : 'No face data',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerificationRow(IconData icon, String label, bool verified, String details) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: verified ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    verified ? Icons.check_circle : Icons.warning,
                    size: 14,
                    color: verified ? Colors.green : Colors.orange,
                  ),
                ],
              ),
              Text(
                details,
                style: TextStyle(
                  fontSize: 11,
                  color: verified ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
