import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/models/external_biometric_device.dart';

/// Service responsible for communicating directly with Hikvision MinMoe Terminals
/// (DS-K1T343EFWX, DS-K1T343MWX, DS-K1T671, etc.) using the ISAPI REST protocol.
class HikvisionIsapiService {
  final HttpClient Function()? clientFactory;

  HikvisionIsapiService({this.clientFactory});

  HttpClient _createClient(BiometricTerminalDevice device) {
    final client = clientFactory != null ? clientFactory!() : HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    // Support Digest Authentication with terminal credentials
    if (device.username != null && device.password != null) {
      final uri = Uri.parse('http://${device.ipAddress}:${device.port}');
      client.addCredentials(
        uri,
        '', // realm
        HttpClientDigestCredentials(device.username!, device.password!),
      );
    }
    return client;
  }

  /// Tests network connectivity and credential validity against `/ISAPI/System/deviceInfo`.
  Future<Map<String, dynamic>> testConnection(BiometricTerminalDevice device) async {
    final client = _createClient(device);
    try {
      final uri = Uri.parse('http://${device.ipAddress}:${device.port}/ISAPI/System/deviceInfo?format=json');
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json, text/xml');

      final response = await request.close().timeout(const Duration(seconds: 8));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.unauthorized) {
        if (response.statusCode == HttpStatus.ok) {
          // Successfully authenticated
          return {
            'success': true,
            'statusCode': response.statusCode,
            'message': 'Connection and authentication successful!',
            'raw': responseBody,
          };
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'Authentication failed. Please verify terminal username and password.',
          };
        }
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Terminal returned HTTP ${response.statusCode}: $responseBody',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to reach terminal at ${device.ipAddress}:${device.port}: $e',
      };
    } finally {
      client.close(force: true);
    }
  }

  /// Searches and retrieves access control / attendance punch events from the MinMoe terminal.
  /// Endpoint: `POST /ISAPI/AccessControl/AcsEvents?format=json`
  Future<List<TerminalAttendanceEvent>> fetchAttendanceEvents(
    BiometricTerminalDevice device, {
    DateTime? startTime,
    DateTime? endTime,
    int maxResults = 100,
    int searchPosition = 0,
  }) async {
    final client = _createClient(device);
    try {
      final uri = Uri.parse('http://${device.ipAddress}:${device.port}/ISAPI/AccessControl/AcsEvents?format=json');
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final startIso = (startTime ?? DateTime.now().subtract(const Duration(hours: 24))).toIso8601String();
      final endIso = (endTime ?? DateTime.now()).toIso8601String();

      final searchPayload = jsonEncode({
        'AcsEventCond': {
          'searchID': '${DateTime.now().millisecondsSinceEpoch}',
          'searchResultPosition': searchPosition,
          'maxResults': maxResults,
          'major': 5, // Access Control Events
          'minor': 0, // All minor events or 75 for Face verification
          'startTime': startIso,
          'endTime': endIso,
        }
      });

      request.write(searchPayload);
      final response = await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == HttpStatus.ok) {
        return parseAcsEventsResponse(responseBody, device.id);
      }
      return [];
    } catch (_) {
      return [];
    } finally {
      client.close(force: true);
    }
  }

  /// Parses raw Hikvision AcsEvents JSON payload into structured [TerminalAttendanceEvent]s.
  List<TerminalAttendanceEvent> parseAcsEventsResponse(String jsonString, String deviceId) {
    final events = <TerminalAttendanceEvent>[];
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final acsEvent = data['AcsEvent'] as Map<String, dynamic>?;
      if (acsEvent == null) return events;

      final infoList = acsEvent['InfoList'] as List<dynamic>? ?? [];
      for (final item in infoList) {
        if (item is Map<String, dynamic>) {
          final employeeNo = item['employeeNoString']?.toString() ?? item['cardNo']?.toString() ?? '';
          if (employeeNo.isEmpty) continue;

          final timeStr = item['time']?.toString() ?? '';
          final time = DateTime.tryParse(timeStr) ?? DateTime.now();

          // Auth mode translation: 1=card, 2=pin, 15=face, 17=fingerprint
          final minor = (item['minor'] as num?)?.toInt() ?? 0;
          final authModeNum = (item['authMode'] as num?)?.toInt();

          DeviceAuthMode authMode;
          if (authModeNum == 15 || minor == 75) {
            authMode = DeviceAuthMode.face;
          } else if (authModeNum == 17 || minor == 76) {
            authMode = DeviceAuthMode.fingerprint;
          } else if (authModeNum == 1 || minor == 1) {
            authMode = DeviceAuthMode.card;
          } else {
            authMode = DeviceAuthMode.face; // default to face for MinMoe
          }

          // Attendance status translation: 0=CheckIn, 1=CheckOut, 2=BreakOut, 3=BreakIn
          final attendanceStatus = (item['attendanceStatus'] as num?)?.toInt() ?? 0;
          String punchType;
          switch (attendanceStatus) {
            case 0:
              punchType = 'PUNCH_IN';
              break;
            case 1:
              punchType = 'PUNCH_OUT';
              break;
            case 2:
              punchType = 'START_BREAK';
              break;
            case 3:
              punchType = 'END_BREAK';
              break;
            default:
              punchType = 'PUNCH_IN';
          }

          events.add(TerminalAttendanceEvent(
            eventId: item['serialNo']?.toString() ?? '${deviceId}_${time.millisecondsSinceEpoch}',
            deviceId: deviceId,
            employeeId: employeeNo,
            employeeName: item['name']?.toString(),
            timestamp: time,
            punchType: punchType,
            authMode: authMode,
            cardNo: item['cardNo']?.toString(),
            similarityScore: (item['similarity'] as num?)?.toDouble(),
            rawPayload: jsonEncode(item),
          ));
        }
      }
    } catch (_) {}
    return events;
  }

  /// Synchronizes an employee record to the physical MinMoe terminal.
  /// Endpoint: `POST /ISAPI/AccessControl/UserInfo/Record?format=json`
  Future<bool> syncPersonToTerminal(
    BiometricTerminalDevice device, {
    required String employeeId,
    required String fullName,
    String? cardNo,
    String userType = 'normal',
  }) async {
    final client = _createClient(device);
    try {
      final uri = Uri.parse('http://${device.ipAddress}:${device.port}/ISAPI/AccessControl/UserInfo/Record?format=json');
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final userPayload = jsonEncode({
        'UserInfo': {
          'employeeNo': employeeId,
          'name': fullName,
          'userType': userType,
          'closeDelayEnabled': false,
          'Valid': {
            'enable': true,
            'beginTime': '2026-01-01T00:00:00',
            'endTime': '2035-12-31T23:59:59',
            'timeType': 'local',
          },
          'doorRight': '1',
          'RightPlan': [
            {'doorNo': 1, 'planTemplateNo': '1'}
          ]
        }
      });

      request.write(userPayload);
      final response = await request.close().timeout(const Duration(seconds: 8));
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Generic helper for authenticated Digest ISAPI REST requests.
  Future<HttpClientResponse> sendDigestRequest({
    required BiometricTerminalDevice device,
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? jsonBody,
  }) async {
    final client = _createClient(device);
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('http://${device.ipAddress}:${device.port}$cleanEndpoint');

    HttpClientRequest request;
    switch (method.toUpperCase()) {
      case 'POST':
        request = await client.postUrl(uri);
        break;
      case 'PUT':
        request = await client.putUrl(uri);
        break;
      case 'DELETE':
        request = await client.deleteUrl(uri);
        break;
      case 'GET':
      default:
        request = await client.getUrl(uri);
        break;
    }

    if (jsonBody != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(jsonBody));
    }

    return await request.close().timeout(const Duration(seconds: 10));
  }
}
