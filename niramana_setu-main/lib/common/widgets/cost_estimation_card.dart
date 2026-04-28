import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/cost_estimation_service.dart';

class CostEstimationCard extends StatefulWidget {
  const CostEstimationCard({super.key});

  @override
  State<CostEstimationCard> createState() => _CostEstimationCardState();
}

class _CostEstimationCardState extends State<CostEstimationCard> {
  final service = CostEstimationService.instance;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await service.init();
    setState(() => _ready = true);
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
                  Icon(Icons.payments_outlined, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text('Cost Estimation', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                ],
              ),
              const SizedBox(height: 10),
              // Listen to summary changes
              ValueListenableBuilder(
                valueListenable: Hive.box(CostEstimationService.summaryBoxName).listenable(),
                builder: (_, Box box, __) {
                  final summary = Map<String, dynamic>.from(box.get('summary') ?? {});
                  if (summary.isEmpty) {
                    return const Text('No estimation available', style: TextStyle(color: Color(0xFF6B7280)));
                  }

                  final builtUpArea = (summary['builtUpArea'] as num).toDouble();
                  final costPerSqFt = (summary['costPerSqFt'] as num).toInt();
                  final totalCost = (summary['totalCost'] as num).toDouble();
                  final List breakdown = summary['breakdown'] as List;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Built-up area: ${builtUpArea.toStringAsFixed(0)} sq.ft • Rate: ₹$costPerSqFt/sq.ft',
                          style: const TextStyle(color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      ...breakdown.map((e) {
                        final Map item = e as Map;
                        final title = item['title'] as String;
                        final percent = (item['percent'] as num).toDouble();
                        final amount = (item['amount'] as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(title, style: const TextStyle(color: Color(0xFF1F2937))),
                              ),
                              Text('₹${_fmt(amount)}  (${(percent * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                          const SizedBox(width: 8),
                          Text('₹${_fmt(totalCost)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Approximate cost – for planning only',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
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

  String _fmt(double v) {
    // Simple grouping formatter for INR
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i > 0) {
        buf.write(',');
      } else if (count > 3 && (count - 3) % 2 == 0 && i > 0) {
        buf.write(',');
      }
    }
    return buf.toString().split('').reversed.join();
  }
}
