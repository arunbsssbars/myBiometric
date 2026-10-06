import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for audible voice feedback (Text-To-Speech)
/// and tactile haptic vibration patterns across the Kiosk & Mobile punch flows.
class KioskFeedbackService {
  static final KioskFeedbackService _instance = KioskFeedbackService._internal();
  factory KioskFeedbackService() => _instance;
  KioskFeedbackService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  bool _voiceGreetingEnabled = true;
  bool _hapticsEnabled = true;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;

  bool get voiceGreetingEnabled => _voiceGreetingEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;

  /// Initialize TTS engine & load stored preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _voiceGreetingEnabled = prefs.getBool('kiosk_voice_greeting_enabled') ?? true;
      _hapticsEnabled = prefs.getBool('kiosk_haptics_enabled') ?? true;
      _speechRate = prefs.getDouble('kiosk_speech_rate') ?? 0.5;
      _speechPitch = prefs.getDouble('kiosk_speech_pitch') ?? 1.0;

      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_speechPitch);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(false);

      _isInitialized = true;
    } catch (e) {
      // Fallback silently if TTS engine fails to initialize on certain OEM devices
      _isInitialized = true;
    }
  }

  /// Toggle voice greeting on or off
  Future<void> setVoiceGreetingEnabled(bool enabled) async {
    _voiceGreetingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kiosk_voice_greeting_enabled', enabled);
  }

  /// Toggle haptic vibration on or off
  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kiosk_haptics_enabled', enabled);
  }

  /// Adjust speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('kiosk_speech_rate', rate);
  }

  /// Trigger tactile haptic feedback for successful punch
  void triggerSuccessHaptic() {
    if (!_hapticsEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Trigger tactile haptic feedback for warning / cooldown / rapid punch-out
  void triggerWarningHaptic() {
    if (!_hapticsEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Speak a warm, professional employee greeting upon punch commit
  Future<void> speakGreeting({
    required String fullName,
    required bool isPunchIn,
    String? statusText,
  }) async {
    if (!_voiceGreetingEnabled) return;

    final firstName = fullName.trim().split(' ').first;
    String message;

    if (isPunchIn) {
      if (statusText != null && statusText.toLowerCase().contains('late')) {
        message = "Welcome, $firstName. Clocked in.";
      } else {
        message = "Welcome, $firstName! Clocked in on time.";
      }
    } else {
      final hour = DateTime.now().hour;
      final partOfDay = hour >= 17 ? "evening" : (hour >= 12 ? "afternoon" : "day");
      message = "Goodbye, $firstName! Have a wonderful $partOfDay.";
    }

    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  /// Speak a short alert prompt (e.g. cooldown or duplicate warning)
  Future<void> speakAlert(String message) async {
    if (!_voiceGreetingEnabled) return;
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  /// Play a preview test voice greeting
  Future<void> playTestGreeting() async {
    await initialize();
    try {
      await _tts.stop();
      await _tts.speak("Voice greetings active. Welcome to Enterprise Biometric Attendance!");
    } catch (_) {}
  }
}
