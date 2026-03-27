import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import 'package:provider/provider.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? queue;
  final int? index;
  final VoidCallback? onTap;
  final bool showIndex;

  const SongTile({
    super.key,
    required this.song,
    this.queue,
    this.index,
    this.onTap,
    this.showIndex = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final isCurrent = provider.currentSong?.videoId == song.videoId;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIndex)
                SizedBox(
                  width: 24,
                  child: Text(
                    '${(index ?? 0) + 1}',
                    style: TextStyle(
                      color: isCurrent ? kAccent : kTextSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 48,
                    color: kSurface,
                    child: const Icon(Icons.music_note, color: kAccent, size: 20),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: kSurface,
                    child: const Icon(Icons.music_note, color: kAccent, size: 20),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            song.title,
            style: TextStyle(
              color: isCurrent ? kAccent : kTextPrimary,
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.durationText,
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kTextSecondary, size: 18),
                color: kSurface,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'next', child: Text('Play next', style: TextStyle(color: kTextPrimary))),
                  const PopupMenuItem(value: 'queue', child: Text('Add to queue', style: TextStyle(color: kTextPrimary))),
                  PopupMenuItem(
                    value: 'like',
                    child: Text(
                      provider.isLiked(song.videoId) ? 'Unlike' : 'Like',
                      style: const TextStyle(color: kTextPrimary),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'next') provider.queueManager.playNext(song);
                  if (value == 'queue') provider.queueManager.addToQueue(song);
                  if (value == 'like') provider.toggleLike(song);
                },
              ),
            ],
          ),
          onTap: onTap ??
              () {
                final q = queue ?? [song];
                final i = index ?? 0;
                provider.playSong(song, queue: q, index: i);
              },
        );
      },
    );
  }
}
