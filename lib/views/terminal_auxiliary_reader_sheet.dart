import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_auxiliary_reader.dart';

/// Responsive bottom sheet for configuring auxiliary slave readers (Wiegand / OSDP) on a biometric terminal.
/// Fully token-driven (AQIL v2): Zero hardcoded hex colors or fonts.
class TerminalAuxiliaryReaderSheet extends StatefulWidget {
  final BiometricTerminalDevice device;
  final TerminalAuxiliaryReaderConfig? initialConfig;
  final ValueChanged<TerminalAuxiliaryReaderConfig>? onSaved;

  const TerminalAuxiliaryReaderSheet({
    super.key,
    required this.device,
    this.initialConfig,
    this.onSaved,
  });

  @override
  State<TerminalAuxiliaryReaderSheet> createState() => _TerminalAuxiliaryReaderSheetState();
}

class _TerminalAuxiliaryReaderSheetState extends State<TerminalAuxiliaryReaderSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _facilityCodeCtrl;
  late TextEditingController _osdpAddrCtrl;
  AuxiliaryReaderProtocol _protocol = AuxiliaryReaderProtocol.wiegand26;
  String _direction = 'ENTRY';
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig;
    _nameCtrl = TextEditingController(text: cfg?.readerName ?? 'Aux Reader 1');
    _facilityCodeCtrl = TextEditingController(text: cfg != null ? cfg.facilityCode.toString() : '101');
    _osdpAddrCtrl = TextEditingController(text: cfg != null ? cfg.osdpAddress.toString() : '1');
    if (cfg != null) {
      _protocol = cfg.protocol;
      _direction = cfg.direction;
      _isEnabled = cfg.isEnabled;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facilityCodeCtrl.dispose();
    _osdpAddrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final config = TerminalAuxiliaryReaderConfig(
      id: widget.initialConfig?.id ?? 'aux_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: widget.device.id,
      readerName: _nameCtrl.text.trim().isEmpty ? 'Aux Reader' : _nameCtrl.text.trim(),
      protocol: _protocol,
      facilityCode: int.tryParse(_facilityCodeCtrl.text.trim()) ?? 101,
      direction: _direction,
      isEnabled: _isEnabled,
      osdpAddress: int.tryParse(_osdpAddrCtrl.text.trim()) ?? 1,
      createdAt: widget.initialConfig?.createdAt ?? DateTime.now(),
    );
    widget.onSaved?.call(config);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(Icons.nfc_rounded, color: colors.onPrimaryContainer, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auxiliary Slave Reader',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Attached to ${widget.device.name}',
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Reader Name
              Text('Reader Label', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xxs),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: AppRadius.brSm),
                  isDense: true,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Protocol Dropdown
              Text('Hardware Protocol', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xxs),
              DropdownButtonFormField<AuxiliaryReaderProtocol>(
                initialValue: _protocol,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: AppRadius.brSm),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                ),
                items: const [
                  DropdownMenuItem(value: AuxiliaryReaderProtocol.wiegand26, child: Text('Wiegand 26-bit (Standard)')),
                  DropdownMenuItem(value: AuxiliaryReaderProtocol.wiegand34, child: Text('Wiegand 34-bit (Extended)')),
                  DropdownMenuItem(value: AuxiliaryReaderProtocol.wiegand37, child: Text('Wiegand 37-bit (High Security)')),
                  DropdownMenuItem(value: AuxiliaryReaderProtocol.osdpV2SecureChannel, child: Text('OSDP v2 (RS-485 Secure)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _protocol = v);
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // Facility Code & Direction Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Facility Code', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xxs),
                        TextField(
                          controller: _facilityCodeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: AppRadius.brSm),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Swipe Direction', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xxs),
                        DropdownButtonFormField<String>(
                          initialValue: _direction,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: AppRadius.brSm),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ENTRY', child: Text('ENTRY (In)')),
                            DropdownMenuItem(value: 'EXIT', child: Text('EXIT (Out)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _direction = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Enabled Switch Row
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Auxiliary Reader Active', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Process cards presented to this slave reader', style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                value: _isEnabled,
                activeTrackColor: colors.primary,
                onChanged: (val) => setState(() => _isEnabled = val),
              ),

              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                      ),
                      child: const Text('Save Configuration'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
