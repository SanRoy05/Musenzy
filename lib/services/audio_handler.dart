import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'music_service.dart';
import 'queue_manager.dart';
import 'sleep_timer_service.dart';

class MusicAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final MusicService _musicService;
  final QueueManager _queueManager;

  /// Generation counter — prevents stale async callbacks from firing
  int _generation = 0;
  bool _isLoadingStream = false;

  MusicAudioHandler({
    required MusicService musicService,
    required QueueManager queueManager,
  })  : _musicService = musicService,
        _queueManager = queueManager {
    _init();
  }

  void _init() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Auto-play next track on completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // Handle audio session interruptions (phone calls, etc.)
    AudioSession.instance.then((session) {
      session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          pause();
        } else {
          if (!kIsWeb &&
              event.type != AudioInterruptionType.unknown) {
            play();
          }
        }
      });
    });
  }

  Future<void> _onTrackCompleted() async {
    final sleepTimer = GetIt.I<SleepTimerService>();
    if (sleepTimer.isActive && sleepTimer.remainingSeconds == -1) {
      await _player.setVolume(1.0);
      await stop();
      sleepTimer.cancel();
      return;
    }

    final next = _queueManager.getNext();
    if (next != null) {
      _queueManager.advance();
      await playMediaItem(_songToMediaItem(next));
    } else {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
      ));
    }
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    _isLoadingStream = true;
    final gen = ++_generation;

    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
      playing: false,
    ));

    try {
      final videoId = mediaItem.extras?['videoId'] as String? ?? mediaItem.id;
      final streamUrl = await _musicService.getStreamUrl(videoId);

      if (gen != _generation) return; // cancelled

      await _player.setUrl(streamUrl);
      if (gen != _generation) return;

      _isLoadingStream = false;
      await _player.play();
    } catch (e) {
      if (gen != _generation) return;
      _isLoadingStream = false;
      debugPrint('MusicAudioHandler: playMediaItem error: $e');
      // Auto-skip after 2s on error
      await Future.delayed(const Duration(seconds: 2));
      if (gen != _generation) return;
      await skipToNext();
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _generation++;
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final sleepTimer = GetIt.I<SleepTimerService>();
    if (sleepTimer.isActive && sleepTimer.remainingSeconds == -1) {
      await _player.setVolume(1.0);
      await stop();
      sleepTimer.cancel();
      return;
    }

    final next = _queueManager.getNext();
    if (next != null) {
      _queueManager.advance();
      await playMediaItem(_songToMediaItem(next));
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
    } else {
      final prev = _queueManager.getPrevious();
      if (prev != null) {
        _queueManager.jumpTo(_queueManager.currentIndex - 1);
        await playMediaItem(_songToMediaItem(prev));
      }
    }
  }

  // ─── Expose streams for UI ───────────────────────────────────────────────────

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;
  bool get isLoadingStream => _isLoadingStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  // ─── Volume ─────────────────────────────────────────────────────────────────

  Future<void> setVolume(double volume) => _player.setVolume(volume);
  double get volume => _player.volume;

  // ─── Sleep Timer ────────────────────────────────────────────────────────────

  void startSleepTimer(int minutes) {
    final sleepTimer = GetIt.I<SleepTimerService>();
    sleepTimer.start(
      minutes: minutes,
      onStop: () async {
        await _player.setVolume(1.0);
        await stop();
        _queueManager.clear();
      },
      onFade: (volume) async {
        await _player.setVolume(volume);
      },
    );
  }

  void cancelSleepTimer() {
    _player.setVolume(1.0);
    GetIt.I<SleepTimerService>().cancel();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  static MediaItem songToMediaItem(Song song) => _songToMediaItemStatic(song);

  static MediaItem _songToMediaItemStatic(Song song) => MediaItem(
        id: song.videoId,
        title: song.title,
        artist: song.artist,
        artUri: song.thumbnailUrl.isNotEmpty
            ? Uri.tryParse(song.thumbnailUrl)
            : null,
        duration: Duration(seconds: song.duration),
        extras: {'videoId': song.videoId},
      );

  MediaItem _songToMediaItem(Song song) => _songToMediaItemStatic(song);

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    return super.onTaskRemoved();
  }
}
