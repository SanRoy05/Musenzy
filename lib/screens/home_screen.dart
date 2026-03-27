import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../core/constants.dart';
import '../services/library_service.dart';
import '../services/music_service.dart';
import '../models/song.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/featured_card.dart';
import '../widgets/recently_played_item.dart';
import '../widgets/song_tile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_preferences.dart';
import '../data/singers_data.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _trending = [];
  List<Song> _featured = [];
  List<Song> _recentlyPlayed = [];
  List<Song> _forYouSongs = [];
  Map<String, List<Song>> _singerSongs = {}; // singerId -> songs
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final ms = GetIt.I<MusicService>();
      final lib = GetIt.I<LibraryService>();
      final results = await Future.wait([
        ms.getTrending(),
        ms.getFeatured(),
      ]);
      if (mounted) {
        setState(() {
          _trending = results[0];
          _featured = results[1];
          _recentlyPlayed = lib.getRecentlyPlayed();
          _loading = false;
        });
      }
      _loadPersonalizedFeed();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPersonalizedFeed() async {
    if (mounted) setState(() {});
    try {
      final box = Hive.box<UserPreferences>('user_preferences');
      final prefs = box.get('prefs');
      final selectedIds = prefs?.favouriteSingerIds ?? [];

      if (selectedIds.isEmpty) {
        if (mounted) setState(() {});
        return;
      }

      // Find selected singer objects
      final selectedSingers = allSingerCategories
          .expand((cat) => cat.singers)
          .where((s) => selectedIds.contains(s.id))
          .toList();

      final ms = GetIt.I<MusicService>();
      
      // Fetch songs for each selected singer in parallel
      final futures = selectedSingers.map((singer) async {
        try {
          final songs = await ms.searchSongs(singer.searchQuery);
          return MapEntry(singer.id, songs.take(10).toList());
        } catch (_) {
          return MapEntry(singer.id, <Song>[]);
        }
      });

      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _singerSongs = Map.fromEntries(results);
          
          // "For You" = mix of top 3 songs from each singer, shuffled
          _forYouSongs = results
              .expand((e) => e.value.take(3))
              .toList()
              ..shuffle();
              
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: kBackground,
      body: RefreshIndicator(
        color: kAccent,
        backgroundColor: kSurface,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildGreetingCard(greeting)),
            if (_recentlyPlayed.isNotEmpty) ...[
              _sectionHeader('🕐 Recently Played'),
              SliverToBoxAdapter(child: _buildRecentlyPlayed()),
            ],

            // Personalized Mix
            if (_forYouSongs.isNotEmpty) ...[
              _sectionHeader('✨ For You'),
              SliverToBoxAdapter(child: _buildHorizontalSongList(_forYouSongs)),
            ],

            // Per-singer sections
            ..._buildSingerSections(),

            _sectionHeader('🔥 Featured Music'),
            SliverToBoxAdapter(child: _buildFeatured()),
            _sectionHeader('📈 Trending Now'),
            _loading ? _buildShimmerList() : _buildTrendingList(),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSingerSections() {
    final box = Hive.box<UserPreferences>('user_preferences');
    final prefs = box.get('prefs');
    final selectedIds = prefs?.favouriteSingerIds ?? [];
    
    final selectedSingers = allSingerCategories
        .expand((cat) => cat.singers)
        .where((s) => selectedIds.contains(s.id))
        .toList();

    return selectedSingers.map((singer) {
      final songs = _singerSongs[singer.id] ?? [];
      if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
      
      return MultiSliver(
        children: [
          SliverToBoxAdapter(child: _buildSingerSectionHeader(singer)),
          SliverToBoxAdapter(child: _buildHorizontalSongList(songs)),
        ],
      );
    }).toList();
  }

  Widget _buildSingerSectionHeader(Singer singer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: singer.photoUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: kSurface, width: 36, height: 36),
              errorWidget: (_, __, ___) => CircleAvatar(
                radius: 18,
                backgroundColor: kAccent,
                child: Text(singer.name[0],
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(singer.name,
            style: const TextStyle(color: kTextPrimary,
              fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Navigation logic for "See all"
            },
            child: const Text('See all',
              style: TextStyle(color: kAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSongList(List<Song> songs) {
    final h = AdaptiveLayout.featuredCardHeight(context);
    return SizedBox(
      height: h + 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (_, i) =>
            FeaturedCard(song: songs[i], queue: songs, index: i, height: h),
      ),
    );
  }

  Widget _buildGreetingCard(String greeting) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 48, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kAccent, kAccentCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: const TextStyle(
                  color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('What do you want to listen to?',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(title,
            style: const TextStyle(
                color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRecentlyPlayed() {
    final size = AdaptiveLayout.isDesktop(context) ? 120.0 : AdaptiveLayout.isTablet(context) ? 100.0 : 80.0;
    return SizedBox(
      height: size + 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recentlyPlayed.length,
        itemBuilder: (_, i) =>
            RecentlyPlayedItem(song: _recentlyPlayed[i], size: size),
      ),
    );
  }

  Widget _buildFeatured() {
    if (_loading) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (_, __) => _shimmerCard(),
        ),
      );
    }
    final h = AdaptiveLayout.featuredCardHeight(context);
    return SizedBox(
      height: h + 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featured.length,
        itemBuilder: (_, i) =>
            FeaturedCard(song: _featured[i], queue: _featured, index: i, height: h),
      ),
    );
  }

  Widget _buildTrendingList() {
    if (AdaptiveLayout.isDesktop(context)) {
      // Two-column list on desktop
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 5,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => SongTile(song: _trending[i], queue: _trending, index: i),
            childCount: _trending.length,
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => SongTile(song: _trending[i], queue: _trending, index: i),
        childCount: _trending.length,
      ),
    );
  }

  SliverToBoxAdapter _buildShimmerList() {
    return SliverToBoxAdapter(
      child: Column(
        children: List.generate(
          6,
          (_) => Shimmer.fromColors(
            baseColor: kSurface,
            highlightColor: kSurface2,
            child: Container(
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: kSurface,
      highlightColor: kSurface2,
      child: Container(
        width: 160,
        height: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
            color: kSurface, borderRadius: BorderRadius.circular(kBorderRadius)),
      ),
    );
  }
}
