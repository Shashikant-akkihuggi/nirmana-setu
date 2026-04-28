import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity Service
/// 
/// Monitors network connectivity status and provides real-time updates
/// to enable offline-first functionality with automatic sync.
/// 
/// Why needed?
/// - Detects when internet connection is available
/// - Triggers automatic sync when online
/// - Prevents sync attempts when offline
/// - Provides UI feedback about connection status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  bool _isOnline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream that emits true when online, false when offline
  /// 
  /// UI components can listen to this stream to show connection status.
  /// Sync service listens to trigger automatic synchronization.
  Stream<bool> get isOnlineStream => _connectionController.stream;

  /// Current connection status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  /// 
  /// This should be called once at app startup.
  /// Checks initial connection status and starts listening for changes.
  Future<void> initialize() async {
    // Check initial connectivity status
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  /// Update connection status based on connectivity result
  /// 
  /// Considers mobile, wifi, and ethernet as "online".
  /// None or bluetooth are considered "offline".
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final wasOnline = _isOnline;
    
    // Check if any connection type indicates online status
    _isOnline = result.any((r) => 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet
    );

    // Only emit if status changed
    if (wasOnline != _isOnline) {
      _connectionController.add(_isOnline);
      print('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    }
  }

  /// Check current connectivity status immediately
  /// 
  /// Returns true if connected to internet, false otherwise.
  /// Useful for one-time checks without listening to stream.
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet
    );
  }

  /// Clean up resources
  /// 
  /// Should be called when service is no longer needed.
  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
  }
}
