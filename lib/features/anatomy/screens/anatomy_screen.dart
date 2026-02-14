import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/glass_widgets.dart';
import '../../../core/providers.dart';
import '../widgets/enhanced_muscle_body_widget.dart';
import '../../../core/models.dart';
import '../../workouts/screens/exercise_detail_screen.dart';

class AnatomyScreen extends StatefulWidget {
  const AnatomyScreen({super.key}) : super();

  @override
  State<AnatomyScreen> createState() => _AnatomyScreenState();
}

class _AnatomyScreenState extends State<AnatomyScreen> {
  String? selectedMuscleGroup;
  bool _isExerciseListExpanded = false;

  @override
  void initState() {
    super.initState();
    // Defer accessing ModalRoute.of(context) until the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map<String, dynamic> &&
          arguments.containsKey('preselectMuscle')) {
        setState(() {
          selectedMuscleGroup = arguments['preselectMuscle'] as String?;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isLight ? Colors.black : Colors.white,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: AppIcon(AppIcons.arrowLeft),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text('Anatomy'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AppIcon(
                      AppIcons.dumbbell,
                      size: 20,
                      color: isLight ? Colors.black87 : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap a muscle group to see exercises',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLight ? Colors.black87 : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_isExerciseListExpanded)
                Expanded(
                  flex: 5,
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: EnhancedMuscleBodyWidget(
                      onMuscleTap: (muscleGroup) {
                        setState(() {
                          selectedMuscleGroup = muscleGroup;
                          _isExerciseListExpanded = false;
                        });
                      },
                      highlightedMuscle: selectedMuscleGroup,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                flex: _isExerciseListExpanded ? 9 : 4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: selectedMuscleGroup == null
                      ? GlassCard(
                          key: const ValueKey('empty-exercises'),
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Select a body part to view exercises',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isLight ? Colors.black54 : Colors.white70,
                              ),
                            ),
                          ),
                        )
                      : GlassCard(
                          key: ValueKey(selectedMuscleGroup),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedMuscleGroup!,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isExerciseListExpanded =
                                            !_isExerciseListExpanded;
                                      });
                                    },
                                    icon: AppIcon(
                                      _isExerciseListExpanded
                                          ? AppIcons.collapse
                                          : AppIcons.expand,
                                      size: 18,
                                      color: isLight
                                          ? Colors.black54
                                          : Colors.white70,
                                    ),
                                    tooltip: _isExerciseListExpanded
                                        ? 'Collapse'
                                        : 'Expand',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildExerciseList(
                                  selectedMuscleGroup!,
                                  bottomInset: 88,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(
    String muscleGroup, {
    double bottomInset = 0,
  }) {
    final provider = Provider.of<FitnessProvider>(context);
    final exercises = provider.exerciseDatabase[muscleGroup] ?? [];

    return exercises.isEmpty
        ? Center(
            child: Text(
              'No exercises found for $muscleGroup',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.only(bottom: bottomInset),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    exercise.name,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    exercise.description,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: AppIcon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ExerciseDetailScreen(exercise: exercise),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  void _showExerciseDetail(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${exercise.description}'),
            const SizedBox(height: 8),
            Text('Equipment: ${exercise.equipmentNeeded}'),
            const SizedBox(height: 8),
            Text('Difficulty: ${exercise.difficultyLevel}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
