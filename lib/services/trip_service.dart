import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the currently active fishing trip.
///
/// When a trip is active, new catches are automatically tagged
/// with the active trip name.
class TripService {
  static final TripService instance = TripService._();
  TripService._();

  static const _key = 'active_trip_name';

  String? _activeTrip;

  /// The name of the currently active trip, or null if none.
  String? get activeTrip => _activeTrip;

  /// Whether a trip is currently active.
  bool get isActive => _activeTrip != null && _activeTrip!.isNotEmpty;

  /// Load the active trip from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _activeTrip = prefs.getString(_key);
  }

  /// Start a new trip with the given [name].
  Future<void> startTrip(String name) async {
    _activeTrip = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
  }

  /// End the current trip — clears the active trip name.
  Future<void> endTrip() async {
    _activeTrip = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
