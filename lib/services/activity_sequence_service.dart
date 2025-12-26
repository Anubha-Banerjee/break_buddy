import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/activity_sequence.dart';
import '../models/activity.dart';
import '../data/activities.dart';

class ActivitySequenceService {
  static const String fileName = 'saved_sequences.json';
  List<ActivitySequence> _sequences = [];

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
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
        print('Deleted sequences file for cleanup');
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
      final file = await _localFile;
      if (!await file.exists()) {
        _sequences = [];
        return [];
      }

      final String contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);

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

      return _sequences;
    } catch (e) {
      print('Error loading sequences: $e');
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
    final file = await _localFile;
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
    print('\nSaving to file: $data');
    await file.writeAsString(data);
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
