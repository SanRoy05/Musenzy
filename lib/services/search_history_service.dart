import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SearchHistoryService {
  static const String _boxName = 'search_history';
  static const int _maxHistory = 20;

  Box<String> get _box => Hive.box<String>(_boxName);

  // Add a search query to history
  void addSearch(String query) {
    if (query.trim().isEmpty) return;
    final q = query.trim();

    // Remove duplicate if exists (move to top)
    final existingEntries = _box.toMap().entries.toList();
    final dupKey = existingEntries.firstWhere(
      (e) => e.value.toLowerCase() == q.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    ).key;

    if (dupKey != '') {
      _box.delete(dupKey);
    }

    // Add with current timestamp as key to keep order
    _box.put(DateTime.now().millisecondsSinceEpoch.toString(), q);

    // Keep only last 20
    if (_box.length > _maxHistory) {
      final keys = _box.keys.toList()..sort();
      if (keys.isNotEmpty) {
        _box.delete(keys.first);
      }
    }
  }

  // Get recent searches — newest first
  List<String> getRecentSearches() {
    final entries = _box.toMap().entries.toList();
    entries.sort((a, b) => b.key.toString().compareTo(a.key.toString()));
    return entries.map((e) => e.value).toList();
  }

  // Delete one search
  void deleteSearch(String query) {
    final key = _box.toMap().entries
      .firstWhere((e) => e.value == query,
        orElse: () => const MapEntry('', ''))
      .key;
    if (key != '') _box.delete(key);
  }

  // Clear all
  void clearAll() => _box.clear();

  // Get ValueListenable for reactive UI updates
  ValueListenable<Box<String>> get listenable => _box.listenable();
}
