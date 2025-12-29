import 'package:flutter/foundation.dart';
import 'dart:js_interop';

/// Service to handle web notifications for timer alerts
class WebNotificationService {
  /// Show a notification when timer finishes
  static void showTimerNotification({
    String title = 'Break Buddy',
    String message = 'Time for a break!',
  }) {
    if (!kIsWeb) return;

    try {
      print('[NOTIFICATIONS] Attempting to show timer notification: $title - $message');
      _showNotification(title, message);
    } catch (e) {
      print('[NOTIFICATIONS] Error showing notification: $e');
    }
  }

  /// Show a notification for snooze action
  static void showSnoozeNotification({required int snoozeMinutes}) {
    if (!kIsWeb) return;

    try {
      print('[NOTIFICATIONS] Attempting to show snooze notification: $snoozeMinutes minutes');
      _showNotification(
        'Break Buddy',
        'Break snoozed for $snoozeMinutes minutes',
      );
    } catch (e) {
      print('[NOTIFICATIONS] Error showing snooze notification: $e');
    }
  }

  /// Request notification permission from user
  static void requestPermission() {
    if (!kIsWeb) return;

    try {
      print('[NOTIFICATIONS] Requesting notification permission...');
      _requestPermission();
    } catch (e) {
      print('[NOTIFICATIONS] Error requesting permission: $e');
    }
  }
}

// Private helper functions
void _showNotification(String title, String message) {
  try {
    print('[NOTIFICATIONS] Calling showNotification with title=$title, message=$message');
    // Access the window._breakBuddy object and call showNotification
    _callShowNotification(title, message);
  } catch (e) {
    print('[NOTIFICATIONS] Error in _showNotification: $e');
  }
}

void _requestPermission() {
  try {
    print('[NOTIFICATIONS] Calling requestNotificationPermission');
    _callRequestPermission();
  } catch (e) {
    print('[NOTIFICATIONS] Error in _requestPermission: $e');
  }
}

// JavaScript interop functions - these will be implemented in JavaScript
@JS('window._breakBuddy.showNotification')
external void _callShowNotification(String title, String message);

@JS('window._breakBuddy.requestNotificationPermission')
external void _callRequestPermission();
