import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/milestone.dart';
import '../../services/milestone_repository.dart';

class MilestoneTimeline extends StatefulWidget {
  const MilestoneTimeline({super.key});

  @override
  State<MilestoneTimeline> createState() => _MilestoneTimelineState();
}

class _MilestoneTimelineState extends State<MilestoneTimeline> {
  final repo = MilestoneRepository();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await repo.init();
    setState(() => _ready = true);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'onTrack':
        return const Color(0xFF16A34A); // green
      case 'atRisk':
        return const Color(0xFFF59E0B); // yellow
      case 'delayed':
        return const Color(0xFFDC2626); // red
      case 'completed':
        return const Color(0xFF111827); // dark/check
      case 'upcoming':
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed':
        return Icons.check_circle;
      case 'delayed':
        return Icons.error_rounded;
      case 'atRisk':
        return Icons.warning_amber_rounded;
      case 'onTrack':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.timeline_rounded, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text('Construction Timeline', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: Hive.box<Milestone>(MilestoneRepository.boxName).listenable(),
                builder: (_, Box<Milestone> box, __) {
                  final items = repo.getAll();
                  if (items.isEmpty) {
                    return const Text('No milestones configured', style: TextStyle(color: Color(0xFF6B7280)));
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < items.length; i++) _tile(items[i], i == items.length - 1),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Milestone m, bool isLast) {
    final c = _statusColor(m.status);
    final icon = _statusIcon(m.status);
    final dateFmt = '${m.plannedStart.day.toString().padLeft(2, '0')}-${m.plannedStart.month.toString().padLeft(2, '0')}-${m.plannedStart.year}';
    final plannedEnd = m.plannedEnd;
    final endFmt = '${plannedEnd.day.toString().padLeft(2, '0')}-${plannedEnd.month.toString().padLeft(2, '0')}-${plannedEnd.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.12),
                border: Border.all(color: c.withValues(alpha: 0.6)),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text('Plan: $dateFmt → $endFmt • ${m.plannedDurationDays} days', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    _label(m.status),
                    style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _label(String s) {
    switch (s) {
      case 'onTrack':
        return 'On Track';
      case 'atRisk':
        return 'At Risk';
      case 'delayed':
        return 'Delayed';
      case 'completed':
        return 'Completed';
      default:
        return 'Upcoming';
    }
  }
}
