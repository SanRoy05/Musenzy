import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String videoId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String thumbnailUrl;

  @HiveField(4)
  final int duration; // seconds

  @HiveField(5)
  bool isLiked;

  Song({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.isLiked = false,
  });

  String get durationText {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    int? duration,
    bool? isLiked,
  }) {
    return Song(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
