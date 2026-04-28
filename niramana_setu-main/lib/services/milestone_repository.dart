import 'package:hive/hive.dart';
import '../models/milestone.dart';

class MilestoneRepository {
  static const String boxName = 'milestones_box';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(MilestoneAdapter());
    }
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Milestone>(boxName);
    }
    await _seedDefaultsIfEmpty();
  }

  Box<Milestone> get _box => Hive.box<Milestone>(boxName);

  Future<void> _seedDefaultsIfEmpty() async {
    if (_box.isEmpty) {
      final DateTime base = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final List<String> titles = const [
        'Site Preparation',
        'Foundation',
        'Super Structure',
        'Brickwork & Plaster',
        'Electrical & Plumbing',
        'Finishing',
        'Final Inspection',
      ];
      final durations = [7, 21, 60, 30, 25, 20, 7];
      DateTime cursor = base;
      for (int i = 0; i < titles.length; i++) {
        final m = Milestone(
          id: 'ms_${i + 1}',
          title: titles[i],
          plannedStart: cursor,
          plannedDurationDays: durations[i],
        );
        m.status = MilestoneStatusCalculator.calculate(m, DateTime.now());
        await _box.put(m.id, m);
        cursor = cursor.add(Duration(days: durations[i]));
      }
    }
  }

  List<Milestone> getAll() {
    final now = DateTime.now();
    return _box.values.map((m) {
      m.status = MilestoneStatusCalculator.calculate(m, now);
      return m;
    }).toList()
      ..sort((a, b) => a.plannedStart.compareTo(b.plannedStart));
  }

  Future<void> upsert(Milestone m) async {
    m.status = MilestoneStatusCalculator.calculate(m, DateTime.now());
    await _box.put(m.id, m);
  }

  Future<void> markStarted(String id, DateTime start) async {
    final m = _box.get(id);
    if (m != null) {
      m.actualStart = start;
      m.status = MilestoneStatusCalculator.calculate(m, DateTime.now());
      await m.save();
    }
  }

  Future<void> markCompleted(String id, DateTime end) async {
    final m = _box.get(id);
    if (m != null) {
      m.actualEnd = end;
      m.status = MilestoneStatusCalculator.calculate(m, DateTime.now());
      await m.save();
    }
  }
}
