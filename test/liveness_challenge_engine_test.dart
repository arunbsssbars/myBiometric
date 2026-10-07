import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/liveness_challenge_engine_service.dart';
import 'package:mybiometric/views/liveness_challenge_progress_card.dart';

void main() {
  group('LivenessChallengeEngineService Suite', () {
    late LivenessChallengeEngineService service;

    setUp(() {
      service = LivenessChallengeEngineService();
      service.clearForTesting();
    });

    test('Generates randomized prompt sequence and tracks progress', () {
      final session = service.startSession(
        employeeId: 'EMP_101',
        stepCount: 2,
        rng: Random(42),
      );

      expect(session.steps.length, equals(2));
      expect(session.currentStepIndex, equals(0));
      expect(session.isCompleted, isFalse);
      expect(session.progressPercentage, equals(0.0));

      final firstPrompt = session.currentStep!.prompt;

      // Pass first step
      final afterStep1 = service.evaluateStepResponse(
        sessionId: session.sessionId,
        observedAction: firstPrompt,
        responseTime: DateTime.now(),
      );

      expect(afterStep1.currentStepIndex, equals(1));
      expect(afterStep1.steps[0].isCompleted, isTrue);
      expect(afterStep1.progressPercentage, equals(0.5));
      expect(afterStep1.isCompleted, isFalse);

      final secondPrompt = afterStep1.currentStep!.prompt;

      // Pass second step
      final afterStep2 = service.evaluateStepResponse(
        sessionId: session.sessionId,
        observedAction: secondPrompt,
        responseTime: DateTime.now(),
      );

      expect(afterStep2.isCompleted, isTrue);
      expect(afterStep2.isFailed, isFalse);
      expect(afterStep2.progressPercentage, equals(1.0));
    });

    test('Fails session when unexpected gesture is submitted', () {
      final session = service.startSession(
        employeeId: 'EMP_102',
        stepCount: 2,
        rng: Random(42),
      );

      final currentPrompt = session.currentStep!.prompt;
      final wrongPrompt = LivenessPromptType.values.firstWhere((p) => p != currentPrompt);

      final failedSession = service.evaluateStepResponse(
        sessionId: session.sessionId,
        observedAction: wrongPrompt,
        responseTime: DateTime.now(),
      );

      expect(failedSession.isFailed, isTrue);
      expect(failedSession.isCompleted, isFalse);
      expect(failedSession.failureReason, contains('Unexpected gesture'));
    });

    testWidgets('LivenessChallengeProgressCard renders without overflow across viewports', (tester) async {
      final session = LivenessChallengeSession(
        sessionId: 'test_session',
        employeeId: 'EMP_001',
        steps: const [
          LivenessChallengeStep(
            stepIndex: 0,
            prompt: LivenessPromptType.smile,
            instruction: 'Please smile into the camera',
            isCompleted: true,
          ),
          LivenessChallengeStep(
            stepIndex: 1,
            prompt: LivenessPromptType.nodUp,
            instruction: 'Gently nod your head upward',
          ),
        ],
        startedAt: DateTime.now(),
        currentStepIndex: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivenessChallengeProgressCard(
              session: session,
            ),
          ),
        ),
      );

      expect(find.textContaining('Challenge 2 of 2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Gently nod your head upward'), findsOneWidget);
    });
  });
}
