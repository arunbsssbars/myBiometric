import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/enterprise_branch.dart';
import '../services/branch_management_service.dart';
import 'branch_location_card.dart';

/// Enterprise Multi-Branch & Job Site Management Screen.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class BranchManagementScreen extends StatefulWidget {
  final String enterpriseId;

  const BranchManagementScreen({
    super.key,
    required this.enterpriseId,
  });

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final BranchManagementService _service = BranchManagementService();

  void _showAddEditBranchDialog([EnterpriseBranch? branch]) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final isEditing = branch != null;
    final nameCtrl = TextEditingController(text: branch?.name ?? '');
    final codeCtrl = TextEditingController(text: branch?.code ?? '');
    final addressCtrl = TextEditingController(text: branch?.address ?? '');
    final latCtrl = TextEditingController(text: branch != null ? branch.latitude.toString() : '0.0');
    final lngCtrl = TextEditingController(text: branch != null ? branch.longitude.toString() : '0.0');
    final radiusCtrl = TextEditingController(text: branch != null ? branch.radiusMeters.toInt().toString() : '150');
    final wifiCtrl = TextEditingController(text: branch?.allowedWifiSsids.join(', ') ?? '');
    bool isActive = branch?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.business_rounded, color: colors.primary, size: AppSizes.iconSm),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Branch Location' : 'Add New Branch',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Branch / Site Name *',
                          hintText: 'e.g. Headquarters, Downtown Hub',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter branch name' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: codeCtrl,
                              decoration: InputDecoration(
                                labelText: 'Code *',
                                hintText: 'HQ, BLR-01',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: radiusCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Radius (m) *',
                                hintText: '150',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                isDense: true,
                              ),
                              validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid radius' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Physical Address',
                          hintText: 'Street, City, Zip Code',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                hintText: '12.9716',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: lngCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                hintText: '77.5946',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: wifiCtrl,
                        decoration: InputDecoration(
                          labelText: 'Allowed Wi-Fi SSIDs',
                          hintText: 'CorpOffice, GuestNet (comma-separated)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Active Location', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('Enforce punches at this branch', style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                        value: isActive,
                        activeTrackColor: statusTheme.success.color,
                        onChanged: (val) => setModalState(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final ssids = wifiCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  final newBranch = EnterpriseBranch(
                    id: branch?.id ?? '',
                    enterpriseId: widget.enterpriseId,
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim().toUpperCase(),
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : 'Office Location',
                    latitude: double.tryParse(latCtrl.text.trim()) ?? 0.0,
                    longitude: double.tryParse(lngCtrl.text.trim()) ?? 0.0,
                    radiusMeters: double.tryParse(radiusCtrl.text.trim()) ?? 150.0,
                    allowedWifiSsids: ssids,
                    isActive: isActive,
                    createdAt: branch?.createdAt ?? DateTime.now(),
                  );

                  final messenger = ScaffoldMessenger.of(context);
                  await _service.saveBranch(enterpriseId: widget.enterpriseId, branch: newBranch);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Branch updated successfully!' : 'Branch created successfully!'),
                        backgroundColor: statusTheme.success.color,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Create Branch'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Multi-Branch & Locations', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: colors.surfaceContainerLowest,
        foregroundColor: colors.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Add Branch',
            icon: Icon(Icons.add_location_alt_rounded, color: colors.primary),
            onPressed: () => _showAddEditBranchDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<EnterpriseBranch>>(
        stream: _service.getEnterpriseBranches(widget.enterpriseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final branches = snapshot.data ?? [];

          if (branches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_city_rounded, size: AppSizes.iconLg * 1.5, color: colors.primary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No Branches Configured',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Define physical offices, warehouse locations, and job sites with dedicated GPS & Wi-Fi boundaries.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                      onPressed: () => _showAddEditBranchDialog(),
                      icon: const Icon(Icons.add_rounded, size: AppSizes.iconSm),
                      label: const Text('Add Primary Branch'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final b = branches[index];
              return BranchLocationCard(
                branch: b,
                onEdit: () => _showAddEditBranchDialog(b),
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      title: Text('Delete Branch?', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      content: Text('Are you sure you want to delete branch "${b.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: Text('Cancel', style: textTheme.labelLarge),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: statusTheme.danger.color,
                            foregroundColor: colors.surfaceContainerLowest,
                          ),
                          onPressed: () {
                            Navigator.pop(dCtx);
                            _service.deleteBranch(
                              enterpriseId: widget.enterpriseId,
                              branchId: b.id,
                              branchName: b.name,
                            );
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
