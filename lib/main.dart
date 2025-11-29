import 'package:flutter/material.dart';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'dialogs/exercise_reminder_dialog.dart';
import 'dialogs/stats_dialog.dart';
import 'models/activity_video.dart';
import 'models/activity.dart';
import 'models/activity_sequence.dart';
import 'services/activity_sequence_service.dart';
import 'data/activities.dart';
import 'services/video_server.dart';
import 'dart:io'; // For Directory
import 'package:path/path.dart' as p; // For p.join
import 'dart:math' as math;

// Global video server instance
final videoServer = VideoServer();

Future<void> main() async {
  // Ensure that Flutter's binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit
  MediaKit.ensureInitialized();

  // Start video server
  try {
    // Get the current working directory (usually the project root when running from IDE)
    String projectRoot = Directory.current.path;

    String assetsPath;
    if (Platform.isWindows) {
      // Or more generally, for release builds
      // Get the directory of the executable
      String exePath = Platform.resolvedExecutable;
      String exeDir = p.dirname(exePath);

      // Construct the path to where Flutter bundles assets in a release build
      // Your video_config.json and video files are expected to be inside
      // 'data\flutter_assets\assets\' if your original structure was 'project_root/assets/'
      // and your VideoServer is set up to serve from a base path given to it.
      //
      // If your VideoServer expects to be given the '.../Release/data/flutter_assets'
      // and then it looks for 'assets/videos' within that, then:
      // assetsPath = p.join(exeDir, 'data', 'flutter_assets');
      //
      // If your VideoServer expects to be given the direct path to '.../Release/data/flutter_assets/assets'
      // (meaning your video_config.json might list paths like 'videos/your_video.mp4')
      // then:
      assetsPath = p.join(exeDir, 'data', 'flutter_assets', 'assets');

      // It's crucial to understand what base path your VideoServer is designed to work with
      // and what the paths in your video_config.json mean relative to that base path.

      print("Release mode: Serving assets from: $assetsPath");
    } else {
      // Debug mode or other platforms - assuming 'assets' is relative to project root
      if (Platform.isAndroid) {
        // For Android debug mode, use the assets directory
        assetsPath = 'assets';
      } else {
        // For other platforms in debug mode
        assetsPath = 'assets';
      }
      print("Debug mode: Serving assets from: $assetsPath");
    }

    print('Attempting to serve assets from: $assetsPath'); // For debugging
    await videoServer.start(assetsPath);

    //await videoServer.start('D:\\AndroidProjects\\break_buddy\\assets');
  } catch (e) {
    print('Failed to start video server: $e');
  }

  // Initialize video configuration
  try {
    await VideoConfig.initialize(videoServer);
  } catch (e) {
    print('Failed to initialize video config: $e');
  }

  // Initialize window manager only on desktop platforms
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();

    // Set window to use larger default size for better visibility
    WindowOptions windowOptions = WindowOptions(
      size: Size(900, 1100),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setMinimumSize(const Size(600, 800));
      await windowManager.setMinimizable(true);
    });
  }

  runApp(ExerciseReminderApp());
}

class ExerciseReminderApp extends StatefulWidget {
  const ExerciseReminderApp({super.key});

  @override
  State<ExerciseReminderApp> createState() => _ExerciseReminderAppState();
}

class _ExerciseReminderAppState extends State<ExerciseReminderApp> {
  @override
  void dispose() {
    // Stop the video server when the app is closed
    videoServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Break Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Realistic Hourglass Painter with Enhanced Animation
class RealisticHourglassPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final double animationTime;

  RealisticHourglassPainter({
    required this.progress,
    required this.isActive,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;

    // Glass frame paint with gradient effect
    final Paint glassPaint = Paint()
      ..color = Colors.brown[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Glass inner surface
    final Paint glassInnerPaint = Paint()
      ..color = Colors.grey[100]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Enhanced sand colors with gradients
    final Paint topSandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.amber[300]!,
          Colors.amber[600]!,
          Colors.orange[700]!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height * 0.4));

    final Paint bottomSandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.orange[600]!,
          Colors.orange[800]!,
          Colors.brown[600]!,
        ],
      ).createShader(Rect.fromLTWH(0, height * 0.6, width, height * 0.4));

    // Create hourglass frame path
    Path frameTopPath = _createHourglassTop(width, height, centerX, centerY);
    Path frameBottomPath =
        _createHourglassBottom(width, height, centerX, centerY);

    // Draw glass background
    canvas.drawPath(frameTopPath, glassInnerPaint);
    canvas.drawPath(frameBottomPath, glassInnerPaint);

    // Draw sand in bottom chamber (elapsed time)
    if (isActive && progress > 0) {
      _drawBottomSand(
          canvas, width, height, centerX, centerY, progress, bottomSandPaint);
    }

    // Draw sand in top chamber (remaining time)
    if (isActive && progress < 1) {
      _drawTopSand(
          canvas, width, height, centerX, centerY, progress, topSandPaint);
    }

    // Draw animated falling sand particles
    if (isActive && progress > 0 && progress < 1) {
      _drawFallingSand(canvas, width, height, centerX, centerY, animationTime);
    }

    // Draw hourglass frame
    canvas.drawPath(frameTopPath, glassPaint);
    canvas.drawPath(frameBottomPath, glassPaint);

    // Draw wooden frame details
    _drawWoodenFrame(canvas, width, height, centerX);

    // Add glass reflection effect
    _drawGlassReflection(canvas, width, height, centerX, centerY);
  }

  Path _createHourglassTop(
      double width, double height, double centerX, double centerY) {
    Path path = Path();
    double topWidth = width * 0.35;
    double neckWidth = width * 0.08;

    path.moveTo(centerX - topWidth, height * 0.15);
    path.lineTo(centerX + topWidth, height * 0.15);
    path.lineTo(centerX + topWidth, height * 0.42);
    path.quadraticBezierTo(centerX + topWidth * 0.7, height * 0.47,
        centerX + neckWidth, centerY - 2);
    path.lineTo(centerX - neckWidth, centerY - 2);
    path.quadraticBezierTo(centerX - topWidth * 0.7, height * 0.47,
        centerX - topWidth, height * 0.42);
    path.close();

    return path;
  }

  Path _createHourglassBottom(
      double width, double height, double centerX, double centerY) {
    Path path = Path();
    double bottomWidth = width * 0.35;
    double neckWidth = width * 0.08;

    path.moveTo(centerX - bottomWidth, height * 0.85);
    path.lineTo(centerX + bottomWidth, height * 0.85);
    path.lineTo(centerX + bottomWidth, height * 0.58);
    path.quadraticBezierTo(centerX + bottomWidth * 0.7, height * 0.53,
        centerX + neckWidth, centerY + 2);
    path.lineTo(centerX - neckWidth, centerY + 2);
    path.quadraticBezierTo(centerX - bottomWidth * 0.7, height * 0.53,
        centerX - bottomWidth, height * 0.58);
    path.close();

    return path;
  }

  void _drawBottomSand(Canvas canvas, double width, double height,
      double centerX, double centerY, double progress, Paint paint) {
    double maxSandHeight = height * 0.27;
    double currentSandHeight = maxSandHeight * progress;
    double sandTop = height * 0.85 - currentSandHeight;

    // Create realistic sand mound shape
    Path sandPath = Path();
    double bottomWidth = width * 0.35;
    double sandWidth =
        bottomWidth * (0.3 + 0.7 * progress); // Sand spreads as it accumulates

    // Create curved sand surface
    sandPath.moveTo(centerX - bottomWidth, height * 0.85);
    sandPath.lineTo(centerX + bottomWidth, height * 0.85);

    if (progress < 0.7) {
      // Cone shape when sand is building up
      sandPath.lineTo(
          centerX + sandWidth * 0.8, sandTop + currentSandHeight * 0.3);
      sandPath.quadraticBezierTo(centerX, sandTop, centerX - sandWidth * 0.8,
          sandTop + currentSandHeight * 0.3);
    } else {
      // Flatter surface when chamber is filling
      sandPath.lineTo(centerX + sandWidth, sandTop + currentSandHeight * 0.1);
      sandPath.quadraticBezierTo(centerX, sandTop - currentSandHeight * 0.05,
          centerX - sandWidth, sandTop + currentSandHeight * 0.1);
    }

    sandPath.close();
    canvas.drawPath(sandPath, paint);

    // Add sand texture with small particles
    _drawSandTexture(
        canvas, centerX, sandTop, sandWidth, currentSandHeight, false);
  }

  void _drawTopSand(Canvas canvas, double width, double height, double centerX,
      double centerY, double progress, Paint paint) {
    double remainingProgress = 1 - progress;
    double maxSandHeight = height * 0.27;
    double currentSandHeight = maxSandHeight * remainingProgress;

    Path sandPath = Path();
    double topWidth = width * 0.35;

    // Top sand chamber
    sandPath.moveTo(centerX - topWidth, height * 0.15);
    sandPath.lineTo(centerX + topWidth, height * 0.15);
    sandPath.lineTo(centerX + topWidth, height * 0.15 + currentSandHeight);

    // Create funnel effect near the neck
    if (remainingProgress > 0.3) {
      sandPath.lineTo(centerX + topWidth * remainingProgress,
          height * 0.15 + currentSandHeight);
      sandPath.quadraticBezierTo(
          centerX,
          height * 0.15 + currentSandHeight + height * 0.05,
          centerX - topWidth * remainingProgress,
          height * 0.15 + currentSandHeight);
    } else {
      // Funnel shape when sand is low
      double funnelWidth = width * 0.25 * remainingProgress;
      sandPath.lineTo(centerX + funnelWidth, centerY - height * 0.08);
      sandPath.lineTo(centerX - funnelWidth, centerY - height * 0.08);
    }

    sandPath.lineTo(centerX - topWidth, height * 0.15 + currentSandHeight);
    sandPath.close();

    canvas.drawPath(sandPath, paint);

    // Add sand texture
    _drawSandTexture(
        canvas, centerX, height * 0.15, topWidth * 2, currentSandHeight, true);
  }

  void _drawFallingSand(Canvas canvas, double width, double height,
      double centerX, double centerY, double time) {
    Paint sandParticlePaint = Paint()
      ..color = Colors.amber[400]!
      ..style = PaintingStyle.fill;

    // Create multiple sand streams with varying speeds
    for (int i = 0; i < 8; i++) {
      double streamOffset = (i - 4) * 0.8;
      double particleSpeed = 30 + (i % 3) * 10; // Varying speeds
      double streamY = (time * particleSpeed) % (height * 0.3);

      // Draw sand particle
      canvas.drawCircle(
        Offset(centerX + streamOffset, centerY - height * 0.15 + streamY),
        1.0 + (i % 2) * 0.5, // Varying sizes
        sandParticlePaint,
      );
    }

    // Main sand stream
    Paint streamPaint = Paint()
      ..color = Colors.amber[300]!.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    double streamWidth = 2.5;
    Path streamPath = Path();
    streamPath.moveTo(centerX - streamWidth, centerY - height * 0.08);
    streamPath.lineTo(centerX + streamWidth, centerY - height * 0.08);
    streamPath.lineTo(centerX + streamWidth * 0.7, centerY + height * 0.08);
    streamPath.lineTo(centerX - streamWidth * 0.7, centerY + height * 0.08);
    streamPath.close();

    canvas.drawPath(streamPath, streamPaint);
  }

  void _drawSandTexture(Canvas canvas, double centerX, double top, double width,
      double height, bool isTop) {
    Paint texturePaint = Paint()
      ..color = isTop
          ? Colors.orange[800]!.withOpacity(0.3)
          : Colors.brown[700]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Add small sand grain details
    for (int i = 0; i < (width * height / 50).round(); i++) {
      double x = centerX -
          width +
          (width * 2 * (i * 0.618034) % 1); // Golden ratio distribution
      double y = top + (height * (i * 0.7548776) % 1);

      if (x > centerX - width && x < centerX + width) {
        canvas.drawCircle(Offset(x, y), 0.5, texturePaint);
      }
    }
  }

  void _drawWoodenFrame(
      Canvas canvas, double width, double height, double centerX) {
    Paint woodPaint = Paint()
      ..color = Colors.brown[600]!
      ..style = PaintingStyle.fill;

    // Top frame
    Rect topFrame = Rect.fromLTWH(
        centerX - width * 0.4, height * 0.1, width * 0.8, height * 0.08);
    canvas.drawRRect(
        RRect.fromRectAndRadius(topFrame, Radius.circular(4)), woodPaint);

    // Bottom frame
    Rect bottomFrame = Rect.fromLTWH(
        centerX - width * 0.4, height * 0.82, width * 0.8, height * 0.08);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bottomFrame, Radius.circular(4)), woodPaint);

    // Side supports
    Rect leftSupport = Rect.fromLTWH(
        centerX - width * 0.42, height * 0.15, width * 0.04, height * 0.7);
    Rect rightSupport = Rect.fromLTWH(
        centerX + width * 0.38, height * 0.15, width * 0.04, height * 0.7);

    canvas.drawRRect(
        RRect.fromRectAndRadius(leftSupport, Radius.circular(2)), woodPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rightSupport, Radius.circular(2)), woodPaint);
  }

  void _drawGlassReflection(Canvas canvas, double width, double height,
      double centerX, double centerY) {
    Paint reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Top chamber reflection
    Path topReflection = Path();
    topReflection.moveTo(centerX - width * 0.3, height * 0.2);
    topReflection.lineTo(centerX - width * 0.15, height * 0.2);
    topReflection.lineTo(centerX - width * 0.2, height * 0.35);
    topReflection.close();

    canvas.drawPath(topReflection, reflectionPaint);

    // Bottom chamber reflection
    Path bottomReflection = Path();
    bottomReflection.moveTo(centerX - width * 0.3, height * 0.65);
    bottomReflection.lineTo(centerX - width * 0.15, height * 0.65);
    bottomReflection.lineTo(centerX - width * 0.2, height * 0.8);
    bottomReflection.close();

    canvas.drawPath(bottomReflection, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  int _secondsRemaining = 1800; // Default 30 minutes = 1800 seconds
  int _selectedInterval = 1800; // Default interval in seconds
  bool _isTimerActive = false;
  bool _isReminderShowing = false;
  int _totalWorkingTime =
      0; // Track working time since last break (resets on completion)
  int _sessionWorkingTime =
      0; // Track cumulative working time for the entire session (for stats)
  int _breaksTaken = 0;
  List<ActivityStats> _activityStats = [];
  int _totalActivityTime = 0;
  final ActivitySequenceService _sequenceService = ActivitySequenceService();
  List<Activity> _savedSequences = [];

  // Timer interval options (in seconds)
  final Map<String, int> _timerOptions = {
    '30 minutes': 1800,
    '45 minutes': 2700,
    '60 minutes': 3600,
  };

  @override
  void initState() {
    super.initState();
    _resetSessionStats();
    _loadSavedSequences();
  }

  Future<void> _loadSavedSequences() async {
    final sequences = await _sequenceService.loadSequences();
    setState(() {
      // First remove any existing sequences from predefined activities
      predefinedActivities
          .removeWhere((activity) => activity.id.startsWith('seq_'));

      // Convert sequences to activities that can be shown in the grid
      _savedSequences = sequences.map((seq) {
        // Get the first activity's icon and thumbnail from the sequence
        final firstActivityIcon = seq.activities.isNotEmpty
            ? seq.activities.first.icon
            : Icons.playlist_play;
        final firstActivityThumbnail = seq.activities.isNotEmpty
            ? seq.activities.first.thumbnailPath
            : null;
        return Activity(
          id: 'seq_${seq.id}',
          name: seq.name,
          icon: firstActivityIcon,
          thumbnailPath: firstActivityThumbnail,
          count: 0,
        );
      }).toList();

      // Add saved sequences to predefined activities
      predefinedActivities.addAll(_savedSequences);
    });
  }

  void _resetSessionStats() {
    setState(() {
      _breaksTaken = 0;
      _activityStats = [];
      _totalActivityTime = 0;
      _totalWorkingTime = 0;
      _sessionWorkingTime = 0; // Also reset cumulative session time
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _isTimerActive = true;
      _secondsRemaining = _selectedInterval; // Use selected interval
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          // Increment both working time counters
          _totalWorkingTime++;
          _sessionWorkingTime++;
        } else {
          _showExerciseReminder();
          _secondsRemaining = _selectedInterval; // Reset to selected interval
        }
      });
    });
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
      _secondsRemaining = _selectedInterval; // Reset to selected interval
      _resetSessionStats(); // Reset all session stats when stopping timer
    });
  }

  void _showExerciseReminder() async {
    if (_isReminderShowing) return;

    setState(() {
      _isReminderShowing = true;
      _breaksTaken++;
    });

    // Only handle window focus on desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (!await windowManager.isFocused()) {
        await windowManager.focus();
      }
      await windowManager.setAlwaysOnTop(true);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        void handleDismiss(List<Activity> completedActivities) {
          Navigator.of(context).pop();
          if (!Platform.isAndroid && !Platform.isIOS) {
            windowManager.setAlwaysOnTop(false);
          }
          setState(() {
            _isReminderShowing = false;

            print('\n[DEBUG] Exercise Dialog Dismiss:');
            print('Activities completed:');
            for (var activity in completedActivities) {
              print('${activity.name}: count=${activity.count}');
            }

            // Update activity stats
            if (completedActivities.isNotEmpty) {
              print('Updating activity stats...');
              _updateActivityStats(completedActivities);
            } else {
              print('No activities to update stats with');
            }

            _secondsRemaining = _selectedInterval;
            // Don't reset total working time here - it should accumulate across activities
          });
        }

        return ExerciseReminderDialog(
          selectedInterval: _selectedInterval,
          totalWorkingTime: _totalWorkingTime,
          onDismiss: (completedActivities) {
            handleDismiss(completedActivities);
            // Reset working time display for next cycle when break is completed
            setState(() {
              _totalWorkingTime = 0;
            });
          },
          sequenceService: _sequenceService,
          onSnooze1: () {
            handleDismiss([]);
            setState(() {
              _secondsRemaining = 60;
              // Don't reset _totalWorkingTime for snooze - it continues counting
            });
          },
          onSnooze5: () {
            handleDismiss([]);
            setState(() {
              _secondsRemaining = 300;
              // Don't reset _totalWorkingTime for snooze - it continues counting
            });
          },
          onSnooze10: () {
            handleDismiss([]);
            setState(() {
              _secondsRemaining = 600;
              // Don't reset _totalWorkingTime for snooze - it continues counting
            });
          },
          onSnooze15: () {
            handleDismiss([]);
            setState(() {
              _secondsRemaining = 900;
              // Don't reset _totalWorkingTime for snooze - it continues counting
            });
          },
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _updateActivityStats(List<Activity> completedActivities) {
    print('\n[DEBUG] Updating Activity Stats:');
    print('Current stats before update:');
    if (_activityStats.isEmpty) {
      print('No existing stats');
    } else {
      for (var stat in _activityStats) {
        print(
            '${stat.activity.name}: count=${stat.count}, time=${stat.timeSpent}s');
      }
    }

    // Completed activities now contain the actual number of completed repetitions

    print('\nProcessing completed activities:');
    for (var activity in completedActivities) {
      print('\nProcessing activity: ${activity.name}');
      print('Current count: ${activity.count}');

      // Find if we already have stats for this activity
      int index = _activityStats
          .indexWhere((stats) => stats.activity.id == activity.id);

      if (index >= 0) {
        // Update existing stats
        int oldCount = _activityStats[index].count;
        int newCount = oldCount + activity.count;
        // Use tracked time if available, otherwise calculate from video duration
        int timeSpent = activity.timeSpent ??
            ((VideoConfig.getVideoForTask(activity.id)?.duration ?? 0) *
                activity.count);

        print('Updating existing stats:');
        print('- Old count: $oldCount');
        print('- Adding count: ${activity.count}');
        print('- New count: $newCount');
        print(
            '- Adding time: ${timeSpent}s (tracked: ${activity.timeSpent}, from config: ${(VideoConfig.getVideoForTask(activity.id)?.duration ?? 0) * activity.count})');

        _activityStats[index] = ActivityStats(
          activity: activity,
          count: newCount,
          timeSpent: _activityStats[index].timeSpent + timeSpent,
        );
      } else {
        // Add new stats
        // Use tracked time if available, otherwise calculate from video duration
        int timeSpent = activity.timeSpent ??
            ((VideoConfig.getVideoForTask(activity.id)?.duration ?? 0) *
                activity.count);
        print('Adding new activity stats:');
        print('- Initial count: ${activity.count}');
        print(
            '- Initial time: ${timeSpent}s (tracked: ${activity.timeSpent}, from config: ${(VideoConfig.getVideoForTask(activity.id)?.duration ?? 0) * activity.count})');

        _activityStats.add(ActivityStats(
          activity: activity,
          count: activity.count,
          timeSpent: timeSpent,
        ));
      }
    }

    // Update total activity time
    _totalActivityTime =
        _activityStats.fold<int>(0, (sum, stats) => sum + stats.timeSpent);

    print('\nFinal stats after update:');
    if (_activityStats.isEmpty) {
      print('No stats recorded');
    } else {
      for (var stat in _activityStats) {
        print(
            '${stat.activity.name}: count=${stat.count}, time=${stat.timeSpent}s');
      }
    }
    print('Total activity time: ${_totalActivityTime}s');
  }

  void _showStats() {
    print('\n[DEBUG] Showing Stats Dialog:');
    print('Breaks taken: $_breaksTaken');
    print('Total activity time: ${_totalActivityTime}s');
    print('Session working time: ${_sessionWorkingTime}s');
    print('Activity stats:');
    if (_activityStats.isEmpty) {
      print('No activities recorded');
    } else {
      for (var stat in _activityStats) {
        print(
            '${stat.activity.name}: count=${stat.count}, time=${stat.timeSpent}s');
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatsDialog(
        breaksTaken: _breaksTaken,
        activityStats: _activityStats,
        totalActivityTime: _totalActivityTime,
        totalWorkingTime: _sessionWorkingTime, // Use session time for stats
      ),
    );
  }

  Future<bool?> _showQuitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Quit Break Buddy?'),
        content: const Text('Are you sure you want to quit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _showStats();
            },
            child: const Text('Show Stats'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show quit confirmation dialog
        return await _showQuitConfirmation(context) ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Break Buddy - Break Reminder'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Quit',
              onPressed: () async {
                final shouldQuit = await _showQuitConfirmation(context);
                if (shouldQuit == true) {
                  exit(0);
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[50]!, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.desktop_windows,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Break Buddy',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Stay healthy with regular breaks!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Timer Interval:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 15),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _timerOptions.entries.map((entry) {
                                bool isSelected =
                                    _selectedInterval == entry.value;
                                return Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: _isTimerActive
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedInterval = entry.value;
                                                _secondsRemaining = entry.value;
                                              });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? Colors.blue[600]
                                            : Colors.grey[300],
                                        foregroundColor: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isTimerActive
                              ? 'Next reminder in:'
                              : 'Timer not active',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated Hourglass
                                  SizedBox(
                                    width: 100,
                                    height: 120,
                                    child: CustomPaint(
                                      painter: RealisticHourglassPainter(
                                        progress: _isTimerActive
                                            ? 1 -
                                                (_secondsRemaining /
                                                    _selectedInterval)
                                            : 0,
                                        isActive: _isTimerActive,
                                        animationTime: _isTimerActive
                                            ? DateTime.now()
                                                    .millisecondsSinceEpoch /
                                                1000
                                            : 0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 30),
                                  // Timer Display
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isTimerActive
                                            ? _formatTime(_secondsRemaining)
                                            : '--:--',
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[600],
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        _isTimerActive
                                            ? '${((1 - (_secondsRemaining / _selectedInterval)) * 100).toInt()}% complete'
                                            : 'Ready to start',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        if (_isTimerActive)
                          LinearProgressIndicator(
                            value: 1 - (_secondsRemaining / _selectedInterval),
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isTimerActive ? null : startTimer,
                        icon: Icon(Icons.play_arrow),
                        label: Text('Start Timer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isTimerActive ? stopTimer : null,
                        icon: Icon(Icons.stop),
                        label: Text('Stop Timer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isTimerActive ? _showExerciseReminder : null,
                          icon: Icon(Icons.preview),
                          label: Text('Take a break now!'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isTimerActive ? Colors.orange : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            textStyle: TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: _isTimerActive ? _showStats : null,
                          icon: Icon(Icons.bar_chart),
                          label: Text('Show Stats'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isTimerActive ? Colors.purple : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            textStyle: TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Keep this app running in the background.\nEvery ${(_selectedInterval / 60).toInt()} minutes, you\'ll get a reminder to take an exercise break!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
