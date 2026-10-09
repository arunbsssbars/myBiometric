import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../domain/models/shift_swap_request.dart';
import '../services/shift_swap_service.dart';
import '../core/design_system/design_system.dart';
import 'shift_swap_card.dart';

class ShiftSwapManagementScreen extends StatefulWidget {
  final String enterpriseId;
  final String currentUserId;
  final bool isManager;

  const ShiftSwapManagementScreen({
    super.key,
    required this.enterpriseId,
    required this.currentUserId,
    this.isManager = true,
  });

  @override
  State<ShiftSwapManagementScreen> createState() => _ShiftSwapManagementScreenState();
}

class _ShiftSwapManagementScreenState extends State<ShiftSwapManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ShiftSwapService _swapService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _swapService = ShiftSwapService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateSwapSheet(List<Map<String, dynamic>> roster) {
    if (roster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees available to swap with.')),
      );
      return;
    }

    // Filter out current user
    final availablePeers = roster
        .where((e) => (e['id'] ?? e['uid'] ?? '').toString() != widget.currentUserId)
        .toList();

    if (availablePeers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No colleagues found to initiate a shift trade.')),
      );
      return;
    }

    String? selectedPeerId = (availablePeers.first['id'] ?? availablePeers.first['uid'] ?? '').toString();
    DateTime requesterDate = DateTime.now().add(const Duration(days: 1));
    DateTime targetDate = DateTime.now().add(const Duration(days: 2));
    final reasonController = TextEditingController();
    String requesterShift = 'Morning Shift (09:00 - 17:00)';
    String targetShift = 'Evening Shift (14:00 - 22:00)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedPeer = availablePeers.firstWhere(
              (p) => (p['id'] ?? p['uid'] ?? '').toString() == selectedPeerId,
              orElse: () => availablePeers.first,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Request Shift Trade',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a colleague and propose a shift swap. Both peer and manager approval are required.',
                      style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                    ),
                    const Divider(height: 24),
                    Text('Select Colleague to Swap With', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPeerId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: availablePeers.map((peer) {
                        final id = (peer['id'] ?? peer['uid'] ?? '').toString();
                        final name = (peer['fullName'] ?? peer['name'] ?? 'Staff Member').toString();
                        final dept = (peer['department'] ?? 'General').toString();
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text('$name ($dept)', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPeerId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Shift Date', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  '${requesterDate.day}/${requesterDate.month}/${requesterDate.year}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: requesterDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (picked != null) setModalState(() => requesterDate = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Their Shift Date', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: targetDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (picked != null) setModalState(() => targetDate = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Reason for Swap', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Personal family commitment on Friday morning',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Submit Shift Trade Request'),
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please provide a reason for the shift swap.')),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          final peerName = (selectedPeer['fullName'] ?? selectedPeer['name'] ?? 'Colleague').toString();
                          final peerDept = (selectedPeer['department'] ?? 'General').toString();

                          final request = ShiftSwapRequest(
                            id: '',
                            enterpriseId: widget.enterpriseId,
                            requesterId: widget.currentUserId,
                            requesterName: 'Me',
                            requesterShiftName: requesterShift,
                            requesterDate: requesterDate,
                            targetEmployeeId: selectedPeerId!,
                            targetEmployeeName: peerName,
                            targetDepartment: peerDept,
                            targetShiftName: targetShift,
                            targetDate: targetDate,
                            reason: reason,
                            createdAt: DateTime.now(),
                          );

                          Navigator.pop(ctx);
                          try {
                            await _swapService.createSwapRequest(request);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Shift trade request submitted successfully!')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to submit swap: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shift Trades & Swaps',
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.isManager
              ? const [
                  Tab(text: 'Pending Approvals'),
                  Tab(text: 'All Organization Swaps'),
                ]
              : const [
                  Tab(text: 'Requests for Me'),
                  Tab(text: 'My Trade Requests'),
                ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('enterprises')
            .doc(widget.enterpriseId)
            .collection('employees')
            .snapshots(),
        builder: (context, rosterSnap) {
          final rosterDocs = rosterSnap.data?.docs ?? [];
          final roster = rosterDocs
              .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList();

          return StreamBuilder<List<ShiftSwapRequest>>(
            stream: _swapService.streamEnterpriseSwaps(widget.enterpriseId),
            builder: (context, swapSnap) {
              final swaps = swapSnap.data ?? [];

              final List<ShiftSwapRequest> tab1Swaps;
              final List<ShiftSwapRequest> tab2Swaps;

              if (widget.isManager) {
                tab1Swaps = swaps.where((s) => s.status == ShiftSwapStatus.pendingManager).toList();
                tab2Swaps = swaps;
              } else {
                tab1Swaps = swaps.where((s) => s.targetEmployeeId == widget.currentUserId).toList();
                tab2Swaps = swaps.where((s) => s.requesterId == widget.currentUserId).toList();
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildSwapList(tab1Swaps, roster, isFirstTab: true),
                  _buildSwapList(tab2Swaps, roster, isFirstTab: false),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('enterprises')
            .doc(widget.enterpriseId)
            .collection('employees')
            .snapshots(),
        builder: (context, snap) {
          final roster = (snap.data?.docs ?? [])
              .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList();

          return FloatingActionButton.extended(
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Request Trade'),
            onPressed: () => _openCreateSwapSheet(roster),
          );
        },
      ),
    );
  }

  Widget _buildSwapList(
    List<ShiftSwapRequest> swaps,
    List<Map<String, dynamic>> roster, {
    required bool isFirstTab,
  }) {
    if (swaps.isEmpty) {
      final String emptyTitle;
      final String emptySubtitle;
      if (widget.isManager) {
        if (isFirstTab) {
          emptyTitle = 'No Pending Manager Approvals';
          emptySubtitle = 'All peer-accepted shift trades have been evaluated.';
        } else {
          emptyTitle = 'No Shift Swaps Logged';
          emptySubtitle = 'All workforce shift allocations are operating on standard rosters.';
        }
      } else {
        if (isFirstTab) {
          emptyTitle = 'No Incoming Trade Proposals';
          emptySubtitle = 'When a colleague requests to trade shifts with you, it will appear here.';
        } else {
          emptyTitle = 'No Outgoing Trade Requests';
          emptySubtitle = 'Tap "Request Trade" below to propose a shift swap with a colleague.';
        }
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horizontal_circle_outlined,
                size: 56,
                color: context.colors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: swaps.length,
      itemBuilder: (context, index) {
        final swap = swaps[index];
        return ShiftSwapCard(
          swap: swap,
          currentUserId: widget.currentUserId,
          onPeerAccept: () => _swapService.peerRespond(
            enterpriseId: widget.enterpriseId,
            swapId: swap.id,
            accept: true,
          ),
          onPeerReject: () => _swapService.peerRespond(
            enterpriseId: widget.enterpriseId,
            swapId: swap.id,
            accept: false,
          ),
          onManagerApprove: widget.isManager
              ? () => _swapService.managerRespond(
                    enterpriseId: widget.enterpriseId,
                    swapId: swap.id,
                    managerUid: widget.currentUserId,
                    approve: true,
                  )
              : null,
          onManagerReject: widget.isManager
              ? () => _swapService.managerRespond(
                    enterpriseId: widget.enterpriseId,
                    swapId: swap.id,
                    managerUid: widget.currentUserId,
                    approve: false,
                  )
              : null,
          onCancel: () => _swapService.cancelSwapRequest(
            enterpriseId: widget.enterpriseId,
            swapId: swap.id,
            userId: widget.currentUserId,
          ),
        );
      },
    );
  }
}

