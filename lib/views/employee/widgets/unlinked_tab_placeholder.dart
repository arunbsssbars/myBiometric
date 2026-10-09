import 'package:flutter/material.dart';

class UnlinkedTabPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onOpenWorkspaceLink;

  const UnlinkedTabPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onOpenWorkspaceLink,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onOpenWorkspaceLink,
                  icon: const Icon(Icons.apartment_rounded),
                  label: const Text('Join or Link Company'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
