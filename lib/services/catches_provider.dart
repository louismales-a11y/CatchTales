import 'package:flutter/foundation.dart';
import '../models/catch.dart';
import 'catches_db_service.dart';

/// Holds the catches list in memory and notifies listeners on changes.
///
/// Screens that display catch data should watch this provider instead of
/// calling CatchesDbService directly and managing their own _catches + _loading.
class CatchesProvider extends ChangeNotifier {
  List<Catch> _catches = [];
  bool _loading = true;
  String? _error;

  List<Catch> get catches => _catches;
  bool get loading => _loading;
  String? get error => _error;
  int get count => _catches.length;

  /// Load catches from DB. Call this on app start and after mutations.
  Future<void> loadCatches() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _catches = await CatchesDbService.instance.getCatches();
      _loading = false;
    } catch (e) {
      _error = 'Failed to load catches: $e';
      _loading = false;
    }
    notifyListeners();
  }

  /// Delete a catch and refresh the list.
  Future<bool> deleteCatch(int id) async {
    try {
      await CatchesDbService.instance.deleteCatch(id);
      await loadCatches();
      return true;
    } catch (e) {
      _error = 'Failed to delete catch: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add a catch and refresh the list.
  Future<bool> addCatch(Catch c) async {
    try {
      await CatchesDbService.instance.addCatch(c);
      await loadCatches();
      return true;
    } catch (e) {
      _error = 'Failed to add catch: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update a catch and refresh the list.
  Future<bool> updateCatch(Catch c) async {
    try {
      await CatchesDbService.instance.updateCatch(c);
      await loadCatches();
      return true;
    } catch (e) {
      _error = 'Failed to update catch: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get total catch count (for Pro limit check).
  Future<int> getCatchCount() => CatchesDbService.instance.getCatchCount();
}
