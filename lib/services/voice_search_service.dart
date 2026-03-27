import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceSearchService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    // Request mic permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    _isAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Voice error: $error'),
      onStatus: (status) => debugPrint('Voice status: $status'),
    );
    return _isAvailable;
  }

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required Function(String words) onResult,
    required Function() onDone,
    String localeId = 'en_US',
  }) async {
    if (!_isAvailable) {
      await initialize();
    }
    if (!_isAvailable) return;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        } else {
          // Show interim results
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      // ignore: deprecated_member_use
      partialResults: true,
      // ignore: deprecated_member_use
      cancelOnError: true,
      // ignore: deprecated_member_use
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  // Get available locales for multi-language support
  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speech.locales();
  }
}
