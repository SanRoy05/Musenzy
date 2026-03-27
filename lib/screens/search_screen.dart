import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:audio_service/audio_service.dart';

import '../models/song.dart';
import '../services/music_service.dart';
import '../services/search_history_service.dart';
import '../services/voice_search_service.dart';
import '../services/recommendation_service.dart';
import '../services/queue_manager.dart';
import '../services/audio_handler.dart';
import '../services/smart_queue_service.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Services
  late final SearchHistoryService _historyService;
  late final RecommendationService _recommendationService;
  late final VoiceSearchService _voiceService;
  late final MusicService _musicService;

  // State
  String _query = '';
  bool _isSearching = false;
  bool _isListening = false;
  bool _isFocused = false;
  List<Song> _searchResults = [];
  List<Song> _recommendedSongs = [];
  bool _loadingRecommended = false;
  String _voiceText = '';

  // Debounce timer
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _historyService = GetIt.I<SearchHistoryService>();
    _recommendationService = GetIt.I<RecommendationService>();
    _voiceService = GetIt.I<VoiceSearchService>();
    _musicService = GetIt.I<MusicService>();

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });

    // Load recommended songs on open
    _loadRecommendedSongs();
  }

  Future<void> _loadRecommendedSongs() async {
    if (!mounted) return;
    setState(() => _loadingRecommended = true);
    try {
      final queries = _recommendationService.getRecommendedSongQueries();
      final allSongs = <Song>[];
      for (final q in queries) {
        final songs = await _musicService.searchSongs(q);
        allSongs.addAll(songs.take(5));
      }
      // Shuffle for variety
      allSongs.shuffle();
      if (mounted) {
        setState(() => _recommendedSongs = allSongs.take(15).toList());
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingRecommended = false);
    }
  }

  // ── SEARCH ──────────────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(value));
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final results = await _musicService.searchSongs(query);
      if (mounted) {
        setState(() => _searchResults = results);
        // Save to history
        _historyService.addSearch(query.trim());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _searchResults = []);
      }
    }
    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  void _onSuggestionTapped(String suggestion) {
    _searchController.text = suggestion;
    _focusNode.unfocus();
    _performSearch(suggestion);
  }

  // ── VOICE SEARCH ────────────────────────────────────────────────────
  Future<void> _startVoiceSearch() async {
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied'),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = 'Listening...';
    });

    // Show voice listening modal
    _showVoiceListeningSheet();

    await _voiceService.startListening(
      onResult: (words) {
        if (mounted) {
          setState(() {
            _voiceText = words;
            _searchController.text = words;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
          Navigator.pop(context); // close modal
          if (_voiceText.isNotEmpty && _voiceText != 'Listening...') {
            _performSearch(_voiceText);
          }
        }
      },
    );
  }

  void _showVoiceListeningSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mic animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 600),
                  builder: (_, scale, child) => Transform.scale(
                    scale: _isListening ? scale : 1.0, child: child),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                        ? const Color(0xFF7B5EA7)
                        : const Color(0xFF1A1A1A),
                      boxShadow: _isListening ? [
                        BoxShadow(
                          color: const Color(0xFF7B5EA7).withValues(alpha: 0.4),
                          blurRadius: 20, spreadRadius: 5),
                      ] : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white, size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Voice text
                Text(
                  _voiceText.isEmpty ? 'Listening...' : _voiceText,
                  style: TextStyle(
                    color: _voiceText.isEmpty || _voiceText == 'Listening...'
                      ? Colors.grey
                      : Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Speak your song or artist name',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 32),

                // Cancel button
                TextButton(
                  onPressed: () {
                    _voiceService.cancelListening();
                    if (mounted) {
                      setState(() => _isListening = false);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── UI BUILD ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── SEARCH BAR ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isFocused
                            ? const Color(0xFF7B5EA7)
                            : const Color(0xFF333333),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: _onSearchChanged,
                              onSubmitted: (v) {
                                _focusNode.unfocus();
                                _performSearch(v);
                              },
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Songs, artists, genres...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          // Clear button
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                if (mounted) {
                                  setState(() {
                                    _query = '';
                                    _searchResults = [];
                                  });
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(Icons.close,
                                  color: Colors.grey, size: 18),
                              ),
                            ),
                          // Mic button
                          GestureDetector(
                            onTap: _startVoiceSearch,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isListening
                                  ? const Color(0xFF7B5EA7).withValues(alpha: 0.2)
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening
                                  ? const Color(0xFF7B5EA7)
                                  : Colors.grey[400],
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Cancel button when focused
                  if (_isFocused) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        _focusNode.unfocus();
                        _searchController.clear();
                        if (mounted) {
                          setState(() { _query = ''; _searchResults = []; });
                        }
                      },
                      child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF7B5EA7), fontSize: 14)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── CONTENT ───────────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                ? _buildEmptySearchView()   // recent + recommendations
                : _isSearching
                  ? _buildSearchingState()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE: Recent + Recommended ─────────────────────────────
  Widget _buildEmptySearchView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [

        // ── RECENT SEARCHES ──────────────────────────────────────────
        ValueListenableBuilder<Box<String>>(
          valueListenable:
            GetIt.I<SearchHistoryService>().listenable,
          builder: (_, box, __) {
            final recent = _historyService.getRecentSearches();
            if (recent.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    const Text('Recent Searches',
                      style: TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _historyService.clearAll();
                        if (mounted) setState(() {});
                      },
                      child: Text('Clear all',
                        style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...recent.map((query) => _buildRecentSearchTile(query)),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // ── RECOMMENDED SEARCHES ────────────────────────────────────
        Builder(
          builder: (_) {
            final recommendations =
              _recommendationService.getRecommendedSearches();
            if (recommendations.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                      color: Color(0xFF7B5EA7), size: 18),
                    SizedBox(width: 8),
                    Text('Recommended For You',
                      style: TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                // Chip-style recommendation pills
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: recommendations.map((suggestion) =>
                    GestureDetector(
                      onTap: () => _onSuggestionTapped(suggestion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search,
                              color: Color(0xFF7B5EA7), size: 14),
                            const SizedBox(width: 6),
                            Text(suggestion,
                              style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // ── RECOMMENDED SONGS ───────────────────────────────────────
        const Row(
          children: [
            Icon(Icons.music_note, color: Color(0xFF7B5EA7), size: 18),
            SizedBox(width: 8),
            Text('Recommended Songs',
              style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),

        if (_loadingRecommended)
          // Shimmer placeholders
          ...List.generate(5, (_) => _buildShimmerTile())
        else if (_recommendedSongs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No recommendations yet.\nSearch for some songs first!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          )
        else
          ..._recommendedSongs.map((song) => SongTile(
            song: song,
            onTap: () => _playSong(song),
          )),

        const SizedBox(height: 100),
      ],
    );
  }

  // Recent search tile
  Widget _buildRecentSearchTile(String query) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.history, color: Colors.grey[600], size: 18),
      ),
      title: Text(query,
        style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arrow to fill search bar
          GestureDetector(
            onTap: () {
              _searchController.text = query;
              if (mounted) setState(() => _query = query);
              _focusNode.requestFocus();
            },
            child: Icon(Icons.north_west,
              color: Colors.grey[700], size: 16),
          ),
          const SizedBox(width: 12),
          // Delete this search
          GestureDetector(
            onTap: () {
              _historyService.deleteSearch(query);
              if (mounted) setState(() {});
            },
            child: Icon(Icons.close, color: Colors.grey[700], size: 16),
          ),
        ],
      ),
      onTap: () => _onSuggestionTapped(query),
    );
  }

  // Searching state
  Widget _buildSearchingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF7B5EA7), strokeWidth: 2),
          SizedBox(height: 16),
          Text('Searching for music...',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  // Search results
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text('No results for "$_query"',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => SongTile(
        song: _searchResults[i],
        onTap: () => _playSong(_searchResults[i]),
      ),
    );
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: ListTile(
        leading: Container(width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8))),
        title: Container(height: 12, width: 150, color: Colors.white),
        subtitle: Container(height: 10, width: 100, color: Colors.white),
      ),
    );
  }

  void _playSong(Song song) {
    GetIt.I<SmartQueueService>().reset();
    GetIt.I<QueueManager>().setQueue([song], startIndex: 0);
    GetIt.I<MusicAudioHandler>().playMediaItem(
      MediaItem(
        id: song.videoId,
        title: song.title,
        artist: song.artist,
        artUri: Uri.parse(song.thumbnailUrl),
        duration: Duration(seconds: song.duration),
        extras: {'videoId': song.videoId, 'isNewSession': true},
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _voiceService.cancelListening();
    super.dispose();
  }
}
