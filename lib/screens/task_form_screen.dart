import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  /// null → 追加モード、非null → 編集モード
  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final TextEditingController _titleController;
  late TaskType _selectedType;
  late DateTime _deadline;
  late int _timeIndex;  // 0-based: index 0 = 15分
  late int _avoidance;  // 1〜10

  bool get _isEditing => widget.task != null;

  static const int _timeStepMinutes = 15;
  static const int _timeSteps = 96; // 15min〜24h

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _selectedType = t?.type ?? TaskType.report;
    _deadline = t?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _timeIndex = t != null
        ? ((t.requiredHours * 60) / _timeStepMinutes).round() - 1
        : 3; // デフォルト60分
    _avoidance = t?.avoidance ?? 5;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  double get _requiredHours => (_timeIndex + 1) * _timeStepMinutes / 60.0;

  String _formatTime(int index) {
    final minutes = (index + 1) * _timeStepMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m分';
    if (m == 0) return '$h時間';
    return '$h時間$m分';
  }

  Future<void> _pickDeadline() async {
    DateTime picked = _deadline;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                child: const Text('完了'),
                onPressed: () {
                  setState(() => _deadline = picked);
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _deadline,
                minimumDate: DateTime.now(),
                use24hFormat: true,
                onDateTimeChanged: (dt) => picked = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('課題名を入力してください')),
      );
      return;
    }

    final task = widget.task ?? Task();
    task
      ..id = widget.task?.id ?? const Uuid().v4()
      ..title = title
      ..deadline = _deadline
      ..requiredHours = _requiredHours
      ..type = _selectedType
      ..avoidance = _avoidance
      ..isCompleted = widget.task?.isCompleted ?? false
      ..createdAt = widget.task?.createdAt ?? DateTime.now();

    await DatabaseService.saveTask(task);
    await NotificationService.scheduleNotificationsForTask(task);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final deadlineText =
        '${_deadline.year}/${_deadline.month.toString().padLeft(2, '0')}/${_deadline.day.toString().padLeft(2, '0')} '
        '${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル', style: TextStyle(color: Colors.blue)),
        ),
        leadingWidth: 100,
        title: Text(
          _isEditing ? '課題を編集' : '課題を追加',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Card(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '例：統計学レポート、英語小テスト',
                    border: InputBorder.none,
                    labelText: '課題名',
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: 12),

              _SectionLabel('課題タイプ'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: TaskType.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _SectionLabel('締切'),
              const SizedBox(height: 6),
              _Card(
                child: InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(deadlineText, style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _SectionLabel('所要時間 / やりたくなさ'),
              const SizedBox(height: 6),
              _Card(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_timeIndex),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('所要時間', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          _DrumDial(
                            itemCount: _timeSteps,
                            selectedIndex: _timeIndex,
                            labelBuilder: _formatTime,
                            onChanged: (i) => setState(() => _timeIndex = i),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 160, color: Colors.grey.shade200),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_avoidance',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('やりたくなさ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          _DrumDial(
                            itemCount: 10,
                            selectedIndex: _avoidance - 1,
                            labelBuilder: (i) => '${i + 1}',
                            onChanged: (i) => setState(() => _avoidance = i + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  child: Text(_isEditing ? '保存する' : '追加する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: child,
      );
}

class _DrumDial extends StatefulWidget {
  const _DrumDial({
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  State<_DrumDial> createState() => _DrumDialState();
}

class _DrumDialState extends State<_DrumDial> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(_DrumDial old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex &&
        _controller.selectedItem != widget.selectedIndex) {
      _controller.jumpToItem(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 36,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: widget.onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.itemCount,
          builder: (context, index) {
            final selected = index == widget.selectedIndex;
            return Center(
              child: Text(
                widget.labelBuilder(index),
                style: TextStyle(
                  fontSize: selected ? 18 : 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.black : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
