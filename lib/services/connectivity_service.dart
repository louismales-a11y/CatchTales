import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monitors network connectivity and exposes observable state.
/// Also manages the WiFi-only data transfer preference.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _isWifi = false;
  /// Whether we're currently connected via WiFi (or ethernet).
  bool get isWifi => _isWifi;

  bool _wifiOnly = false;
  /// User preference: only allow data transfers over WiFi.
  bool get wifiOnly => _wifiOnly;

  /// Whether data transfer is allowed right now.
  /// Returns false if wifiOnly is enabled and we're not on WiFi.
  bool get canTransferData => _isOnline && (!_wifiOnly || _isWifi);

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Start listening. Call once at app startup.
  void start() async {
    // Load WiFi-only preference
    final prefs = await SharedPreferences.getInstance();
    _wifiOnly = prefs.getBool('wifi_only_transfer') ?? false;

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      _updateState(results);
    });
    // Initial check
    await _check();
  }

  /// Set the WiFi-only preference.
  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifi_only_transfer', value);
    notifyListeners();
  }

  void _updateState(List<ConnectivityResult> results) {
    final online = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    final wifi = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    final changed = (online != _isOnline) || (wifi != _isWifi);
    _isOnline = online;
    _isWifi = wifi;
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _check() async {
    final results = await Connectivity().checkConnectivity();
    _updateState(results);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
