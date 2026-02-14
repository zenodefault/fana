import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_icons.dart';
import '../../../core/glass_widgets.dart';
import '../../../core/providers.dart';
import '../../anatomy/screens/anatomy_screen.dart';

class ExerciseHistoryScreen extends StatelessWidget {
  const ExerciseHistoryScreen({super.key});

  String _formatDayLabel(DateTime date) {
    final today = DateTime.now();
    final difference = DateTime(date.year, date.month, date.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    if (difference == 0) return 'Today';
    if (difference == -1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatTime(DateTime timestamp) =>
      DateFormat('HH:mm').format(timestamp);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FitnessProvider>(context);
    final history = provider.getExerciseHistory();
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise History'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: history.isEmpty
              ? _EmptyHistoryState(
                  isLight: isLight,
                )
              : ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = history[index];
                    final entries = log.exerciseEntries;
                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDayLabel(log.date),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (isLight
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.secondary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${entries.length} exercise${entries.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isLight
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, entryIndex) {
                              final entry = entries[entryIndex];
                              final exercise =
                                  provider.getExerciseById(entry.exerciseId);
                              final name = exercise?.name ?? 'Unknown exercise';
                              final muscle = exercise?.muscleGroup;
                              return GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                margin: EdgeInsets.zero,
                                borderRadius: 16,
                                opacity: 0.18,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AppIcon(
                                      AppIcons.time,
                                      size: 22,
                                      color: theme.iconTheme.color
                                          ?.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${entry.sets} sets × ${entry.reps} reps',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme
                                                  .textTheme.bodyMedium?.color
                                                  ?.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatTime(entry.timestamp),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (muscle != null &&
                                            muscle.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (isLight
                                                      ? theme
                                                          .colorScheme.primary
                                                      : theme
                                                          .colorScheme.secondary)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              muscle,
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: isLight
                                                    ? theme
                                                        .colorScheme.primary
                                                    : theme
                                                        .colorScheme.secondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final bool isLight;
  const _EmptyHistoryState({required this.isLight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 22,
            opacity: 0.18,
            child: AppIcon(
              AppIcons.list,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No exercise history yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log your first set to see it here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          GlassButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnatomyScreen(),
                  settings: const RouteSettings(
                    arguments: {'preselectMuscle': 'Chest'},
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  AppIcons.dumbbell,
                  size: 18,
                  color: isLight
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log an exercise',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
