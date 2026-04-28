import 'package:flutter/material.dart';
import '../widgets/timeline.dart';
// cost estimation moved to its own screen to fix navigation

class MilestoneTimelineScreen extends StatelessWidget {
  const MilestoneTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Timeline'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              MilestoneTimeline(),
            ],
          ),
        ),
      ),
    );
  }
}
