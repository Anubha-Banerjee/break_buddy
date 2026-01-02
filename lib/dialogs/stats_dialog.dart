import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/activity_video.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

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

  void _openGmail(BuildContext context) async {
    try {
      // Build HTML email with stats and activity images
      final sortedStats = List<ActivityStats>.from(activityStats)
        ..sort((a, b) => b.timeSpent.compareTo(a.timeSpent));

      StringBuffer htmlBody = StringBuffer();
      htmlBody.write('''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
.container { background-color: white; padding: 30px; border-radius: 8px; max-width: 700px; margin: 0 auto; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
h1 { color: #0066cc; border-bottom: 3px solid #0066cc; padding-bottom: 15px; margin-top: 0; }
h2 { color: #333; margin-top: 20px; margin-bottom: 15px; font-size: 18px; }
.stat-item { margin: 15px 0; padding: 12px; background-color: #f0f7ff; border-left: 4px solid #0066cc; border-radius: 4px; }
.stat-label { font-weight: bold; color: #333; }
.stat-value { color: #0066cc; font-weight: bold; }
.activity-card { margin: 15px 0; padding: 15px; border: 1px solid #ddd; border-radius: 6px; background-color: #fafafa; }
.activity-row { display: flex; align-items: center; gap: 15px; }
.activity-thumbnail { width: 80px; height: 80px; border-radius: 6px; object-fit: cover; border: 1px solid #ddd; flex-shrink: 0; }
.activity-content { flex-grow: 1; }
.activity-name { font-weight: bold; font-size: 15px; color: #333; margin-bottom: 8px; }
.activity-detail { font-size: 13px; color: #666; margin: 4px 0; }
.footer { margin-top: 25px; padding-top: 15px; border-top: 1px solid #ddd; font-size: 12px; color: #999; text-align: center; }
.button-container { margin-top: 20px; margin-bottom: 20px; }
.button-with-help { display: flex; align-items: center; gap: 15px; }
.gmail-button { padding: 12px 24px; background-color: #ea4335; color: white; text-align: center; border-radius: 6px; text-decoration: none; font-weight: bold; display: inline-block; border: none; cursor: pointer; font-size: 14px; white-space: nowrap; }
.gmail-button:hover { background-color: #d33425; }
.help-text { margin: 0; font-size: 13px; color: #666; font-style: italic; }
</style>
</head>
<body>
<div class="container">
<h1>📊 Break Buddy - My Workout Stats</h1>

<div class="button-container">
  <div class="button-with-help">
    <a href="https://mail.google.com/mail/?view=cm&fs=1&to=" target="_blank" class="gmail-button">📧 Send via Gmail</a>
    <p class="help-text">Copy the stats below and paste them in the email body.</p>
  </div>
</div>

<div class="stat-item">
  <span class="stat-label">☕ Breaks Taken:</span>
  <span class="stat-value">$breaksTaken</span>
</div>

<div class="stat-item">
  <span class="stat-label">⏱️ Total Activity Time:</span>
  <span class="stat-value">${_formatDuration(totalActivityTime)}</span>
</div>

<div class="stat-item">
  <span class="stat-label">💼 Total Working Time:</span>
  <span class="stat-value">${_formatDuration(totalWorkingTime)}</span>
</div>
''');

      if (activityStats.isNotEmpty) {
        htmlBody.write('<h2>🏋️ Activities Completed</h2>');
        for (var stat in sortedStats) {
          final video = VideoConfig.getVideoForTask(stat.activity.id);

          htmlBody.write('''
<div class="activity-card">
  <div class="activity-row">
''');

          // Add activity thumbnail image
          if (video?.thumbnailPath != null) {
            try {
              final imageBytes = await rootBundle.load(video!.thumbnailPath);
              final base64Image = base64Encode(imageBytes.buffer.asUint8List());
              htmlBody.write(
                '<img src="data:image/jpeg;base64,$base64Image" class="activity-thumbnail" alt="${stat.activity.name}">',
              );
            } catch (e) {
              print('Error loading image: $e');
              htmlBody.write(
                '<div class="activity-thumbnail" style="background-color: #e0e0e0; display: flex; align-items: center; justify-content: center; font-size: 24px;">🏋️</div>',
              );
            }
          } else {
            htmlBody.write(
              '<div class="activity-thumbnail" style="background-color: #e0e0e0; display: flex; align-items: center; justify-content: center; font-size: 24px;">🏋️</div>',
            );
          }

          htmlBody.write('''
    <div class="activity-content">
      <div class="activity-name">${stat.activity.name}</div>
''');

          if (stat.activity.countMatters) {
            htmlBody.write(
              '<div class="activity-detail">✓ Repetitions: ${stat.count} times</div>',
            );
          }

          htmlBody.write('''
      <div class="activity-detail">⏱️ Time Spent: ${_formatDuration(stat.timeSpent)}</div>
    </div>
  </div>
</div>
''');
        }
      } else {
        htmlBody.write('<p>No activities completed.</p>');
      }

      htmlBody.write('''
<div class="footer">
<p>Generated by Break Buddy App | Stay healthy with regular breaks! 💪</p>
</div>
</div>
</body>
</html>
''');

      final htmlContent = htmlBody.toString();

      // Save HTML to temporary file and open in browser
      final tempDir = await getTemporaryDirectory();
      final htmlFile = File(
        '${tempDir.path}/break_buddy_stats_${DateTime.now().millisecondsSinceEpoch}.html',
      );
      await htmlFile.writeAsString(htmlContent);

      // Open the HTML file in the default browser
      await launchUrl(Uri.file(htmlFile.path),
          mode: LaunchMode.externalApplication);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your formatted stats are now displayed in your browser! '
              'You can copy this content and email it, or take a screenshot.',
            ),
            backgroundColor: Colors.blue[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error opening stats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to open stats. $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900,
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
                fontSize: 14,
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
                  maxHeight:
                      math.min(280, (activityStats.length / 4).ceil() * 140.0),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: activityStats.length,
                  itemBuilder: (context, index) {
                    // Sort activities by time spent in descending order
                    final sortedStats = List<ActivityStats>.from(activityStats)
                      ..sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
                    final stat = sortedStats[index];
                    final video = VideoConfig.getVideoForTask(stat.activity.id);
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              image: video?.thumbnailPath != null
                                  ? DecorationImage(
                                      image: AssetImage(video!.thumbnailPath),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: video?.thumbnailPath == null
                                ? Icon(stat.activity.icon,
                                    color: Colors.blue, size: 20)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stat.activity.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (stat.activity.countMatters)
                            Text(
                              '${stat.count}x',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (stat.timeSpent >= 60)
                            Text(
                              _formatDuration(stat.timeSpent),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
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
