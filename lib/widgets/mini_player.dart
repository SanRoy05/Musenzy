import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/music_provider.dart';
import '../screens/player_screen.dart';
import '../services/audio_handler.dart';
import '../widgets/adaptive_layout.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide on desktop — desktop uses DesktopPlayerBar
    if (AdaptiveLayout.isDesktop(context)) return const SizedBox.shrink();

    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return AnimatedSlide(
          offset: const Offset(0, 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            ),
            child: Container(
              height: kMiniPlayerH,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(102),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        // Thumbnail with Hero
                        Hero(
                          tag: 'player_thumbnail',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: song.thumbnailUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(width: 40, height: 40, color: kSurface2),
                              errorWidget: (_, __, ___) => Container(
                                width: 40,
                                height: 40,
                                color: kSurface2,
                                child: const Icon(Icons.music_note, color: kAccent, size: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title + artist
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
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Play/Pause
                        StreamBuilder<PlaybackState>(
                          stream: GetIt.I<MusicAudioHandler>().playbackState,
                          builder: (_, snap) {
                            final isPlaying = snap.data?.playing ?? false;
                            final isLoading = snap.data?.processingState ==
                                    AudioProcessingState.loading ||
                                snap.data?.processingState ==
                                    AudioProcessingState.buffering;
                            return isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: kAccent),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: kTextPrimary,
                                    ),
                                    onPressed: provider.togglePlayPause,
                                  );
                          },
                        ),
                        // Skip next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded,
                              color: kTextPrimary),
                          onPressed: provider.skipNext,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  // Progress line
                  StreamBuilder<Duration>(
                    stream: provider.positionStream,
                    builder: (_, posSnap) {
                      return StreamBuilder<Duration?>(
                        stream: provider.durationStream,
                        builder: (_, durSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          final dur = durSnap.data ?? const Duration(seconds: 1);
                          final progress =
                              (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: kSurface2,
                            valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
                            minHeight: 2,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
