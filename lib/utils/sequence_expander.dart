import '../models/activity.dart';
import '../models/activity_sequence.dart';
import '../services/activity_sequence_service.dart';
import '../data/activities.dart';

class SequenceExpander {
  static List<Activity> expandSequence(
      Activity sequenceActivity, ActivitySequenceService service) {
    if (!sequenceActivity.id.startsWith('seq_')) {
      return [sequenceActivity];
    }

    final sequence = service.getSequenceById(sequenceActivity.id.substring(4));
    if (sequence == null) {
      print('Warning: Could not find sequence for ID: ${sequenceActivity.id}');
      return [];
    }

    print('\nExpanding sequence: ${sequence.name}');
    final List<Activity> expandedActivities = [];

    for (var activity in sequence.activities) {
      // Find the original activity in predefined activities
      final original = predefinedActivities
          .where((a) => !a.id.startsWith('seq_'))
          .firstWhere(
        (a) => a.id == activity.id,
        orElse: () {
          print('Warning: Could not find original activity for ${activity.id}');
          return activity;
        },
      );

      // Create a copy with the sequence's count and preserve selection time
      final expandedActivity = original.copyWith(
        count: activity.count,
        selectionTime: activity.selectionTime,
      );

      print(
          '- Added ${expandedActivity.name} (${expandedActivity.id}) with count: ${expandedActivity.count}');
      expandedActivities.add(expandedActivity);
    }

    // Sort expanded activities by selection time
    expandedActivities.sort((a, b) {
      final aTime = a.selectionTime;
      final bTime = b.selectionTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    return expandedActivities;
  }

  static List<Activity> expandAllSequences(
      List<Activity> activities, ActivitySequenceService service) {
    final List<Activity> result = [];

    for (var activity in activities) {
      if (activity.count > 0) {
        if (activity.id.startsWith('seq_')) {
          // Get the sequence's selection time to use for all its expanded activities
          final sequenceSelectionTime = activity.selectionTime;
          final expandedActivities = expandSequence(activity, service);

          // Use the sequence's selection time for all expanded activities
          if (sequenceSelectionTime != null) {
            result.addAll(expandedActivities
                .map((a) => a.copyWith(selectionTime: sequenceSelectionTime))
                .toList());
          } else {
            result.addAll(expandedActivities);
          }
        } else {
          result.add(activity.copyWith());
        }
      }
    }

    return result;
  }
}
