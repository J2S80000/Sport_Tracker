import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level callback for the foreground task.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StepCounterTaskHandler());
}

class StepCounterTaskHandler extends TaskHandler {
  StreamSubscription<StepCount>? _sub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sub = Pedometer.stepCountStream.listen(_onStep, onError: (_) {});
  }

  void _onStep(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString('stepDate');

    if (storedDate != today) {
      await prefs.setString('stepDate', today);
      await prefs.setInt('stepStart', event.steps);
      await prefs.setInt('stepOffset', 0);
    }

    int start = prefs.getInt('stepStart') ?? event.steps;
    int offset = prefs.getInt('stepOffset') ?? 0;
    final storedStepsToday = prefs.getInt('stepsToday') ?? 0;

    int stepsToday;
    if (event.steps < start) {
      // Capteur réinitialisé (ex: redémarrage app) — garder le total et repartir de la nouvelle baseline
      await prefs.setInt('stepStart', event.steps);
      await prefs.setInt('stepOffset', storedStepsToday);
      stepsToday = storedStepsToday;
    } else {
      stepsToday = offset + (event.steps - start);
      if (storedDate == today && storedStepsToday > stepsToday) {
        stepsToday = storedStepsToday;
      }
    }

    await prefs.setInt('lastRawSteps', event.steps);
    await prefs.setInt('stepsToday', stepsToday);

    FlutterForegroundTask.updateService(
      notificationTitle: 'SportTracker',
      notificationText: '$stepsToday pas aujourd\'hui',
    );

    FlutterForegroundTask.sendDataToMain(stepsToday);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final stepsToday = prefs.getInt('stepsToday') ?? 0;
    FlutterForegroundTask.sendDataToMain(stepsToday);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _sub?.cancel();
  }
}

/// Initialise et demarre le service de premier plan.
class StepCounterService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'step_counter',
        channelName: 'Compteur de pas',
        channelDescription: 'Compte vos pas en arrière-plan',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> start() async {
    final notifPerm =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifPerm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      serviceId: 200,
      notificationTitle: 'SportTracker',
      notificationText: 'Comptage des pas...',
      callback: startCallback,
    );
  }
}
