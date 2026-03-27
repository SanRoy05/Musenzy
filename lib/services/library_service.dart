import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/playlist.dart';
import '../models/song.dart';

class LibraryService {
  Box<Song> get _liked => Hive.box<Song>('liked_songs');
  Box<Song> get _history => Hive.box<Song>('recently_played');
  Box<Playlist> get _playlists => Hive.box<Playlist>('playlists');

  // ─── Liked Songs ─────────────────────────────────────────────────────────────

  void likeSong(Song song) {
    final liked = song.copyWith(isLiked: true);
    _liked.put(liked.videoId, liked);
  }

  void unlikeSong(String videoId) => _liked.delete(videoId);

  bool isLiked(String videoId) => _liked.containsKey(videoId);

  List<Song> getLikedSongs() => _liked.values.toList().reversed.toList();

  ValueListenable<Box<Song>> get likedListenable => _liked.listenable();

  // ─── History ─────────────────────────────────────────────────────────────────

  void addToHistory(Song song) {
    _history.delete(song.videoId); // remove duplicate if exists
    final all = _history.values.toList();
    if (all.length >= 50) {
      _history.delete(all.first.videoId); // delete oldest
    }
    _history.put(song.videoId, song);
  }

  List<Song> getRecentlyPlayed() =>
      _history.values.toList().reversed.toList();

  // ─── Playlists ────────────────────────────────────────────────────────────────

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
      createdAt: DateTime.now(),
    );
    await _playlists.put(playlist.id, playlist);
    return playlist;
  }

  void addToPlaylist(String id, Song song) {
    final p = _playlists.get(id);
    if (p != null && !p.songs.any((s) => s.videoId == song.videoId)) {
      p.songs.add(song);
      p.save();
    }
  }

  void removeFromPlaylist(String id, String videoId) {
    final p = _playlists.get(id);
    if (p != null) {
      p.songs.removeWhere((s) => s.videoId == videoId);
      p.save();
    }
  }

  void renamePlaylist(String id, String name) {
    final p = _playlists.get(id);
    if (p != null) {
      p.name = name;
      p.save();
    }
  }

  void deletePlaylist(String id) => _playlists.delete(id);

  List<Playlist> getPlaylists() => _playlists.values.toList();

  ValueListenable<Box<Playlist>> get playlistsListenable =>
      _playlists.listenable();
}
