import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../common/widgets/timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _ThemePD {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class AttendanceEntry {
  final String id;
  final String workerName;
  final bool present;
  final String role;
  final DateTime date;
  AttendanceEntry({required this.id, required this.workerName, required this.present, required this.role, required this.date});

  static AttendanceEntry fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceEntry(
      id: doc.id,
      workerName: data['workerName'] ?? '',
      present: data['present'] == true,
      role: data['role'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  Stream<List<AttendanceEntry>> _attendanceTodayStream() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map(AttendanceEntry.fromFirestore).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: StreamBuilder<List<AttendanceEntry>>(
              stream: _attendanceTodayStream(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <AttendanceEntry>[];
                final int totalWorkers = items.length;
                final int presentWorkers = items.where((w) => w.present).length;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(
                        project: 'Project',
                        engineer: 'Engineer',
                      ),
                      const SizedBox(height: 12),
                      _DatesProgressCard(
                        start: DateTime(2024, 1, 12),
                        end: DateTime(2025, 11, 30),
                        progress: 0.62,
                      ),
                      const SizedBox(height: 12),
                      const _CostSummaryCard(total: 1.20, spent: 0.87, remaining: 0.33),
                      const SizedBox(height: 12),
                      const MilestoneTimeline(),
                      const SizedBox(height: 12),
                      _WorkforceOverviewCard(
                        totalWorkers: totalWorkers,
                        presentWorkers: presentWorkers,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
            _ThemePD.primary.withValues(alpha: 0.12),
            _ThemePD.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String project;
  final String engineer;
  const _HeaderCard({required this.project, required this.engineer});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: _ThemePD.primary.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
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
                  gradient: const LinearGradient(colors: [_ThemePD.primary, _ThemePD.accent]),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.engineering, size: 18, color: Color(0xFF374151)),
                        const SizedBox(width: 6),
                        Text(engineer, style: const TextStyle(color: Color(0xFF374151))),
                      ],
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
}

class _DatesProgressCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final double progress;
  const _DatesProgressCard({required this.start, required this.end, required this.progress});

  @override
  Widget build(BuildContext context) {
    final String s = '${start.day.toString().padLeft(2, '0')}-${start.month.toString().padLeft(2, '0')}-${start.year}';
    final String e = '${end.day.toString().padLeft(2, '0')}-${end.month.toString().padLeft(2, '0')}-${end.year}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFF374151)),
                  const SizedBox(width: 8),
                  Text('Start: $s   •   End: $e', style: const TextStyle(color: Color(0xFF374151))),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, c) => Container(
                      height: 10,
                      width: c.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostSummaryCard extends StatelessWidget {
  final double total; // crores
  final double spent; // crores
  final double remaining; // crores
  const _CostSummaryCard({required this.total, required this.spent, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _costTile(Icons.savings, 'Total', '₹${(total).toStringAsFixed(2)} Cr'),
              const SizedBox(width: 12),
              _costTile(Icons.account_balance_wallet, 'Spent', '₹${(spent).toStringAsFixed(2)} Cr'),
              const SizedBox(width: 12),
              _costTile(Icons.account_balance, 'Remain', '₹${(remaining).toStringAsFixed(2)} Cr'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _costTile(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF374151)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}

class _WorkforceOverviewCard extends StatelessWidget {
  final int totalWorkers;
  final int presentWorkers;
  const _WorkforceOverviewCard({required this.totalWorkers, required this.presentWorkers});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: _ThemePD.accent.withValues(alpha: 0.18), blurRadius: 30, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.groups_rounded, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text('Workforce Overview', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statTile(
                    icon: Icons.engineering,
                    label: 'Total Workers',
                    value: totalWorkers.toString(),
                    color: const Color(0xFF1F2937),
                  ),
                  const SizedBox(width: 12),
                  _statTile(
                    icon: Icons.check_circle,
                    label: 'Present Today',
                    value: presentWorkers.toString(),
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_ThemePD.primary, _ThemePD.accent]),
                    boxShadow: [BoxShadow(color: _ThemePD.primary.withValues(alpha: 0.25), blurRadius: 14)],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Color(0xFF4B5563))),
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: color,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
