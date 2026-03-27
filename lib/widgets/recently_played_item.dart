import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';

class RecentlyPlayedItem extends StatelessWidget {
  final Song song;
  final double size;

  const RecentlyPlayedItem({super.key, required this.song, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<MusicProvider>().playSong(song),
      child: Container(
        width: size + 40,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kBorderRadius),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: size, height: size, color: kSurface),
                errorWidget: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: kSurface,
                  child: const Icon(Icons.music_note, color: kAccent),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              style: const TextStyle(
                  color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              song.artist,
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
