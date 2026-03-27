import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:marquee/marquee.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/audio_handler.dart';
import '../services/library_service.dart';
import '../services/queue_manager.dart';
import '../services/sleep_timer_service.dart';
import '../widgets/sleep_timer_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  Color _dominantColor = kAccent;
  Song? _lastSong;
  bool _isSeeking = false;
  double _seekValue = 0;
  late AnimationController _albumArtController;

  @override
  void initState() {
    super.initState();
    _albumArtController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _albumArtController.dispose();
    super.dispose();
  }

  Future<void> _extractColor(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final pg = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        maximumColorCount: 8,
      );
      if (mounted) {
        setState(() {
          _dominantColor =
              pg.dominantColor?.color ?? pg.vibrantColor?.color ?? kAccent;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;

        if (song != null && song != _lastSong) {
          _lastSong = song;
          _extractColor(song.thumbnailUrl);
          // Animate album art
          _albumArtController.forward(from: 0.0);
        }

        return Scaffold(
          backgroundColor: kBackground,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _dominantColor.withAlpha(153),
                  kBackground,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      _buildTopBar(context),
                      _buildFadeIndicator(),
                      const SizedBox(height: 24),
                      if (song != null) ...[
                        _buildAlbumArt(song),
                        const SizedBox(height: 32),
                        _buildTitleRow(context, provider, song),
                        const SizedBox(height: 24),
                        _buildProgressBar(provider),
                        const SizedBox(height: 16),
                        _buildControls(provider),
                        const SizedBox(height: 20),
                        _buildBottomActions(context, provider, song),
                      ] else
                        const Expanded(
                          child: Center(
                            child: Text('No song playing',
                                style: TextStyle(
                                    color: kTextSecondary, fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: kTextPrimary, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Now Playing',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextPrimary, fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded,
                color: kTextPrimary, size: 24),
            onPressed: () => _showQueueSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    return StreamBuilder<PlaybackState>(
      stream: GetIt.I<MusicAudioHandler>().playbackState,
      builder: (_, snap) {
        final isPlaying = snap.data?.playing ?? false;
        return AnimatedScale(
          scale: isPlaying ? 1.0 : 0.92,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Hero(
            tag: 'player_thumbnail',
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65,
              height: MediaQuery.of(context).size.width * 0.65,
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kPlayerRadius),
                boxShadow: [
                  BoxShadow(
                    color: _dominantColor.withAlpha(102),
                    blurRadius: 40,
                    spreadRadius: 8,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kPlayerRadius),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: kSurface),
                  errorWidget: (_, __, ___) => Container(
                    color: kSurface,
                    child: const Icon(Icons.music_note_rounded,
                        color: kAccent, size: 64),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleRow(
      BuildContext context, MusicProvider provider, Song song) {
    final isLiked = provider.isLiked(song.videoId);
    final titleTooLong = song.title.length > 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleTooLong
                    ? SizedBox(
                        height: 26,
                        child: Marquee(
                          text: song.title,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 40,
                          velocity: 40,
                          pauseAfterRound: const Duration(seconds: 1),
                          fadingEdgeEndFraction: 0.1,
                          fadingEdgeStartFraction: 0.1,
                        ),
                      )
                    : Text(
                        song.title,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                const SizedBox(height: 4),
                Text(song.artist,
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? kAccent : kTextSecondary,
              size: 26,
            ),
            onPressed: () => provider.toggleLike(song),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(MusicProvider provider) {
    return StreamBuilder<Duration>(
      stream: provider.positionStream,
      builder: (_, posSnap) {
        return StreamBuilder<Duration?>(
          stream: provider.durationStream,
          builder: (_, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final ratio = dur.inMilliseconds > 0
                ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14),
                      activeTrackColor: kAccent,
                      inactiveTrackColor: kSurface,
                      thumbColor: kTextPrimary,
                      overlayColor: kAccent.withAlpha(51),
                    ),
                    child: Slider(
                      value: _isSeeking ? _seekValue : ratio.toDouble(),
                      onChangeStart: (v) {
                        setState(() {
                          _isSeeking = true;
                          _seekValue = v;
                        });
                      },
                      onChanged: (v) => setState(() => _seekValue = v),
                      onChangeEnd: (v) {
                        setState(() => _isSeeking = false);
                        if (dur.inMilliseconds > 0) {
                          provider.seek(Duration(
                            milliseconds:
                                (v * dur.inMilliseconds).toInt(),
                          ));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(pos),
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                        Text(_fmt(dur),
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls(MusicProvider provider) {
    final qm = provider.queueManager;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle_rounded,
              color: qm.shuffle ? kAccent : kTextSecondary, size: 22),
          onPressed: provider.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded,
              color: kTextPrimary, size: 32),
          onPressed: provider.skipPrevious,
        ),
        // Play/Pause with loading state
        StreamBuilder<PlaybackState>(
          stream: GetIt.I<MusicAudioHandler>().playbackState,
          builder: (_, snap) {
            final isPlaying = snap.data?.playing ?? false;
            final isLoading = snap.data?.processingState ==
                    AudioProcessingState.loading ||
                snap.data?.processingState ==
                    AudioProcessingState.buffering;
            return GestureDetector(
              onTap: provider.togglePlayPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: kTextPrimary,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: kBackground),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: kBackground,
                        size: 34,
                      ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded,
              color: kTextPrimary, size: 32),
          onPressed: provider.skipNext,
        ),
        IconButton(
          icon: Icon(_repeatIcon(qm.repeat),
              color:
                  qm.repeat != RepeatMode.none ? kAccent : kTextSecondary,
              size: 22),
          onPressed: provider.cycleRepeat,
        ),
      ],
    );
  }

  Widget _buildBottomActions(
      BuildContext context, MusicProvider provider, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionBtn(Icons.add_to_queue_rounded, 'Queue', () {
            provider.queueManager.addToQueue(song);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Added to queue'),
                  backgroundColor: kSurface,
                  duration: Duration(seconds: 1)),
            );
          }),
          // ★ SLEEP TIMER BUTTON ★
          Consumer<SleepTimerService>(
            builder: (_, timer, __) => GestureDetector(
              onTap: () => _showSleepTimerSheet(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.bedtime_outlined,
                        color: timer.isActive ? kAccent : kTextSecondary,
                        size: 24,
                      ),
                      if (timer.isActive)
                        Positioned(
                          top: -6,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              timer.remainingSeconds == -1
                                  ? '♪'
                                  : timer.remainingFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sleep',
                    style: TextStyle(
                      color: timer.isActive ? kAccent : kTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _actionBtn(Icons.playlist_add_rounded, 'Playlist', () {
            _showAddToPlaylistSheet(context, song);
          }),
          _actionBtn(Icons.share_rounded, 'Share', () {
            Share.share(
                'Listen to ${song.title} by ${song.artist} on Musenzy!');
          }),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kTextSecondary, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Consumer<MusicProvider>(
          builder: (context, provider, _) {
            final queue = provider.queueManager.queue;
            final currentIdx = provider.queueManager.currentIndex;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (_, ctrl) => Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: kTextSecondary,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  const Text('Queue',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ReorderableListView.builder(
                      scrollController: ctrl,
                      itemCount: queue.length,
                      onReorder: provider.queueManager.reorder,
                      itemBuilder: (_, i) {
                        final s = queue[i];
                        return ListTile(
                          key: Key(s.videoId + i.toString()),
                          leading: Icon(
                            i == currentIdx
                                ? Icons.equalizer_rounded
                                : Icons.music_note_rounded,
                            color: i == currentIdx
                                ? kAccent
                                : kTextSecondary,
                          ),
                          title: Text(s.title,
                              style: TextStyle(
                                  color: i == currentIdx
                                      ? kAccent
                                      : kTextPrimary,
                                  fontSize: 13)),
                          subtitle: Text(s.artist,
                              style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11)),
                          trailing: const Icon(Icons.drag_handle_rounded,
                              color: kTextSecondary),
                          onTap: () {
                            provider.queueManager.jumpTo(i);
                            final song = queue[i];
                            provider.playSong(song);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, Song song) {
    final lib = GetIt.I<LibraryService>();
    final playlists = lib.getPlaylists();
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Add to Playlist',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No playlists yet. Create one from Library.',
                  style: TextStyle(color: kTextSecondary),
                  textAlign: TextAlign.center),
            )
          else
            ...playlists.map((p) => ListTile(
                  leading: const Icon(Icons.queue_music_rounded,
                      color: kAccent),
                  title: Text(p.name,
                      style: const TextStyle(color: kTextPrimary)),
                  onTap: () {
                    lib.addToPlaylist(p.id, song);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Added to ${p.name}'),
                          backgroundColor: kSurface),
                    );
                  },
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return Icons.repeat_one_rounded;
      case RepeatMode.all:
      case RepeatMode.none:
        return Icons.repeat_rounded;
    }
  }

  Widget _buildFadeIndicator() {
    return Consumer<SleepTimerService>(
      builder: (_, timer, __) {
        if (timer.status != SleepTimerStatus.finishing) {
          return const SizedBox.shrink();
        }
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: kAccent,
                    strokeWidth: 1.5,
                  ),
                ),
                SizedBox(width: 8),
                Text('Fading out...',
                    style: TextStyle(color: kAccent, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
