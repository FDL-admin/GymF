import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tracking_repository.dart';
import '../../domain/tracking.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'progress_photos_view.dart';
import 'tracking_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  bool _showPhotos = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Graphiques'),
                icon: Icon(Icons.show_chart),
              ),
              ButtonSegment(
                value: true,
                label: Text('Photos'),
                icon: Icon(Icons.photo_library_outlined),
              ),
            ],
            selected: {_showPhotos},
            onSelectionChanged: (selection) =>
                setState(() => _showPhotos = selection.first),
          ),
        ),
        Expanded(
          child: _showPhotos ? const ProgressPhotosView() : const _GraphsView(),
        ),
      ],
    );
  }
}

class _GraphsView extends ConsumerWidget {
  const _GraphsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(trackingPeriodProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final value in TrackingPeriod.values)
              ChoiceChip(
                label: Text(value.label),
                selected: period == value,
                onSelected: (_) =>
                    ref.read(trackingPeriodProvider.notifier).select(value),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _ProgressionCard(),
        const SizedBox(height: AppSpacing.lg),
        const _VolumeCard(),
      ],
    );
  }
}

class _ProgressionCard extends ConsumerWidget {
  const _ProgressionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(trackedExercisesProvider).value ?? [];
    final selected = ref.watch(selectedExerciseProvider);
    final effectiveId = exercises.any((e) => e.id == selected)
        ? selected
        : (exercises.isEmpty ? null : exercises.first.id);
    final pointsAsync = effectiveId == null
        ? const AsyncValue<List<ProgressPoint>>.data([])
        : ref.watch(weightProgressionProvider(effectiveId));

    return _ChartCard(
      title: 'Progression par exercice',
      child: exercises.isEmpty
          ? const _NotEnoughData()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: effectiveId,
                  isExpanded: true,
                  items: [
                    for (final exercise in exercises)
                      DropdownMenuItem(
                        value: exercise.id,
                        child: Text(exercise.name),
                      ),
                  ],
                  onChanged: (id) =>
                      ref.read(selectedExerciseProvider.notifier).select(id),
                ),
                const SizedBox(height: AppSpacing.lg),
                pointsAsync.when(
                  data: (points) => points.length < Tracking.minimumPoints
                      ? const _NotEnoughData()
                      : SizedBox(
                          height: 220,
                          child: _WeightLineChart(points: points),
                        ),
                  loading: () => const _ChartLoading(),
                  error: (_, _) => const _NotEnoughData(),
                ),
              ],
            ),
    );
  }
}

class _VolumeCard extends ConsumerWidget {
  const _VolumeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(volumeBySessionProvider);
    return _ChartCard(
      title: 'Volume par séance',
      child: pointsAsync.when(
        data: (points) => points.length < Tracking.minimumPoints
            ? const _NotEnoughData()
            : SizedBox(
                height: 220,
                child: _VolumeBarChart(points: points),
              ),
        loading: () => const _ChartLoading(),
        error: (_, _) => const _NotEnoughData(),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _NotEnoughData extends StatelessWidget {
  const _NotEnoughData();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text('Pas encore assez de données'),
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

abstract final class _ChartFormat {
  static String day(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';

  static Widget bottomTitle(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        day(date),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    );
  }

  static Widget leftTitle(double value) {
    return Text(
      value.toStringAsFixed(0),
      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
    );
  }

  static double interval(int count) => count <= 4 ? 1 : (count / 4).ceilToDouble();
}

class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({required this.points});

  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].weightKg),
    ];
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.accentPrimary,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => _ChartFormat.leftTitle(value),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _ChartFormat.interval(points.length),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return _ChartFormat.bottomTitle(points[index].date);
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItems: (spots) => spots.map((spot) {
              final point = points[spot.x.round()];
              return LineTooltipItem(
                '${_ChartFormat.day(point.date)} · '
                '${point.weightKg.toStringAsFixed(1)} kg',
                const TextStyle(color: AppColors.text),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _VolumeBarChart extends StatelessWidget {
  const _VolumeBarChart({required this.points});

  final List<VolumePoint> points;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].volume,
                  color: AppColors.accentSecondary,
                  width: 12,
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => _ChartFormat.leftTitle(value),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _ChartFormat.interval(points.length),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return _ChartFormat.bottomTitle(points[index].date);
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x];
              return BarTooltipItem(
                '${_ChartFormat.day(point.date)}\n'
                '${point.volume.toStringAsFixed(0)} kg',
                const TextStyle(color: AppColors.text),
              );
            },
          ),
        ),
      ),
    );
  }
}