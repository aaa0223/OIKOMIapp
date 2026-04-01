import 'package:isar/isar.dart';

part 'task.g.dart';

enum TaskType {
  miniReport,
  report,
  quizStudy,
  presentation,
  finalExam,
}

extension TaskTypeLabel on TaskType {
  String get label {
    switch (this) {
      case TaskType.miniReport:   return 'ミニレポート';
      case TaskType.report:       return 'レポート';
      case TaskType.quizStudy:    return '小テスト勉強';
      case TaskType.presentation: return '発表準備';
      case TaskType.finalExam:    return '期末テスト';
    }
  }
}

@collection
class Task {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // UUID

  late String title;
  late DateTime deadline;
  late double requiredHours;

  @Enumerated(EnumType.name)
  late TaskType type;

  late int avoidance;
  late bool isCompleted;
  late DateTime createdAt;
}
