import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_sequence.dart';
import '../models/activity.dart';
import '../data/activities.dart';

class ActivitySequenceService {
  static const String fileName = 'saved_sequences.json';
  static const String _prefsKey =
      'break_buddy_sequences'; // Key for shared preferences
  List<ActivitySequence> _sequences = [];
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _initializePrefs();
    _initialized = true;
  }

  Future<void> _initializePrefs() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    print('[SequenceService] SharedPreferences initialized');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<bool> cleanupStoredSequences() async {
    try {
      if (kIsWeb) {
        // For web, remove from shared preferences
        await _initializePrefs();
        await _prefs!.remove(_prefsKey);
        print('Deleted sequences from SharedPreferences for web cleanup');
      } else {
        // For native platforms, delete file
        final file = await _localFile;
        if (await file.exists()) {
          await file.delete();
          print('Deleted sequences file for cleanup');
        }
      }
      _sequences = [];
      return true;
    } catch (e) {
      print('Error cleaning up sequences: $e');
      return false;
    }
  }

  Future<List<ActivitySequence>> loadSequences() async {
    try {
      await initialize(); // Ensure initialized
      String? contents;

      if (kIsWeb) {
        // For web, load from SharedPreferences
        contents = _prefs!.getString(_prefsKey);
        print(
            '[SequenceService] Loaded from SharedPreferences (web): ${contents != null ? "Found ${(json.decode(contents) as List).length} sequences" : "No sequences found"}');
        if (contents == null) {
          _sequences = [];
          return [];
        }
      } else {
        // For native platforms, load from file
        final file = await _localFile;
        if (!await file.exists()) {
          _sequences = [];
          print('[SequenceService] No sequences file found on native platform');
          return [];
        }
        contents = await file.readAsString();
        print('[SequenceService] Loaded from file (native)');
      }

      final List<dynamic> jsonList = json.decode(contents);
      print(
          '[SequenceService] Decoded ${jsonList.length} sequences from storage');

      _sequences = jsonList.map<ActivitySequence>((json) {
        print('\nLoading sequence from JSON:');
        print('Sequence name: ${json['name']}');
        print('Sequence ID: ${json['id']}');
        print('Activities in sequence:');
        (json['activities'] as List).forEach((a) {
          print('- Activity ID: ${a['id']}, Count: ${a['count']}');
        });

        final sequence = ActivitySequence.fromJson(json);

        // Fill in the activity details from predefined activities
        final updatedActivities = sequence.activities.map((activity) {
          final predefined = predefinedActivities.firstWhere(
            (a) => a.id == activity.id,
            orElse: () {
              print(
                  'WARNING: Could not find predefined activity for ID: ${activity.id}');
              return activity;
            },
          );
          print(
              'Found predefined activity: ${predefined.name} for ID: ${activity.id}');
          return predefined.copyWith(
            count: activity.count,
            selectionTime: activity.selectionTime,
          );
        }).toList();

        return ActivitySequence(
          id: sequence.id,
          name: sequence.name,
          activities: updatedActivities,
          createdAt: sequence.createdAt,
        );
      }).toList();

      print(
          '[SequenceService] Successfully loaded ${_sequences.length} sequences');
      return _sequences;
    } catch (e) {
      print('[SequenceService] Error loading sequences: $e');
      _sequences = [];
      return [];
    }
  }

  Future<void> saveSequence(List<Activity> activities, String name) async {
    // Only save activities with count > 0 and filter out any sequence activities
    final selectedActivities = activities
        .where((a) => a.count > 0 && !a.id.startsWith('seq_'))
        .map((a) => a.copyWith()) // Create copies of activities
        .toList()
      ..sort((a, b) =>
          a.selectionTime?.compareTo(b.selectionTime ?? DateTime.now()) ?? 0);

    if (selectedActivities.isEmpty) return;

    final sequence = ActivitySequence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      activities: selectedActivities,
      createdAt: DateTime.now(),
    );

    _sequences.add(sequence);
    await _saveToFile();
  }

  Future<void> _saveToFile() async {
    await initialize(); // Ensure initialized
    final List<Map<String, dynamic>> jsonData = _sequences.map((s) {
      final json = s.toJson();
      print('\nSaving sequence: ${s.name}');
      print('Sequence ID: ${s.id}');
      print('Activities in sequence:');
      (json['activities'] as List).forEach((a) {
        print('- Activity ID: ${a['id']}, Count: ${a['count']}');
      });
      return json;
    }).toList();

    final String data = json.encode(jsonData);
    print('\n[SequenceService] Saving ${_sequences.length} sequences');
    print(
        '[SequenceService] Serialized data length: ${data.length} characters');

    if (kIsWeb) {
      // For web, save to SharedPreferences
      print('[SequenceService] Saving to SharedPreferences (web)');
      final success = await _prefs!.setString(_prefsKey, data);
      print('[SequenceService] Save to SharedPreferences success: $success');
      if (!success) {
        print(
            '[SequenceService] WARNING: Failed to save to SharedPreferences!');
      }
    } else {
      // For native platforms, save to file
      print('[SequenceService] Saving to file (native)');
      final file = await _localFile;
      await file.writeAsString(data);
      print('[SequenceService] Sequences saved to file (native)');
    }
  }

  Future<bool> deleteSequence(String id) async {
    print('\nDeleting sequence with ID: $id');
    final initialCount = _sequences.length;
    _sequences.removeWhere((s) => s.id == id);
    final wasRemoved = _sequences.length < initialCount;

    if (wasRemoved) {
      print('Sequence found and removed');
      await _saveToFile();
    } else {
      print('Sequence not found for deletion');
    }

    return wasRemoved;
  }

  Future<bool> updateSequence(String id, List<Activity> activities) async {
    print('\nUpdating sequence with ID: $id');
    try {
      final index = _sequences.indexWhere((s) => s.id == id);
      if (index != -1) {
        final oldSequence = _sequences[index];
        // Only save activities with count > 0 and filter out any sequence activities
        final updatedActivities = activities
            .where((a) => a.count > 0 && !a.id.startsWith('seq_'))
            .map((a) => a.copyWith())
            .toList()
          ..sort((a, b) =>
              a.selectionTime?.compareTo(b.selectionTime ?? DateTime.now()) ??
              0);

        final updatedSequence = ActivitySequence(
          id: oldSequence.id,
          name: oldSequence.name,
          activities: updatedActivities,
          createdAt: oldSequence.createdAt,
        );

        _sequences[index] = updatedSequence;
        print('Sequence updated: ${oldSequence.name}');
        await _saveToFile();
        return true;
      } else {
        print('Sequence not found for updating');
        return false;
      }
    } catch (e) {
      print('Error updating sequence: $e');
      return false;
    }
  }

  List<ActivitySequence> get sequences => List.unmodifiable(_sequences);

  ActivitySequence? getSequenceById(String id) {
    try {
      return _sequences.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addSequenceAndNotify(ActivitySequence sequence) async {
    _sequences.add(sequence);
    await _saveToFile();
  }
}
