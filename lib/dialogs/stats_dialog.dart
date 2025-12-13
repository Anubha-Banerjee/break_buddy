import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/activity_video.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityStats {
  final Activity activity;
  final int count;
  final int timeSpent; // in seconds

  ActivityStats({
    required this.activity,
    required this.count,
    required this.timeSpent,
  });
}

class StatsDialog extends StatelessWidget {
  final int breaksTaken;
  final List<ActivityStats> activityStats;
  final int totalActivityTime;
  final int totalWorkingTime;

  const StatsDialog({
    Key? key,
    required this.breaksTaken,
    required this.activityStats,
    required this.totalActivityTime,
    required this.totalWorkingTime,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      int minutes = seconds ~/ 60;
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      return '$hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  void _shareStats(BuildContext context) {
    // Build the share text with all stats - comprehensive format
    StringBuffer shareText = StringBuffer();
    shareText.write('Break Buddy - My Workout Stats\n');
    shareText.write('=' * 50);
    shareText.write('\n\n');

    // Breaks taken
    shareText.write('BREAKS TAKEN: $breaksTaken\n\n');

    // Total times
    shareText.write('-' * 50);
    shareText.write('\n');
    shareText
        .write('Total Activity Time: ${_formatDuration(totalActivityTime)}\n');
    shareText
        .write('Total Working Time: ${_formatDuration(totalWorkingTime)}\n\n');

    // Activities completed with full details - sorted by time spent
    if (activityStats.isNotEmpty) {
      shareText.write('ACTIVITIES COMPLETED:\n');
      shareText.write('-' * 50);
      shareText.write('\n\n');
      final sortedStats = List<ActivityStats>.from(activityStats)
        ..sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
      for (var stat in sortedStats) {
        shareText.write('Activity: ${stat.activity.name}\n');
        if (stat.activity.countMatters) {
          shareText.write('Repetitions: ${stat.count} times\n');
        }
        shareText.write('Time Spent: ${_formatDuration(stat.timeSpent)}\n\n');
      }
      shareText.write('=' * 50);
      shareText.write('\n\n');
    } else {
      shareText.write('No activities completed.\n\n');
    }

    shareText.write('\nShared from Break Buddy App');

    final finalText = shareText.toString();
    print('Sharing stats:\n$finalText');

    // Share with the text
    Share.share(
      finalText,
      subject: 'My Break Buddy Workout Stats',
    );
  }

  void _copyStatsToClipboard(BuildContext context) {
    // Build the share text with all stats - comprehensive format
    StringBuffer shareText = StringBuffer();
    shareText.write('Break Buddy - My Workout Stats\n');
    shareText.write('=' * 50);
    shareText.write('\n\n');

    // Breaks taken
    shareText.write('BREAKS TAKEN: $breaksTaken\n\n');

    // Total times
    shareText.write('-' * 50);
    shareText.write('\n');
    shareText
        .write('Total Activity Time: ${_formatDuration(totalActivityTime)}\n');
    shareText
        .write('Total Working Time: ${_formatDuration(totalWorkingTime)}\n\n');

    // Activities completed with full details - sorted by time spent
    if (activityStats.isNotEmpty) {
      shareText.write('ACTIVITIES COMPLETED:\n');
      shareText.write('-' * 50);
      shareText.write('\n\n');
      final sortedStats = List<ActivityStats>.from(activityStats)
        ..sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
      for (var stat in sortedStats) {
        shareText.write('Activity: ${stat.activity.name}\n');
        if (stat.activity.countMatters) {
          shareText.write('Repetitions: ${stat.count} times\n');
        }
        shareText.write('Time Spent: ${_formatDuration(stat.timeSpent)}\n\n');
      }
      shareText.write('=' * 50);
      shareText.write('\n\n');
    } else {
      shareText.write('No activities completed.\n\n');
    }

    shareText.write('\nShared from Break Buddy App');

    final finalText = shareText.toString();

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: finalText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stats copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _openGmail(BuildContext context) {
    // Build the share text with all stats
    StringBuffer shareText = StringBuffer();
    shareText.write('Break Buddy - My Workout Stats\n');
    shareText.write('=' * 50);
    shareText.write('\n\n');

    // Breaks taken
    shareText.write('BREAKS TAKEN: $breaksTaken\n\n');

    // Total times
    shareText.write('-' * 50);
    shareText.write('\n');
    shareText
        .write('Total Activity Time: ${_formatDuration(totalActivityTime)}\n');
    shareText
        .write('Total Working Time: ${_formatDuration(totalWorkingTime)}\n\n');

    // Activities completed with full details - sorted by time spent
    if (activityStats.isNotEmpty) {
      shareText.write('ACTIVITIES COMPLETED:\n');
      shareText.write('-' * 50);
      shareText.write('\n\n');
      final sortedStats = List<ActivityStats>.from(activityStats)
        ..sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
      for (var stat in sortedStats) {
        shareText.write('Activity: ${stat.activity.name}\n');
        if (stat.activity.countMatters) {
          shareText.write('Repetitions: ${stat.count} times\n');
        }
        shareText.write('Time Spent: ${_formatDuration(stat.timeSpent)}\n\n');
      }
      shareText.write('=' * 50);
      shareText.write('\n\n');
    } else {
      shareText.write('No activities completed.\n\n');
    }

    shareText.write('\nShared from Break Buddy App');

    final finalText = shareText.toString();
    final body = Uri.encodeComponent(finalText);
    final subject = Uri.encodeComponent('My Break Buddy Workout Stats');

    // Create Gmail URL - try multiple approaches
    final gmailUrl =
        'https://mail.google.com/mail/?view=cm&fs=1&su=$subject&body=$body';
    final mailtoUrl = 'mailto:?subject=$subject&body=$body';

    // Try to open Gmail web first, then fallback to mailto
    launchUrl(Uri.parse(gmailUrl), mode: LaunchMode.externalApplication)
        .catchError((_) {
      // Fallback to mailto if Gmail web doesn't work
      return launchUrl(Uri.parse(mailtoUrl));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session Statistics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Row(
                  children: [
                    PopupMenuButton(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      onSelected: (value) {
                        if (value == 'share') {
                          _shareStats(context);
                        } else if (value == 'copy') {
                          _copyStatsToClipboard(context);
                        } else if (value == 'gmail') {
                          _openGmail(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 10),
                              Text('Share Stats'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 20),
                              SizedBox(width: 10),
                              Text('Copy to Clipboard'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'gmail',
                          child: Row(
                            children: [
                              Icon(Icons.mail, size: 20),
                              SizedBox(width: 10),
                              Text('Open Gmail'),
                            ],
                          ),
                        ),
                      ],
                      tooltip: 'Share Options',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Breaks taken
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.coffee, color: Colors.blue),
              ),
              title: Text(
                'Breaks Taken',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              trailing: Text(
                breaksTaken.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            const Divider(height: 24),

            // Activity stats
            const Text(
              'Activities Completed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            if (activityStats.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No activities completed yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Container(
                constraints: BoxConstraints(
                  maxHeight: math.min(200, activityStats.length * 60.0),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activityStats.length,
                  itemBuilder: (context, index) {
                    // Sort activities by time spent in descending order
                    final sortedStats = List<ActivityStats>.from(activityStats)
                      ..sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
                    final stat = sortedStats[index];
                    final video = VideoConfig.getVideoForTask(stat.activity.id);
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: video?.thumbnailPath != null
                              ? DecorationImage(
                                  image: AssetImage(video!.thumbnailPath),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: video?.thumbnailPath == null
                            ? Icon(stat.activity.icon, color: Colors.blue)
                            : null,
                      ),
                      title: Text(stat.activity.name),
                      subtitle: stat.activity.countMatters
                          ? Text('${stat.count} times')
                          : null,
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (stat.activity.countMatters)
                            Text(
                              '${stat.count} times',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            )
                          else
                            const SizedBox(height: 0),
                          if (stat.activity.countMatters)
                            const SizedBox(height: 4),
                          Text(
                            _formatDuration(stat.timeSpent),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 24),

            // Total times
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: Colors.green),
              ),
              title: const Text('Total Activity Time'),
              trailing: Text(
                _formatDuration(totalActivityTime),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work, color: Colors.orange),
              ),
              title: const Text('Total Working Time'),
              trailing: Text(
                _formatDuration(totalWorkingTime),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
