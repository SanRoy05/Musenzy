# 🎵 Musenzy

Your Personal Music Universe — Flutter Music App

## Features
- 🎵 YouTube music streaming
- 🎙️ Voice search
- 🤖 Smart auto queue (mood/language detection)
- 😴 Sleep timer
- 🔔 Background playback + notification controls
- 📚 Library, playlists, liked songs
- 🌍 Artists from 7 regions worldwide
- 🎨 Dynamic player colors

## Build

### Using GitHub Actions (recommended)
Push to main branch → APK builds automatically
Download from Actions → Artifacts tab

### Local build
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release --split-per-abi
```

## Tech Stack
- Flutter + Dart
- youtube_explode_dart
- just_audio + audio_service
- Hive (local storage)
- Provider + GetIt
