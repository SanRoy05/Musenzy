import 'dart:async';
import 'package:flutter/foundation.dart';

enum SleepTimerStatus { inactive, active, finishing }

class SleepTimerService extends ChangeNotifier {
  Timer? _timer;
  Timer? _fadeTimer;
  Duration? _selectedDuration;
  // ignore: unused_field
  DateTime? _endTime;
  SleepTimerStatus _status = SleepTimerStatus.inactive;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  // Getters
  SleepTimerStatus get status => _status;
  bool get isActive => _status != SleepTimerStatus.inactive;
  Duration? get selectedDuration => _selectedDuration;
  int get remainingSeconds => _remainingSeconds;

  String get remainingFormatted {
    if (!isActive) return '';
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // Preset timer options
  static const List<Map<String, dynamic>> presets = [
    {'label': '5 min',   'minutes': 5},
    {'label': '10 min',  'minutes': 10},
    {'label': '15 min',  'minutes': 15},
    {'label': '20 min',  'minutes': 20},
    {'label': '30 min',  'minutes': 30},
    {'label': '45 min',  'minutes': 45},
    {'label': '1 hour',  'minutes': 60},
    {'label': '1.5 hrs', 'minutes': 90},
    {'label': '2 hours', 'minutes': 120},
    {'label': 'End of song', 'minutes': -1}, // special case
  ];

  // Start sleep timer
  void start({
    required int minutes,
    required VoidCallback onStop,
    required Function(double volume) onFade,
  }) {
    cancel(); // cancel any existing timer

    _selectedDuration = Duration(minutes: minutes);
    _endTime = DateTime.now().add(_selectedDuration!);
    _remainingSeconds = minutes * 60;
    _status = SleepTimerStatus.active;
    notifyListeners();

    // Countdown ticker — updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }
    });

    // Fade out starts 30 seconds before end
    final fadeStartSeconds = (minutes * 60) - 30;
    if (fadeStartSeconds > 0) {
      _fadeTimer = Timer(Duration(seconds: fadeStartSeconds), () {
        _status = SleepTimerStatus.finishing;
        notifyListeners();
        // Gradually reduce volume over 30 seconds
        _startFadeOut(onFade);
      });
    }

    // Main timer — stops music at end
    _timer = Timer(Duration(minutes: minutes), () {
      onStop();
      cancel();
    });
  }

  // Start "end of song" timer — stops after current song finishes
  void startEndOfSong({required VoidCallback onNextSongStart}) {
    cancel();
    _status = SleepTimerStatus.active;
    _selectedDuration = null; // null = end of song mode
    _remainingSeconds = -1;   // -1 = end of song mode
    notifyListeners();
    // onNextSongStart is called by audio handler when next song would start
  }

  void _startFadeOut(Function(double volume) onFade) {
    const int steps = 30; // 30 steps over 30 seconds
    int currentStep = 0;
    Timer.periodic(const Duration(seconds: 1), (t) {
      currentStep++;
      final volume = 1.0 - (currentStep / steps);
      onFade(volume.clamp(0.0, 1.0));
      if (currentStep >= steps) t.cancel();
    });
  }

  // Cancel sleep timer
  void cancel() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _countdownTimer?.cancel();
    _timer = null;
    _fadeTimer = null;
    _countdownTimer = null;
    _status = SleepTimerStatus.inactive;
    _selectedDuration = null;
    _remainingSeconds = 0;
    _endTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
