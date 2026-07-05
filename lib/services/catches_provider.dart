import 'package:flutter/foundation.dart';
import '../models/catch.dart';
import 'catches_db_service.dart';

/// Holds the catches list in memory and notifies listeners on changes.
///
/// Screens that display catch data should watch this provider instead of
/// calling CatchesDbService directly and managing their own _catches + _loading.
class CatchesProvider extends ChangeNotifier {
  List<Catch> _catches = [];
  List<Catch> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  List<Catch> get catches => _searchQuery.isEmpty ? _catches : _filtered;
  bool get loading => _loading;
  String? get error => _error;
  int get count => catches.length;
  String get searchQuery => _searchQuery;

  /// Update the search query and re-filter.
  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    if (_searchQuery.isEmpty) {
      _filtered = [];
    } else {
      _filtered = _catches.where((c) {
        return c.species.toLowerCase().contains(_searchQuery) ||
            c.angler.toLowerCase().contains(_searchQuery) ||
            c.location.toLowerCase().contains(_searchQuery) ||
            c.lure.toLowerCase().contains(_searchQuery) ||
            (c.notes?.toLowerCase().contains(_searchQuery) ?? false) ||
            (c.tripName?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  /// Load catches from DB. Call this on app start and after mutations.
  Future<void> loadCatches() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _catches = await CatchesDbService.instance.getCatches();
      _filtered = _catches;
      _loading = false;
    } catch (e) {
      _error = 'Failed to load catches: $e';
      _loading = false;
    }
    if (_searchQuery.isNotEmpty) setSearchQuery(_searchQuery);
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
