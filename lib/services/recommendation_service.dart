import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import '../models/user_preferences.dart';
import '../data/singers_data.dart';
import '../services/search_history_service.dart';
import '../services/queue_manager.dart';

class RecommendationService {

  // ── RECOMMENDED SEARCH QUERIES ──────────────────────────────────────
  // Returns smart search suggestions based on 3 sources:

  List<String> getRecommendedSearches() {
    final suggestions = <String>{};

    // SOURCE 1: Based on recent search history
    final history = GetIt.I<SearchHistoryService>().getRecentSearches();
    for (final query in history.take(3)) {
      // Generate related queries from history
      suggestions.addAll(_relatedQueriesFromSearch(query));
    }

    // SOURCE 2: Based on currently playing song
    final currentSong = GetIt.I<QueueManager>().currentSong;
    if (currentSong != null) {
      suggestions.addAll(_queriesFromSong(currentSong));
    }

    // SOURCE 3: Based on onboarding singer picks
    final box = Hive.isBoxOpen('user_preferences') 
        ? Hive.box<UserPreferences>('user_preferences') 
        : null;
    final prefs = box?.get('prefs');
    
    if (prefs != null) {
      for (final singerId in prefs.favouriteSingerIds.take(3)) {
        final singer = allSingerCategories
          .expand((c) => c.singers)
          .firstWhere((s) => s.id == singerId,
            orElse: () => const Singer(id: '', name: '', region: '',
              photoUrl: '', searchQuery: ''));
        if (singer.name.isNotEmpty) {
          suggestions.add('${singer.name} best songs');
          suggestions.add('${singer.name} new songs 2025');
        }
      }
    }

    // Remove already-searched queries
    final searched = history.map((s) => s.toLowerCase()).toSet();
    return suggestions
      .where((s) => !searched.contains(s.toLowerCase()))
      .take(10)
      .toList();
  }

  // Generate related queries from a past search
  List<String> _relatedQueriesFromSearch(String query) {
    final q = query.toLowerCase();
    final related = <String>[];

    // Language-based expansions
    if (_has(q, ['hindi', 'bollywood', 'arijit', 'jubin', 'atif'])) {
      related.addAll([
        'Hindi romantic songs 2025',
        'Hindi sad songs playlist',
        'Bollywood hits 2025',
        'Arijit Singh new songs',
      ]);
    }
    if (_has(q, ['bengali', 'bangla', 'brishti', 'tumi', 'svf'])) {
      related.addAll([
        'Bengali romantic songs',
        'Bengali sad songs 2025',
        'SVF Music new songs',
        'Bangla hits playlist',
      ]);
    }
    if (_has(q, ['tamil', 'anirudh', 'kollywood'])) {
      related.addAll([
        'Tamil melody songs',
        'Anirudh new songs 2025',
        'Tamil romantic hits',
      ]);
    }
    if (_has(q, ['telugu', 'dsp', 'thaman'])) {
      related.addAll([
        'Telugu hit songs 2025',
        'DSP mass songs',
        'Telugu romantic songs',
      ]);
    }
    if (_has(q, ['kpop', 'bts', 'blackpink', 'twice'])) {
      related.addAll([
        'K-Pop hits 2025',
        'BTS new songs',
        'BLACKPINK songs playlist',
      ]);
    }
    if (_has(q, ['arabic', 'amr', 'fairuz', 'nancy'])) {
      related.addAll([
        'Arabic love songs',
        'Amr Diab best songs',
        'Arabic hits 2025',
      ]);
    }
    if (_has(q, ['latin', 'bad bunny', 'shakira', 'reggaeton'])) {
      related.addAll([
        'Latin hits 2025',
        'Reggaeton playlist',
        'Bad Bunny new songs',
      ]);
    }
    if (_has(q, ['sad', 'emotional', 'heartbreak', 'dard'])) {
      related.addAll([
        'Sad songs playlist',
        'Emotional Hindi songs',
        'Heartbreak songs 2025',
      ]);
    }
    if (_has(q, ['romantic', 'love', 'pyaar', 'ishq'])) {
      related.addAll([
        'Romantic songs playlist',
        'Love songs 2025',
        'Best Hindi love songs',
      ]);
    }
    if (_has(q, ['party', 'dance', 'remix', 'dj'])) {
      related.addAll([
        'Party songs playlist',
        'Dance hits 2025',
        'Best remix songs',
      ]);
    }

    // Add artist name + "songs" if query looks like an artist name
    if (!q.contains(' songs') && !q.contains(' hits') && q.split(' ').length <= 3) {
      related.add('$query songs');
      related.add('$query best hits');
      related.add('$query new 2025');
    }

    return related.take(3).toList();
  }

  // Generate queries from currently playing song
  List<String> _queriesFromSong(Song song) {
    final suggestions = <String>[];
    final lang = _detectLanguage(song);
    final mood = _detectMood(song);

    suggestions.add('${song.artist} songs');
    suggestions.add('${song.artist} new songs 2025');

    final moodMap = {
      'sad': ['sad songs playlist', 'emotional songs', 'heartbreak songs'],
      'romantic': ['romantic songs playlist', 'love songs 2025', 'best love songs'],
      'party': ['party songs playlist', 'dance hits', 'best remix 2025'],
      'motivational': ['motivational songs', 'gym workout songs', 'power songs'],
    };
    suggestions.addAll(moodMap[mood] ?? []);

    final langMap = {
      'hindi': 'Hindi hit songs 2025',
      'bengali': 'Bengali popular songs 2025',
      'tamil': 'Tamil melody songs 2025',
      'telugu': 'Telugu hit songs 2025',
      'kpop': 'K-Pop hits 2025',
      'arabic': 'Arabic popular songs 2025',
      'latin': 'Latin hits 2025',
      'english': 'English pop hits 2025',
    };
    if (langMap.containsKey(lang)) suggestions.add(langMap[lang]!);

    return suggestions.take(4).toList();
  }

  // ── RECOMMENDED SONGS ──────────────────────────────────────────────
  // Returns search queries to fetch recommended songs for search screen

  List<String> getRecommendedSongQueries() {
    final queries = <String>[];

    // From currently playing
    final current = GetIt.I<QueueManager>().currentSong;
    if (current != null) {
      queries.add(_buildSongQuery(current));
    }

    // From recent searches
    final history = GetIt.I<SearchHistoryService>().getRecentSearches();
    if (history.isNotEmpty) {
      queries.add('${history.first} latest');
    }

    // From onboarding picks
    final box = Hive.isBoxOpen('user_preferences') 
        ? Hive.box<UserPreferences>('user_preferences') 
        : null;
    final prefs = box?.get('prefs');

    if (prefs != null && prefs.favouriteSingerIds.isNotEmpty) {
      final ids = prefs.favouriteSingerIds.toList()..shuffle();
      final randomId = ids.first;
      final singer = allSingerCategories
        .expand((c) => c.singers)
        .firstWhere((s) => s.id == randomId,
          orElse: () => const Singer(id:'',name:'',region:'',photoUrl:'',searchQuery:''));
      if (singer.searchQuery.isNotEmpty) queries.add(singer.searchQuery);
    }

    return queries.take(3).toList();
  }

  String _buildSongQuery(Song song) {
    final lang = _detectLanguage(song);
    final mood = _detectMood(song);
    const map = {
      'hindi_romantic': 'Hindi romantic songs 2025',
      'hindi_sad': 'Hindi sad songs emotional',
      'hindi_party': 'Hindi dance party songs',
      'hindi_general': 'Hindi superhit songs 2025',
      'bengali_romantic': 'Bengali romantic songs 2025',
      'bengali_sad': 'Bengali sad emotional songs',
      'bengali_general': 'Bengali popular songs 2025',
      'tamil_general': 'Tamil melody songs 2025',
      'telugu_general': 'Telugu hit songs 2025',
      'kpop_general': 'K-Pop hits 2025',
      'arabic_general': 'Arabic songs 2025',
      'latin_general': 'Latin hits 2025',
      'english_romantic': 'English romantic songs 2025',
      'english_sad': 'English sad songs emotional',
      'english_general': 'English pop hits 2025',
    };
    return map['${lang}_$mood'] ?? map['${lang}_general'] ?? 'Top hits 2025';
  }

  String _detectLanguage(Song song) {
    final t = '${song.title} ${song.artist}'.toLowerCase();
    if (_has(t, ['hindi','bollywood','arijit','jubin','atif','dil ','pyaar','ishq','tum '])) return 'hindi';
    if (_has(t, ['bengali','bangla','brishti','tumi','tomake','svf','abacus','mahtim','mon '])) return 'bengali';
    if (_has(t, ['tamil','anirudh','sid sriram','kollywood','kadhal'])) return 'tamil';
    if (_has(t, ['telugu','dsp','thaman','nuvvu','prema'])) return 'telugu';
    if (_has(t, ['bts','blackpink','kpop','k-pop','twice','exo'])) return 'kpop';
    if (_has(t, ['arabic','amr diab','fairuz','nancy ajram','habibi'])) return 'arabic';
    if (_has(t, ['latin','spanish','bad bunny','shakira','reggaeton'])) return 'latin';
    return 'english';
  }

  String _detectMood(Song song) {
    final t = '${song.title} ${song.artist}'.toLowerCase();
    if (_has(t, ['sad','dard','cry','tears','heartbreak','pain','brishti','emotional','lofi'])) return 'sad';
    if (_has(t, ['love','romantic','pyaar','ishq','tera','bhalobasha','kadhal','romance'])) return 'romantic';
    if (_has(t, ['party','dance','remix','dj ','beats','bhangra','boom','nacho'])) return 'party';
    if (_has(t, ['motivation','gym','power','energy','hustle','winner'])) return 'motivational';
    return 'general';
  }

  bool _has(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));
}
