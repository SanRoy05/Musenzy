import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';

class FeaturedCard extends StatelessWidget {
  final Song song;
  final List<Song>? queue;
  final int? index;
  final double height;

  const FeaturedCard({
    super.key,
    required this.song,
    this.queue,
    this.index,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<MusicProvider>();
        final q = queue ?? [song];
        final i = index ?? 0;
        provider.playSong(song, queue: q, index: i);
      },
      child: Container(
        width: 160,
        height: height,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
          color: kSurface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: kSurface2),
                errorWidget: (_, __, ___) => Container(
                  color: kSurface2,
                  child: const Icon(Icons.music_note, color: kAccent, size: 40),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(178),
                      ],
                    ),
                  ),
                ),
              ),
              // Title + artist
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: const TextStyle(color: kTextSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
