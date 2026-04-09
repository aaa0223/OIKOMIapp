import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/task_list_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await DatabaseService.init();
  await NotificationService.init();
  await NotificationService.requestPermission();
  await _onAppLaunch();

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(TGLApp(showOnboarding: !onboardingCompleted));
}

Future<void> _onAppLaunch() async {
  final tasks = await DatabaseService.getAllIncompleteTasks();
  for (final task in tasks) {
    await NotificationService.scheduleNotificationsForTask(task);
  }
}

class TGLApp extends StatelessWidget {
  const TGLApp({super.key, required this.showOnboarding});
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OIKOMI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: '.SF Pro Text',
      ),
      home: showOnboarding ? const OnboardingScreen() : const TaskListScreen(),
    );
  }
}
