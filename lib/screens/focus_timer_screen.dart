import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/services.dart';

class FocusTimerScreen extends StatefulWidget {
  final Task? task;
  const FocusTimerScreen({super.key, this.task});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with WidgetsBindingObserver {
  static const List<int> _presets = [25, 45, 60];
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  DateTime? _targetEndTime;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreActiveTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning && _targetEndTime != null) {
      _syncRemainingFromTimestamp();
    }
  }

  Future<void> _restoreActiveTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt('active_focus_end_ms');
    final savedMinutes = prefs.getInt('active_focus_duration_min');
    if (endMs != null && savedMinutes != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(endMs);
      final diff = end.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        setState(() {
          _selectedMinutes = savedMinutes;
          _targetEndTime = end;
          _remainingSeconds = diff;
          _isRunning = true;
        });
        _startTicker();
      } else {
        await _clearPersistedTimer();
      }
    }
  }

  Future<void> _persistTimer(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_focus_end_ms', endTime.millisecondsSinceEpoch);
    await prefs.setInt('active_focus_duration_min', _selectedMinutes);
  }

  Future<void> _clearPersistedTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_focus_end_ms');
    await prefs.remove('active_focus_duration_min');
  }

  void _syncRemainingFromTimestamp() {
    if (_targetEndTime == null) return;
    final left = _targetEndTime!.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      _onTimerCompleted();
    } else {
      setState(() => _remainingSeconds = left);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemainingFromTimestamp();
    });
  }

  Future<void> _startTimer() async {
    final end = DateTime.now().add(Duration(seconds: _remainingSeconds));
    setState(() {
      _isRunning = true;
      _targetEndTime = end;
    });
    await _persistTimer(end);
    await NotificationService.scheduleFocusTimerFinished(end, taskTitle: widget.task?.title);
    _startTicker();
  }

  Future<void> _pauseTimer() async {
    _ticker?.cancel();
    if (_targetEndTime != null) {
      final left = _targetEndTime!.difference(DateTime.now()).inSeconds;
      _remainingSeconds = left > 0 ? left : 0;
    }
    setState(() {
      _isRunning = false;
      _targetEndTime = null;
    });
    await _clearPersistedTimer();
    await NotificationService.cancelFocusTimerNotification();
  }

  Future<void> _resetTimer() async {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _targetEndTime = null;
      _remainingSeconds = _selectedMinutes * 60;
    });
    await _clearPersistedTimer();
    await NotificationService.cancelFocusTimerNotification();
  }

  Future<void> _onTimerCompleted() async {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _targetEndTime = null;
      _remainingSeconds = _selectedMinutes * 60;
    });
    await _clearPersistedTimer();
    HapticFeedback.heavyImpact();

    if (!mounted) return;
    final store = context.read<TaskStore>();
    await store.addFocusSession(
      durationMinutes: _selectedMinutes,
      taskId: widget.task?.id,
      taskTitle: widget.task?.title,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Harika Odaklandın! 🔥', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        content: Text(
          '$_selectedMinutes dakikalık odaklanma seansını tamamladın ve +25 XP kazandın!',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          if (widget.task != null && !widget.task!.isDone)
            TextButton(
              onPressed: () async {
                await store.toggleTask(widget.task!.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Görevi de Tamamla ✓', style: TextStyle(color: AppColors.xp, fontWeight: FontWeight.bold)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.xp, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _selectedMinutes * 60;
    final progress = totalSeconds == 0 ? 0.0 : (_remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Odaklanma Modu', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              if (widget.task != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.task!.categoryColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.track_changes_rounded, color: widget.task!.categoryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.task!.title,
                          style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _presets.map((min) {
                  final selected = _selectedMinutes == min;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: _isRunning
                          ? null
                          : () => setState(() {
                                _selectedMinutes = min;
                                _remainingSeconds = min * 60;
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.xp : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AppColors.xp : AppColors.border),
                        ),
                        child: Text(
                          '$min dk',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: const AlwaysStoppedAnimation(AppColors.xp),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formattedTime,
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRunning ? 'ODAKLANIYORSUN 🔥' : 'BAŞLAMAYA HAZIR',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRunning || _remainingSeconds != _selectedMinutes * 60) ...[
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(Icons.refresh_rounded, color: AppColors.text, size: 26),
                      ),
                    ),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? AppColors.work : AppColors.xp,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                      label: Text(
                        _isRunning ? 'Duraklat' : 'Odaklanmayı Başlat',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}