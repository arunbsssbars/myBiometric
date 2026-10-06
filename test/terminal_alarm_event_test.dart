import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_alarm_event.dart';
import 'package:mybiometric_app/services/terminal_alarm_event_monitor.dart';

void main() {
  group('Terminal Alarm Event & Tamper Monitor Suite', () {
    test('TerminalAlarmEvent serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 1, 15, 30);

      final alarm = TerminalAlarmEvent(
        id: 'alm-901',
        deviceId: 'term-turnstile-1',
        enterpriseId: 'ent-101',
        terminalName: 'North Gate MinMoe',
        type: TerminalAlarmType.doorForcedOpen,
        severity: TerminalAlarmSeverity.critical,
        timestamp: now,
        details: 'Door sensor triggered without valid badge authentication',
        isAcknowledged: false,
      );

      expect(alarm.typeDisplayName, contains('Door Forced Open'));
      expect(alarm.severity, TerminalAlarmSeverity.critical);

      final map = alarm.toMap();
      expect(map['id'], 'alm-901');
      expect(map['type'], 'doorForcedOpen');
      expect(map['severity'], 'critical');
      expect(map['isAcknowledged'], isFalse);

      final revived = TerminalAlarmEvent.fromMap(map, id: 'alm-901');
      expect(revived.terminalName, 'North Gate MinMoe');
      expect(revived.type, TerminalAlarmType.doorForcedOpen);
      expect(revived.severity, TerminalAlarmSeverity.critical);
    });

    test('mapHikvisionAlarmCode maps standard ISAPI major/minor alarm codes', () {
      expect(
        TerminalAlarmEventMonitor.mapHikvisionAlarmCode(5, 2),
        TerminalAlarmType.doorForcedOpen,
      );
      expect(
        TerminalAlarmEventMonitor.mapHikvisionAlarmCode(5, 27),
        TerminalAlarmType.deviceTamper,
      );
      expect(
        TerminalAlarmEventMonitor.mapHikvisionAlarmCode(5, 75),
        TerminalAlarmType.antiPassbackBreach,
      );
      expect(
        TerminalAlarmEventMonitor.mapHikvisionAlarmCode(5, 34),
        TerminalAlarmType.duressPinTriggered,
      );
      expect(
        TerminalAlarmEventMonitor.mapHikvisionAlarmCode(1, 1),
        isNull,
      );
    });
  });
}
