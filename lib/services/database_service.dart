import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import '../models/user_preference.dart';

class DatabaseService {
  static late Isar _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TaskSchema, UserPreferenceSchema],
      directory: dir.path,
    );
  }

  // ─── UserPreference ───────────────────────────────────────────

  static Future<UserPreference> getUserPreference() async {
    return await _isar.userPreferences.get(0) ?? UserPreference();
  }

  static Future<void> saveUserPreference(UserPreference pref) async {
    await _isar.writeTxn(() async {
      await _isar.userPreferences.put(pref);
    });
  }

  static Future<List<Task>> getAllIncompleteTasks() {
    return _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .findAll();
  }

  static Future<Task?> getTaskByUuid(String uuid) {
    return _isar.tasks.filter().idEqualTo(uuid).findFirst();
  }

  static Future<void> saveTask(Task task) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
  }

  static Future<void> markCompleted(String uuid) async {
    final task = await getTaskByUuid(uuid);
    if (task == null) return;
    task.isCompleted = true;
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
  }

  static Future<void> deleteTask(String uuid) async {
    final task = await getTaskByUuid(uuid);
    if (task == null) return;
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(task.isarId);
    });
  }

  static Stream<List<Task>> watchIncompleteTasks() {
    return _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .watch(fireImmediately: true);
  }
}
