import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/task_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await DatabaseService.init();
  await NotificationService.init();
  await NotificationService.requestPermission();
  await _onAppLaunch();

  runApp(const TGLApp());
}

Future<void> _onAppLaunch() async {
  final tasks = await DatabaseService.getAllIncompleteTasks();
  for (final task in tasks) {
    await NotificationService.scheduleNotificationsForTask(task);
  }
}

class TGLApp extends StatelessWidget {
  const TGLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '課題',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: '.SF Pro Text',
      ),
      home: const TaskListScreen(),
    );
  }
}
