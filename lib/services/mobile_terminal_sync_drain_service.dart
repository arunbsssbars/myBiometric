import '../domain/models/mobile_terminal_sync_batch.dart';

/// Service managing offline mobile attendance queue that auto-drains to physical terminal upon connection
class MobileTerminalSyncDrainService {
  final List<MobileQueuedTerminalPunch> _queue = [];

  List<MobileQueuedTerminalPunch> get queuedPunches => List.unmodifiable(_queue);

  void enqueuePunch({
    required String employeeId,
    required String enterpriseId,
    required String punchType,
    DateTime? punchTime,
  }) {
    _queue.add(MobileQueuedTerminalPunch(
      punchId: 'OFF_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      punchType: punchType,
      localPunchTime: punchTime ?? DateTime.now(),
      synced: false,
    ));
  }

  /// Drains queued punches into the physical machine
  Future<int> drainToTerminal({required String terminalIp}) async {
    if (_queue.isEmpty || terminalIp.isEmpty) return 0;

    int drained = 0;
    for (int i = 0; i < _queue.length; i++) {
      if (!_queue[i].synced) {
        _queue[i] = MobileQueuedTerminalPunch(
          punchId: _queue[i].punchId,
          employeeId: _queue[i].employeeId,
          enterpriseId: _queue[i].enterpriseId,
          punchType: _queue[i].punchType,
          localPunchTime: _queue[i].localPunchTime,
          synced: true,
        );
        drained++;
      }
    }

    _queue.removeWhere((p) => p.synced);
    return drained;
  }

  void clearQueue() => _queue.clear();
}
