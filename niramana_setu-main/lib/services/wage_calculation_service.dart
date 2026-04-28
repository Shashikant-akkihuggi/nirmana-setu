import 'package:cloud_firestore/cloud_firestore.dart';

/// Wage Calculation Service for Labour Payroll
/// 
/// Automatically calculates daily and monthly wages based on
/// GPS + Face verified attendance records.
class WageCalculationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate daily wage for a labour
  static Future<double> calculateDailyWage(String labourId, String date) async {
    try {
      // Get labour details
      DocumentSnapshot labourDoc = await _firestore
          .collection('labours')
          .doc(labourId)
          .get();

      if (!labourDoc.exists) {
        return 0.0;
      }

      Map<String, dynamic> labourData = labourDoc.data() as Map<String, dynamic>;
      double dailyWage = (labourData['dailyWage'] ?? 0).toDouble();

      // Check if attendance was marked for this date
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('labourId', isEqualTo: labourId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'PRESENT')
          .where('gpsVerified', isEqualTo: true)
          .where('faceVerified', isEqualTo: true)
          .limit(1)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        return dailyWage;
      }

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate monthly wage for a labour
  static Future<MonthlyWageReport> calculateMonthlyWage(
    String labourId,
    int year,
    int month,
  ) async {
    try {
      // Get labour details
      DocumentSnapshot labourDoc = await _firestore
          .collection('labours')
          .doc(labourId)
          .get();

      if (!labourDoc.exists) {
        return MonthlyWageReport(
          labourId: labourId,
          labourName: 'Unknown',
          year: year,
          month: month,
          dailyWage: 0,
          presentDays: 0,
          totalWage: 0,
        );
      }

      Map<String, dynamic> labourData = labourDoc.data() as Map<String, dynamic>;
      String labourName = labourData['name'] ?? 'Unknown';
      double dailyWage = (labourData['dailyWage'] ?? 0).toDouble();

      // Get attendance records for the month
      String startDate = '$year-${month.toString().padLeft(2, '0')}-01';
      String endDate = '$year-${month.toString().padLeft(2, '0')}-31';

      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('labourId', isEqualTo: labourId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'PRESENT')
          .where('gpsVerified', isEqualTo: true)
          .where('faceVerified', isEqualTo: true)
          .get();

      int presentDays = attendanceSnapshot.docs.length;
      double totalWage = presentDays * dailyWage;

      return MonthlyWageReport(
        labourId: labourId,
        labourName: labourName,
        year: year,
        month: month,
        dailyWage: dailyWage,
        presentDays: presentDays,
        totalWage: totalWage,
        attendanceRecords: attendanceSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList(),
      );
    } catch (e) {
      return MonthlyWageReport(
        labourId: labourId,
        labourName: 'Error',
        year: year,
        month: month,
        dailyWage: 0,
        presentDays: 0,
        totalWage: 0,
      );
    }
  }

  /// Calculate project-wide monthly wage summary
  static Future<ProjectWageSummary> calculateProjectMonthlyWages(
    String projectId,
    int year,
    int month,
  ) async {
    try {
      // Get all labours for the project
      QuerySnapshot labourSnapshot = await _firestore
          .collection('labours')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      List<MonthlyWageReport> labourReports = [];
      double totalProjectWage = 0.0;
      int totalPresentDays = 0;

      for (var labourDoc in labourSnapshot.docs) {
        String labourId = labourDoc.id;
        MonthlyWageReport report = await calculateMonthlyWage(labourId, year, month);
        
        labourReports.add(report);
        totalProjectWage += report.totalWage;
        totalPresentDays += report.presentDays;
      }

      return ProjectWageSummary(
        projectId: projectId,
        year: year,
        month: month,
        totalLabours: labourSnapshot.docs.length,
        totalPresentDays: totalPresentDays,
        totalWage: totalProjectWage,
        labourReports: labourReports,
      );
    } catch (e) {
      return ProjectWageSummary(
        projectId: projectId,
        year: year,
        month: month,
        totalLabours: 0,
        totalPresentDays: 0,
        totalWage: 0,
        labourReports: [],
      );
    }
  }

  /// Get daily wage summary for a project
  static Future<DailyWageSummary> calculateDailyWageSummary(
    String projectId,
    String date,
  ) async {
    try {
      // Get all attendance records for the date
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('projectId', isEqualTo: projectId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'PRESENT')
          .where('gpsVerified', isEqualTo: true)
          .where('faceVerified', isEqualTo: true)
          .get();

      double totalDailyWage = 0.0;
      List<Map<String, dynamic>> labourWages = [];

      for (var attendanceDoc in attendanceSnapshot.docs) {
        Map<String, dynamic> attendanceData = attendanceDoc.data() as Map<String, dynamic>;
        String labourId = attendanceData['labourId'];

        // Get labour wage
        DocumentSnapshot labourDoc = await _firestore
            .collection('labours')
            .doc(labourId)
            .get();

        if (labourDoc.exists) {
          Map<String, dynamic> labourData = labourDoc.data() as Map<String, dynamic>;
          double dailyWage = (labourData['dailyWage'] ?? 0).toDouble();
          
          totalDailyWage += dailyWage;
          
          labourWages.add({
            'labourId': labourId,
            'labourName': labourData['name'],
            'role': labourData['role'],
            'dailyWage': dailyWage,
          });
        }
      }

      return DailyWageSummary(
        projectId: projectId,
        date: date,
        totalLabours: attendanceSnapshot.docs.length,
        totalWage: totalDailyWage,
        labourWages: labourWages,
      );
    } catch (e) {
      return DailyWageSummary(
        projectId: projectId,
        date: date,
        totalLabours: 0,
        totalWage: 0,
        labourWages: [],
      );
    }
  }

  /// Stream daily wage summary
  static Stream<DailyWageSummary> streamDailyWageSummary(
    String projectId,
    String date,
  ) {
    return _firestore
        .collection('attendance')
        .where('projectId', isEqualTo: projectId)
        .where('date', isEqualTo: date)
        .where('status', isEqualTo: 'PRESENT')
        .snapshots()
        .asyncMap((_) => calculateDailyWageSummary(projectId, date));
  }
}

/// Monthly wage report for a single labour
class MonthlyWageReport {
  final String labourId;
  final String labourName;
  final int year;
  final int month;
  final double dailyWage;
  final int presentDays;
  final double totalWage;
  final List<Map<String, dynamic>>? attendanceRecords;

  MonthlyWageReport({
    required this.labourId,
    required this.labourName,
    required this.year,
    required this.month,
    required this.dailyWage,
    required this.presentDays,
    required this.totalWage,
    this.attendanceRecords,
  });

  Map<String, dynamic> toJson() {
    return {
      'labourId': labourId,
      'labourName': labourName,
      'year': year,
      'month': month,
      'dailyWage': dailyWage,
      'presentDays': presentDays,
      'totalWage': totalWage,
    };
  }
}

/// Project-wide wage summary for a month
class ProjectWageSummary {
  final String projectId;
  final int year;
  final int month;
  final int totalLabours;
  final int totalPresentDays;
  final double totalWage;
  final List<MonthlyWageReport> labourReports;

  ProjectWageSummary({
    required this.projectId,
    required this.year,
    required this.month,
    required this.totalLabours,
    required this.totalPresentDays,
    required this.totalWage,
    required this.labourReports,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'year': year,
      'month': month,
      'totalLabours': totalLabours,
      'totalPresentDays': totalPresentDays,
      'totalWage': totalWage,
      'labourReports': labourReports.map((r) => r.toJson()).toList(),
    };
  }
}

/// Daily wage summary for a project
class DailyWageSummary {
  final String projectId;
  final String date;
  final int totalLabours;
  final double totalWage;
  final List<Map<String, dynamic>> labourWages;

  DailyWageSummary({
    required this.projectId,
    required this.date,
    required this.totalLabours,
    required this.totalWage,
    required this.labourWages,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'date': date,
      'totalLabours': totalLabours,
      'totalWage': totalWage,
      'labourWages': labourWages,
    };
  }
}
