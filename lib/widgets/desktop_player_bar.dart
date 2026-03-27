import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/music_provider.dart';
import '../services/audio_handler.dart';
import '../services/queue_manager.dart';

class DesktopPlayerBar extends StatefulWidget {
  const DesktopPlayerBar({super.key});

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  double _seekValue = 0;
  bool _isSeeking = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;

        return Container(
          height: kDesktopBarH,
          decoration: const BoxDecoration(
            color: kDesktopBar,
            border: Border(top: BorderSide(color: kDivider, width: 1)),
          ),
          child: Row(
            children: [
              // ── Left: thumbnail + title + artist + like ──────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (song != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(width: 48, height: 48, color: kSurface2),
                            errorWidget: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: kSurface2,
                              child: const Icon(Icons.music_note, color: kAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            provider.isLiked(song.videoId)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: provider.isLiked(song.videoId)
                                ? kAccent
                                : kTextSecondary,
                            size: 20,
                          ),
                          onPressed: () => provider.toggleLike(song),
                        ),
                      ] else
                        const Text('No song playing',
                            style: TextStyle(color: kTextSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              // ── Center: controls + progress ──────────────────────────────
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlBtn(
                          Icons.shuffle_rounded,
                          provider.queueManager.shuffle ? kAccent : kTextSecondary,
                          provider.toggleShuffle,
                        ),
                        _controlBtn(
                            Icons.skip_previous_rounded, kTextPrimary, provider.skipPrevious),
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
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: const BoxDecoration(
                                  color: kTextPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: kBackground),
                                      )
                                    : Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: kBackground,
                                        size: 22,
                                      ),
                              ),
                            );
                          },
                        ),
                        _controlBtn(
                            Icons.skip_next_rounded, kTextPrimary, provider.skipNext),
                        _controlBtn(
                          _repeatIcon(provider.queueManager.repeat),
                          provider.queueManager.repeat != RepeatMode.none
                              ? kAccent
                              : kTextSecondary,
                          provider.cycleRepeat,
                        ),
                      ],
                    ),
                    // Progress row
                    StreamBuilder<Duration>(
                      stream: provider.positionStream,
                      builder: (_, posSnap) {
                        return StreamBuilder<Duration?>(
                          stream: provider.durationStream,
                          builder: (_, durSnap) {
                            final pos = posSnap.data ?? Duration.zero;
                            final dur = durSnap.data ?? Duration.zero;
                            final progress = dur.inMilliseconds > 0
                                ? (pos.inMilliseconds / dur.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0.0;

                            return Row(
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  _fmt(pos),
                                  style: const TextStyle(
                                      color: kTextSecondary, fontSize: 11),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5),
                                      overlayShape: const RoundSliderOverlayShape(
                                          overlayRadius: 10),
                                      activeTrackColor: kAccent,
                                      inactiveTrackColor: kSurface,
                                      thumbColor: kTextPrimary,
                                    ),
                                    child: Slider(
                                      value: _isSeeking
                                          ? _seekValue
                                          : progress.toDouble(),
                                      onChangeStart: (v) {
                                        setState(() {
                                          _isSeeking = true;
                                          _seekValue = v;
                                        });
                                      },
                                      onChanged: (v) {
                                        setState(() => _seekValue = v);
                                      },
                                      onChangeEnd: (v) {
                                        setState(() => _isSeeking = false);
                                        if (dur.inMilliseconds > 0) {
                                          provider.seek(Duration(
                                            milliseconds: (v * dur.inMilliseconds).toInt(),
                                          ));
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _fmt(dur),
                                  style: const TextStyle(
                                      color: kTextSecondary, fontSize: 11),
                                ),
                                const SizedBox(width: 8),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              // ── Right: volume + queue ────────────────────────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.volume_up_rounded,
                          color: kTextSecondary, size: 18),
                      SizedBox(
                        width: 100,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            activeTrackColor: kAccent,
                            inactiveTrackColor: kSurface,
                            thumbColor: kTextPrimary,
                          ),
                          child: Slider(
                            value: provider.volume,
                            onChanged: provider.setVolume,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _controlBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
    );
  }

  IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return Icons.repeat_one_rounded;
      case RepeatMode.all:
        return Icons.repeat_rounded;
      case RepeatMode.none:
        return Icons.repeat_rounded;
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
