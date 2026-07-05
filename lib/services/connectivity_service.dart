import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and exposes an observable [isOnline] state.
///
/// Screens that care about offline state can watch this via Provider
/// or listen to [addListener]/[removeListener].
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Start listening. Call once at app startup.
  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
    // Initial check
    _check();
  }

  Future<void> _check() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
