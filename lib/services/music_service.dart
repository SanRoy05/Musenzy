import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../core/api_config.dart';
import '../core/platform_helper.dart';
import '../models/song.dart';

class MusicService {
  final YoutubeExplode? _yt;
  final http.Client _http;

  MusicService()
      : _yt = kIsWeb ? null : YoutubeExplode(),
        _http = http.Client();

  // ─── Search ─────────────────────────────────────────────────────────────────

  Future<List<Song>> searchSongs(String query) async {
    if (PlatformHelper.useBackendProxy) {
      return _searchViaBackend(query);
    } else {
      return _searchNative(query);
    }
  }

  Future<List<Song>> _searchNative(String query) async {
    try {
      final results = await _yt!.search.search(query);
      return results.whereType<Video>().take(20).map((v) => Song(
            videoId: v.id.value,
            title: v.title,
            artist: v.author,
            thumbnailUrl: v.thumbnails.highResUrl,
            duration: v.duration?.inSeconds ?? 0,
            isLiked: false,
          )).toList();
    } catch (e) {
      debugPrint('Native search error: $e');
      rethrow;
    }
  }

  Future<List<Song>> _searchViaBackend(String query) async {
    final uri = Uri.parse(
        '${ApiConfig.searchUrl}?q=${Uri.encodeComponent(query)}&limit=20');
    final response = await _http.get(uri);
    if (response.statusCode != 200) throw Exception('Search failed');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['songs'] as List)
        .map((s) => Song(
              videoId: s['videoId'] as String,
              title: s['title'] as String,
              artist: s['artist'] as String,
              thumbnailUrl: s['thumbnailUrl'] as String? ?? '',
              duration: (s['duration'] as num?)?.toInt() ?? 0,
              isLiked: false,
            ))
        .toList();
  }

  // ─── Stream URL ─────────────────────────────────────────────────────────────

  Future<String> getStreamUrl(String videoId) async {
    if (PlatformHelper.useBackendProxy) {
      return _getStreamUrlViaBackend(videoId);
    } else {
      return _getStreamUrlNative(videoId);
    }
  }

  Future<String> _getStreamUrlNative(String videoId) async {
    final manifest = await _yt!.videos.streams.getManifest(
      videoId,
      ytClients: [
        YoutubeApiClient.ios,
        YoutubeApiClient.androidVr,
        YoutubeApiClient.android,
      ],
    );
    final stream = manifest.audioOnly.withHighestBitrate();
    return stream.url.toString();
  }

  Future<String> _getStreamUrlViaBackend(String videoId) async {
    final uri = Uri.parse('${ApiConfig.streamUrl}?videoId=$videoId');
    final response = await _http.get(uri);
    if (response.statusCode == 403) {
      final error =
          (jsonDecode(response.body) as Map<String, dynamic>)['error'];
      throw Exception(error);
    }
    if (response.statusCode != 200) throw Exception('Stream URL failed');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  // ─── Trending ────────────────────────────────────────────────────────────────

  Future<List<Song>> getTrending({String genre = 'top hits'}) async {
    if (PlatformHelper.useBackendProxy) {
      final uri = Uri.parse(
          '${ApiConfig.trendingUrl}?genre=${Uri.encodeComponent(genre)}');
      final response = await _http.get(uri);
      if (response.statusCode != 200) throw Exception('Trending failed');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['songs'] as List)
          .map((s) => Song(
                videoId: s['videoId'] as String,
                title: s['title'] as String,
                artist: s['artist'] as String,
                thumbnailUrl: s['thumbnailUrl'] as String? ?? '',
                duration: (s['duration'] as num?)?.toInt() ?? 0,
                isLiked: false,
              ))
          .toList();
    } else {
      return _searchNative('$genre ${DateTime.now().year}');
    }
  }

  // ─── Featured (random genre picks) ───────────────────────────────────────────

  Future<List<Song>> getFeatured() async {
    final genres = ['pop hits', 'hip hop', 'rock classics', 'electronic'];
    final genre = genres[Random().nextInt(genres.length)];
    return getTrending(genre: genre);
  }

  void dispose() {
    _yt?.close();
    _http.close();
  }
}
