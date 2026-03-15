import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_activity.dart';

class CustomActivityService {
  static const String _customActivitiesKey = 'custom_activities';

  /// Save a custom activity to local storage
  Future<void> saveCustomActivity(CustomActivity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> activitiesJson =
        prefs.getStringList(_customActivitiesKey) ?? [];

    // Check if activity already exists and update it, otherwise add new
    final index = activitiesJson.indexWhere((json) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded['id'] == activity.id;
    });

    if (index >= 0) {
      activitiesJson[index] = jsonEncode(activity.toJson());
    } else {
      activitiesJson.add(jsonEncode(activity.toJson()));
    }

    await prefs.setStringList(_customActivitiesKey, activitiesJson);
    print('[CustomActivityService] Saved activity: ${activity.name}');
  }

  /// Load all custom activities from local storage
  Future<List<CustomActivity>> loadCustomActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> activitiesJson =
          prefs.getStringList(_customActivitiesKey) ?? [];

      if (activitiesJson.isEmpty) {
        print('[CustomActivityService] No custom activities found');
        return [];
      }

      final activities = activitiesJson
          .map((json) =>
              CustomActivity.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();

      print(
          '[CustomActivityService] Loaded ${activities.length} custom activities');
      return activities;
    } catch (e) {
      print('[CustomActivityService] Error loading custom activities: $e');
      return [];
    }
  }

  /// Delete a custom activity
  Future<void> deleteCustomActivity(String activityId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> activitiesJson =
        prefs.getStringList(_customActivitiesKey) ?? [];

    activitiesJson.removeWhere((json) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded['id'] == activityId;
    });

    await prefs.setStringList(_customActivitiesKey, activitiesJson);
    print('[CustomActivityService] Deleted activity: $activityId');
  }

  /// Generate a unique ID for a custom activity
  String generateActivityId() {
    return 'custom_${DateTime.now().millisecondsSinceEpoch}';
  }
}
