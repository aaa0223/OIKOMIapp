import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/tgl_state.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/tgl_calculator.dart';
import 'task_form_screen.dart';
import 'settings_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        title: const Text('課題', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskFormScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: DatabaseService.watchIncompleteTasks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          tasks.sort((a, b) => calculateTGL(b).compareTo(calculateTGL(a)));

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                '課題なし。平和。',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
          );
        },
      ),
    );
  }
}

// ─── Task Card ────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  const _TaskCard({required this.task});
  final Task task;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  double _dragOffset = 0;
  bool _revealed = false;
  static const double _revealWidth = 210.0; // 3ボタン × 70px

  void _closeMenu() => setState(() {
        _dragOffset = 0;
        _revealed = false;
      });

  Future<void> _complete() async {
    try {
      await DatabaseService.markCompleted(widget.task.id);
      await NotificationService.cancelNotificationsForTask(widget.task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完了処理に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    try {
      await NotificationService.cancelNotificationsForTask(widget.task.id);
      await DatabaseService.deleteTask(widget.task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  void _edit(BuildContext context) {
    _closeMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: widget.task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final tgl = calculateTGL(task);
    final state = tglToState(tgl);
    final isHighAlert = state == TGLState.noEscape || state == TGLState.war;

    final deadlineText =
        '${task.deadline.month}/${task.deadline.day} '
        '${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 背景アクションボタン
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionButton(
                    label: '編集',
                    color: Colors.blue,
                    onTap: () => _edit(context),
                  ),
                  _ActionButton(
                    label: '完了',
                    color: Colors.green,
                    onTap: _complete,
                  ),
                  _ActionButton(
                    label: '削除',
                    color: Colors.red,
                    onTap: _delete,
                  ),
                ],
              ),
            ),
            // カード本体
            GestureDetector(
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _dragOffset = (_dragOffset + d.delta.dx).clamp(-_revealWidth, 0.0);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  if (_dragOffset < -_revealWidth / 2) {
                    _dragOffset = -_revealWidth;
                    _revealed = true;
                  } else {
                    _dragOffset = 0;
                    _revealed = false;
                  }
                });
              },
              onTap: () {
                if (_revealed) _closeMenu();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                decoration: BoxDecoration(
                  color: isHighAlert ? const Color(0xFFFFF0F0) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isHighAlert
                      ? Border.all(color: Colors.red.shade200, width: 1.5)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${task.type.label}　M=${task.avoidance}　${_formatHours(task.requiredHours)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatePill(state: state),
                        const SizedBox(height: 6),
                        Text(
                          deadlineText,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '$m分';
    if (m == 0) return '$h時間';
    return '$h時間$m分';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── State Pill ───────────────────────────────────────────────

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});
  final TGLState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor(),
        ),
      ),
    );
  }

  Color _bgColor() {
    switch (state) {
      case TGLState.peaceful: return const Color(0xFFD4EDDA);
      case TGLState.someday:  return const Color(0xFFFFF3CD);
      case TGLState.reality:  return const Color(0xFFFFE0B2);
      case TGLState.noEscape: return const Color(0xFFFFCDD2);
      case TGLState.war:      return const Color(0xFFB71C1C);
    }
  }

  Color _textColor() {
    switch (state) {
      case TGLState.peaceful: return const Color(0xFF155724);
      case TGLState.someday:  return const Color(0xFF856404);
      case TGLState.reality:  return const Color(0xFFE65100);
      case TGLState.noEscape: return const Color(0xFFC62828);
      case TGLState.war:      return Colors.white;
    }
  }
}
