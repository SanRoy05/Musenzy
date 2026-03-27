import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/audio_handler.dart';
import '../services/library_service.dart';
import '../services/queue_manager.dart';

class MusicProvider extends ChangeNotifier {
  final MusicAudioHandler _handler;
  final QueueManager _queueManager;
  final LibraryService _libraryService;

  Song? _currentSong;
  bool _isLoading = false;
  String? _error;

  MusicProvider(this._handler, this._queueManager, this._libraryService) {
    // Listen to queue changes to sync current song
    _queueManager.addListener(_onQueueChanged);

    // Listen to playback state for UI updates
    _handler.playbackState.listen((_) => notifyListeners());
    _handler.mediaItem.listen((item) {
      if (item != null) {
        _currentSong = _queueManager.currentSong;
        notifyListeners();
      }
    });
  }

  void _onQueueChanged() {
    notifyListeners();
  }

  Song? get currentSong => _currentSong ?? _queueManager.currentSong;
  bool get isPlaying =>
      _handler.playbackState.value.playing;
  bool get isLoading => _isLoading ||
      _handler.playbackState.value.processingState ==
          AudioProcessingState.loading ||
      _handler.playbackState.value.processingState ==
          AudioProcessingState.buffering;
  String? get error => _error;
  QueueManager get queueManager => _queueManager;
  LibraryService get libraryService => _libraryService;
  MusicAudioHandler get handler => _handler;

  Stream<Duration> get positionStream => _handler.positionStream;
  Stream<Duration?> get durationStream => _handler.durationStream;
  Stream<PlayerState> get playerStateStream => _handler.playerStateStream;

  // ─── Playback control ──────────────────────────────────────────────────────

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Set up queue
    if (queue != null) {
      _queueManager.setQueue(queue, startIndex: index ?? 0);
    } else {
      // Play single song — wrap in single-item queue if no queue active
      if (!_queueManager.queue.contains(song)) {
        _queueManager.setQueue([song]);
      }
    }

    _currentSong = song;

    try {
      await _handler.playMediaItem(
        MusicAudioHandler.songToMediaItem(song),
      );
      _libraryService.addToHistory(song);
    } catch (e) {
      _error = 'Cannot play this song';
      debugPrint('MusicProvider.playSong error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
    notifyListeners();
  }

  Future<void> skipNext() async {
    await _handler.skipToNext();
    _currentSong = _queueManager.currentSong;
    notifyListeners();
  }

  Future<void> skipPrevious() async {
    await _handler.skipToPrevious();
    _currentSong = _queueManager.currentSong;
    notifyListeners();
  }

  Future<void> seek(Duration pos) async {
    await _handler.seek(pos);
    notifyListeners();
  }

  void toggleShuffle() {
    _queueManager.toggleShuffle();
    notifyListeners();
  }

  void cycleRepeat() {
    _queueManager.cycleRepeat();
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    await _handler.setVolume(v);
    notifyListeners();
  }

  double get volume => _handler.volume;

  // ─── Liked state helpers ──────────────────────────────────────────────────

  bool isLiked(String videoId) => _libraryService.isLiked(videoId);

  void toggleLike(Song song) {
    if (_libraryService.isLiked(song.videoId)) {
      _libraryService.unlikeSong(song.videoId);
    } else {
      _libraryService.likeSong(song);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _queueManager.removeListener(_onQueueChanged);
    super.dispose();
  }
}
