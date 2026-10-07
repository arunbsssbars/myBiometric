import 'dart:math';

enum LivenessPromptType {
  blinkTwice,
  smile,
  turnHeadLeft,
  turnHeadRight,
  nodUp,
}

class LivenessChallengeStep {
  final int stepIndex;
  final LivenessPromptType prompt;
  final String instruction;
  final Duration timeout;
  final bool isCompleted;

  const LivenessChallengeStep({
    required this.stepIndex,
    required this.prompt,
    required this.instruction,
    this.timeout = const Duration(seconds: 4),
    this.isCompleted = false,
  });

  LivenessChallengeStep copyWith({bool? isCompleted}) {
    return LivenessChallengeStep(
      stepIndex: stepIndex,
      prompt: prompt,
      instruction: instruction,
      timeout: timeout,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'stepIndex': stepIndex,
    'prompt': prompt.name,
    'instruction': instruction,
    'timeoutMs': timeout.inMilliseconds,
    'isCompleted': isCompleted,
  };
}

class LivenessChallengeSession {
  final String sessionId;
  final String employeeId;
  final List<LivenessChallengeStep> steps;
  final DateTime startedAt;
  final int currentStepIndex;
  final bool isCompleted;
  final bool isFailed;
  final String? failureReason;

  const LivenessChallengeSession({
    required this.sessionId,
    required this.employeeId,
    required this.steps,
    required this.startedAt,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.isFailed = false,
    this.failureReason,
  });

  LivenessChallengeStep? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  double get progressPercentage =>
      steps.isEmpty ? 0.0 : (currentStepIndex / steps.length).clamp(0.0, 1.0);

  LivenessChallengeSession copyWith({
    List<LivenessChallengeStep>? steps,
    int? currentStepIndex,
    bool? isCompleted,
    bool? isFailed,
    String? failureReason,
  }) {
    return LivenessChallengeSession(
      sessionId: sessionId,
      employeeId: employeeId,
      steps: steps ?? this.steps,
      startedAt: startedAt,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

class LivenessChallengeEngineService {
  static final LivenessChallengeEngineService _instance = LivenessChallengeEngineService._internal();
  factory LivenessChallengeEngineService() => _instance;
  LivenessChallengeEngineService._internal();

  final Map<String, LivenessChallengeSession> _activeSessions = {};

  LivenessChallengeSession startSession({
    required String employeeId,
    int stepCount = 2,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final promptsPool = List<LivenessPromptType>.from(LivenessPromptType.values)..shuffle(random);
    final selectedPrompts = promptsPool.take(stepCount.clamp(1, 4)).toList();

    final steps = <LivenessChallengeStep>[];
    for (int i = 0; i < selectedPrompts.length; i++) {
      steps.add(
        LivenessChallengeStep(
          stepIndex: i,
          prompt: selectedPrompts[i],
          instruction: _getInstructionForPrompt(selectedPrompts[i]),
        ),
      );
    }

    final session = LivenessChallengeSession(
      sessionId: 'live_${DateTime.now().millisecondsSinceEpoch}_$employeeId',
      employeeId: employeeId,
      steps: steps,
      startedAt: DateTime.now(),
    );

    _activeSessions[session.sessionId] = session;
    return session;
  }

  String _getInstructionForPrompt(LivenessPromptType prompt) {
    switch (prompt) {
      case LivenessPromptType.blinkTwice:
        return 'Please blink your eyes naturally twice';
      case LivenessPromptType.smile:
        return 'Please smile into the camera';
      case LivenessPromptType.turnHeadLeft:
        return 'Slightly turn your head to your left';
      case LivenessPromptType.turnHeadRight:
        return 'Slightly turn your head to your right';
      case LivenessPromptType.nodUp:
        return 'Gently nod your head upward';
    }
  }

  LivenessChallengeSession evaluateStepResponse({
    required String sessionId,
    required LivenessPromptType observedAction,
    required DateTime responseTime,
  }) {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw StateError('Session $sessionId not found');
    }

    if (session.isCompleted || session.isFailed) {
      return session;
    }

    final step = session.currentStep;
    if (step == null) {
      return session.copyWith(isCompleted: true);
    }

    // Check timeout
    final elapsed = responseTime.difference(session.startedAt);
    if (elapsed > const Duration(seconds: 12)) {
      final failed = session.copyWith(
        isFailed: true,
        failureReason: 'Liveness challenge timed out',
      );
      _activeSessions[sessionId] = failed;
      return failed;
    }

    if (observedAction == step.prompt) {
      final updatedSteps = List<LivenessChallengeStep>.from(session.steps);
      updatedSteps[session.currentStepIndex] = step.copyWith(isCompleted: true);

      final nextIndex = session.currentStepIndex + 1;
      final isFinished = nextIndex >= session.steps.length;

      final updatedSession = session.copyWith(
        steps: updatedSteps,
        currentStepIndex: nextIndex,
        isCompleted: isFinished,
      );

      _activeSessions[sessionId] = updatedSession;
      return updatedSession;
    } else {
      final failed = session.copyWith(
        isFailed: true,
        failureReason: 'Unexpected gesture. Expected: ${step.prompt.name}, Received: ${observedAction.name}',
      );
      _activeSessions[sessionId] = failed;
      return failed;
    }
  }

  void endSession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  void clearForTesting() {
    _activeSessions.clear();
  }
}
