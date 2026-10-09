import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';

class ModernDigitalClockCard extends StatefulWidget {
  const ModernDigitalClockCard({super.key});

  @override
  State<ModernDigitalClockCard> createState() => _ModernDigitalClockCardState();
}

class _ModernDigitalClockCardState extends State<ModernDigitalClockCard> {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '$hour:$minute $ampm';
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    if (!mounted) return;
    if (_currentTime != timeStr || _currentDate != dateStr) {
      setState(() {
        _currentTime = timeStr;
        _currentDate = dateStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          children: [
            Text(
              _currentTime,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w300,
                letterSpacing: -1,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentDate,
              style: TextStyle(fontSize: 14, color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
