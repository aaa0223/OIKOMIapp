import 'dart:math';
import '../models/task.dart';
import '../models/tgl_state.dart';

const double epsilon = 0.01;

double calculateTGL(Task task) {
  final now = DateTime.now();
  final D = task.deadline.difference(now).inMinutes / 60.0;
  final T = task.requiredHours;
  final M = task.avoidance.toDouble();

  final slack = max(D - T, epsilon);
  final tgl = (T * M) / slack;

  return tgl;
}

TGLState taskToState(Task task) => tglToState(calculateTGL(task));
