import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/library_service.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        title: const Text('📚 Library',
            style: TextStyle(
                color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAccent,
          labelColor: kAccent,
          unselectedLabelColor: kTextSecondary,
          tabs: const [Tab(text: 'Liked Songs'), Tab(text: 'Playlists')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LikedSongsTab(),
          _PlaylistsTab(),
        ],
      ),
    );
  }
}

// ── Liked Songs Tab ─────────────────────────────────────────────────────────────

class _LikedSongsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lib = GetIt.I<LibraryService>();
    return ValueListenableBuilder(
      valueListenable: lib.likedListenable,
      builder: (context, Box<Song> box, _) {
        final songs = box.values.toList().reversed.toList();
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border_rounded,
                    color: kTextSecondary, size: 64),
                SizedBox(height: 16),
                Text('No liked songs yet',
                    style: TextStyle(color: kTextSecondary, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 140),
          itemCount: songs.length,
          itemBuilder: (_, i) => Dismissible(
            key: Key(songs[i].videoId),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              color: Colors.red.withAlpha(51),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_rounded, color: Colors.red),
            ),
            onDismissed: (_) => lib.unlikeSong(songs[i].videoId),
            child: SongTile(song: songs[i], queue: songs, index: i),
          ),
        );
      },
    );
  }
}

// ── Playlists Tab ────────────────────────────────────────────────────────────────

class _PlaylistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lib = GetIt.I<LibraryService>();
    return ValueListenableBuilder(
      valueListenable: lib.playlistsListenable,
      builder: (context, Box<Playlist> box, _) {
        final playlists = box.values.toList();
        return Scaffold(
          backgroundColor: kBackground,
          floatingActionButton: FloatingActionButton(
            backgroundColor: kAccent,
            child: const Icon(Icons.add_rounded, color: kTextPrimary),
            onPressed: () => _createPlaylist(context, lib),
          ),
          body: playlists.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music_rounded,
                          color: kTextSecondary, size: 64),
                      SizedBox(height: 16),
                      Text('No playlists yet',
                          style:
                              TextStyle(color: kTextSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 140),
                  itemCount: playlists.length,
                  itemBuilder: (_, i) {
                    final p = playlists[i];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: p.songs.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: p.songs.first.thumbnailUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.queue_music_rounded,
                                color: kAccent),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(color: kTextPrimary)),
                      subtitle: Text('${p.songs.length} songs',
                          style: const TextStyle(color: kTextSecondary)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: kTextSecondary),
                        color: kSurface,
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                  style:
                                      TextStyle(color: Colors.red))),
                        ],
                        onSelected: (_) => lib.deletePlaylist(p.id),
                      ),
                      onTap: () => _openPlaylist(context, p),
                    );
                  },
                ),
        );
      },
    );
  }

  void _createPlaylist(BuildContext context, LibraryService lib) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('New Playlist',
            style: TextStyle(color: kTextPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          cursorColor: kAccent,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: kTextSecondary),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kTextSecondary)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                lib.createPlaylist(ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child:
                const Text('Create', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PlaylistDetailScreen(playlist: p),
      ),
    );
  }
}

// ── Playlist Detail Screen ────────────────────────────────────────────────────────

class _PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistDetailScreen({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        title: Text(playlist.name,
            style: const TextStyle(color: kTextPrimary)),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: playlist.songs.isEmpty
          ? const Center(
              child: Text('No songs in this playlist',
                  style: TextStyle(color: kTextSecondary)))
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 140),
              itemCount: playlist.songs.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final song = playlist.songs.removeAt(oldIndex);
                playlist.songs.insert(newIndex, song);
                playlist.save();
              },
              itemBuilder: (_, i) {
                final song = playlist.songs[i];
                return SongTile(
                  key: Key(song.videoId),
                  song: song,
                  queue: playlist.songs,
                  index: i,
                );
              },
            ),
    );
  }
}
