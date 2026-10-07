import 'package:flutter/material.dart';
import '../services/kiosk_audio_accessibility_service.dart';
import '../core/design_system/design_system.dart';

class KioskAudioAccessibilityCard extends StatelessWidget {
  final KioskAudioConfig config;
  final ValueChanged<AudioPromptLanguage>? onLanguageChanged;
  final ValueChanged<double>? onVolumeChanged;
  final VoidCallback? onToggleMute;

  const KioskAudioAccessibilityCard({
    super.key,
    required this.config,
    this.onLanguageChanged,
    this.onVolumeChanged,
    this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: config.isMuted ? colors.outlineVariant : colors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: config.isMuted ? colors.onSurfaceVariant : colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio Guidance: ${config.deviceId}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    config.language.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Volume: ${(config.volume * 100).toInt()}% • Quiet: ${config.quietHourStart}:00–${config.quietHourEnd}:00',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (onToggleMute != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: IconButton(
                      icon: Icon(
                        config.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        size: 20,
                        color: config.isMuted ? colors.error : colors.primary,
                      ),
                      onPressed: onToggleMute,
                      tooltip: config.isMuted ? 'Unmute Kiosk' : 'Mute Kiosk',
                    ),
                  ),
              ],
            ),
            if (!config.isMuted && onVolumeChanged != null) ...[
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: config.volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onVolumeChanged,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
