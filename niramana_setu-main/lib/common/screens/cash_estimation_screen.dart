import 'package:flutter/material.dart';
import '../widgets/cost_estimation_card.dart';

class CashEstimationScreen extends StatelessWidget {
  const CashEstimationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Estimation'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: CostEstimationCard(),
        ),
      ),
    );
  }
}
