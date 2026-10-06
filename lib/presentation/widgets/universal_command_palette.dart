import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single executable command or quick navigation item.
class AppCommand {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final List<String> keywords;
  final VoidCallback onExecute;
  final String? shortcutLabel;

  const AppCommand({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.onExecute,
    this.keywords = const [],
    this.shortcutLabel,
  });
}

/// Global Universal Command Palette Controller & Dialog.
///
/// Supports:
/// 1. Desktop & Web: Global `Ctrl + K` / `Cmd + K` keyboard shortcut listening.
/// 2. Mobile: Dedicated AppBar quick-search icon button or Floating Action Trigger.
/// 3. Responsive: Floating modal dialog on desktop/tablet, adaptive bottom sheet on mobile.
class UniversalCommandPalette {
  /// Opens the Command Palette dialog or bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<AppCommand> commands,
    String? title,
  }) async {
    // Check if mobile or compact window
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _CommandPaletteSheet(commands: commands),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => _CommandPaletteDialog(commands: commands),
      );
    }
  }

  /// Builds an AppBar quick-action icon button for mobile and desktop.
  static Widget buildAppBarButton(
    BuildContext context, {
    required List<AppCommand> Function() commandBuilder,
    Color? iconColor,
  }) {
    return IconButton(
      key: const Key('command_palette_appbar_button'),
      icon: const Icon(Icons.search_rounded),
      tooltip: kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux
          ? 'Command Palette (Ctrl+K)'
          : 'Quick Search & Actions',
      color: iconColor,
      onPressed: () {
        HapticFeedback.lightImpact();
        show(context, commands: commandBuilder());
      },
    );
  }
}

/// Modal Dialog layout for desktop and tablet screens.
class _CommandPaletteDialog extends StatefulWidget {
  final List<AppCommand> commands;
  const _CommandPaletteDialog({required this.commands});

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<AppCommand> get _filteredCommands {
    if (_query.isEmpty) return widget.commands;
    return widget.commands.where((cmd) {
      final matchTitle = cmd.title.toLowerCase().contains(_query);
      final matchSubtitle = cmd.subtitle.toLowerCase().contains(_query);
      final matchCategory = cmd.category.toLowerCase().contains(_query);
      final matchKeywords = cmd.keywords.any((k) => k.toLowerCase().contains(_query));
      return matchTitle || matchSubtitle || matchCategory || matchKeywords;
    }).toList();
  }

  void _executeCommand(AppCommand cmd) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    cmd.onExecute();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCommands;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (filtered.isNotEmpty) {
                setState(() {
                  _selectedIndex = (_selectedIndex + 1) % filtered.length;
                });
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (filtered.isNotEmpty) {
                setState(() {
                  _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length;
                });
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (filtered.isNotEmpty && _selectedIndex < filtered.length) {
                _executeCommand(filtered[_selectedIndex]);
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 22, color: Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('command_palette_search_input'),
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: 'Type a command, screen, or action...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: const Text(
                        'ESC',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

              // Filtered list
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                              SizedBox(height: 8),
                              Text('No matching commands found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    : Material(
                        type: MaterialType.transparency,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final cmd = filtered[index];
                            final isSelected = index == _selectedIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  cmd.icon,
                                  size: 20,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                                title: Text(
                                  cmd.title,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1D4ED8) : null,
                                  ),
                                ),
                                subtitle: Text(
                                  cmd.subtitle,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        cmd.category,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                    if (cmd.shortcutLabel != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        cmd.shortcutLabel!,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () => _executeCommand(cmd),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // Footer hints
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF64748B)),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                    SizedBox(width: 4),
                    Text('Navigate', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    SizedBox(width: 14),
                    Text('â†µ Select', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Spacer(),
                    Text('Universal Command Palette', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile Bottom Sheet layout optimized for touch and thumbs.
class _CommandPaletteSheet extends StatefulWidget {
  final List<AppCommand> commands;
  const _CommandPaletteSheet({required this.commands});

  @override
  State<_CommandPaletteSheet> createState() => _CommandPaletteSheetState();
}

class _CommandPaletteSheetState extends State<_CommandPaletteSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppCommand> get _filteredCommands {
    if (_query.isEmpty) return widget.commands;
    return widget.commands.where((cmd) {
      final matchTitle = cmd.title.toLowerCase().contains(_query);
      final matchSubtitle = cmd.subtitle.toLowerCase().contains(_query);
      final matchCategory = cmd.category.toLowerCase().contains(_query);
      final matchKeywords = cmd.keywords.any((k) => k.toLowerCase().contains(_query));
      return matchTitle || matchSubtitle || matchCategory || matchKeywords;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCommands;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              key: const Key('command_palette_mobile_input'),
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                hintText: 'Search actions, screens, employees...',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Action list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No actions match your search', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  )
                : Material(
                    type: MaterialType.transparency,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                      itemBuilder: (context, index) {
                        final cmd = filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                            child: Icon(cmd.icon, size: 18, color: const Color(0xFF2563EB)),
                          ),
                          title: Text(cmd.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text(cmd.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            cmd.onExecute();
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Global Hotkey Wrapper for Desktop, Web, and Tablet keyboards.
/// Intercepts `Ctrl + K` (Windows/Linux) and `Cmd + K` (macOS).
class UniversalCommandPaletteHotKey extends StatelessWidget {
  final Widget child;
  final List<AppCommand> Function() commandBuilder;

  const UniversalCommandPaletteHotKey({
    super.key,
    required this.child,
    required this.commandBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          UniversalCommandPalette.show(context, commands: commandBuilder());
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          UniversalCommandPalette.show(context, commands: commandBuilder());
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
