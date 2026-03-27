import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/song.dart';

enum RepeatMode { none, all, one }

class QueueManager extends ChangeNotifier {
  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.none;

  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong => _queue.isEmpty ? null : _queue[_currentIndex];
  bool get hasPrevious => _currentIndex > 0;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, songs.isEmpty ? 0 : songs.length - 1);
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNext(Song song) {
    _queue.insert(_currentIndex + 1, song);
    notifyListeners();
  }

  void removeAt(int index) {
    _queue.removeAt(index);
    if (_currentIndex >= _queue.length && _currentIndex > 0) {
      _currentIndex = _queue.length - 1;
    }
    notifyListeners();
  }

  void clear() {
    _queue.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);
    notifyListeners();
  }

  Song? getNext() {
    if (_queue.isEmpty) return null;
    if (_repeat == RepeatMode.one) return currentSong;
    if (_shuffle) {
      final idx = Random().nextInt(_queue.length);
      _currentIndex = idx;
      notifyListeners();
      return currentSong;
    }
    if (hasNext) return _queue[_currentIndex + 1];
    if (_repeat == RepeatMode.all) return _queue[0];
    return null;
  }

  void advance() {
    if (_queue.isEmpty) return;
    if (_shuffle) return; // already advanced in getNext
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    } else if (_repeat == RepeatMode.all) {
      _currentIndex = 0;
      notifyListeners();
    }
  }

  Song? getPrevious() => hasPrevious ? _queue[_currentIndex - 1] : null;

  void jumpTo(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void cycleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }
}
