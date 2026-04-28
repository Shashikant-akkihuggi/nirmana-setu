import 'dart:async';
import 'package:hive/hive.dart';

import '../models/milestone.dart';
import 'milestone_repository.dart';

class CostEstimationService {
  static const String settingsBoxName = 'cost_settings';
  static const String summaryBoxName = 'cost_summary';

  static final CostEstimationService instance =
  CostEstimationService._internal();
  CostEstimationService._internal();

  bool _initialized = false;
  StreamSubscription? _milestoneSub;

  // Defaults
  static const double defaultLength = 30;
  static const double defaultWidth = 40;
  static const int defaultFloors = 1;
  static const int defaultCostPerSqFt = 2200;

  static const Map<String, double> defaultPercentages = {
    'Site Preparation': 0.03,
    'Foundation': 0.15,
    'Super Structure': 0.35,
    'Brickwork & Plaster': 0.15,
    'Electrical & Plumbing': 0.12,
    'Finishing': 0.18,
    'Final Inspection': 0.02,
  };

  Future<void> init() async {
    if (_initialized) return;

    await MilestoneRepository().init();

    if (!Hive.isBoxOpen(settingsBoxName)) {
      await Hive.openBox(settingsBoxName);
    }
    if (!Hive.isBoxOpen(summaryBoxName)) {
      await Hive.openBox(summaryBoxName);
    }

    final settings = Hive.box(settingsBoxName);

    // ✅ FIX: Hive-safe default seeding
    if (!settings.containsKey('plotLength')) {
      settings.put('plotLength', defaultLength);
    }
    if (!settings.containsKey('plotWidth')) {
      settings.put('plotWidth', defaultWidth);
    }
    if (!settings.containsKey('numberOfFloors')) {
      settings.put('numberOfFloors', defaultFloors);
    }
    if (!settings.containsKey('costPerSqFt')) {
      settings.put('costPerSqFt', defaultCostPerSqFt);
    }
    if (!settings.containsKey('percentages')) {
      settings.put(
        'percentages',
        Map<String, double>.from(defaultPercentages),
      );
    }

    await _computeAndStore();

    final milestonesBox =
    Hive.box<Milestone>(MilestoneRepository.boxName);
    _milestoneSub = milestonesBox.watch().listen((_) async {
      await _computeAndStore();
    });

    _initialized = true;
  }

  Future<void> dispose() async {
    await _milestoneSub?.cancel();
    _milestoneSub = null;
    _initialized = false;
  }

  Future<void> updateArea({
    double? plotLength,
    double? plotWidth,
    int? numberOfFloors,
  }) async {
    final settings = Hive.box(settingsBoxName);
    if (plotLength != null && plotLength > 0) {
      settings.put('plotLength', plotLength);
    }
    if (plotWidth != null && plotWidth > 0) {
      settings.put('plotWidth', plotWidth);
    }
    if (numberOfFloors != null && numberOfFloors > 0) {
      settings.put('numberOfFloors', numberOfFloors);
    }
    await _computeAndStore();
  }

  Future<void> updateCostPerSqFt(int value) async {
    final v = value.clamp(1800, 2500);
    Hive.box(settingsBoxName).put('costPerSqFt', v);
    await _computeAndStore();
  }

  Future<void> updatePercentages(Map<String, double> percents) async {
    Hive.box(settingsBoxName).put(
      'percentages',
      Map<String, double>.from(percents),
    );
    await _computeAndStore();
  }

  Map<String, dynamic> currentSettings() {
    final s = Hive.box(settingsBoxName);
    return {
      'plotLength': (s.get('plotLength') as num).toDouble(),
      'plotWidth': (s.get('plotWidth') as num).toDouble(),
      'numberOfFloors': (s.get('numberOfFloors') as num).toInt(),
      'costPerSqFt': (s.get('costPerSqFt') as num).toInt(),
      'percentages':
      Map<String, double>.from(s.get('percentages')),
    };
  }

  Map<String, dynamic> currentSummary() {
    final b = Hive.box(summaryBoxName);
    return Map<String, dynamic>.from(b.get('summary') ?? {});
  }

  Future<void> _computeAndStore() async {
    final settings = currentSettings();
    final length = settings['plotLength'] as double;
    final width = settings['plotWidth'] as double;
    final floors = settings['numberOfFloors'] as int;
    final costPerSqFt = settings['costPerSqFt'] as int;
    final Map<String, double> percentages =
    settings['percentages'] as Map<String, double>;

    final builtUpArea = length * width * floors;
    final totalCost = builtUpArea * costPerSqFt;

    final repo = MilestoneRepository();
    final milestones = repo.getAll();

    final List<Map<String, dynamic>> breakdown = [];
    for (final m in milestones) {
      final p = percentages[m.title] ?? 0.0;
      breakdown.add({
        'title': m.title,
        'percent': p,
        'amount': totalCost * p,
        'status': m.status,
      });
    }

    final summary = {
      'builtUpArea': builtUpArea,
      'costPerSqFt': costPerSqFt,
      'totalCost': totalCost,
      'breakdown': breakdown,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    Hive.box(summaryBoxName).put('summary', summary);
  }
}
