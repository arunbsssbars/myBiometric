import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling FCM background message: ${message.messageId}");
}

/// Service managing Push Notifications via FCM, local foreground notifications,
/// device token registration, and in-app alert dispatches.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'attendance_alerts_channel',
    'Attendance & Regularization Alerts',
    description: 'Notifications for shift events, regularization approvals, and geofence alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _isInitialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging & Local Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request OS permission for Push Notifications (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint("FCM Notification Permission status: ${settings.authorizationStatus}");

      // 2. Setup Local Notifications for Foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint("Local notification tapped: ${response.payload}");
        },
      );

      // Create Android Notification Channel
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(_channel);

      // 3. Set foreground notification presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Retrieve device FCM token
      try {
        _fcmToken = await _fcm.getToken();
        debugPrint("FCM Registration Token: $_fcmToken");
      } catch (e) {
        debugPrint("Could not retrieve FCM token: $e");
      }

      // 5. Listen to Token Refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _syncTokenToFirestore(newToken);
      });

      // 6. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground message received: ${message.notification?.title}");
        _showLocalNotification(message);
      });

      // 7. Handle background message opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Notification opened app: ${message.data}");
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("PushNotificationService initialize error: $e");
    }
  }

  /// Register user's device token in their Firestore document
  Future<void> registerUserDevice(String userId) async {
    if (_fcmToken == null) {
      try {
        _fcmToken = await _fcm.getToken();
      } catch (_) {}
    }
    if (_fcmToken != null) {
      await _syncTokenToFirestore(_fcmToken!, userId: userId);
    }
  }

  Future<void> _syncTokenToFirestore(String token, {String? userId}) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error syncing FCM token: $e");
    }
  }

  /// Display a heads-up local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      final details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint("showNotification error: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await showNotification(
        title: notification.title ?? 'Attendance Alert',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Send an in-app & database notification for Regularization Request
  Future<void> sendRegularizationRequestNotification({
    required String enterpriseId,
    required String employeeName,
    required String employeeId,
    required DateTime shiftDate,
    required String reason,
  }) async {
    final dateStr =
        "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}";
    final title = "Regularization Request: $employeeName";
    final body = "$employeeName (ID: $employeeId) requested a clock-out correction for $dateStr. Reason: $reason";

    // 1. Record in notifications collection for enterprise admins
    await _firestore.collection('notifications').add({
      'target': 'ENTERPRISE_ADMIN',
      'enterpriseId': enterpriseId,
      'title': title,
      'body': body,
      'type': 'REGULARIZATION_REQUEST',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Trigger local notification on device
    await showNotification(title: title, body: body);
  }

  /// Send an in-app & database notification when Regularization is Approved/Rejected
  Future<void> sendRegularizationStatusNotification({
    required String userId,
    required bool isApproved,
    required DateTime shiftDate,
    String? reason,
  }) async {
    final dateStr =
        "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}";
    final title = isApproved
        ? "✅ Regularization Approved"
        : "❌ Regularization Rejected";
    final body = isApproved
        ? "Your attendance regularization for $dateStr has been approved! Shift is now closed."
        : "Your attendance regularization for $dateStr was rejected.${reason != null ? ' Reason: $reason' : ''}";

    // 1. Record in notifications collection for the specific user
    await _firestore.collection('notifications').add({
      'target': 'USER',
      'userId': userId,
      'title': title,
      'body': body,
      'type': isApproved ? 'REGULARIZATION_APPROVED' : 'REGULARIZATION_REJECTED',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Trigger local notification
    await showNotification(title: title, body: body);
  }

  /// Send an in-app & database notification for Geofence Boundary Breach
  Future<void> sendGeofenceBreachAlert({
    required String enterpriseId,
    required String employeeName,
    required String punchType,
    required double distanceFromOfficeMeters,
  }) async {
    final title = "⚠️ Geofence Boundary Alert";
    final body = "$employeeName clocked $punchType ${distanceFromOfficeMeters.toInt()}m outside the office perimeter.";

    await _firestore.collection('notifications').add({
      'target': 'ENTERPRISE_ADMIN',
      'enterpriseId': enterpriseId,
      'title': title,
      'body': body,
      'type': 'GEOFENCE_BREACH',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await showNotification(title: title, body: body);
  }

  /// Send an in-app & database notification for Leave Application to Enterprise Admin
  Future<void> sendLeaveApplicationAlert({
    required String enterpriseId,
    required String employeeName,
    required String leaveType,
    required int daysCount,
  }) async {
    final title = "📅 New Leave Request";
    final body = "$employeeName submitted a $leaveType request for $daysCount day${daysCount > 1 ? 's' : ''}.";

    await _firestore.collection('notifications').add({
      'target': 'ENTERPRISE_ADMIN',
      'enterpriseId': enterpriseId,
      'title': title,
      'body': body,
      'type': 'LEAVE_APPLICATION',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await showNotification(title: title, body: body);
  }

  /// Send an in-app & database notification when Leave Request is Approved/Rejected
  Future<void> sendLeaveReviewAlert({
    required String userId,
    required bool isApproved,
    required String leaveType,
    String? reviewerNotes,
  }) async {
    final title = isApproved ? "✅ Leave Approved" : "❌ Leave Rejected";
    final body = isApproved
        ? "Your $leaveType request was approved! Enjoy your time off."
        : "Your $leaveType request was rejected.${reviewerNotes != null ? ' Notes: $reviewerNotes' : ''}";

    await _firestore.collection('notifications').add({
      'target': 'USER',
      'userId': userId,
      'title': title,
      'body': body,
      'type': isApproved ? 'LEAVE_APPROVED' : 'LEAVE_REJECTED',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await showNotification(title: title, body: body);
  }

  /// Stream unread notifications for a user or enterprise admin
  Stream<List<QueryDocumentSnapshot>> streamNotifications({
    required String userId,
    String? enterpriseId,
    bool isAdmin = false,
  }) {
    Query query = _firestore.collection('notifications');

    if (isAdmin && enterpriseId != null && enterpriseId.isNotEmpty) {
      query = query
          .where('enterpriseId', isEqualTo: enterpriseId)
          .where('target', isEqualTo: 'ENTERPRISE_ADMIN');
    } else {
      query = query
          .where('userId', isEqualTo: userId)
          .where('target', isEqualTo: 'USER');
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final tA = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });
      return docs;
    });
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'read': true});
    } catch (_) {}
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(List<String> notificationIds) async {
    final batch = _firestore.batch();
    for (final id in notificationIds) {
      batch.update(_firestore.collection('notifications').doc(id), {'read': true});
    }
    try {
      await batch.commit();
    } catch (_) {}
  }
}
