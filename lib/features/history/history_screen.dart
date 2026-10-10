import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/history_repository.dart';
import '../../data/models/workout_session.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';
import 'history_providers.dart';
import 'session_history_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _calendarMode = false;
  DateTime? _dayFilter;

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dayFilter ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Filtrer par jour',
    );
    if (picked == null) return;
    setState(() {
      _dayFilter = DateTime(picked.year, picked.month, picked.day);
      _calendarMode = false;
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _dayFilter = day;
      _calendarMode = false;
    });
  }

  Future<void> _openDetail(String sessionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionHistoryDetailScreen(sessionId: sessionId),
      ),
    );
    if (!mounted) return;
    ref.invalidate(historyFeedProvider);
    ref.invalidate(trainingDaysProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Liste'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Calendrier'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_calendarMode},
              onSelectionChanged: (selection) =>
                  setState(() => _calendarMode = selection.first),
            ),
          ),
          if (_calendarMode)
            _MonthCalendar(
              selectedDay: _dayFilter,
              onSelectDay: _selectDay,
            )
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dayFilter == null
                                ? 'Toutes les séances'
                                : 'Le ${_formatDay(_dayFilter!)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (_dayFilter != null)
                          IconButton(
                            tooltip: 'Retirer le filtre',
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _dayFilter = null),
                          ),
                        IconButton(
                          tooltip: 'Filtrer par jour',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: _pickDay,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final dayKey = _dayFilter?.millisecondsSinceEpoch;
    final feed = ref.watch(historyFeedProvider(dayKey));
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const EmptyState(
        icon: Icons.error_outline,
        message: 'Impossible de charger l\'historique.',
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.history_outlined,
            message: _dayFilter == null
                ? 'Aucune séance terminée.\nL\'historique s\'affichera ici.'
                : 'Aucune séance ce jour-là.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _HistoryTile(
              entry: entry,
              onTap: () => _openDetail(entry.session.id),
            );
          },
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = entry.session;
    final started = DateTime.parse(session.startedAt).toLocal();
    final abandoned = session.status == WorkoutStatus.abandoned;
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(child: Text(session.name)),
            if (entry.recordExerciseIds.isNotEmpty) const _RecordChip(),
            if (abandoned)
              const Text(
                'Abandonnée',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
          ],
        ),
        subtitle: Text(
          '${_formatDay(started)} · ${_formatTime(started)} · '
          '${entry.durationMinutes} min · ${_formatNumber(entry.volume)} kg',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  const _RecordChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: const Text(
        'RECORD',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MonthCalendar extends ConsumerStatefulWidget {
  const _MonthCalendar({
    required this.selectedDay,
    required this.onSelectDay,
  });

  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  ConsumerState<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<_MonthCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final base = widget.selectedDay ?? DateTime.now();
    _month = DateTime(base.year, base.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(trainingDaysProvider(_month.millisecondsSinceEpoch));
    final marked = days.value ?? const <DateTime>{};
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = _month.weekday - 1;
    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthLabel(_month)} ${_month.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (final label in weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: leading + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final dayNumber = index - leading + 1;
                final day = DateTime(_month.year, _month.month, dayNumber);
                final isMarked = marked.contains(day);
                final isSelected = widget.selectedDay != null &&
                    widget.selectedDay!.year == day.year &&
                    widget.selectedDay!.month == day.month &&
                    widget.selectedDay!.day == day.day;
                return _DayCell(
                  day: dayNumber,
                  isMarked: isMarked,
                  isSelected: isSelected,
                  onTap: () => widget.onSelectDay(day),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isMarked,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isMarked;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.accentPrimary : null,
              border: isSelected ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? AppColors.background : AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMarked ? AppColors.success : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(DateTime month) {
  const names = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return names[month.month - 1];
}

String _formatDay(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}