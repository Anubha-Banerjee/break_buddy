class ActivityCounter {
  final String activityId;
  final String activityName;
  int totalRepetitions;
  int totalTimeSpent;

  ActivityCounter({
    required this.activityId,
    required this.activityName,
    this.totalRepetitions = 0,
    this.totalTimeSpent = 0,
  });
}

class ActivityCounterManager {
  static final Map<String, ActivityCounter> _counters = {};

  static void updateActivity(
      String activityId, String activityName, int repetitions, int timeSpent) {
    if (!_counters.containsKey(activityId)) {
      _counters[activityId] = ActivityCounter(
        activityId: activityId,
        activityName: activityName,
      );
    }
    _counters[activityId]!.totalRepetitions += repetitions;
    _counters[activityId]!.totalTimeSpent += timeSpent;
  }

  static List<ActivityCounter> getAllCounters() {
    return _counters.values.toList();
  }

  static ActivityCounter? getCounter(String activityId) {
    return _counters[activityId];
  }

  static void reset() {
    _counters.clear();
  }
}
