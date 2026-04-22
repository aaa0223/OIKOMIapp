import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/adaptive/adaptive_app_bar.dart';
import '../widgets/adaptive/adaptive_button.dart';

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
    _deadline = t?.deadline ?? DateTime.now();
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
    final l = AppLocalizations.of(context)!;
    final minutes = (index + 1) * _timeStepMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l.timeUnitMinutes(m);
    if (m == 0) return l.timeUnitHours(h);
    return l.timeUnitHoursMinutes(h, m);
  }

  Future<void> _pickDeadline() async {
    final l = AppLocalizations.of(context)!;
    // minimumDate と initialDateTime のミリ秒差によるアサーション違反を防ぐため
    // minimumDate を1分前に設定し、初期値は現在時刻以降にクランプする
    final minDate = DateTime.now().subtract(const Duration(minutes: 1));
    final initial = _deadline.isBefore(minDate) ? minDate : _deadline;
    DateTime picked = initial;
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
                child: Text(l.doneButton),
                onPressed: () {
                  setState(() => _deadline = picked);
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: initial,
                minimumDate: minDate,
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
    final l = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.taskNameRequired)),
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
    final l = AppLocalizations.of(context)!;
    final deadlineText =
        '${_deadline.year}/${_deadline.month.toString().padLeft(2, '0')}/${_deadline.day.toString().padLeft(2, '0')} '
        '${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: adaptiveAppBar(
        title: _isEditing ? l.editTaskTitle : l.addTaskTitle,
        leading: adaptiveTextButton(
          text: l.cancelButton,
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
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
                  decoration: InputDecoration(
                    hintText: l.taskNamePlaceholder,
                    border: InputBorder.none,
                    labelText: l.taskNameLabel,
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: 12),

              _SectionLabel(l.taskTypeLabel),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: TaskType.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type.label(context)),
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

              _SectionLabel(l.deadlineLabel),
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

              _SectionLabel(l.timeAndAvoidanceLabel),
              const SizedBox(height: 6),
              _Card(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l.requiredTimeLabel,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          _DrumDial(
                            itemCount: _timeSteps,
                            selectedIndex: _timeIndex,
                            labelBuilder: _formatTime,
                            onChanged: (i) => setState(() => _timeIndex = i),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 170, color: Colors.grey.shade200),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l.avoidanceLevelLabel,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          _DrumDial(
                            itemCount: 10,
                            selectedIndex: _avoidance - 1,
                            labelBuilder: (i) => '${i + 1}',
                            sublabelBuilder: (i) => _avoidanceLabel(context, i + 1),
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
                  child: Text(_isEditing ? l.saveTaskButton : l.addTaskButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _avoidanceLabel(BuildContext context, int level) {
  final l = AppLocalizations.of(context)!;
  switch (level) {
    case 1:  return l.avoidance1;
    case 2:  return l.avoidance2;
    case 3:  return l.avoidance3;
    case 4:  return l.avoidance4;
    case 5:  return l.avoidance5;
    case 6:  return l.avoidance6;
    case 7:  return l.avoidance7;
    case 8:  return l.avoidance8;
    case 9:  return l.avoidance9;
    case 10: return l.avoidance10;
    default: return '';
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
    this.sublabelBuilder,
  });

  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelBuilder;
  final String? Function(int index)? sublabelBuilder;
  final ValueChanged<int> onChanged;

  @override
  State<_DrumDial> createState() => _DrumDialState();
}

class _DrumDialState extends State<_DrumDial> {
  late FixedExtentScrollController _controller;

  static const double _height = 150;
  static const double _itemExtent = 38;
  static const double _fadeSize = 45;

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

  TextStyle _textStyle(int index) {
    final diff = (index - widget.selectedIndex).abs();
    if (diff == 0) {
      return const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      );
    } else if (diff == 1) {
      return TextStyle(fontSize: 16, color: Colors.grey.shade500);
    } else {
      return TextStyle(fontSize: 15, color: Colors.grey.shade400);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          // フェードアウト付きドラム
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, _fadeSize / _height, 1.0 - _fadeSize / _height, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: _height,
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: _itemExtent,
                perspective: 0.003,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  widget.onChanged(i);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.itemCount,
                  builder: (context, index) {
                    final sublabel = widget.sublabelBuilder?.call(index);
                    return Center(
                      child: sublabel != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.labelBuilder(index), style: _textStyle(index)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    sublabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: index == widget.selectedIndex
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(widget.labelBuilder(index), style: _textStyle(index)),
                    );
                  },
                ),
              ),
            ),
          ),
          // 中央選択行ハイライト帯
          Positioned(
            top: (_height - _itemExtent) / 2,
            left: 4,
            right: 4,
            child: IgnorePointer(
              child: Container(
                height: _itemExtent,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
