
enum AudioPromptLanguage {
  en, // English
  es, // Spanish
  hi, // Hindi
  ar, // Arabic
  fr, // French
}

enum AudioPromptType {
  welcome,
  stepCloser,
  lookDirectly,
  punchSuccess,
  tryAgain,
  accessDenied,
}

class KioskAudioConfig {
  final String deviceId;
  final AudioPromptLanguage language;
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final bool quietHoursEnabled;
  final int quietHourStart; // e.g. 22 (10 PM)
  final int quietHourEnd; // e.g. 6 (6 AM)

  const KioskAudioConfig({
    required this.deviceId,
    this.language = AudioPromptLanguage.en,
    this.volume = 0.8,
    this.isMuted = false,
    this.quietHoursEnabled = true,
    this.quietHourStart = 22,
    this.quietHourEnd = 6,
  });

  bool isQuietTime(DateTime time) {
    if (!quietHoursEnabled) return false;
    final hour = time.hour;
    if (quietHourStart > quietHourEnd) {
      // Overnight (e.g. 22 to 6)
      return hour >= quietHourStart || hour < quietHourEnd;
    } else {
      return hour >= quietHourStart && hour < quietHourEnd;
    }
  }

  KioskAudioConfig copyWith({
    AudioPromptLanguage? language,
    double? volume,
    bool? isMuted,
    bool? quietHoursEnabled,
  }) {
    return KioskAudioConfig(
      deviceId: deviceId,
      language: language ?? this.language,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHourStart: quietHourStart,
      quietHourEnd: quietHourEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'language': language.name,
    'volume': volume,
    'isMuted': isMuted,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHourStart': quietHourStart,
    'quietHourEnd': quietHourEnd,
  };

  factory KioskAudioConfig.fromJson(Map<String, dynamic> json) {
    return KioskAudioConfig(
      deviceId: json['deviceId'] as String? ?? '',
      language: AudioPromptLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => AudioPromptLanguage.en,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      isMuted: json['isMuted'] as bool? ?? false,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
      quietHourStart: (json['quietHourStart'] as num?)?.toInt() ?? 22,
      quietHourEnd: (json['quietHourEnd'] as num?)?.toInt() ?? 6,
    );
  }
}

class KioskAudioAccessibilityService {
  static final KioskAudioAccessibilityService _instance = KioskAudioAccessibilityService._internal();
  factory KioskAudioAccessibilityService() => _instance;
  KioskAudioAccessibilityService._internal();

  final Map<String, KioskAudioConfig> _configs = {};

  void setConfig(KioskAudioConfig config) {
    _configs[config.deviceId] = config;
  }

  KioskAudioConfig getConfig(String deviceId) {
    return _configs[deviceId] ?? KioskAudioConfig(deviceId: deviceId);
  }

  String getLocalizedVoicePrompt({
    required AudioPromptType type,
    required AudioPromptLanguage language,
    String? employeeName,
  }) {
    final name = employeeName != null && employeeName.isNotEmpty ? employeeName : '';

    switch (language) {
      case AudioPromptLanguage.en:
        switch (type) {
          case AudioPromptType.welcome:
            return 'Welcome to the office';
          case AudioPromptType.stepCloser:
            return 'Please step slightly closer to the terminal';
          case AudioPromptType.lookDirectly:
            return 'Please look directly into the camera circle';
          case AudioPromptType.punchSuccess:
            return name.isNotEmpty ? 'Punch recorded successfully. Welcome, $name' : 'Punch recorded successfully';
          case AudioPromptType.tryAgain:
            return 'Face not recognized. Please try again';
          case AudioPromptType.accessDenied:
            return 'Access denied. Please consult your admin';
        }
      case AudioPromptLanguage.es:
        switch (type) {
          case AudioPromptType.welcome:
            return 'Bienvenido a la oficina';
          case AudioPromptType.stepCloser:
            return 'Por favor acérquese al terminal';
          case AudioPromptType.lookDirectly:
            return 'Por favor mire directamente a la cámara';
          case AudioPromptType.punchSuccess:
            return name.isNotEmpty ? 'Marcación registrada. Bienvenido, $name' : 'Marcación registrada con éxito';
          case AudioPromptType.tryAgain:
            return 'Rostro no reconocido. Inténtelo de nuevo';
          case AudioPromptType.accessDenied:
            return 'Acceso denegado. Consulte con el administrador';
        }
      case AudioPromptLanguage.hi:
        switch (type) {
          case AudioPromptType.welcome:
            return 'कार्यालय में आपका स्वागत है';
          case AudioPromptType.stepCloser:
            return 'कृपया कैमरे के थोड़ा करीब आएं';
          case AudioPromptType.lookDirectly:
            return 'कृपया सीधे कैमरे की ओर देखें';
          case AudioPromptType.punchSuccess:
            return name.isNotEmpty ? 'उपस्थिति दर्ज की गई। स्वागत है, $name' : 'उपस्थिति सफलतापूर्वक दर्ज की गई';
          case AudioPromptType.tryAgain:
            return 'चेहरा पहचाना नहीं गया। कृपया पुन: प्रयास करें';
          case AudioPromptType.accessDenied:
            return 'प्रवेश अस्वीकृत। कृपया अपने व्यवस्थापक से संपर्क करें';
        }
      case AudioPromptLanguage.ar:
        switch (type) {
          case AudioPromptType.welcome:
            return 'مرحبًا بك في المكتب';
          case AudioPromptType.stepCloser:
            return 'يرجى الاقتراب من الشاشة';
          case AudioPromptType.lookDirectly:
            return 'يرجى النظر مباشرة إلى الكاميرا';
          case AudioPromptType.punchSuccess:
            return name.isNotEmpty ? 'تم تسجيل الحضور بنجاح. مرحبًا $name' : 'تم تسجيل الحضور بنجاح';
          case AudioPromptType.tryAgain:
            return 'لم يتم التعرف على الوجه. يرجى المحاولة مرة أخرى';
          case AudioPromptType.accessDenied:
            return 'تم رفض الدخول. يرجى مراجعة المسؤول';
        }
      case AudioPromptLanguage.fr:
        switch (type) {
          case AudioPromptType.welcome:
            return 'Bienvenue au bureau';
          case AudioPromptType.stepCloser:
            return 'Veuillez vous rapprocher du terminal';
          case AudioPromptType.lookDirectly:
            return 'Veuillez regarder directement la caméra';
          case AudioPromptType.punchSuccess:
            return name.isNotEmpty ? 'Pointage enregistré. Bienvenue, $name' : 'Pointage enregistré avec succès';
          case AudioPromptType.tryAgain:
            return 'Visage non reconnu. Veuillez réessayer';
          case AudioPromptType.accessDenied:
            return 'Accès refusé. Veuillez contacter votre administrateur';
        }
    }
  }

  bool shouldPlayAudio({
    required String deviceId,
    required DateTime currentTime,
  }) {
    final config = getConfig(deviceId);
    if (config.isMuted) return false;
    if (config.isQuietTime(currentTime)) return false;
    return true;
  }

  void clearForTesting() {
    _configs.clear();
  }
}
