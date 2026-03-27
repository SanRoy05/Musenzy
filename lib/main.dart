import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'providers/music_provider.dart';
import 'models/playlist.dart';
import 'models/song.dart';
import 'services/audio_handler.dart';
import 'services/library_service.dart';
import 'services/music_service.dart';
import 'services/queue_manager.dart';
import 'services/sleep_timer_service.dart';
import 'services/search_history_service.dart';
import 'services/voice_search_service.dart';
import 'services/recommendation_service.dart';
import 'services/smart_queue_service.dart';
import 'models/user_preferences.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Desktop window setup ───────────────────────────────────────────────────
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      title: 'Musenzy',
      backgroundColor: Colors.black,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
  }

  // ── Hive init ──────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(UserPreferencesAdapter());
  await Hive.openBox<Song>('liked_songs');
  await Hive.openBox<Song>('recently_played');
  await Hive.openBox<Playlist>('playlists');
  await Hive.openBox<String>('search_history');
  // Initialize user_preferences box if not already open
  await Hive.openBox<UserPreferences>('user_preferences');

  // ── Services ───────────────────────────────────────────────────────────────
  final musicService = MusicService();
  final libraryService = LibraryService();
  final queueManager = QueueManager();

  // ── Audio service ──────────────────────────────────────────────────────────
  final audioHandler = await AudioService.init(
    builder: () => MusicAudioHandler(
      musicService: musicService,
      queueManager: queueManager,
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.musenzy.channel',
      androidNotificationChannelName: 'Musenzy',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF7B5EA7),
    ),
  );

  // ── Register with GetIt ────────────────────────────────────────────────────
  GetIt.I.registerSingleton<MusicService>(musicService);
  GetIt.I.registerSingleton<LibraryService>(libraryService);
  GetIt.I.registerSingleton<QueueManager>(queueManager);
  GetIt.I.registerSingleton<MusicAudioHandler>(audioHandler);
  GetIt.I.registerSingleton<SleepTimerService>(SleepTimerService());
  GetIt.I.registerSingleton<SearchHistoryService>(SearchHistoryService());
  GetIt.I.registerSingleton<VoiceSearchService>(VoiceSearchService());
  GetIt.I.registerSingleton<RecommendationService>(RecommendationService());
  GetIt.I.registerSingleton<SmartQueueService>(SmartQueueService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: queueManager),
        ChangeNotifierProvider.value(value: GetIt.I<SleepTimerService>()),
        ChangeNotifierProvider(
          create: (_) => MusicProvider(
            audioHandler,
            queueManager,
            libraryService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// StartWrapper is no longer used — onboarding check is inside MyApp.
