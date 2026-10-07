import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/kiosk_audio_accessibility_service.dart';
import 'package:mybiometric/views/kiosk_audio_accessibility_card.dart';

void main() {
  group('KioskAudioAccessibilityService Suite', () {
    late KioskAudioAccessibilityService service;

    setUp(() {
      service = KioskAudioAccessibilityService();
      service.clearForTesting();
    });

    test('Returns accurate localized voice prompts for multiple languages', () {
      final enPrompt = service.getLocalizedVoicePrompt(
        type: AudioPromptType.welcome,
        language: AudioPromptLanguage.en,
      );
      expect(enPrompt, equals('Welcome to the office'));

      final esPrompt = service.getLocalizedVoicePrompt(
        type: AudioPromptType.stepCloser,
        language: AudioPromptLanguage.es,
      );
      expect(esPrompt, contains('Por favor'));

      final hiPrompt = service.getLocalizedVoicePrompt(
        type: AudioPromptType.punchSuccess,
        language: AudioPromptLanguage.hi,
        employeeName: 'राजेश',
      );
      expect(hiPrompt, contains('राजेश'));

      final frPrompt = service.getLocalizedVoicePrompt(
        type: AudioPromptType.welcome,
        language: AudioPromptLanguage.fr,
      );
      expect(frPrompt, equals('Bienvenue au bureau'));
    });

    test('Enforces quiet hours and muting rules', () {
      service.setConfig(
        const KioskAudioConfig(
          deviceId: 'TERM_LOBBY_01',
          quietHoursEnabled: true,
          quietHourStart: 22,
          quietHourEnd: 6,
        ),
      );

      // 11 PM should be quiet hours (suppressed)
      final nightTime = DateTime(2026, 10, 8, 23, 0);
      expect(service.shouldPlayAudio(deviceId: 'TERM_LOBBY_01', currentTime: nightTime), isFalse);

      // 2 PM daytime should allow audio
      final dayTime = DateTime(2026, 10, 8, 14, 0);
      expect(service.shouldPlayAudio(deviceId: 'TERM_LOBBY_01', currentTime: dayTime), isTrue);
    });

    testWidgets('KioskAudioAccessibilityCard renders without overflow across viewports', (tester) async {
      const config = KioskAudioConfig(
        deviceId: 'TERM_ENTRANCE_01',
        language: AudioPromptLanguage.en,
        volume: 0.75,
        isMuted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KioskAudioAccessibilityCard(
              config: config,
              onToggleMute: () {},
              onVolumeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('TERM_ENTRANCE_01'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.textContaining('75%'), findsOneWidget);
    });
  });
}
